/**************************************************
Description:       Account Extension Controller for Org Account Addresses.
                   Used by AccountOrgAddressInformation VF page to show different address fields using AddressComponent
History:
--------------------------------------------------
18-04-2019 Gunith.Devasurendra@auspost.com.au   Duplicated AccountAddressInformationAccExt and altered for Org Accounts
29.05.2019 Ronnie.Yang@sodastrategic.com.au MW0003155 Using Database method to insert instead of DML to bypass new duplicate rules for now
**************************************************/
public with sharing class AccountOrgShippingAddressInfoAccExt {
    public Account currentAccount {get; set;}
    public Boolean showComp {get; set;}
    public Boolean success {get; set;}
    public AddressExtension shippingAddress {get;set;}
 
    public AccountOrgShippingAddressInfoAccExt(ApexPages.StandardController stdController)
    {
        currentAccount = [
                SELECT
                        ShippingCountry, ShippingCity, Shipping_DPID__c, ShippingPostalCode, ShippingState, ShippingStreet
                FROM Account
                WHERE Id =:(Id)stdController.getId()
                LIMIT 1
        ];

        // NOTE: No ShippingStreet2 field is available. Therefore we're merging this field to ShippingStreet
        shippingAddress = new AddressExtension(currentAccount.ShippingStreet, '', currentAccount.ShippingCity, currentAccount.ShippingState, currentAccount.ShippingPostalCode, currentAccount.Shipping_DPID__c, currentAccount.ShippingCountry);
        
        
        success = false;
        showComp = true;
    }    
    
    public void saveAccount() {
      try
      {
        
        currentAccount.ShippingStreet = shippingAddress.line1;
        // NOTE: No ShippingStreet2 field is available. Therefore we're merging this field to ShippingStreet
        if (shippingAddress.line2 != null && shippingAddress.line2.trim() != ''){
            currentAccount.ShippingStreet = currentAccount.ShippingStreet + ' ' + shippingAddress.line2;
        }
        currentAccount.ShippingCity = shippingAddress.city;
        currentAccount.ShippingState = shippingAddress.state;
        currentAccount.ShippingPostalCode = shippingAddress.postcode;
        currentAccount.Shipping_DPID__c = shippingAddress.dpid;
        currentAccount.ShippingCountry = shippingAddress.country;
        
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