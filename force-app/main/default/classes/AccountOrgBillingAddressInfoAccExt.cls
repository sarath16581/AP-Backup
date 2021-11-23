/**************************************************
Description:       Account Extension Controller for Account Billing Address.
                   Used by VF page to show different address fields using AddressComponent
History:
--------------------------------------------------
18-04-2019 Gunith.Devasurendra@auspost.com.au   Duplicated AccountAddressInformationAccExt and altered for Org Accounts
29.05.2019 Ronnie.Yang@sodastrategic.com.au MW0003155 Using Database method to insert instead of DML to bypass new duplicate rules for now
**************************************************/
public with sharing class AccountOrgBillingAddressInfoAccExt {
    public Account currentAccount {get; set;}
    public Boolean showComp {get; set;}
    public Boolean success {get; set;}
    public AddressExtension billingAddress {get;set;}
 
    public AccountOrgBillingAddressInfoAccExt(ApexPages.StandardController stdController)
    {
        currentAccount = [
                SELECT
                        BillingCity, Billing_DPID__c, BillingPostalCode, BillingState, BillingStreet, BillingStreet2__c, BillingCountry
                FROM Account
                WHERE Id =:(Id)stdController.getId()
                LIMIT 1
        ];
        
        billingAddress = new AddressExtension(currentAccount.BillingStreet, currentAccount.BillingStreet2__c, currentAccount.BillingCity, currentAccount.BillingState, currentAccount.BillingPostalCode, currentAccount.Billing_DPID__c, currentAccount.BillingCountry);
        
        success = false;
        showComp = true;
    }    
    
    public void saveAccount() {
      try
      {
        currentAccount.BillingStreet = billingAddress.line1;
        currentAccount.BillingStreet2__c = billingAddress.line2;
        currentAccount.BillingCity = billingAddress.city;
        currentAccount.BillingState = billingAddress.state;
        currentAccount.BillingPostalCode = billingAddress.postcode;
        currentAccount.Billing_DPID__c = billingAddress.dpid;
        currentAccount.BillingCountry = billingAddress.country;
        
        //21-05-2019 MW0003155 Using Database method to insert instead of DML to bypass new duplicate rules for now 
        //update currentAccount;
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        dml.OptAllOrNone = true; 
          
        Database.update(currentAccount, dml);
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