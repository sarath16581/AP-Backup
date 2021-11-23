/***
 * @description
 * Event handler for processing Job Dispatch Events (platform events) received from Dispatch System (via Tibco).
 * @author Ranjeewa Silva
 * @date 2021-08-25
 * @domain PUD
 * @changelog
 * 2021-08-25 - Ranjeewa Silva - Created.
 * 2021-10-11 - Ranjeewa Silva - Implemented special handling for receiving "Accepted" job action out of order.
 * 2021-11-11 - Ranjeewa Silva - Fixed an issue where cancellation confirmed timestamp was not getting populated.
 */

public inherited sharing class PUDJobDispatchEventHandler {

	// load status mappings configured in custom metadata
	private static Map<String, PUD_Job_Dispatch_Status_Mapping__mdt> jobDispatchStatusMappings {
		get {
			if(jobDispatchStatusMappings == null) {
				Map<String, PUD_Job_Dispatch_Status_Mapping__mdt> mappings = new Map<String, PUD_Job_Dispatch_Status_Mapping__mdt>();
				for (PUD_Job_Dispatch_Status_Mapping__mdt record : [
						Select Label, DeveloperName, Job_Status__c, Is_Scheduled_Confirmation__c
						From PUD_Job_Dispatch_Status_Mapping__mdt
				]) {
					mappings.put(record.DeveloperName, record);
				}
				jobDispatchStatusMappings = mappings;
			}
			return jobDispatchStatusMappings;
		}
		private set;
	}

	/**
     * Creates a new instance. This allows use to use dependency injection for mocking
     * @return the new instance
     */
	public static PUDJobDispatchEventHandler getInstance() {
		return (PUDJobDispatchEventHandler) Application.Utilities.getInstance(PUDJobDispatchEventHandler.class);
	}

	/**
	 * Process events of type 'Job_Action' and update PUD Job status
	 *
	 * @param events 'Job_Action' events from dispatch system
	 */
	public void processJobActionEvents(List<PUD_Job_Dispatch_Event__e> events) {

		// iterate through each event and collect all parent job ids.
		Set<Id> parentJobIds = new Set<Id>();
		for (PUD_Job_Dispatch_Event__e event : events) {
			if (String.isNotBlank(event.Parent_Id__c)) {
				Id jobId = getParentJobId(event.Parent_Id__c);
				if (jobId != null) {
					parentJobIds.add(jobId);
				}
			}
		}

		// retrieve all parent jobs
		Map<Id, PUD_Job__c> jobs = new Map<Id, PUD_Job__c>(PUDJobsSelector.newInstance().selectById(parentJobIds));

		// process each event to determine the list of updatable jobs
		Map<Id, PUD_Job__c> updatableJobs = new Map<Id, PUD_Job__c>();
		for (PUD_Job_Dispatch_Event__e event: events) {
			Id jobId = getParentJobId(event.Parent_Id__c);
			if (jobId != null && jobs.containsKey(jobId)) {
				// we have a valid Job Id. need to get the current job details before processing this event.
				// if same job has been previously updated in current batch, get the job from 'updatableJobs' map. otherwise
				// use the job record returned by selector query.
				PUD_Job__c currentJob = updatableJobs.containsKey(jobId) ? updatableJobs.get(jobId): jobs.get(jobId);

				// process the event and update job if required.
				PUD_Job__c updatableJob = processJobActionEvent(event, currentJob);
				if (updatableJob != null) {
					// job has been updated as a result of processing current event.
					// make it the version to be updated for this job id. discard any previous versions.
					updatableJobs.put(updatableJob.Id, updatableJob);
				}
			}
		}

		if (!updatableJobs.isEmpty()) {
			// attempt to update the jobs. any dml failures result in an exception being thrown
			ApplicationDatabase.getInstance().dmlUpdate(updatableJobs.values());
		}
	}

	/**
	 * Process the event and update relevant Job details and return the updatable Job.
	 *
	 * @param event the event to process
	 * @param job parent Job related to this event
	 *
	 * @return updateable instance of the Job. returns null if nothing to update.
	 */
	private PUD_Job__c processJobActionEvent(PUD_Job_Dispatch_Event__e event, PUD_Job__c job) {

		// check if the mapping is available for the status in the event.
		if (jobDispatchStatusMappings.containsKey(event.Status__c)) {
			PUD_Job_Dispatch_Status_Mapping__mdt mapping = jobDispatchStatusMappings.get(event.Status__c);

			// determine job status based on the mapping.
			String jobStatus = (String.isNotBlank(mapping.Job_Status__c) ? mapping.Job_Status__c: job.Status__c);

			// special handling for out of order job actions - ignore 'Accepted' action if existing job status is
			// not "New" or "Schedule". indicates that the "Accepted" event has been received out of order.
			if (jobStatus != PUDConstants.PUD_JOB_STATUS_ACCEPTED
					|| (job.Status__c == PUDConstants.PUD_JOB_STATUS_NEW || job.Status__c == PUDConstants.PUD_JOB_STATUS_SCHEDULE)) {

				// job status has to be updated
				PUD_Job__c updatableJob = new PUD_Job__c(Id = job.Id);
				updatableJob.Status__c = jobStatus;

				if (mapping.Is_Scheduled_Confirmation__c) {
					// event is considered a confirmation for a schedule request. populate Schedule_Confirmed_Timestamp__c
					// to current time if not already populated.
					// if Schedule_Confirmed_Timestamp__c is already populated, that means we have already received a schedule
					// confirmation for this job.
					updatableJob.Schedule_Confirmed_Timestamp__c = (job.Schedule_Confirmed_Timestamp__c != null ? job.Schedule_Confirmed_Timestamp__c : System.now());
				}

				if (updatableJob.Status__c == PUDConstants.PUD_JOB_STATUS_FAILED) {
					// populate failure reason and comments for Failed jobs.
					updatableJob.Failure_Reason__c = event.Reason__c;
					updatableJob.Driver_Comments__c = event.Comments__c;
				}

				if (updatableJob.Status__c == PUDConstants.PUD_JOB_STATUS_CANCELLED) {
					// event is confirmation for a cancel request
					// if Cancellation_Confirmed_Timestamp__c is already populated, that means we had already received a cancellation
					// confirmation for this job.
					updatableJob.Cancellation_Confirmed_Timestamp__c = (job.Cancellation_Confirmed_Timestamp__c != null ? job.Cancellation_Confirmed_Timestamp__c : System.now());
				}
				return updatableJob;
			}
		}

		// nothing to update. return null
		return null;
	}

	/**
	 * Validate the id passed in is a valid PUD_Job__c Id.
	 * @param parentId id (string) to check
	 *
	 * @return Id (type Id). returns null if the id(string) passed in is not valid
	 */
	private Id getParentJobId(String parentId) {
		try {
			Id jobId = Id.valueOf(parentId);
			if (PUD_Job__c.getSObjectType() == jobId.getSobjectType()) {
				return jobId;
			}
		} catch (Exception ex) {}
		return null;
	}

}