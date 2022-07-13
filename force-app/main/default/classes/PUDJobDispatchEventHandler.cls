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
 * 2022-01-18 - Ranjeewa Silva - Populate dispatch event timestamp on job.
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
		Map<Id, PUD_Job__c> jobs = new Map<Id, PUD_Job__c>(PUDJobsSelector.newInstance(0, new Set<SObjectField>{
				PUD_Job__c.Id, PUD_Job__c.Status__c, PUD_Job__c.Failure_Reason__c, PUD_Job__c.Driver_Comments__c,
				PUD_Job__c.Schedule_Request_Timestamp__c, PUD_Job__c.Cancellation_Request_Timestamp__c,
				PUD_Job__c.Schedule_Confirmed_Timestamp__c, PUD_Job__c.Last_Pushed_to_Dispatch_System__c,
				PUD_Job__c.Cancellation_Confirmed_Timestamp__c, PUD_Job__c.Failed_Timestamp__c, PUD_Job__c.Accepted_Timestamp__c,
				PUD_Job__c.Completed_Timestamp__c, PUD_Job__c.Cancelled_Timestamp__c, PUD_Job__c.Containers_Payload_From_MobileStar__c
		}).selectById(parentJobIds));


		Map<Id, List<PUD_Container__c>> jobIdVsContainers = new Map<Id, List<PUD_Container__c>>();
		
		//get all containers under jobs.
		for(PUD_Container__c container : PUDContainersSelector.newInstance().selectByJobIds(parentJobIds, new Set<Object>())){
			if(!jobIdVsContainers.containsKey(container.Job__c)){
				jobIdVsContainers.put(container.Job__c, new List<PUD_Container__c>{container});
			}
			else{
				jobIdVsContainers.get(container.Job__c).add(container);
			}
		}

		//containers to upsert with actual numbers.
		//Update: existing containers with actual numbers sent from MobileStar
		//Insert: MobileStar sends containers which does not exists under a job in Salesforce.
		List<PUD_Container__c> containersToUpsert = new List<PUD_Container__c>();


		// process each event to determine the list of updatable jobs
		Map<Id, PUD_Job__c> updatableJobs = new Map<Id, PUD_Job__c>();
		for (PUD_Job_Dispatch_Event__e event: events) {
			Id jobId = getParentJobId(event.Parent_Id__c);
			if (jobId != null && jobs.containsKey(jobId)) {
				// we have a valid Job Id. need to get the current job details before processing this event.
				// if same job has been previously updated in current batch, get the job from 'updatableJobs' map. otherwise
				// use the job record returned by selector query.
				PUD_Job__c updatableJob = updatableJobs.containsKey(jobId) ? updatableJobs.get(jobId): jobs.get(jobId);

				// process the event and update job if required.
				Boolean isUpdated = processJobActionEvent(event, updatableJob);
				if (isUpdated && !updatableJobs.containsKey(jobId)) {
					// job has been updated as a result of processing current event.
					// add job instance into 'updatableJobs' map if not already in it.
					updatableJobs.put(updatableJob.Id, updatableJob);
				}

				if(event.Containers_Payload__c != null && jobIdVsContainers.containsKey(updatableJob.Id)){
					List<PUD_Container__c> containersWithActuals = populateActualsOnContainers(event.Containers_Payload__c, jobIdVsContainers.get(updatableJob.Id));
					if(!containersWithActuals.isEmpty()){
						containersToUpsert.addAll(containersWithActuals);
					}
				}

			}
		}

		if (!updatableJobs.isEmpty()) {
			// attempt to update the jobs. any dml failures result in an exception being thrown
			ApplicationDatabase.getInstance().dmlUpdate(updatableJobs.values());
		}

		if (!containersToUpsert.isEmpty()) {
			// attempt to upsert the containers.
			upsert containersToUpsert;
			//ApplicationDatabase.getInstance().dmlUpsert(containersToUpsert, idField);
			//ApplicationDatabase.getInstance().dmlUpsert(new List<Account>{}, Account.Id);
		}
		
	}

	/**
	 * Process the event and update relevant details on the Job record passed in.
	 *
	 * @param event the event to process
	 * @param job parent Job related to this event
	 *
	 * @return true if job has been updated as a result of processing the event. false otherwise.
	 */
	private Boolean processJobActionEvent(PUD_Job_Dispatch_Event__e event, PUD_Job__c job) {

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
				job.Status__c = jobStatus;

				//populate container payload received from MobileStar
				job.Containers_Payload_From_MobileStar__c = event.Containers_Payload__c;

				if (mapping.Is_Scheduled_Confirmation__c && job.Schedule_Confirmed_Timestamp__c == null) {
					// event is considered a confirmation for a schedule request. populate Schedule_Confirmed_Timestamp__c
					// to current time if not already populated.
					// if Schedule_Confirmed_Timestamp__c is already populated, that means we have already received a schedule
					// confirmation for this job.
					job.Schedule_Confirmed_Timestamp__c = System.now();
				}

				if (job.Status__c == PUDConstants.PUD_JOB_STATUS_FAILED) {
					// populate failure reason and comments for Failed jobs.
					job.Failure_Reason__c = event.Reason__c;
					job.Driver_Comments__c = event.Comments__c;
					job.Failed_Timestamp__c = event.Event_Timestamp__c;
				} else if (job.Status__c == PUDConstants.PUD_JOB_STATUS_CANCELLED) {
					// event is confirmation for a cancel request
					// if Cancellation_Confirmed_Timestamp__c is already populated, that means we had already received a cancellation
					// confirmation for this job.
					job.Cancellation_Confirmed_Timestamp__c = (job.Cancellation_Confirmed_Timestamp__c != null ? job.Cancellation_Confirmed_Timestamp__c : System.now());
					job.Cancelled_Timestamp__c = event.Event_Timestamp__c;
				} else if (job.Status__c == PUDConstants.PUD_JOB_STATUS_ACCEPTED) {
					job.Accepted_Timestamp__c = event.Event_Timestamp__c;
				} else if (job.Status__c == PUDConstants.PUD_JOB_STATUS_COMPLETED) {
					job.Completed_Timestamp__c = event.Event_Timestamp__c;
				}

				return true;
			} else {
				// 'Accepted' job action received out of order. No need to update status as a subsequent job action has
				// already been processed - only update the event timestamp for the 'Accepted' event.
				job.Accepted_Timestamp__c = event.Event_Timestamp__c;

				//populate container payload received from MobileStar
				job.Containers_Payload_From_MobileStar__c = event.Containers_Payload__c;
				return true;
			}
		}

		// nothing to update. return false
		return false;
	}

	/**
	 * Get list of container Ids under a job to update with actuals quantity
	 * @param event the event to process
	 * @param job parent Job related to this event
	 *
	 * @return list of container ids and their actual numbers
	 */
	private List<PUD_Container__c> populateActualsOnContainers(String eventContainerPayload, List<PUD_Container__c> containers) {
		List<PUD_Container__c> containersToUpsert = new List<PUD_Container__c>();
		//get Job Container record type ID
		Id jobContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Job_Container'}).values()[0].Id;
				
		List<ContainersPayload> containerPayloadObjects = (List<ContainersPayload>) JSON.deserialize(eventContainerPayload, List<ContainersPayload>.class);
		Id bookingId; Id jobId;

		for(ContainersPayload containerWrapper : containerPayloadObjects){
			Boolean isMatchingContainerFound = false;

			System.debug('Matching: '+containerWrapper.Name+' and Condition: '+containerWrapper.Condition);

			for(PUD_Container__c pContainer : containers){

				//storing booking id and job id in case a new container type need to be created under a job.
				//This avoid additional SOQL to get booking id from container.
				bookingId = pContainer.Booking__c;
				jobId = pContainer.Job__c;

				//if type and condition is matched, update the actuals.
				//Note: Pallets, Empty and Pallets, Full are considered as two different containers.

				System.debug('With Name: '+pContainer.Type__c+' and Condition: '+pContainer.Condition__c);
				
				if(pContainer.Type__c == containerWrapper.Name && pContainer.Condition__c == containerWrapper.Condition){
					containersToUpsert.add(New PUD_Container__c(Id = pContainer.Id, Actual_Quantity__c = containerWrapper.ActualQuantity));
					isMatchingContainerFound = true;

					system.debug('Match Found');
				}
			}

			System.debug('Match Not Found for : '+containerWrapper.Name + ' Boolean value: '+isMatchingContainerFound);

			//if MobileStar sends container type which does not exist under a job in Salesforce, then create a container type.
			if(!isMatchingContainerFound){
				PUD_Container__c newContainer =  new PUD_Container__c();
				newContainer.Booking__c = bookingId;
				newContainer.Job__c = jobId;
				newContainer.Type__c = containerWrapper.Name;
				newContainer.Actual_Quantity__c = containerWrapper.ActualQuantity;
				newContainer.Condition__c = containerWrapper.Condition;
				newContainer.Expected_Quantity__c = containerWrapper.Quantity;
				newContainer.RecordTypeId = jobContainerRecordTypeId;
				containersToUpsert.add(newContainer);
			}
		}

		return containersToUpsert;
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

	private class ContainersPayload{
		String Name;
		String Condition;
		Integer Quantity;
		Integer ActualQuantity;

	}


}