/**
* Description: Populate Credit Assessment Status and Credit Limit on Proposal and Charge Account 
* Created By - Mausam Padhiyar
* Created Date - 15th Sept, 2016
**/
trigger APT_CreditAssessmentTrigger on APT_Credit_Assessment__c (after update) {
    //after update
    if(trigger.isAfter && trigger.isUpdate) {
        String result = APT_CreditAssessmentTriggerHandler.afterUpdateEvent(trigger.new, trigger.oldMap);
        
        if(result != null && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
            for(APT_Credit_Assessment__c ca : trigger.new) {
                ca.addError(result);
            }
        }
    }
}