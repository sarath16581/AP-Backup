/**
* @author Dheeraj Mandavilli
* @date 2020-06-11
* @group PUD Project
* @tag Controller
* @tag PUD_Booking_Location__c
* @domain Interoperability PUD Project
* @description controller class for LocationconfirmationComponent.
* NOTE: This is used for genarating HTML booking confirmation email when Booking Location record is created
* 2020-06-11 - Dheeraj Mandavilli - Created
*/
public without sharing class PUD_LocationConfirmationController {
    public string locationRecordId{get;set;}
    public PUD_Booking_Location__c locationRecord;     
    public PUD_Booking_Location__c getlocationRecord(){        
        return [Select id, Name, Customer__c, Customer__r.name, Customer__r.AccountNumber,Route__r.Name,Address__c,
                Billing_Account__r.LEGACY_ID__c,Contact_Name__c,Contact_Phone_Number__c,Customer__r.Owner.Name,
                City__c,State__c,Street__c,Post_Code__c
                from PUD_Booking_Location__c where id =: locationRecordId];
    }
}