/**
* @author Rajneewa Silva
* @date 2021-08-10
* @group Controller
* @domain PUD
* @description Controller for PUD Pickup Booking Lightning Application
* @changelog
* 2021-08-10 - Ranjeewa Silva - Created.
*/
public with sharing class PUDPickupBookingController {

	/**
	 * Validate the job to see if it is eligible for sending to external dispatch system. If eligible, trigger an
	 * outbound message to dispatch system.
	 *
	 * @param jobId Id of the Job to be sent
	 *
	 * @return Status of triggering the outbound message. Returns an error if the Job is not eligible to be sent to dispatch system.
	 */
	@AuraEnabled
	public static PickupBookingActionResult triggerDispatchSystemSync(Id jobId) {

		try {
			PickupBookingActionResult result = new PickupBookingActionResult();

			List<PUD_Job__c> jobs = PUDJobsSelector.newInstance().selectById(new Set<Id>{jobId});

			if (canTriggerDispatchSystemSync(jobs[0], result)) {

				List<PUD_Job__c> eligibleJobs = PUDUtility.getInstance().setEligibleJobsToTriggerDispatchSystemSync(new List<PUD_Job__c>{jobs[0]});
				if (eligibleJobs.isEmpty()) {
					result.status = Status.ERROR.name();
					result.errorMessage = System.Label.PUDJobDispatchSystemSyncRestrictedDepotErrorMessage;
				} else {
					ApplicationDatabase.getInstance().dmlUpdate(new List<PUD_Job__c>{jobs[0]});
					result.status = Status.SUCCESSFUL.name();
				}
			}

			return result;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Cancel the PUD Job.
	 *
	 * @param jobId Id of the Job to be sent
	 *
	 * @return Status of cancellation. Returns an error if the Job is not eligible to be cancelled.
	 */
	@AuraEnabled
	public static PickupBookingActionResult cancel(Id jobId) {

		try {

			PickupBookingActionResult result = new PickupBookingActionResult();

			List<PUD_Job__c> jobs = PUDJobsSelector.newInstance().selectById(new Set<Id>{jobId});

			// check if the job is allowed to be cancelled
			if (canCancelJob(jobs[0], result)) {
				// job is allowed to be cancelled.
				PUD_Job__c updatableJob = new PUD_Job__c(Id=jobId);
				updatableJob.Status__c = PUDConstants.PUD_JOB_STATUS_CANCEL;
				ApplicationDatabase.getInstance().dmlUpdate(new List<PUD_Job__c>{updatableJob});
				result.status = Status.SUCCESSFUL.name();
			}

			return result;

		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Validate the Job to check if it can be pushed to dispatch system.
	 *
	 * @param job Job instance to check
	 * @param result result to populate error details
	 *
	 * @return true if job can be sent to dispatch system. false otherwise.
	 */
	private static Boolean canTriggerDispatchSystemSync(PUD_Job__c job, PickupBookingActionResult result) {
		// only current day jobs are allowed to be sent to dispatch system.
		if (job.Date__c != Date.today()) {
			result.status = Status.ERROR.name();
			result.errorMessage = System.Label.PUDJobDispatchSystemSyncRestrictedForDateErrorMessage;
			return false;
		}

		// jobs with Stop Credit = true are not allowed to be sent to dispatch system
		if (job.Stop_Credit__c) {
			result.status = Status.ERROR.name();
			result.errorMessage = System.Label.PUDJobDispatchSystemSyncRestrictedForStopCreditJobsErrorMessage;
			return false;
		}

		//TODO - validate status check TBC
		return true;
	}

	/**
	 * Validate the Job to check if it can be cancelled.
	 *
	 * @param job Job instance to check
	 * @param result result to populate error details
	 *
	 * @return true if job can be cancelled. false otherwise.
	 */
	private static Boolean canCancelJob(PUD_Job__c job, PickupBookingActionResult result) {

		// Jobs in past cannot be cancelled.
		if (Date.today() > job.Date__c) {
			result.status = Status.ERROR.name();
			result.errorMessage = System.Label.PUDCannotCancelPastJobsErrorMessage;
			return false;
		}

		// Future jobs can only be cancelled by updating booking.
		if (Date.today() < job.Date__c) {
			result.status = Status.ERROR.name();
			result.errorMessage = System.Label.PUDUpdateBookingToCancelFutureJobsErrorMessage;
			return false;
		}

		// Jobs in 'New' status are not yet sent to dispatch system.
		// Update the booking to cancel such jobs.
		if (job.Status__c == PUDConstants.PUD_JOB_STATUS_NEW) {
			result.status = Status.ERROR.name();
			result.errorMessage = String.format(System.Label.PUDUpdateBookingToCancelNewJobErrorMessage, new List<String>{job.Status__c});
			return false;
		}

		// Only the jobs in 'Schedule' or 'Accepted' status can be cancelled.
		if (job.Status__c != PUDConstants.PUD_JOB_STATUS_SCHEDULE && job.Status__c != PUDConstants.PUD_JOB_STATUS_ACCEPTED) {
			result.status = Status.ERROR.name();
			result.errorMessage = String.format(System.Label.PUDCancelJobsRestrictedStatusErrorMessage, new List<String>{job.Status__c});
			return false;
		}

		return true;
	}

	/**
     * Status of create Case operation.
     */
	public enum Status {
		SUCCESSFUL,
		ERROR
	}

	public class PickupBookingActionResult {
		@AuraEnabled public String status {get; private set;}
		@AuraEnabled public String errorMessage {get; private set;}
	}

}