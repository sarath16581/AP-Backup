/**
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Dattaraj Deshmukh (dattaraj.deshmukh@slalom.com)
 * @date 2022-06-23
 * @tag Container Types
 * @domain Container Booking
 * @description Module class to process a business logic when Containers are created under bookgings.
 * @changelog
 * 2022-06-23 - Dattaraj Deshmukh - Created
 */


public inherited sharing class PUDContainerTypeSyncModule  extends ApplicationDomain.Module{
	
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

	/**
	 * @param: new container records
	 * @desc: This methods prevent duplicate Booking Containers being created under bookings.
	 */
	private void preventDuplicateContainerRecords(List<PUD_Container__c> newRecords){
		Set<Id> bookingIds = new Set<Id>();

		//map to store existing containers under a booking.
		//Container Type + Condition is a criteria to identify uniqueness.
		//e.g. Pallets, Empty and Pallets, Full are considered as two different containers.
		//Duplicates will be checked against Type + Condition uniqueness.
		Map<Id, Set<String>> bookingIdVsContainerUniqueKey = new Map<Id, Set<String>>();
		

		//get job and booking ids
		for(PUD_Container__c container : newRecords){
			bookingIds.add(container.Booking__c);
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
				newContainer.addError(String.format(Label.PUDDuplicateBookingContainerErrorMessage, new List<String>{newContainer.Type__c, newContainer.Condition__c}));
			}
		}
	}

	/**
	 * @param: new/updated container records
	 */
	private void processContainers(List<PUD_Container__c> records, ApplicationUnitOfWork uow){

		Set<Id> bookingIds = new Set<Id>();
		for(PUD_Container__c container : records){
			bookingIds.add(container.Booking__c);
		}

		//if Booking Containers are not updated then return.
		if(bookingIds.isEmpty()){
			return;
		}

		try{
			//If this is being called from a future or batch method (e.g. Booking Location update), then call createJobs directly
			if(System.IsBatch() == true || System.isFuture() == true){
				//call utility method to sycn containers.
				PUDUtility.getInstance().refreshContainerTypes(bookingIds, uow);
			} else {
				//Else call Async method to refresh jobs for bookings
				refreshContainersAsync(bookingIds);
			}
		} catch(Exception exp) {
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDContainerTypeSyncModule.class.getName(), 'refreshContainerTypesSync', 'PUDContainerTrigger', LoggingLevel.ERROR);
		}

		
	}

	@future
	//Async method to add/update/delete containers associated with bookings
	public static void refreshContainersAsync(Set<Id> bookingIdSet){
	try{
		PUDUtility.getInstance().refreshContainerTypes(bookingIdSet);
	} catch(Exception exp) {
		//Log error to Exception object for analysis
		UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDContainerTypeSyncModule.class.getName(), 'refreshContainerTypesSync', 'PUDContainerTrigger', LoggingLevel.ERROR);
	}
	}

}
