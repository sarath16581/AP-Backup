/**
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Dattaraj Deshmukh (dattaraj.deshmukh@slalom.com)
 * @date 2022-06-23
 * @tag Container Types
 * @domain Container Booking
 * @description Module class to process a business logic when Implementation stage is update on DSR record..
 * @changelog
 * 2022-06-23 - Dattaraj Deshmukh - Created
 */


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
		getTriggerEvents().enableAfterUpdate().enableAfterInsert().enableBeforeInsert().enableAfterDelete();
	}

    /**
	 * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
	 */
	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module)PUDContainerTypeSyncModule.newInstance();
		}
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow){
		processContainers((List<PUD_Container__c> )records, uow);
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow){
		preventDuplicateContainerRecords(records);
	}

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
		processContainers((List<PUD_Container__c> )records, uow);
    }


    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow){
		processContainers((List<PUD_Container__c> )records, uow);
    }

	private void preventDuplicateContainerRecords(List<PUD_Container__c> newRecords){
		Set<Id> bookingIds = new Set<Id>();
		Set<Id> jobIds = new Set<Id>();
		
		//map to store existing containers under a booking.
		//Container Type + Condition is a criteria to identify uniqueness.
		//e.g. Pallets, Empty and Pallets, Full are considered as two different containers.
		//Duplicates will be checked against Type + Condition uniqueness.
		Map<Id, Set<String>> bookingIdVsContainerUniqueKey = new Map<Id, Set<String>>();
		
		Id bookingContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Booking_Container'}).values()[0].Id;

		//get job and booking ids
		for(PUD_Container__c container : newRecords){

			if(container.RecordTypeId == bookingContainerRecordTypeId){
				bookingIds.add(container.Booking__c);
			}
		}

		//get booking container
		for(PUD_Container__c container : PUDContainersSelector.newInstance().selectBookingContainersByBookingIds(bookingIds, new Set<Object>())){
			String uniqueKey = container.Type__c+container.Condition__c;

			if(!bookingIdVsContainerUniqueKey.containsKey(container.Booking__c)){
				bookingIdVsContainerUniqueKey.put(container.Booking__c, new Set<String> {uniqueKey});
			}
			else{
				bookingIdVsContainerUniqueKey.get(container.Booking__c).add(uniqueKey);
			}
		}

		for(PUD_Container__c newContainer : newRecords){
			String uniqueKey = newContainer.Type__c+newContainer.Condition__c;

			if(bookingIdVsContainerUniqueKey.containsKey(newContainer.Booking__c) && bookingIdVsContainerUniqueKey.get(newContainer.Booking__c).contains(uniqueKey)){
				newContainer.addError('Container type: '+newContainer.Type__c+ ' with condition: '+ newContainer.Condition__c+ ' already exists under a booking. Please update existing container type.');
			}
		}
	}

	private void processContainers(List<PUD_Container__c> records, ApplicationUnitOfWork uow){
		Id bookingContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Booking_Container'}).values()[0].Id;

		Set<Id> bookingIds = new Set<Id>();
		for(PUD_Container__c container : records){
			//Check if container's record type id = Booking_Container.
			if(container.RecordTypeId == bookingContainerRecordTypeId){
				bookingIds.add(container.Booking__c);
			}
		}

		//if Booking Containers are not updated then return.
		//Todo: Job Containers are processed separately.
		if(bookingIds.isEmpty()){
			return;
		}

		try{
			//call utility method to sycn containers.
			PUDUtility.getInstance().refreshContainerTypes(bookingIds, uow);
		} catch(Exception exp) {
            system.debug('Exp: '+exp);
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDContainerTypeSyncModule.class.getName(), 'refreshContainerTypesSync', 'PUDContainerTrigger', LoggingLevel.ERROR);
		}
	}

}
