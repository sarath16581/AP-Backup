/***
 * @description
 * Handles platform events published by Tibco for job dispatch events from external dispatch system (MobileSTAR).
 * This class deals with platform event specific logic (such as retry handling) and delegates to appropriate handler
 * methods in PUDJobDispatchEventHandler class to process events.
 * @author Ranjeewa Silva
 * @date 2021-08-25
 * @domain PUD
 * @changelog
 * 2021-08-25 - Ranjeewa Silva - Created.
 * 2022-08-15 - Dattaraj Deshmukh - Added UnitOfWork and passed to processJobActionEvents() method.
 */

public inherited sharing class PUDJobDispatchEventTriggerHandler {

	private static Integer maximumRetryAttempts {
		get {
			if (maximumRetryAttempts == null) {
				Pickup_Booking_Settings__c settings = Pickup_Booking_Settings__c.getInstance();
				if (settings != null && settings.Job_Dispatch_Event_Retry_Attempts__c != null) {
					maximumRetryAttempts = Integer.valueOf(settings.Job_Dispatch_Event_Retry_Attempts__c);
				} else {
					maximumRetryAttempts = 3; // set a default value if not configured in custom setting
				}
			}
			return maximumRetryAttempts;
		}
		private set;
	}

	// calls the respective handler method
	public static void execute() {
		// trigger on platform events fired only on after insert.
		afterInsertHandler(Trigger.new);
	}

	private static void afterInsertHandler(List<PUD_Job_Dispatch_Event__e> events) {
		try {

			//Creating UnitOfWork for PUD_Job__c and PUD_Container__c 
			//UnitOfWork is required to process partially saved records received from Dispatch Interface.
			ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
			
			// currently only job action (status update) events are being received by Salesforce - call the status update event handler
			// with the full list.
			// if other types of events are received by Salesforce, below code need to iterate through the list
			// and call appropriate event handler based on the event type.
			PUDJobDispatchEventHandler.getInstance().processJobActionEvents(events, uow);

			//commit UnitOfWork.
			//This commits job updates and container types upserts into database.
			uow.commitWork();


		} catch (Exception e) {
			// check the number of times the batch has been retried
			if (EventBus.TriggerContext.currentContext().retries < maximumRetryAttempts) {
				// more retry attempts available based on configuration. throw EventBus.RetryableException
				// so the current batch of events are processed again.
				throw new EventBus.RetryableException(e);
			} else {
				// batch has been retried the maximum number of times allowed.
				// log an error and move on to process the next batch.
				UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP,
						PUDJobDispatchEventTriggerHandler.class.getName(), 'afterInsertHandler',
						'PUDJobDispatchEventTrigger', LoggingLevel.ERROR);
			}
		}
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			PUD_Container__c.SObjectType,
			PUD_Job__c.SObjectType			
		};
	}
}