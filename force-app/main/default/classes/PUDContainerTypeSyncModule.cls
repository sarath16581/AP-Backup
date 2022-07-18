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
		system.debug('in after Delete: ');

		processContainerDeletionOnBookings((List<PUD_Container__c> )records, uow);
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow){
		//preventNewContainersCreation(records);
		preventDuplicateContainerRecords(records);
	}

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
        system.debug('in after update: ');
        processContainerUpdatesOnBookings((List<PUD_Container__c> )records, (Map<Id, PUD_Container__c> ) existingRecords, uow);
    }


    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow){
		system.debug('in after insert: ');
        processContainerUpdatesOnBookings((List<PUD_Container__c> )records, null, uow);

    }

	private void processContainerDeletionOnBookings(List<PUD_Container__c> deletedRecords, ApplicationUnitOfWork uow){
		//get Booking Container record type ID
		Id bookingContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Booking_Container'}).values()[0].Id;
		Boolean isDelete = true;

		Set<Id> bookingIdSet = new Set<Id>();
		for(PUD_Container__c container : deletedRecords){

			//Check if container's record type id = Container_Booking.
			//Also, container is updated only for monitored fields. In case of new containers, changedRecordIdsVsFields == NULL.
			if(container.RecordTypeId == bookingContainerRecordTypeId){
				bookingIdSet.add(container.Booking__c);
			}
		}

		//if Booking Containers are not updated then return.
		//Todo: Job Containers are processed separately.
		if(bookingIdSet.isEmpty()){
			return;
		}

		try{
			//call utility method to add containers against jobs.
			PUDUtility.getInstance().processContainers(deletedRecords, null, bookingIdSet, isDelete);
		} catch(Exception exp) {
            system.debug('Exp: '+exp);
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDContainerTypeSyncModule.class.getName(), 'refreshContainerTypesSync', 'PUDContainerTrigger', LoggingLevel.ERROR);
		}

	}

	private void preventDuplicateContainerRecords(List<PUD_Container__c> newRecords){
		Set<Id> bookingIds = new Set<Id>();
		Set<Id> jobIds = new Set<Id>();
		
		//map to store existing containers under a booking.
		//Container Type + Condition is a criteria to identify uniqueness.
		//e.g. Pallets, Empty and Pallets, Full are considered as two different containers.
		//Duplicates will be checked against Type + Condition uniqueness.
		Map<Id, Set<String>> bookingIdVsContainerUniqueKey = new Map<Id, Set<String>>();
		Map<Id, Set<String>> jobIdVsContainerUniqueKey = new Map<Id, Set<String>>();
		
		Id bookingContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Booking_Container'}).values()[0].Id;

		//get job and booking ids
		for(PUD_Container__c container : newRecords){

			if(container.RecordTypeId == bookingContainerRecordTypeId){
				bookingIds.add(container.Booking__c);
			}
			else{
				jobIds.add(container.Job__c);
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

		//get job containers
		for(PUD_Container__c container : PUDContainersSelector.newInstance().selectByJobIds(jobIds, new Set<Object>())){
			String uniqueKey = container.Type__c+container.Condition__c;

			if(!jobIdVsContainerUniqueKey.containsKey(container.Job__c)){
				jobIdVsContainerUniqueKey.put(container.Job__c, new Set<String> {uniqueKey});
			}
			else{
				jobIdVsContainerUniqueKey.get(container.Job__c).add(uniqueKey);
			}
		}
		

		for(PUD_Container__c newContainer : newRecords){
			String uniqueKey = newContainer.Type__c+newContainer.Condition__c;

			if(bookingIdVsContainerUniqueKey.containsKey(newContainer.Booking__c) && bookingIdVsContainerUniqueKey.get(newContainer.Booking__c).contains(uniqueKey)){
				newContainer.addError('Container type: '+newContainer.Type__c+ ' with condition: '+ newContainer.Condition__c+ ' already exists under a booking. Please update existing container type.');
			}

			if(jobIdVsContainerUniqueKey.containsKey(newContainer.Job__c) && jobIdVsContainerUniqueKey.get(newContainer.Job__c).contains(uniqueKey)){
				newContainer.addError('Container type: '+newContainer.Type__c+ ' with condition: '+ newContainer.Condition__c+ ' already exists under a job. Please update existing container type.');
			}
		}
	}
	// private void preventNewContainersCreation(List<PUD_Container__c> records){
	// 	if(System.isBatch()){
	// 		//allow
	// 	}
	// 	else{
	// 		//prevent

	// 		Set<Id> jobIds = new Set<Id>();
	// 		for(PUD_Container__c container : records){
	// 			jobIds.add(container.Job__c);
	// 		}


	// 		//query jobs where date = TODAY.
	// 		List<PUD_Job__c> jobs = [Select Id, Date__c from PUD_Job__c where ID IN : jobIds];

	// 		Map<Id, PUD_Job__c> jobIdVsJob = new Map<Id, PUD_Job__c>();

	// 		for(PUD_Job__c job : jobs){
	// 			jobIdVsJob.put(job.Id, job);
	// 		}
	// 		Date TODAYS_Date = Date.today();

	// 		for(PUD_Container__c newRecord : records){
	// 			if(newRecord.Job__c != null && 
	// 					jobIdVsJob.containsKey(newRecord.Job__c) && 
	// 						jobIdVsJob.get(newRecord.Job__c).Date__c  != TODAYS_Date){

	// 				newRecord.addError('You can create containers against future or historical jobs');
	// 			}
	// 		}
	// 	}
	// }


	private void processContainerUpdatesOnBookings(List<PUD_Container__c> records, Map<Id, PUD_Container__c> existingRecords, ApplicationUnitOfWork uow){

		//get Booking Container record type ID
		Id bookingContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Booking_Container'}).values()[0].Id;
		Boolean isDelete = false;
		//if(System.isBatch()) return;

		Map<Id, Set<SObjectField>> changedRecordIdsVsFields;

		//check null as existingRecords will be unavailable for AfterInsert trigger.
		if(existingRecords != null){
			//check if records are updated and updated via booking
			changedRecordIdsVsFields = getIsChanged(records, existingRecords, MONITORED_FIELDS_FOR_UPDATES);
		}
		
		Set<Id> bookingIdSet = new Set<Id>();
		for(PUD_Container__c container : records){

			//Check if container's record type id = Booking_Container.
			//Also, container is updated only for monitored fields. In case of new containers, changedRecordIdsVsFields == NULL.
			if(container.RecordTypeId == bookingContainerRecordTypeId 
				&& (changedRecordIdsVsFields == null || changedRecordIdsVsFields.keySet().contains(container.Id))){
				bookingIdSet.add(container.Booking__c);
			}
		}

		//if Booking Containers are not updated then return.
		//Todo: Job Containers are processed separately.
		if(bookingIdSet.isEmpty()){
			return;
		}

		try{
			//call utility method to add containers against jobs.
			PUDUtility.getInstance().processContainers(records, existingRecords, bookingIdSet, isDelete);
		} catch(Exception exp) {
            system.debug('Exp: '+exp);
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDContainerTypeSyncModule.class.getName(), 'refreshContainerTypesSync', 'PUDContainerTrigger', LoggingLevel.ERROR);
		}
	}

}
