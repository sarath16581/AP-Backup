/**************************************************
Type:       Account Extension Controller 
Purpose:    Used by AccountAddressInformation VF page to show different address fields using AddressComponent 
History:
--------------------------------------------------
Jan-2014:  shruthi.kunchinadka@bluewolf.com  Created
May-2015:  scherukuwada@salesforce.com  Added Sharing
23.06.2015 Eric.shen@auspost.com.au   Add residential related fields 
**************************************************/
public with sharing class AccountAddressInformationAccExt {
    public Account currentAccount {get; set;}
    public Boolean showComp {get; set;}
    public Boolean success {get; set;}
    public AddressExtension mailingAddress {get;set;}
    public AddressExtension otherAddress {get;set;}
 
    public AccountAddressInformationAccExt(ApexPages.StandardController stdController) 
    {
        currentAccount = [SELECT PersonMailingCity,MailingDPID__pc,PersonMailingPostalCode,PersonMailingState,PersonMailingStreet,MailingStreet2__pc,PersonMailingCountry,PersonOtherCountry,
                                 PersonOtherCity,OtherDPID__pc,PersonOtherPostalCode,PersonOtherState,PersonOtherStreet,OtherStreet2__pc FROM Account where id=:(Id)stdController.getId() limit 1];
        
        mailingAddress = new AddressExtension(currentAccount.PersonMailingStreet, currentAccount.MailingStreet2__pc, currentAccount.PersonMailingCity, currentAccount.PersonMailingState, currentAccount.PersonMailingPostalCode, currentAccount.MailingDPID__pc, currentAccount.PersonMailingCountry);
        otherAddress = new AddressExtension(currentAccount.PersonOtherStreet, currentAccount.OtherStreet2__pc, currentAccount.PersonOtherCity, currentAccount.PersonOtherState, currentAccount.PersonOtherPostalCode, currentAccount.OtherDPID__pc, currentAccount.PersonOtherCountry);
        
        
        success = false;
        showComp = true;
    }    
    
    public void saveAccount() {
      try
      {
        currentAccount.PersonMailingStreet = mailingAddress.line1;
        currentAccount.MailingStreet2__pc = mailingAddress.line2;
        currentAccount.PersonMailingCity = mailingAddress.city;
        currentAccount.PersonMailingState = mailingAddress.state;
        currentAccount.PersonMailingPostalCode = mailingAddress.postcode;
        currentAccount.MailingDPID__pc = mailingAddress.dpid;
        currentAccount.PersonMailingCountry = mailingAddress.country;
        
        currentAccount.PersonOtherStreet = otherAddress.line1;
        currentAccount.OtherStreet2__pc = otherAddress.line2;
        currentAccount.PersonOtherCity = otherAddress.city;
        currentAccount.PersonOtherState = otherAddress.state;
        currentAccount.PersonOtherPostalCode = otherAddress.postcode;
        currentAccount.OtherDPID__pc = otherAddress.dpid;
        currentAccount.PersonOtherCountry = otherAddress.country;
        
        update currentAccount;
      }
      catch(DmlException ex){
        for (Integer i = 0; i < ex.getNumDml(); i++) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(i))); 
        }
      }
      catch(Exception ex)
      {
        ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The Account has missing required fields, or a validation rule. The system was not able to save the address.');
        ApexPages.addMessage(errorMsg);
      }
    }
    
    public void cancel() {
        success=false;
    }
}