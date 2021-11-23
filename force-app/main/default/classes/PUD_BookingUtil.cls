/**
* @changelog
* 26/11/2019    ajudd@salesforce.com    Changed booking route field from Route__c to Route_Lookup__c
* 2021-08-31 - Ranjeewa Silva - Updated to use PUDUtility.getInstance() to create a new instance
* 2021-10-18 - Ranjeewa Silva - Refactored to move SOQL outside of for loop. fixed indentation / formatting.
*/
public class PUD_BookingUtil {

	//Method called from PUD_BookingTrigger to refresh jobs associated to changed bookings
	public static void refreshJobs(Map<Id,PUD_Booking__c> bookingOldMap, List<PUD_Booking__c> bookingNewList, Boolean isUpdate){

		List<PUD_Booking__c> bookingChildList = new List<PUD_Booking__c>();
		Set<Id> bookingWithParFldChgIdSet = new Set<Id>();
		Set<Id> bookingIdSet = new Set<Id>();

		//For all bookings
		for (PUD_Booking__c booking : bookingNewList) {

			//TODO:Consider excluding bookings that were and still are expired (old and new).
			//Not critical as refreshJobs and getNewJobsList only get future jobs

			//Check the record type on Bookings records getting created.
			//If the record type is MPB_Pickup, check for the address verified field to determine job creation
			system.debug('Address Verification flag:::'+booking.Address_Verified__c);
			Id RecTyp = RecordTypes.getRecordTypeByName('MPB_Pickup','PUD_Booking__c').Id;
			system.debug('record Type Id in PUD Util:::'+RecTyp);
			if (booking.RecordTypeId == RecTyp && booking.Address_Verified__c == false) {
				//do nothing
			} else {
				//#1. Add the new or modifed booking to set to evaluate jobs
				bookingIdSet.add(booking.Id);

				//#2. Add any impacted child bookings to list to evaluate jobs
				//2a If is update (i.e. if a new record, there will be no child records)
				if (isUpdate) {

					//#If any parent fields have changed (these are fields whos values are dictated to child bookings)
					if (bookingOldMap.get( booking.Id ).Route_Lookup__c != booking.Route_Lookup__c ||
							bookingOldMap.get( booking.Id ).Monday__c != booking.Monday__c ||
							bookingOldMap.get( booking.Id ).Tuesday__c != booking.Tuesday__c ||
							bookingOldMap.get( booking.Id ).Wednesday__c != booking.Wednesday__c ||
							bookingOldMap.get( booking.Id ).Thursday__c != booking.Thursday__c ||
							bookingOldMap.get( booking.Id ).Friday__c != booking.Friday__c ||
							bookingOldMap.get( booking.Id ).Saturday__c != booking.Saturday__c ||
							bookingOldMap.get( booking.Id ).Sunday__c != booking.Sunday__c ||
							bookingOldMap.get( booking.Id ).Effective_Date__c != booking.Effective_Date__c ||
							bookingOldMap.get( booking.Id ).Expiry_Date__c != booking.Expiry_Date__c) {

						//Store booking Id with dictated parent field changes to list - to get any child bookings
						bookingWithParFldChgIdSet.add(booking.Id);
					}
				}
			}
		}

		//2b If there are bookings with parent field changes
		if (bookingWithParFldChgIdSet.size() > 0) {

			//Get all child bookings (note that child bookings derive status from parent, so get all regardless of status)
			bookingChildList = [SELECT Id FROM PUD_Booking__c WHERE Parent_Booking__c IN :bookingWithParFldChgIdSet];

			//Add all child bookings to the list to check
			for (PUD_Booking__c bookingChild : bookingChildList) {
				bookingIdSet.add(bookingChild.Id);
			}

		}

		//If bookings to process
		if (bookingIdSet.size() > 0 ) {
			//If this is being called from a future or batch method (e.g. Booking Location update), then call createJobs directly
			if(System.IsBatch() == true || System.isFuture() == true){
				PUDUtility.getInstance().createJobs(bookingIdSet, true);
			} else {
				//Else call Async method to refresh jobs for bookings
				refreshJobsAsync(bookingIdSet);
			}
		}
	}

	@future
	//Async method to update jobs associated bookings
	public static void refreshJobsAsync(Set<Id> bookingIdSet){
		try{
			PUDUtility.getInstance().createJobs(bookingIdSet, true);
		} catch(Exception exp) {
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUD_BookingUtil.class.getName(), 'refreshJobsAsync', 'PUD_BookingTrigger', LoggingLevel.ERROR);
		}
	}
}