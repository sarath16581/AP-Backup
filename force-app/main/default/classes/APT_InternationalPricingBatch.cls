/**
Description: This batch job will create internation pricing - Price Matrix Entry records
Created By - Mausam Padhiyar
Created Date - 5th Oct, 2015
Last Modified By -
Last Modified Date - 
**/
global class APT_InternationalPricingBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global set<String> setErrorMessage {get;set;}
    
    map<String, list<APT_International_Price_Data__c>> mapInternationalPriceData {get;set;}
    set<Id> setPriceMatrixId = new set<Id>();
    
    /**
        constructor
    **/    
    global APT_InternationalPricingBatch(set<Id> setPMId,
                                        map<String, list<APT_International_Price_Data__c>> mapIPData){
        
        setErrorMessage = new set<String>();
        setPriceMatrixId = setPMId;
        mapInternationalPriceData = mapIPData;
    }
    /**
        Query locator to fetch price matrix data
    **/    
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        //start
        return Database.getQueryLocator([SELECT Id, Name, Apttus_Config2__PriceListItemId__c,
                                        Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.ProductCode,
                                        Apttus_Config2__PriceListItemId__r.APT_Industry__c,
                                        Apttus_Config2__PriceListItemId__r.APT_eParcel_Lodgment__c,
                                        Apttus_Config2__PriceListItemId__r.APT_Band__c,
                                        Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c
                                        FROM Apttus_Config2__PriceMatrix__c
                                        WHERE Id IN :setPriceMatrixId]);
    }
    /**
        Batch method to delete price matrix entries
    **/     
    global void execute(Database.BatchableContext BC, list<Apttus_Config2__PriceMatrix__c> scope){
        //execute
        try { 
            set<Id> setPriceMatrixId = new set<Id>();
            for(Apttus_Config2__PriceMatrix__c pm : scope) {
                setPriceMatrixId.add(pm.Id);
            }
            
            //delete existing price matrix entry
            list<Apttus_Config2__PriceMatrixEntry__c> listExistingPME = [SELECT Id FROM Apttus_Config2__PriceMatrixEntry__c
                                                                        WHERE Apttus_Config2__PriceMatrixId__c IN :setPriceMatrixId];
            
            if(listExistingPME != null && listExistingPME.size() > 0) {
                system.debug('*** listExistingPME > size ***'+listExistingPME.size());
                delete listExistingPME;
            }
                
            //create price matrix entry records                 
            list<Apttus_Config2__PriceMatrixEntry__c> listPME = APT_PricingUtility.createPriceMatrixEntryForInternational(scope, mapInternationalPriceData);
            if(listPME != null && listPME.size() > 0) {
                system.debug('*** listPME > size ***'+listPME.size());
                insert listPME;
            } 
        } catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
        }
    }
    /**
        Finish method
    **/      
    global void finish(Database.BatchableContext BC) {
        //finish
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :BC.getJobId()];
        
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        //get email addresses
        APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
        String emailAddresses;            
        if(r2tSystemProperties != null) {            
            if(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c != null) {
                emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
            }
        } 
        
        list<String> toAddresses = new list<String>();
        if(String.isNotEmpty(emailAddresses)) {
            toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
        }
        toAddresses.add(a.CreatedBy.Email);
        
        //String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject(APT_Constants.EMAIL_SUB_INTERNATIONAL_PRICING_BATCH_STATUS);
        
        //Handle Batch Error Message    
        if(a.NumberOfErrors > 0) {
            setErrorMessage.add(a.ExtendedStatus);
        }
        Integer iErrorCount = setErrorMessage.size();
            
        String errorMessage;
        for(String errorMessage1 : setErrorMessage) {
            if(errorMessage != null) {
                errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
            } else {
                errorMessage = errorMessage1;
            }
        }
        
        //add Batch Error Message in Email
        if(errorMessage != null) {
            mail.setPlainTextBody(APT_Constants.APEX_JOB_PROCESSED + a.TotalJobItems + APT_Constants.EMAIL_PLAIN_TEXT_PART_2 + iErrorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage);
        } else {
            mail.setPlainTextBody(APT_Constants.APEX_JOB_PROCESSED + a.TotalJobItems + APT_Constants.EMAIL_PLAIN_TEXT_PART_2 + iErrorCount + APT_Constants.EMAIL_PLAIN_SUCCESS_PART_2);
        }
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}