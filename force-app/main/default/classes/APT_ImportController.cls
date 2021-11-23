/**
Description: 
Created By - Szymon Marciniewicz
Created Date - 13th Oct,2015
Last Modified By -
Last Modified Date -
**/
public with sharing class APT_ImportController
{

public String apiSessionId {get;set;} 
public String apiServerURL {get;set;}    
public String retURL {get;set;} 
public Apttus__APTS_Agreement__c agreement;
public Id agreementId = null;
public String nextStep {get;set;}
public String pageURL = null;
public static final String OUTPUT_TEXT = 'Completing Import, please wait...';
public String output_text_Value {set;get{return OUTPUT_TEXT;}}
    /**
        Constructor
    **/
    public APT_ImportController(ApexPages.StandardController stdController) 
    {
        try {
          system.debug('in the controller');   
            agreement = (Apttus__APTS_Agreement__c)stdController.getRecord();  
            
            agreementId = agreement.Id;
            nextStep = ApexPages.currentPage().getParameters().get(APT_Constants.URL_NEXTSTEP);
            retURL = ApexPages.currentPage().getParameters().get(APT_Constants.URL_RETURL);
            pageURL = ApexPages.currentPage().getUrl();
        system.debug('URL is: ' + pageURL); 
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           
        }  
    }
    /**
        This method will change status of agreement.
    **/
    public PageReference doFullySigned()
    {
        try {
            if(agreement != null) {
                agreement = [Select Apttus__Status_Category__c, Apttus__Status__c From Apttus__APTS_Agreement__c Where Id = :agreementId];
            }
            system.debug(logginglevel.error,'StatusCategory is: ' + agreement.Apttus__Status_Category__c+'  Status is: '+agreement.Apttus__Status__c); 
            if ((agreement.Apttus__Status_Category__c.equals(APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES) && (agreement.Apttus__Status__c.equals(APT_Constants.AGREEMENT_STATUS_OTHER_PARTY_SIGNATURE) || agreement.Apttus__Status__c.equals(APT_Constants.AGREEMENT_STATUS_SIGNED_BY_CUSTOMER_ONLY))))
                {   
                    agreement.Apttus__Status_Category__c = APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES;
                    agreement.Apttus__Status__c = APT_Constants.AGREEMENT_STATUS_FULLY_SIGNED;
                    System.debug(logginglevel.error,'  agreement : ' + agreement);
                    update agreement;
            }
            
            PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + agreementId);       
            return pageRef;
         } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           return null;
        }  
    }
     /**
        This method will change status of agreement.
    **/   
    public PageReference doPartiallySigned()
    {
        try {
            if(agreement != null) {
                agreement = [Select Apttus__Status_Category__c, Apttus__Status__c From Apttus__APTS_Agreement__c Where Id = :agreementId];
            }
            system.debug('StatusCategory is: ' + agreement.Apttus__Status_Category__c+'  Status is: '+agreement.Apttus__Status__c); 
            if ((agreement.Apttus__Status_Category__c.equals(APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES) && agreement.Apttus__Status__c.equals(APT_Constants.AGREEMENT_STATUS_OTHER_PARTY_SIGNATURE)) )
                {   
                    agreement.Apttus__Status_Category__c = APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES;
                    agreement.Apttus__Status__c = APT_Constants.AGREEMENT_STATUS_FULLY_SIGNED;
                    update agreement;
            }
            
            PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + agreementId);       
            return pageRef;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           return null;
        }  
    }
    
     /**
        This method will change status of agreement.
    **/   
    public PageReference doThirdParty()
    {
        try {
            if(agreement != null) {
                agreement = [Select Apttus__Status_Category__c, Apttus__Status__c, Apttus__Source__c, Apttus__Agreement_Category__c From Apttus__APTS_Agreement__c Where Id = :agreementId];
            }
            system.debug('StatusCategory is: ' + agreement.Apttus__Status_Category__c+'  Status is: '+agreement.Apttus__Status__c); 
            if (agreement.Apttus__Status_Category__c.equals(APT_Constants.AGREEMENT_STATUS_CATEGORY_REQUEST))
                {   
                    agreement.Apttus__Status_Category__c = APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_AUTHORING;
                    agreement.Apttus__Status__c = APT_Constants.AGREEMENT_STATUS_AUTHOR_CONTRACT;
                    agreement.Apttus__Source__c = APT_Constants.AGREEMENT_SOURCE_OTHER_PARTY_PAPER;
                    agreement.Apttus__Agreement_Category__c = APT_Constants.AGREEMENT_CATEGORY_CUSTOMISED;
                    update agreement;
            }
            
            PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + agreementId);       
            return pageRef;
        } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           return null;
        }  
    }
     /**
        This method will change status of agreement.
    **/   
    public PageReference doLegacy()
    {
        try {
            if(agreement != null) {
                agreement = [Select Apttus__Status_Category__c, Apttus__Status__c, Apttus__Source__c From Apttus__APTS_Agreement__c Where Id = :agreementId];
            }
            system.debug('StatusCategory is: ' + agreement.Apttus__Status_Category__c+'  Status is: '+agreement.Apttus__Status__c); 
            if (agreement.Apttus__Status_Category__c.equals(APT_Constants.AGREEMENT_STATUS_CATEGORY_REQUEST))
                {   
                    agreement.Apttus__Status_Category__c = APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_AUTHORING;
                    agreement.Apttus__Status__c = APT_Constants.AGREEMENT_STATUS_AUTHOR_CONTRACT;
                    update agreement;
            }
            
            PageReference pageRef = new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + agreementId);       
            return pageRef;
         } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           return null;
        }  
    }
    /**
        This method will redirect you to previous page.
    **/    
        public PageReference doCancel() 
    {
        try {    
            return (new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + agreement.Id));     
         } catch(system.exception ex) {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
           return null;
        }  
    }
    
    

}