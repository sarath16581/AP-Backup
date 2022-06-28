public with sharing class PUDContainerTypeSyncModule  extends ApplicationDomain.Module{
    private static final Set<SObjectField> MONITORED_FIELDS_FOR_UPDATES {
		get {
			if (MONITORED_FIELDS_FOR_UPDATES == null) {
				MONITORED_FIELDS_FOR_UPDATES = new Set<SObjectField>{
					PUD_Container__c.Type__c, PUD_Container__c.Actual_Quantity__c, PUD_Container__c.Expected_Quantity__c, PUD_Container__c.Condition__c 
				};
			}
			return MONITORED_FIELDS_FOR_UPDATES;
		}
		set;
	}

    public static PUDContainerTypeSyncModule newInstance() {
		return (PUDContainerTypeSyncModule) Application.Utilities.newInstance(PUDContainerTypeSyncModule.class);
	}

	// Setup which trigger events this module should respond to
	public PUDContainerTypeSyncModule() {
		getTriggerEvents().enableAfterUpdate().enableAfterInsert();
	}

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)PUDContainerTypeSyncModule.newInstance();
		}
	}

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
        system.debug('in after update: ');
        processContainerUpdatesOnBookings((List<PUD_Container__c> )records, (Map<Id, PUD_Container__c> ) existingRecords, uow);
    }


    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow){
		system.debug('in after insert: ');
        processContainerUpdatesOnBookings((List<PUD_Container__c> )records, null, uow);

    }


	private void processContainerUpdatesOnBookings(List<PUD_Container__c> records, Map<Id, PUD_Container__c> existingRecords, ApplicationUnitOfWork uow){

		Map<Id, Set<SObjectField>> changedRecords;

		//check null as existingRecords will be unavailable for AfterInsert trigger.
		if(existingRecords != null){
			//check if records are updated and updated via booking
			changedRecords = getIsChanged(records, existingRecords, MONITORED_FIELDS_FOR_UPDATES);
		}
		Set<Id> bookingIdSet = new Set<Id>();
		for(PUD_Container__c container : records){

			if(container.Booking__c != null && container.job__c == null){
				bookingIdSet.add(container.Booking__c);
			}
		}


		//query booking records
		List<PUD_Booking__c> bookings = PUDBookingsSelector.newInstance().selectById(bookingIdSet);

		//call utility method to refreshJobs.
		try{
			PUDUtility.getInstance().processContainers(records, bookings);
		} catch(Exception exp) {
            system.debug('Exp: '+exp);
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDContainerTypeSyncModule.class.getName(), 'refreshContainerTypesSync', 'PUDContainerTrigger', LoggingLevel.ERROR);
		}
	}

}
