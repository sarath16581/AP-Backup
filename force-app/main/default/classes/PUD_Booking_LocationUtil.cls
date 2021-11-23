/*-------------------------    
Overview: Trigger utility to process updates to Booking Location

History:
15/10/2019  ajudd@salesforce.com	Added customer change check
20/11/2019  ajudd@salesforce.com	Added detection of Revenue Check field change
26/11/2019  ajudd@salesforce.com	Added detection of Route field change, and set on booking if it's route is the same as the booking location prior route
02/12/2019  dheeraj.mandavilli@auspost.com.au	Added detection of Stop Credit field change
21/01/2020  dheeraj.mandavilli@auspost.com.au   Added detection of keyNumber field change on network
04/05/2020  dheeraj.mandavilli@auspost.com.au   Updated Rev Check Population Logic based upon Booking Type-Delivery
08/09/2021  arjun.singh@auspost.com.au          Modified to update the network on Booking and jobs when network changes on location
2021-09-29 - Ranjeewa Silva - Populate additional address fields (frontage geocode and side of street) onto booking when location is updated.
2021-10-13 - Ranjeewa Silva - Exclude expired bookings from getting updated on updates to parent booking location.
-------------------------
*/
public class PUD_Booking_LocationUtil {
	
    //Method called from PUD_Booking_LocationTrigger to determine if any fields dictated to booking have changed
    public static void updateBookingFields(Map<Id,PUD_Booking_Location__c> bookingLocationOldMap, Map<Id,PUD_Booking_Location__c> bookingLocationNewMap, List<PUD_Booking_Location__c> bookingLocationNewList){
        
        Set<Id> bookingLocationIdSet = new Set<Id>();
        
        for(PUD_Booking_Location__c bookingLocation : bookingLocationNewList){
            
            //If location name, any address fields or, hazard, comment or site instruction fields are changed, then 
            //- update the address and location search fields all related bookings.  Note that this will in turn trigger refresh in PUD_BookingTrigger to update jobs
            if( bookingLocationOldMap.get( bookingLocation.Id ).Name 					!= bookingLocationNewMap.get( bookingLocation.Id ).Name || 
                bookingLocationOldMap.get( bookingLocation.Id ).Street__c 				!= bookingLocationNewMap.get( bookingLocation.Id ).Street__c ||
                bookingLocationOldMap.get( bookingLocation.Id ).City__c 				!= bookingLocationNewMap.get( bookingLocation.Id ).City__c ||
                bookingLocationOldMap.get( bookingLocation.Id ).Post_Code__c 			!= bookingLocationNewMap.get( bookingLocation.Id ).Post_Code__c ||
                bookingLocationOldMap.get( bookingLocation.Id ).State__c 				!= bookingLocationNewMap.get( bookingLocation.Id ).State__c || 
                bookingLocationOldMap.get( bookingLocation.Id ).Hazards__c 				!= bookingLocationNewMap.get( bookingLocation.Id ).Hazards__c || 
                bookingLocationOldMap.get( bookingLocation.Id ).Site_Instructions__c 	!= bookingLocationNewMap.get( bookingLocation.Id ).Site_Instructions__c || 
                bookingLocationOldMap.get( bookingLocation.Id ).Comments__c 			!= bookingLocationNewMap.get( bookingLocation.Id ).Comments__c || 
                bookingLocationOldMap.get( bookingLocation.Id ).Geo__Latitude__s 		!= bookingLocationNewMap.get( bookingLocation.Id ).Geo__Latitude__s || 
                bookingLocationOldMap.get( bookingLocation.Id ).Geo__Longitude__s 		!= bookingLocationNewMap.get( bookingLocation.Id ).Geo__Longitude__s ||
                bookingLocationOldMap.get( bookingLocation.Id ).Customer__c		 		!= bookingLocationNewMap.get( bookingLocation.Id ).Customer__c || 
                bookingLocationOldMap.get( bookingLocation.Id ).Revenue_Check__c		!= bookingLocationNewMap.get( bookingLocation.Id ).Revenue_Check__c ||
                bookingLocationOldMap.get( bookingLocation.Id ).Route__c				!= bookingLocationNewMap.get( bookingLocation.Id ).Route__c ||
               	bookingLocationOldMap.get( bookingLocation.Id ).Stop_Credit__c		    != bookingLocationNewMap.get( bookingLocation.Id ).Stop_Credit__c ||
               	bookingLocationOldMap.get( bookingLocation.Id ).Key_Number__c 			!= bookingLocationNewMap.get( bookingLocation.Id ).Key_Number__c  ||
                bookingLocationOldMap.get( bookingLocation.Id ).Network__c 			    != bookingLocationNewMap.get( bookingLocation.Id ).Network__c ||
                bookingLocationOldMap.get( bookingLocation.Id ).Frontage_Geo__Latitude__s != bookingLocationNewMap.get( bookingLocation.Id ).Frontage_Geo__Latitude__s ||
                bookingLocationOldMap.get( bookingLocation.Id ).Frontage_Geo__Longitude__s != bookingLocationNewMap.get( bookingLocation.Id ).Frontage_Geo__Longitude__s ||
                bookingLocationOldMap.get( bookingLocation.Id ).DPID__c                  != bookingLocationNewMap.get( bookingLocation.Id ).DPID__c ||
                bookingLocationOldMap.get( bookingLocation.Id ).Side_Of_Street_Code__c   != bookingLocationNewMap.get( bookingLocation.Id ).Side_Of_Street_Code__c){
                //Add location id to set
                bookingLocationIdSet.add(bookingLocation.Id);
            }
        }
        //If dictated fields updated on any locations
        if(bookingLocationIdSet.size() > 0){
            //If this is being called from a future or batch method (e.g. Network update), then call method directly 
            if(System.IsBatch() == true || System.isFuture() == true){
                updateBookingFieldsProcess(bookingLocationIdSet);
            }
            //Else call method in future mode
            else{
                updateBookingFieldsAsync(bookingLocationIdSet);
            }            
        }
    }
    
    @future
     //Method to call process method in future mode
    private static void updateBookingFieldsAsync(Set<Id> bookingLocationIdSet){
        try{
        	updateBookingFieldsProcess(bookingLocationIdSet);
        }
        catch(Exception exp) {
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUD_Booking_LocationUtil.class.getName(), 'updateBookingFieldsAsync', 'PUD_Booking_LocationTrigger', LoggingLevel.ERROR);
		}
    }
    
    //Method to process the update of fields of related bookings
    private static void updateBookingFieldsProcess(Set<Id> bookingLocationIdSet){
        
        List<PUD_Booking__c> bookingList = new List<PUD_Booking__c>();
        
        //Build Map with new Booking Location Field values
        Map<ID, PUD_Booking_Location__c> locationMap = new Map<ID, PUD_Booking_Location__c>(
					[SELECT  Name,		
                             Street__c,
                             City__c,	
                             Post_Code__c,
                             State__c,
                             Hazards__c,
                             Site_Instructions__c,
                             Comments__c, 
                     		 Geo__Latitude__s, 
                             Geo__Longitude__s, 
                     		 Customer__c, 
                     		 Revenue_Check__c, 
                     		 Route__c,
                     		 Stop_Credit__c,
                     		 Key_Number__c,
                             Network__c,
                             Frontage_Geo__Latitude__s,
                             Frontage_Geo__Longitude__s,
                             DPID__c,
                             Side_Of_Street_Code__c
                      FROM 	 PUD_Booking_Location__c 
                      WHERE  Id IN :bookingLocationIdSet]);

        //Then get all bookings with this location. should exclude expired bookings (confirmed by CCP project team).
        // 'Expired' bookings are excluded by filtering on 'Status_Calc__c' formula field to cater for dependent bookings.
        bookingList = [SELECT Id, Booking_Location__c, Booking_Type__c,
                       Street__c, City__c, Post_Code__c, State__c, Geo__Latitude__s, Geo__Longitude__s, Customer__c, Revenue_Check__c,
                       Route_Lookup__c, Booking_Location__r.Route_Prior__c, Status__c, Parent_Booking__c,Stop_Credit__c,Key_Number__c,
                       Frontage_Geo__Latitude__s, Frontage_Geo__Longitude__s, DPID__c, Side_Of_Street_Code__c
                       FROM PUD_Booking__c 
                       WHERE Booking_Location__c IN :bookingLocationIdSet AND Status_Calc__c != :PUDConstants.PUD_BOOKING_STATUS_EXPIRED];
        
        //If bookings found with this location
        if(bookingList.size() > 0){
            
            //Loop thru list and set address fields
            for(PUD_Booking__c booking : bookingList){
                booking.Street__c = locationMap.get(booking.Booking_Location__c).Street__c;
                booking.City__c = locationMap.get(booking.Booking_Location__c).City__c;
                booking.Post_Code__c = locationMap.get(booking.Booking_Location__c).Post_Code__c;
                booking.State__c = locationMap.get(booking.Booking_Location__c).State__c;
                booking.Location__c = locationMap.get(booking.Booking_Location__c).Name; 
                booking.Geo__Latitude__s = locationMap.get(booking.Booking_Location__c).Geo__Latitude__s; 
                booking.Geo__Longitude__s = locationMap.get(booking.Booking_Location__c).Geo__Longitude__s; 
                booking.Customer__c = locationMap.get(booking.Booking_Location__c).Customer__c; 
                if(booking.Booking_Type__c != 'Delivery'){
                 booking.Revenue_Check__c = locationMap.get(booking.Booking_Location__c).Revenue_Check__c;    
                }
                
                //If booking route is the same as the prior booking location route, and the booking is not expired or a child booking
                if((booking.Route_Lookup__c == booking.Booking_Location__r.Route_Prior__c) && booking.Status__c != 'Expired' && booking.Parent_Booking__c == null) {
                    //Then update to the new booking to the current route of the location
                    booking.Route_Lookup__c = locationMap.get(booking.Booking_Location__c).Route__c;
                }
                booking.Stop_Credit__c = locationMap.get(booking.Booking_Location__c).Stop_Credit__c; 
                booking.Key_Number__c = locationMap.get(booking.Booking_Location__c).Key_Number__c;
                booking.Network__c = locationMap.get(booking.Booking_Location__c).Network__c;
                booking.Frontage_Geo__Latitude__s = locationMap.get(booking.Booking_Location__c).Frontage_Geo__Latitude__s;
                booking.Frontage_Geo__Longitude__s = locationMap.get(booking.Booking_Location__c).Frontage_Geo__Longitude__s;
                booking.DPID__c = locationMap.get(booking.Booking_Location__c).DPID__c;
                booking.Side_Of_Street_Code__c = locationMap.get(booking.Booking_Location__c).Side_Of_Street_Code__c;
            }
            //Update bookings
            update bookingList;
        }
        
    }
}