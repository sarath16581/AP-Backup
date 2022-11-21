/**
* @author Andrew Judd
* @date 2019-10-15
* @group PUD Project
* @tag Trigger
* @tag PUD_Booking_Location__c
* @domain Interoperability PUD Project
* @description Overview: Trigger to process updates to Booking Location 
* 2019-10-15 - ajudd@salesforce.com  - Created and Added set of Legacy Id
* 2019-11-26 - ajudd@salesforce.com  - Added set of Route_Prior__c
* 2020-06-17 - Dheeraj Mandavilli    - Added set of Account_Manager_Email__c
*/
trigger PUD_Booking_LocationTrigger on PUD_Booking_Location__c (before insert, before update, after update) {
    
    if(Trigger.isBefore){ 
        
        if(Trigger.isUpdate || Trigger.isInsert){
            
            for(PUD_Booking_Location__c bookingLocation : Trigger.New){ 
                
                //If new and network booking location, or network is updated, update Address fields to those of the Network
                if((Trigger.isInsert && bookingLocation.Network__c != null) || 
                   (Trigger.isUpdate && (Trigger.oldMap.get( bookingLocation.Id ).Network__c != bookingLocation.Network__c)) && Trigger.newMap.get( bookingLocation.Id ).Network__c != null){
                       
                       //Then update address field to those from new network
                       bookingLocation.Street__c = bookingLocation.Network_Street__c;
                       bookingLocation.City__c = bookingLocation.Network_City__c;
                       bookingLocation.Post_Code__c = bookingLocation.Network_Post_Code__c;
                       bookingLocation.State__c = bookingLocation.Network_State__c;
                       bookingLocation.Geo__Latitude__s = bookingLocation.Network_Latitude__c;
                       bookingLocation.Geo__Longitude__s = bookingLocation.Network_Longitude__c;
                       
                   }
                //If new and customer booking location, or customer is updated, update Customer Id field
                if((Trigger.isInsert && bookingLocation.Customer__c != null) || 
                   (Trigger.isUpdate && (Trigger.oldMap.get( bookingLocation.Id ).Customer__c != bookingLocation.Customer__c)) && Trigger.newMap.get( bookingLocation.Id ).Customer__c != null){
                       
                       //Then update Customer Id to that of new customer
                       bookingLocation.LEGACY_ID__c = bookingLocation.LEGACY_ID_FX__c;
                       //Update Account Manager Email to that of new Customer, which is further used to send email Alert
                       bookingLocation.Account_Manager_Email__c = bookingLocation.Account_Manager_Email_FX__c;
                       
                   } 
                //If route updated set route prior field to old value
                if(Trigger.isUpdate && (Trigger.oldMap.get( bookingLocation.Id ).Route__c != Trigger.newMap.get( bookingLocation.Id ).Route__c)){
                    System.debug('set old route to = ' + Trigger.oldMap.get( bookingLocation.Id ).Route__c);
                    bookingLocation.Route_Prior__c = Trigger.oldMap.get( bookingLocation.Id ).Route__c;
                } else {
                    //spingali - INC1932337 - Reset the field to null when the route on location is not updated.This is to avoid updating the route value on the bookings that matches to route_prior__c value.
                    bookingLocation.Route_Prior__c = null;
                }
            }   
        }
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        //Call method to update booking fields if dicated fields from location have changed
        PUD_Booking_LocationUtil.updateBookingFields(Trigger.oldMap, Trigger.newMap, Trigger.New);
    }
    
}