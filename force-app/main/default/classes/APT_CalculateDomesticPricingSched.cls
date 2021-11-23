/**
Descirtion: This scheduleable class will schedule job to calculate domestic pricing. Create Price List Item and Price Matrix records. 
Price Matrix Entry records will be creates using batch apex.
Created By - Mausam Padhiyar
Created Date - 9th Oct, 2015
**/
global class APT_CalculateDomesticPricingSched implements Schedulable {
    /**
        Execution start
    **/
    global void execute (SchedulableContext sc) {
        list<String> listErrorMessage = new list<String>();
        String emailAddresses;
        try {            
            //get default price list item
            APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
            if(r2tSystemProperties != null) {                
                if(!String.isEmpty(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c)) {
                    emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
                }
            } 

            APT_DeleteExistingDomesticPricingBatch domesticBatchController = new APT_DeleteExistingDomesticPricingBatch();
            database.executeBatch(domesticBatchController, 1);
                           
        } catch(System.Exception ex) {
            listErrorMessage.add(ex.getMessage() + ' ' + ex.getStackTraceString());
            if(!String.isEmpty(emailAddresses) && !String.isEmpty(APT_Constants.DEFINE_STRING) &&  emailAddresses.equalsIgnoreCase(APT_Constants.DEFINE_STRING)) {
                sendEmailAlert(emailAddresses, listErrorMessage);
            }
        }
    }
    
    /**
        This method will send email alert.
        @params -
        emailAddresses - comma separated email addresses
        listErrorMessage - list of error messages
     */ 
    @TestVisible 
    private static void sendEmailAlert(String emailAddresses, list<String> listErrorMessage) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        list<String> toAddresses = emailAddresses.split(APT_Constants.ADD_COMMA);
        mail.setToAddresses(toAddresses);
        mail.setSubject(APT_Constants.INTERNATIONAL_PRICING_STATUS);
        
        //Handle Batch Error Message             
        String errorMessage;
        for(String em : listErrorMessage) {
            if(!String.isEmpty(errorMessage)) {
                errorMessage += APT_Constants.SEPARATOR_NEXT_LINE + em;
            } else {
                errorMessage = em;
            }
        }
        
        mail.setPlainTextBody(APT_Constants.JOB_PROCESSED + listErrorMessage.size() + APT_Constants.FAILURES_ERRORS + errorMessage);                
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}