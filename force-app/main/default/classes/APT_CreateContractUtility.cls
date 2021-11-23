/**
 * This class will provide utility methods for Create Contract - one click functionality.
 * Created By - Mausam Padhiyar
 * Created Date - 24th June, 2016
 */ 
public with sharing class APT_CreateContractUtility {
    
    /**
     * This method will send email notification
     */ 
    public static void sendEmailNotification(String strAgreementId, String instanceURL, String jobId, set<String> setErrorMessage) {
        //setErrorMessage = new set<String>();
        //share error via send email
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                            FROM AsyncApexJob 
                            WHERE Id = :jobId];
                
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
        toAddresses.add(a.CreatedBy.Email);
        mail.setToAddresses(toAddresses);
        
        String responseMsg =  APT_Constants.CONTRACT_LINK_ACCESS + APT_Constants.SEPERATOR_NEW_LINE + instanceURL + APT_Constants.SEPERATOR_BACKWARD_SLASH + strAgreementId;
        
        if(setErrorMessage != null && setErrorMessage.size() > 0) {
            
            mail.setSubject(APT_Constants.CREATE_CONTRACT_JOB_ERROR);
                
            //Handle Batch Error Message 
            Integer iErrorCount = setErrorMessage.size();
                
            String errorMessage;
            for(String errorMessage1 : setErrorMessage) {
                if(!String.isEmpty(errorMessage)) {
                    errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
                } else {
                    errorMessage = errorMessage1;
                }
            }
            
            //add Batch Error Message in Email
           if(!String.isEmpty(errorMessage)){
                mail.setPlainTextBody(APT_Constants.CREATED_CONTRACT_JOB_COMPLETED_WITH + iErrorCount + APT_Constants.EMAIL_PLAIN_TEXT_PART_3 + errorMessage + APT_Constants.SEPERATOR_NEW_LINE + APT_Constants.SEPERATOR_NEW_LINE + responseMsg);
            }
        } else {
            mail.setSubject(APT_Constants.CREATE_CONTRACT_JOB_STATUS);
            mail.setPlainTextBody(APT_Constants.CREATE_CONTRACT_JOB_COMPLETED_SUCCESSFULLY + APT_Constants.SEPERATOR_NEW_LINE + APT_Constants.SEPERATOR_NEW_LINE + responseMsg);
        }
        
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}