/***
 * @description
 *      Orchestrates the status checking when an async-soql has been added to retrieve ApiEvent data
 *      The async soql pumps data into ApiEventAnalysis__c object which is used to analyse and understand what inbound integrations are in use
 *
 * @author Nathan Franklin
 * @date 2021-03-01
 * @group Integration
 * @changelog
 */
public inherited sharing class IntegrationInboundApiStatusScheduler implements System.Schedulable {
	private Id asyncSoqlJobId;
	private Datetime endEventDateCriteria;
	private Boolean reenqueueAsyncSoqlJob;

	/**
	 * @param endEventDateCriteria This is the end date used in the async soql criteria, we pass this through so we know what the new Last Event Date is when the async soql job completes successfully
	 * @param reenqueueAsyncSoqlJob This is used to indicate whether a subsequent async soql job is required to continue the retrieval of all the records to bring us uptodate with the current time (now()). If this is set to true another async-soql job will be enqueued with the new Event Date criteria
	 */
	public IntegrationInboundApiStatusScheduler(Id jobId, Datetime endEventDateCriteria, Boolean reenqueueAsyncSoqlJob) {
		this.asyncSoqlJobId = jobId;
		this.endEventDateCriteria = endEventDateCriteria;
		this.reenqueueAsyncSoqlJob = reenqueueAsyncSoqlJob;
	}

	public void execute(SchedulableContext sc) {
		// Use a queue here to allow callouts
		System.enqueueJob(new StatusCheckQueueable(sc.getTriggerId(), asyncSoqlJobId, endEventDateCriteria, reenqueueAsyncSoqlJob));
	}

	/**
	 * Schedule a job to check the status of the async soql job
	 * This will keep rescheduling itself until the job is complete
	 *
	 * @param jobId
	 * @param endEventDateCriteria This is the end date used in the async soql criteria, we pass this through so we know what the new Last Event Date is when the async soql job completes successfully
	 * @param reenqueueAsyncSoqlJob This is used to indicate whether a subsequent async soql job is required to continue the retrieval of all the records to bring us uptodate with the current time (now()). If this is set to true another async-soql job will be enqueued with the new Event Date criteria
	 */
	public static void scheduleOneTimeAsyncSoqlStatusCheck(Id jobId, Datetime endEventDateCriteria, Boolean reenqueueAsyncSoqlJob) {
		IntegrationApiSettings__c settings = IntegrationInboundApiLoggingService.getIntegrationApiSettings();
		IntegrationInboundApiStatusScheduler statusJob = new IntegrationInboundApiStatusScheduler(jobId, endEventDateCriteria, reenqueueAsyncSoqlJob);

		// increment the current time by settings.InboundQueryApiAsyncStatusInterval__c to get the next scheduled time
		// since we can't run schedules every x minutes, we run a single schedule and abort it at it's conclusion
		Datetime nextRunTime = Datetime.now().addMinutes(Integer.valueOf(settings.InboundQueryApiAsyncStatusInterval__c));
		System.debug('nextRunTime: ' + nextRunTime);
		String cron = '0 ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year();
		System.schedule('IntegrationInboundApiLoggingScheduler - status check', cron, statusJob);
	}

	/**
	 * Remove the one time status check scheduled task
	 * This is done at the conclusion of every status check run since the status job itself will enqueue the next status check job
	 */
	private static void unscheduleJob(Id jobId) {
		System.abortJob(jobId);
	}

	public class StatusCheckQueueable implements Queueable, Database.AllowsCallouts {
		Id scheduledJobId;
		Id asyncSoqlJobId;
		Datetime endEventDateCriteria;
		Boolean reenqueueAsyncSoqlJob;

		public StatusCheckQueueable(Id scheduledJobId, Id asyncSoqlJobId, Datetime endEventDateCriteria, Boolean reenqueueAsyncSoqlJob) {
			this.scheduledJobId = scheduledJobId;
			this.asyncSoqlJobId = asyncSoqlJobId;
			this.endEventDateCriteria = endEventDateCriteria;
			this.reenqueueAsyncSoqlJob = reenqueueAsyncSoqlJob;
		}

		public void execute(QueueableContext context) {
			System.debug('asyncSoqlJobId: ' + asyncSoqlJobId);
			System.debug('Schedulable Job Id: ' + scheduledJobId);
			System.debug('Upper Event Date Upper Bound: ' + endEventDateCriteria);
			System.debug('Another Async Soql Job After This One: ' + reenqueueAsyncSoqlJob);

			Boolean rescheduleStatusJob = false;

			// call the salesforce API to get the current status of the logged job
			AsyncSOQLService.Response apiResponse = AsyncSOQLService.getInstance().getJobStatus(asyncSoqlJobId);
			System.debug('apiResponse: ' + apiResponse);

			if(apiResponse.isComplete) {
				System.debug('Job has completed!');

				// grab the latest settings
				IntegrationApiSettings__c settings = IntegrationInboundApiLoggingService.getIntegrationApiSettings();

				// Update the event date in the custom settings to reflect the completion of the async soql job
				// The end date is set at the start of the process where the async-soql is initially enqueued
				// It's passed through to the Status scheduler and finally to this queueable
				// We do this so we can track the point in time where we need to rekick our extraction off from.
				ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{new IntegrationApiSettings__c(Id = settings.Id, LastInboundQueryApiEventDate__c = endEventDateCriteria)});

				if(reenqueueAsyncSoqlJob) {
					System.debug('Reenqueuing the next Async-Soql job to grab the latest data since end date is only: ' + endEventDateCriteria);
					// the job has completed and now we can kick off the batch job for processing the records copied into the ApiEventAnalysis__c object
					System.enqueueJob(new AsyncSoqlQueueable());
				} else {
					// the job has completed and now we can kick off the batch job for processing the records copied into the ApiEventAnalysis__c object
					Database.executeBatch(new IntegrationInboundApiLoggingBatch(), Integer.valueOf(settings.InboundQueryApiBatchScopeSize__c));
				}
			} else if(apiResponse.isError) {
				// do not reschedule status check job...
				// log an error in the error log table
				//TODO error handling
				System.debug('ERROR');
			} else {
				// reschedule the next status check
				// this will be rescheduled based on custom settings x number of minutes
				rescheduleStatusJob = true;
			}

			// remove the current schedule job
			unscheduleJob(scheduledJobId);

			if(rescheduleStatusJob) {
				// the async soql job hasn't completed yet so we need to reschedule it for another run
				scheduleOneTimeAsyncSoqlStatusCheck(asyncSoqlJobId, endEventDateCriteria, reenqueueAsyncSoqlJob);
			}
		}

	}

	/**
	 * Queueable for kicking of the next async-soql request
	 * This is used when we need to chain async-soql requests together in order to ensure we are always up to date with our data extraction
	 */
	public class AsyncSoqlQueueable implements Queueable, Database.AllowsCallouts {
		public void execute(QueueableContext context) {
			IntegrationInboundApiLoggingService.extractBigObjectData();
		}
	}
}