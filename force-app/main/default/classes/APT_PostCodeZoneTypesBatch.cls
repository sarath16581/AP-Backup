/**
Description: This batch job will create zone types in post code mapping
Created By - Mahesh Patel
Created Date - 20th Oct, 2020
Last Modified By -
Last Modified Date - 
**/
global class APT_PostCodeZoneTypesBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global set<String> setErrorMessage {get;set;} 
    global List<APT_Post_Code_Mapping__c> listPostCodeMapping; 

    public APT_PostCodeZoneTypesBatch(List<APT_Post_Code_Mapping__c> listPostCodeMapping) {
        setErrorMessage = new set<String>();
        this.listPostCodeMapping = listPostCodeMapping;
    }

    /**
        Start
    **/ 
    //start() Method to pass eligible post code mappings
    global Iterable<sObject> start(Database.BatchableContext bc){      
        return (Iterable<sObject>)this.listPostCodeMapping;
    }  

    /**
        execute
    **/    
    global void execute(Database.BatchableContext bc, List<APT_Post_Code_Mapping__c> listPostCodeMapping){
        try 
        { 
            update listPostCodeMapping;
        } 
        catch(System.Exception ex) {
            setErrorMessage.add(ex.getMessage());          
            system.debug('APT_PostCodeZoneTypesBatch Exception: ' + ex.getMessage());
        }
    }

    /**
        send email notification
    **/    
    public void sendEmailNotification(AsyncApexJob asyncApexJob, set<String> setErrorMessage) {
        
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
        toAddresses.add(asyncApexJob.CreatedBy.Email);
        
        //String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject(APT_Constants.EMAIL_SUB_DOMESTIC_PRICING_BATCH_STATUS);
        
        //Handle Batch Error Message
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
            mail.setPlainTextBody(APT_Constants.EMAIL_PLAIN_TEXT_PART_1 + asyncApexJob.TotalJobItems + APT_Constants.EMAIL_PLAIN_TEXT_PART_2 + iErrorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage);
        } /**else {
            mail.setPlainTextBody('The Domestic Pricing Batch job has processed ' + a.TotalJobItems + ' batches with '+ iErrorCount + ' failures.');
        }**/
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    /**
        finish
    **/    
    global void finish(Database.BatchableContext bc) {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob asyncApexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :bc.getJobId()];
                        
        if(asyncApexJob.NumberOfErrors > 0) {
            setErrorMessage.add(asyncApexJob.ExtendedStatus);
        }
        
        if(setErrorMessage.size() > 0) {
            
            this.sendEmailNotification(asyncApexJob, setErrorMessage);

        } else {
            //call price list item and price matrix batch
            APT_DomesticPricingPLIAndPMBatch domesticBatchController = new APT_DomesticPricingPLIAndPMBatch();
            database.executeBatch(domesticBatchController, 1);
        }
    }
}