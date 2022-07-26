/**
 * @description       : This class handles calling the Customer Data Sync Event Trigger
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-20-2022
 * @Test CustomerDataSyncEventTrgrHldr_Test
 * @last modified by  : Sreenish Krishnan
 **/
public inherited sharing class CustomerDataSyncEventTriggerHandler {
	private static void afterInsertHandler(List<CustomerDataSync__e> events) {
		try {
			CustomerDataSyncEventHandler.getInstance()
				.processCustomerDataSyncEvent(events);
		} catch (Exception e) {
			UTIL_LoggingService.logHandledException(
				e,
				UserInfo.getOrganizationId(),
				'CustomerDataSyncEventTriggerHandler',
				CustomerDataSyncEventTriggerHandler.class.getName(),
				'afterInsertHandler',
				'CustomerDataSyncEventTrigger',
				LoggingLevel.ERROR
			);
		}
	}

	// calls the respective handler method
	public static void execute() {
		// trigger on platform events fired only on after insert.
		afterInsertHandler(Trigger.new);
	}
}