/**
Description: This apex class is controller for vf page - APT_SubAccountAssessment. This will manage Sub Account record 
for Credit Assessment process.
Created By - Mausam Padhiyar
Created Date - 10th Dec, 2015

Last Modified By - Mausam Padhiyar
Last Modified Date - 6th Sept, 2016 | 940 - Validate State

Last Modified By - Sheryl Crisostomo
Last Modified Date - 27th Apr, 2017 | 1855 - Added new custom label to update State error message

**/
public with sharing class APT_SubAccountAssessmentController {
    
    public boolean isAccountFlow {get;set;}
    
    public boolean isExistingCustomer {get;set;}
    
    public boolean haserrorMessages {get; set;}
    public APT_Sub_Account__c subAccount {get; set;}
    
    String proposalId;
    String chargeAccountId;
    Apttus_Proposal__Proposal__c proposal;
    Account account;
    String accountID;
    public String billingAcc { get; set; }
    public String chargeAcc{ get; set; }
    
    public AddressExtension mailingAddress {get;set;}
    public AddressExtension physicaladdress {get;set;}
    
    
    public List<SelectOption> ChargeAccounts {get;set;}
    public Integer ChargeAccountsCount {get{
        Integer count = 0;
        if(ChargeAccounts != null){
            count = ChargeAccounts.size();
        }
        return count;
    } set;}
    
    public static final string strTitle = 'Sub-Account Assessment';
    /**
        get method;
    **/
    public static string strGetValTitle {get{return strTitle;} set;}
    
    public static final string strTitleDetails = 'Sub-Account Details';
    public static string strGetValTitleDetails {get{return strTitleDetails;} set;}
    
    public static final string strAccName = 'Sub-Account Name';
    public static string strGetValAccName {get{return strAccName;} set;}
    
    public static final string strBranch = 'Branch';
    public static string strGetValBranch {get{return strBranch;} set;}
    
    public static final string strAccContactName = 'Sub Account Contact Name';
    public static string strGetValAccContactName {get{return strAccContactName;} set;}
    
    public static final string strAccContactTel = 'Sub Account Contact Telephone';
    public static string strGetValAccContactTel {get{return strAccContactTel;} set;}
    
    public static final string strAccContactEmail = 'Sub Account Contact Email Address';
    public static string strGetValAccContactEmail {get{return strAccContactEmail;} set;}
    
    public static final string strAccContactFax = 'Sub Account Contact Fax Number';
    public static string strGetValAccContactFax {get{return strAccContactFax;} set;}
    
    public static final string strChargeAcc = 'Charge Account';
    public static string strGetValChargeAcc {get{return strChargeAcc;} set;}
    
    public static final string strOrg = 'Organisation';
    public static string strGetValOrg {get{return strOrg;} set;}
    
    public static final string strAddr = 'Postal Address of Business';
    public static string strGetValAddr {get{return strAddr;} set;}
    
    public static final string strStreet = 'Street Address of Business';
    public static string strGetValStreet {get{return strStreet;} set;}
    
    public static final string strSaveClose = 'Save & Close';
    public static string strGetValSaveClose {get{return strSaveClose;} set;}
    
    public static final string strSaveNew = 'Save & New';
    public static string strGetValSaveNew {get{return strSaveNew;} set;}
    
    public static final string strCancel = 'Cancel';
    public static string strGetValCancel {get{return strCancel;} set;}

    /**
        Constructor
    **/
    public APT_SubAccountAssessmentController(ApexPages.StandardController controller) {
        try {
          init ();
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }   
        if(!(isAccountFlow || isExistingCustomer)) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, APT_Constants.PLEASE_PROVIDE_SUB_ACCOUNT_DETAILS));
        } 
    }

    /**
     init method
    **/
    public void init () {
        haserrorMessages = false;
        subAccount = new APT_Sub_Account__c();
        account = new Account();
        system.Debug(isExistingCustomer);
        
        proposalId = ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_PROPOSAL_ID2);
        chargeAccountId = ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_CHARGE_ACCOUNT_ID);
        accountID = ApexPages.currentPage().getParameters().get(APT_Constants.URL_ACCOUNT_ID);
        
        isExistingCustomer = Boolean.valueOf(String.IsNotBlank(ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_IS_EXISTING_CUSTOMER)));
        
        system.Debug('**********isExistingCustomer:'+isExistingCustomer);
        isAccountFlow = String.IsBlank(proposalId) && String.IsNotBlank(accountID);
        
            System.debug('**********isAccountFlow:'+isAccountFlow);
        if(!isAccountFlow) {
            if(String.isNotBlank(chargeAccountId)) {
                subAccount.APT_Charge_Account__c = chargeAccountId;
                //chargeAcc = chargeAccountId;
            } 
            
            system.debug('*** proposalId ***'+proposalId);
            if(String.isNotBlank(proposalId)) {
                proposal = [SELECT id, Apttus_Proposal__Account__c, APT_Credit_Assessment__c, 
                            APT_Credit_Assessment_Status__c, Apttus_Proposal__Opportunity__c,
                            Apttus_Proposal__Opportunity__r.KeyContact__r.Name,
                            Apttus_Proposal__Opportunity__r.KeyContact__r.Phone,
                            Apttus_Proposal__Opportunity__r.KeyContact__r.Email
                            FROM Apttus_Proposal__Proposal__c 
                            WHERE Id = :proposalId];

                if(proposal != null) {   
                    accountID = proposal.Apttus_Proposal__Account__c;               
                    subAccount.APT_Organisation__c = proposal.Apttus_Proposal__Account__c;
                } else {
                    haserrorMessages = true;
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.MISSING_PROPOSAL));
                }
            } else {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.MISSING_PROPOSAL));
            } 
        } 
        
        
        account = [SELECT Id, Name, BillingPostalCode, BillingState, BillingStreet, BillingCountry,BillingCity,ShippingCity,
                        ShippingPostalCode, ShippingStreet, ShippingState, ShippingCountry,ABN__c
                        FROM Account WHERE Id = :accountID];

        if(account != null) {
            //default values
            subAccount = populateDefaultValues(subAccount, proposal, account);
        }
    }
    /**
        This method will populate default fields
     */
    private APT_Sub_Account__c populateDefaultValues(APT_Sub_Account__c subAccount, Apttus_Proposal__Proposal__c proposal, Account account) {
        
        if(!isAccountFlow){
        //proposal
            subAccount.APT_Quote_Proposal__c = proposal.Id;
    
            subAccount.APT_Sub_Account_Contact_Name__c = proposal.Apttus_Proposal__Opportunity__r.KeyContact__r.Name;
            subAccount.APT_Sub_Account_Contact_Telephone__c = proposal.Apttus_Proposal__Opportunity__r.KeyContact__r.Phone;
            subAccount.APT_Sub_Account_Contact_Email_Address__c = proposal.Apttus_Proposal__Opportunity__r.KeyContact__r.Email;
        }
        //account
        
        subAccount.APT_Organisation__c = account.Id;
        mailingAddress = new AddressExtension(account.billingStreet, APT_Constants.EMPTY_STRING , account.BillingCity, account.BillingState, account.BillingPostalCode, account.ABN__c, account.BillingCountry);
        physicaladdress = new AddressExtension(account.ShippingStreet, APT_Constants.EMPTY_STRING, account.ShippingCity, account.ShippingState, account.ShippingPostalCode, account.ABN__c, account.ShippingCountry);       
        
        if(String.isNotBlank(chargeAccountId)){
           subAccount.APT_Charge_Account__c =  chargeAccountId;
        }
        return subAccount;       
    }

    /**
        This method will create sub-account and redirect back to proposal
     */
    public pageReference saveAndClose(){ 
        
        pageReference redirectPage = null; 
        try {
            
            //940
            APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            Boolean bIsValidState = true;
            if(r2tSystemProperty != null && String.isNotBlank(r2tSystemProperty.APT_Credit_Assessment_Valid_States__c)) {
                list<String> listValidStates = r2tSystemProperty.APT_Credit_Assessment_Valid_States__c.split(APT_Constants.SEPERATOR_COMMA);
                if(listValidStates != null) {
                    set<String> setValidStates = new set<String>();
                    for(String vs : listValidStates) {
                        setValidStates.add(vs);
                    }
                    
                    if(mailingAddress != null && String.isNotBlank(mailingAddress.state) && !setValidStates.contains(mailingAddress.state)) {
                        bIsValidState = false;
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid State.'));
                        //27042017 SC: 1855 Added new custom label to show State Error Message
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_State_Name_in_Uppercase));
                    }
                    
                    if(physicaladdress != null && String.isNotBlank(physicaladdress.state) && !setValidStates.contains(physicaladdress.state)) {
                        bIsValidState = false;
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid State.'));
                        //27042017 SC: 1855 Added new custom label to show State Error Message
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_State_Name_in_Uppercase));
                    }
                }
            }
            //940
            
            if(bIsValidState && saveSubAccount()){   //940
                redirectPage = backToProposal();
            }
            
        }  catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        } 

        return redirectPage;                
    }
    public boolean ChargeAccountEmptyFlag {get{
        return String.isBlank(chargeAccountId);
        }set;}
    private Boolean saveSubAccount(){
        boolean saveFlag = false;
        if(String.isNotBlank(chargeAccountId)){
           subAccount.APT_Charge_Account__c =  chargeAccountId;
        }
        if(String.IsBlank(subAccount.APT_Charge_Account__c) && String.IsBlank(subAccount.APT_Billing_Account__c)){
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.MISSING_CHARGE_ACCOUNT));
        } else {
            system.debug('*** subAccount ***'+subAccount);
            
            subAccount.APT_Postal_Address_State__c = mailingAddress.state;
            subAccount.APT_Postal_Address_Street_Postcode__c = mailingAddress.PostCode;
            subAccount.APT_Postal_Address_Suburb__c = mailingAddress.city;
            subAccount.APT_Postal_Address_Country_Code__c = mailingAddress.country;
            subAccount.APT_Postal_Address_Street_Name__c = String.isNotBlank(mailingAddress.Line1) ? mailingAddress.Line1.left(25) : APT_Constants.EMPTY_STRING;
            subAccount.APT_Postal_Address_Street_Type__c = mailingAddress.Line2;
            
            
            subAccount.APT_Street_Address_Street_Type__c = physicalAddress.Line2;
            
            subAccount.APT_Street_Address_State__c = physicalAddress.State;
            subAccount.APT_Street_Address_Street_Postcode__c = physicalAddress.PostCode;
            subAccount.APT_Street_Address_Suburb__c = physicalAddress.City;
            subAccount.APT_Street_Address_Country_Code__c = physicalAddress.Country;
            subAccount.APT_Street_Address_Street_Name__c = String.isNotBlank(physicalAddress.Line1) ? physicalAddress.Line1.left(25) : APT_Constants.EMPTY_STRING;
            System.debug('**subAccount:'+ subAccount);
            
            insert subAccount;
            saveFlag =  true;
            
        }
        return saveFlag;
    }

    /**
        This method will create sub-account and redirect back to proposal
     */
    public pageReference saveAndNew(){  
        try {
            
            //940
            APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            Boolean bIsValidState = true;
            if(r2tSystemProperty != null && String.isNotBlank(r2tSystemProperty.APT_Credit_Assessment_Valid_States__c)) {
                list<String> listValidStates = r2tSystemProperty.APT_Credit_Assessment_Valid_States__c.split(APT_Constants.SEPERATOR_COMMA);
                if(listValidStates != null) {
                    set<String> setValidStates = new set<String>();
                    for(String vs : listValidStates) {
                        setValidStates.add(vs);
                    }
                    
                    if(mailingAddress != null && String.isNotBlank(mailingAddress.state) && !setValidStates.contains(mailingAddress.state)) {
                        bIsValidState = false;
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid State.'));
                        //27042017 SC: 1855 Added new custom label to show State Error Message
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_State_Name_in_Uppercase));
                    }
                    
                    if(physicaladdress != null && String.isNotBlank(physicaladdress.state) && !setValidStates.contains(physicaladdress.state)) {
                        bIsValidState = false;
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid State.'));
                        //27042017 SC: 1855 Added new custom label to show State Error Message
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_State_Name_in_Uppercase));
                    }
                }
            }
            //940
            
            if(bIsValidState && saveSubAccount()){  //940
            
                subAccount = new APT_Sub_Account__c();
    
                //default values
                subAccount = populateDefaultValues(subAccount, proposal, account);
                billingAcc = null;
                chargeAcc = null;
                
            }

        }  catch(Exception ex) {
            haserrorMessages = true;
            System.debug('**Message:'+ ex.getMessage());
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        } 

        return null;                
    }

    /**
        This method will redirect user to quote/proposal detail page
     */
    public pageReference backToProposal(){
     PageReference redirectPage = null; 
     try {   
        
         
        if(String.isNotBlank(proposalId)) {
            redirectPage=  new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + proposalId);
        } else if(isAccountFlow) {
            redirectPage =  new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + accountID);
        } else {}
    }  catch(Exception ex) {
            haserrorMessages = true;
            System.debug('**Message:'+ ex.getMessage());
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        } 
        return redirectPage;        
    }
}