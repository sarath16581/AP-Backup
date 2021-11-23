/*
* This class will delete SAP Rates records for Sync Contract and Rates request
* Created By - Mausam Padhiyar
* Created Date - 26th Aug, 2016
* 
* Last Modified By - Seth Heang
* Last Modified Date - 31th July, 2020 | SOQL 50001 fix on SAP Rate objects
*
*/ 
global class APT_DeleteSAPRatesBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    global set<String> setPLIId {get; set;}
    global set<String> setErrorMessage {get; set;}
    
    /**
        Constructor
    */
    global APT_DeleteSAPRatesBatch(set<String> pliIdSet) {        
        setPLIId = new set<String>();        
        setErrorMessage = new set<String>();        
        
        setPLIId = pliIdSet;
    }
    
    /**
        start
     */
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        return Database.getQueryLocator([SELECT Id, APT_Proposal_Line_Item__c FROM APT_SAP_Rate__c
                                        WHERE APT_Proposal_Line_Item__c IN :setPLIId]);
        
    }
    
    /**
        execute
     */
    global void execute(Database.BatchableContext BC, list<APT_SAP_Rate__c> listSR){
        try{
            delete listSR;
        } catch(system.exception ex) {
            setErrorMessage.add(ex.getMessage());
        }
    }
    
    /**
        Finish
     */
    global void finish(Database.BatchableContext BC) {
        if(setErrorMessage.size() > 0) {
            //send email alert
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :BC.getJobId()];
                        
            if(a.NumberOfErrors > 0) {
                setErrorMessage.add(a.ExtendedStatus);
            }
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
            //get email addresses
            APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
            String emailAddresses;            
            if(r2tSystemProperties != null) {            
                if(!String.isEMpty(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c)) {
                    emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
                }
            } 
            list<String> toAddresses = new list<String>();
            if(!String.isEmpty(emailAddresses)) {
                toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
            }
            mail.setToAddresses(toAddresses);
            
            mail.setSubject(APT_Constants.SYNC_CONTRACT_RATES_ERROR);
            
            //Handle Batch Error Message 
            Integer iErrorCount = setErrorMessage.size();
                
            String errorMessage;
            for(String errorMessage1 : setErrorMessage) {
                if(String.isNotBlank(errorMessage)) {
                    errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
                } else {
                    errorMessage = errorMessage1;
                }
            }
            
            //add Batch Error Message in Email
            if(String.isNotBlank(errorMessage)) {
                mail.setPlainTextBody(APT_Constants.SYNC_CONTRACT_RATES_BATCH_JOB_COMPLETED_WITH + iErrorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage);
            }
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });           
        } 
    }
}