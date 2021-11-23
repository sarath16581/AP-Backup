/**
* @author Arjun Singh
* @date 2021-07-27
* @description pick up all the PUD  Jobs which has not been sent to Dispatch system and updates the 'Send To Dispatch System' Flag as true.
*              In turns it fires a workflow which is responsible for sending the job record to Dispatch system via outbound message mechanism
* @domain PUD
* @changelog
* 2021-07-27 - Arjun Singh - Created.
*/
public class PUDSendJobToDispatchSystemBatch implements Database.Batchable<SObject>, Schedulable {

	private static final Integer BATCH_SIZE {
        get {
            if (BATCH_SIZE == null) {
	            // get the batch size configured in custom settings. defaults to 200 if configuration is not available.
                Pickup_Booking_Settings__c pickupBookingSettings = Pickup_Booking_Settings__c.getInstance();
                BATCH_SIZE = (pickupBookingSettings?.PUDSendJobToDispatchSystemBatchSize__c != null ? Integer.valueOf(pickupBookingSettings.PUDSendJobToDispatchSystemBatchSize__c) : 200);
            }
            return BATCH_SIZE;
        }
        private set;
    }

    public Database.QueryLocator start(Database.BatchableContext ctx) {
		PUDJobsSelector pudJobSelector = PUDJobsSelector.newInstance(0);
		return pudJobSelector.selectJobsByDateAndStatusQueryLocator(date.today(), PUDConstants.PUD_JOB_STATUS_NEW);
	}

	public void execute(Database.BatchableContext ctx, List<SObject> scope) {
		try {
			List<PUD_Job__c> pudBookingList = PUDUtility.getInstance().setEligibleJobsToTriggerDispatchSystemSync((List<PUD_Job__c>) scope);
			if (!pudBookingList.isEmpty()) {
				List<Database.SaveResult> pudJobSaveResults = ApplicationDatabase.getInstance().dmlUpdate(pudBookingList, false);
				// Error Logged to Exception object for analysis. logDmlResults method filters out the success and only log errors
				// from pudJobSaveResults list
				UTIL_LoggingService.logDmlResults(pudJobSaveResults, null, pudBookingList, PUDConstants.PICKUP_BOOKING_APP,
						PUDSendJobToDispatchSystemBatch.class.getName(), 'execute',null, LoggingLevel.ERROR);
			}

		} catch (Exception exp) {
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDSendJobToDispatchSystemBatch.class.getName(), 'execute', null, LoggingLevel.ERROR);
		}
	}

    public void execute(SchedulableContext ctx) {
		Database.executeBatch(new PUDSendJobToDispatchSystemBatch(), BATCH_SIZE);
	}

    public void finish(Database.BatchableContext ctx) {
	}
}