/**************************************************
Type:       Contact Extension Controller 
Purpose:    Used by ContactAddressInformation VF page to show different address fields using AddressComponent 
History:
--------------------------------------------------
   Jan-2014:  shruthi.kunchinadka@bluewolf.com  Created   
27-May-2015:  Clinton McIntyre -  Added "with sharing" as part of security audit.                                         
**************************************************/
public with sharing class ContactAddressInformationContExt {
    
    public Contact currentContact {get; set;}
    public Boolean showComp {get; set;}
    public Boolean success {get; set;}
    public AddressExtension mailingAddress {get;set;}
    public AddressExtension otherAddress {get;set;}
    
    public ContactAddressInformationContExt(ApexPages.StandardController stdController) 
    {
        currentContact = [SELECT MailingCity,MailingDPID__c,MailingPostalCode,MailingState,MailingStreet,MailingStreet2__c,OtherCity,OtherDPID__c,OtherPostalCode,OtherState,OtherStreet,OtherStreet2__c,MailingCountry,OtherCountry FROM Contact where id=:(Id)stdController.getId() limit 1];
        
        mailingAddress = new AddressExtension(currentContact.MailingStreet, currentContact.MailingStreet2__c, currentContact.MailingCity, currentContact.MailingState, currentContact.MailingPostalCode, currentContact.MailingDPID__c, currentContact.MailingCountry);
        otherAddress = new AddressExtension(currentContact.OtherStreet, currentContact.OtherStreet2__c, currentContact.OtherCity, currentContact.OtherState, currentContact.OtherPostalCode, currentContact.OtherDPID__c, currentContact.OtherCountry);
   
        success = false;
        showComp = true;
    }
    
    public void saveContact() {
      try
      {
        currentContact.MailingStreet = mailingAddress.line1;
        currentContact.MailingStreet2__c = mailingAddress.line2;
        currentContact.MailingCity = mailingAddress.city;
        currentContact.MailingState = mailingAddress.state;
        currentContact.MailingPostalCode = mailingAddress.postcode;
        currentContact.MailingDPID__c = mailingAddress.dpid;
        currentContact.MailingCountry = mailingAddress.country;
        
        currentContact.OtherStreet = otherAddress.line1;
        currentContact.OtherStreet2__c = otherAddress.line2;
        currentContact.OtherCity = otherAddress.city;
        currentContact.OtherState = otherAddress.state;
        currentContact.OtherPostalCode = otherAddress.postcode;
        currentContact.OtherDPID__c = otherAddress.dpid;
        currentContact.OtherCountry = otherAddress.country;
        
        update currentContact;
      }
      catch(DmlException ex){
        for (Integer i = 0; i < ex.getNumDml(); i++) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(i))); 
        }
      }
      catch(Exception ex)
      {
        ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The Contact has missing required fields, or a validation rule. The system was not able to save the address.');
        ApexPages.addMessage(errorMsg);
      }
    }
    
    public void cancel() {
        success=false;
    }
}