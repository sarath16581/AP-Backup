/**
Description: This apex class is controller for vf page APT_RequestNewAccount. The page is being called using 
'Request for New Acccount' button from Account detail page. 
Created By - Mausam Padhiyar
Created Date - 17th Nov, 2015
Last Modified By -
Last Modified Date - 
**/
public with sharing class APT_RequestNewAccountController {
    /**
        This method will redirect you to next page.
    */
    public PageReference doNext() {
        try {
            PageReference redirectPage = null;
            
            system.debug('--->' + selectedAccountType);
            system.debug('--->' + accountTypes);
            
            if(selectedAccountType.toLowercase().contains(APT_Constants.STRING_CHARGE)){
                
                redirectPage = Page.Apt_CreditAssessment;
                redirectPage.setRedirect(true);
                redirectPage.getParameters().put(APT_Constants.STIRNG_ID_CAPITAL, organisationId);
                redirectPage.getParameters().put(APT_Constants.PARAM_ACCOUNT_TYPE, selectedAccountType);
                
            } else if(selectedAccountType.toLowercase().contains(APT_Constants.ACCOUNT_TYPE_CASH_LOWER)) {
            
                redirectPage = Page.APT_CashAccountAssessment;
                redirectPage.setRedirect(true);
                redirectPage.getParameters().put(APT_Constants.PARAM_ACCOUNT_ID, organisationId);
            } else {
            
                redirectPage = Page.APT_SubAccountAssessment;
                redirectPage.setRedirect(true);
                redirectPage.getParameters().put(APT_Constants.PARAM_ACCOUNT_ID, organisationId);
            }
            
            return redirectPage;
         }   
         catch(Exception ex) {
           
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;        
         }  
    }

    String organisationId;
    
    public Account organisation {get; set;}
    public boolean haserrorMessages {get; set;}
    public String selectedAccountType {get; set;}
    public list<SelectOption> accountTypes {get; set;}
     /**
        Constructor
    */   
    public APT_RequestNewAccountController() {
        haserrorMessages = false;
        
        organisationId= string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.URL_ID));
        
        if(String.isNotBlank(organisationId)) {
            organisation = [SELECT Id, Name, IsPersonAccount FROM Account WHERE Id = :organisationId limit 1];
        } else {
        
            organisation = new Account();
        }
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
        accountTypes = new list<SelectOption>();
        if(r2tSystemProperties != null) {      
            if(String.isNotBlank(r2tSystemProperties.APT_Account_Types__c)) {
                list<String> listAccountTypes = r2tSystemProperties.APT_Account_Types__c.split(APT_Constants.SEPERATOR_COMMA);
                if(listAccountTypes != null && listAccountTypes.size() > 0) {
                    selectOption op;
                    for(String listAccountType : listAccountTypes ) {
                        op = new selectOption(listAccountType, listAccountType);
                        accountTypes.add(op);
                    }
                }
            } else {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.STRING_ERROR_MESSAGE_MISSING_ACCOUNT_TYPES));
            }
        } else {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MESSAGE_MISSING_CUSTOM_SETTINGS));
        }
    }
}