/**
Description: This apex class is controller for vf page - APT_CreateCase. This will create case of Contract Management Enquiry.
Created By - Mausam Padhiyar
Created Date - 19th Nov, 2015

Last Modified By - Mausam Padhiyar
Last Modified Date - 2nd Aug, 2016
Description - APOST-2032 > Initiating Area and Owner field on Case record
07/10/2019   Swati.mogadala@auspost.com.auAdded 'Support work type' as a field to be populated on createcase REQ1952691
**/
public with sharing class APT_CreateCaseController {
    
    String agreementId;
    String selectedCategory;
    public Case caseRecord {get; set;}
    public boolean haserrorMessages {get; set;}
    public static String PAGEBLOCK_TITLE {get{return APT_Constants.CASE_DETAILS;}set;}
    public static String processing {get{return APT_Constants.PROCESSING_IMAGE;}set;}
    public static String Save_Text {get{return APT_Constants.SAVE_BUTTON;}set;}
    public static String Cancel_Text {get{return APT_Constants.CANCEL_BUTTON;}set;}
  
    /**
    constructor
    */
    public APT_CreateCaseController() {
        
        try {
            init ();
        } catch(System.Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }        
    }
    
    /**
     Init Method
    **/
    public void init () {
        haserrorMessages = false;
        agreementId = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.URL_AGREEMENTID));
        selectedCategory = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.URL_SELECTED_CATEGORY));
        caseRecord = new Case();
        caseRecord.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.RECORD_TYPE_CONTRACT_MANAGEMENT_ENQUIRY).getRecordTypeId();
        caseRecord.Work_Type__c = APT_Constants.CASE_WORK_TYPE_ADDENDUM_DOV;
        caseRecord.Subject = selectedCategory;
        caseRecord.Support_Work_Type__c = APT_Constants.CASE_SUPPORT_WORK_TYPE_DEAL_ENABLEMENT;
        
        //populate biling account no
        if(!String.isEmpty(agreementId)) {
            caseRecord.APT_Contract__c = agreementId;
            Apttus__APTS_Agreement__c agreement = new Apttus__APTS_Agreement__c  ();
            agreement = [SELECT Id, Billing_Account_No__c, Apttus__Primary_Contact__c,Apttus__Related_Opportunity__c,
                        Apttus__Account__c, Apttus__Account__r.Sales_Segment__c
                        FROM Apttus__APTS_Agreement__c             
                        WHERE Id =:agreementId];    
            if(!String.isEmpty(agreement.Billing_Account_No__c)) {
                caseRecord.Billing_Number__c = agreement.Billing_Account_No__c;
            }  

            if(!String.isEmpty(agreement.Apttus__Primary_Contact__c)) {
                caseRecord.contactId = agreement.Apttus__Primary_Contact__c;
            }
            
            if(!String.isEmpty(agreement.Apttus__Related_Opportunity__c)) {
                caseRecord.Opportunity__c = agreement.Apttus__Related_Opportunity__c;
            }
            
            caseRecord.Initiating_Area__c = agreement.Apttus__Account__r.Sales_Segment__c;  //APOST-2032
        }
    }
    
    /**
    Save Button
    */
    public PageReference doSave() {
        try {
            //caseRecord.ownerId =  userinfo.getuserid();   //APOST-2032
            caseRecord.Requestor__c = userinfo.getuserid();
            //caseRecord.Initiating_Area__c = APT_Constants.CASE_INITIATING_AREA_SALESFORCE;    //APOST-2032
            caseRecord.Type = APT_Constants.CASE_TYPE_SALES_CONTRACT_CONSULTING;
            caseRecord.Status = APT_Constants.CASE_STATUS_NEW;
            caseRecord.Origin = APT_Constants.CASE_ORIGIN_SALESFORCE;

            insert caseRecord;

            if(!String.isEmpty(agreementId )) {
                return new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH +agreementId);
            }
        } catch(System.Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        
        return null;
    }
    
    /**
    cancel Button
    */   
    public PageReference doCancel() {
        try {
            if(!String.isEmpty(agreementId)) {
                return new PageReference(APT_Constants.URL_AMEND_RENEW_PAGE + agreementId + APT_Constants.URL_AMEND_RENEW_PAGE_ACTION_NAME);
            } 
            return null;
        }  catch(Exception ex) {
            
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;        
         }  
        
    }
}