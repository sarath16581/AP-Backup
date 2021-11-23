/* @author       : Arjun Singh
* @date         : 
* @description  : controller class for BookingconfirmationComponent.
*               : used for genarating HTML booking confirmation email when MPB Pickup booking record is created
*/
/*******************************  History ************************************************
01/31/2020  : Created
*******************************  History ************************************************/
global without sharing class PUD_BookingConfirmationController {
    global string bookingRecordId{get;set;}
    public PUD_Booking__c bookingRecord;
    public PUD_BookingConfirmationController (){
   
    }        
    public PUD_Booking__c getbookingRecord(){        
        return [Select id, Booking_Type__c, Customer__c, Customer__r.name, Customer__r.AccountNumber, Depot__r.name, Booking_Location__r.name,
                            Booking_Location_Address__c, Effective_Date__c, Start_Time__c, Latest_End_Time__c,Booking_Comments__c, Contact_Phone_Number__c,
                            Article_Info__c,Article_Count__c,Location__c, Street__c, City__c, Post_Code__c, State__c, Source_Street__c, Source_City__c, Source_Post_Code__c, Source_State__c, Earliest_Start_Time__c
                                                        from PUD_Booking__c where id =: bookingRecordId];
    }
}