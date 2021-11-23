/**************************************************
Type:       Account Controller Extension used for creating and editing Account.             
Purpose:    Used by ManageAccount VF page. User's default Record Type will be used for creating new record.  
History:
Don't know the purpose of showComp and success variables.
Keeping them to retain current functionality of Address Component.
saveNew variable is used to decide whether Save or Save&New is clicked.
copyFromBilling variable is used to know whether Address should be copied from Billing or Physical address.
displaySave variable is used to render the "Please Save.." message after the page is refreshed.
newUrl variable is the VF page URL to redirect after Save&New is clicked.
--------------------------------------------------
Jun-2015:  scherukuwada@salesforce.com  Created     
Oct-2015:  eric.shen@auspost.com.au     Update billingaddress and shippingaddress with 'clone' method to avoid bugs                                       
**************************************************/
public with sharing class ManageAccountControllerExtension {
    
    // Constants
    private static final String COMMA = ',';
    private static final String WHITE_SPACE = '';
    
    public Account currentAccount {get; set;}
    public Boolean showComp {get; set;}
    public Boolean success {get; set;}
    public AddressExtension billingAddress {get;set;}
    public AddressExtension shippingAddress {get;set;}
    public Boolean saveNew {get; set;}
    public Boolean copyFromBilling {get; set;}
    public Boolean displaySave {get; set;}
    public String newUrl{get; set;}

    public ManageAccountControllerExtension(ApexPages.StandardController stdController)  
    {
        Id id = ApexPages.currentPage().getParameters().get('id');
        if(id == null) {
            currentAccount = new Account();
            currentAccount.OwnerID = UserInfo.getUserId();
                }
        else { 
            String query = 'SELECT ';
            Map<String, Schema.fieldset> accFieldSets = Schema.SObjectType.Account.fieldSets.getMap();
            for (String fsName : accFieldSets.keySet() ) {
                         if(fsName.toLowerCase().startsWith('business_account_')) {
                               for(Schema.FieldSetMember f : (accFieldSets.get(fsName)).getFields()) {
                                   query += f.getFieldPath() + ', ';
                               }
                            }                               
                 }
            query += 'id,isPersonAccount,BillingCity,BillingPostalCode,BillingState,BillingStreet,BillingCountry,Billing_DPID__c,';
            query += 'ShippingCity,ShippingPostalCode,ShippingState,ShippingStreet,ShippingCountry,Shipping_DPID__c';
            query += ' FROM Account where id= :id limit 1';                             
            currentAccount = Database.query(query);
         }   

        // Nandan N : Added Street split 
        List<String> billStreet = String.isNotBlank(currentAccount.BillingStreet) ? currentAccount.BillingStreet.split(COMMA) : new List<String>();
        List<String> shipStreet = String.isNotBlank(currentAccount.ShippingStreet) ? currentAccount.ShippingStreet.split(COMMA) : new List<String>();
        
        System.debug('** billStreet ==>'+billStreet);
        System.debug('** shipStreet ==>'+shipStreet);
        
        String billStreet1 = billStreet.size() > 0 && billStreet.get(0) != null ? billStreet.get(0) : null ;
        String billStreet2 = billStreet.size() > 1 && billStreet.get(1) != null ? billStreet.get(1) : null ;
        
        String shipStreet1 = shipStreet.size() > 0 && shipStreet.get(0) != null ? shipStreet.get(0) : null ;
        String shipStreet2 = shipStreet.size() > 1 && shipStreet.get(1) != null ? shipStreet.get(1) : null ;
        
        System.debug('** billStreet1 ==>'+billStreet1);
        System.debug('** billStreet2 ==>'+billStreet2);
        System.debug('** shipStreet1 ==>'+shipStreet1);
        System.debug('** shipStreet2 ==>'+shipStreet2);
        
        billingAddress = new AddressExtension(billStreet1, billStreet2,
                                                currentAccount.BillingCity, currentAccount.BillingState, currentAccount.BillingPostalCode, 
                                                currentAccount.Billing_DPID__c, currentAccount.BillingCountry);
        shippingAddress = new AddressExtension(shipStreet1, shipStreet2, 
                                                currentAccount.ShippingCity, currentAccount.ShippingState, currentAccount.ShippingPostalCode, 
                                                currentAccount.Shipping_DPID__c,currentAccount.ShippingCountry);
        success = false;
        showComp = true;
        displaySave = false;
    }    
    
    public PageReference saveAccount() {
      PageReference pr;
      try
      {
        System.debug('** billingAddress==>'+billingAddress);
        System.debug('** shippingAddress==>'+shippingAddress);
        currentAccount.BillingStreet = billingAddress.line1 + (String.isNotBlank(billingAddress.line2) ? COMMA : WHITE_SPACE) + billingAddress.line2;
        currentAccount.BillingCity = billingAddress.city;
        currentAccount.BillingState = billingAddress.state;
        currentAccount.BillingPostalCode = billingAddress.postcode;
        currentAccount.BillingCountry = billingAddress.country;
        currentAccount.Billing_DPID__c = billingAddress.dpid;
        
        currentAccount.ShippingStreet = shippingAddress.line1 + (String.isNotBlank(shippingAddress.line2) ? COMMA : WHITE_SPACE) + shippingAddress.line2;
        currentAccount.ShippingCity = shippingAddress.city;
        currentAccount.ShippingState = shippingAddress.state;
        currentAccount.ShippingPostalCode = shippingAddress.postcode;
        currentAccount.ShippingCountry = shippingAddress.country;
        currentAccount.Shipping_DPID__c = shippingAddress.dpid;
        
        upsert currentAccount;
      }
      catch(DmlException ex){
        for (Integer i = 0; i < ex.getNumDml(); i++) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(i))); 
        }
      }
      catch(Exception ex)
      {
        ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'The Account has missing required fields, or a validation rule. The system was not able to save the Account');
        ApexPages.addMessage(errorMsg);
      }
      success = true;
      displaySave = false;
/**
If Save & New is clicked, then redirect to the same VF page with blank values.
If Save is clicked, then redirect to the details page of the Account record.
**/      
      if(saveNew) {
          saveNew=null;
          copyFromBilling=null;
          pr = new PageReference(newUrl);
         }
      else {    
          pr =  new PageReference('/' + currentAccount.Id);
          }
      pr.setRedirect(true);
      return pr;
           
    }
    
   public void copyAddress() {
   
         if(copyFromBilling) {
            currentAccount.ShippingStreet = billingAddress.line1 + (String.isNotBlank(billingAddress.line2) ? COMMA : WHITE_SPACE) + billingAddress.line2;
            currentAccount.ShippingCity = billingAddress.city;
            currentAccount.ShippingState = billingAddress.state;
            currentAccount.ShippingPostalCode = billingAddress.postcode;
            currentAccount.ShippingCountry = billingAddress.country;
            currentAccount.Shipping_DPID__c = billingAddress.dpid;
            // add .clone()  19-Oct-15 Eric Shen
            shippingAddress = billingAddress.clone();
            }
         else {
                currentAccount.BillingStreet = shippingAddress.line1 + (String.isNotBlank(shippingAddress.line2) ? COMMA : WHITE_SPACE) + shippingAddress.line2;
                currentAccount.BillingCity = shippingAddress.city;
                currentAccount.BillingState = shippingAddress.state;
                currentAccount.BillingPostalCode = shippingAddress.postcode;
                currentAccount.BillingCountry = shippingAddress.country;
                currentAccount.Billing_DPID__c = shippingAddress.dpid;
                
                 // add .clone()  19-Oct-15 Eric Shen
                billingAddress = shippingAddress.clone();
                }   
         displaySave = true;

    }

    

    public PageReference cancelOp() {
        success=false;
        return new PageReference('/001/o');
    }
}