/**
* Description: Populate Credit Assessment Status and Credit Limit on Proposal and Charge Account 
* Created By - Mausam Padhiyar
* Created Date - 15th Sept, 2016
* Updated - avula.jansirani@crmit.com, 11-05-2021  (added 'after insert block')
**/
trigger APT_CreditAssessmentTrigger on APT_Credit_Assessment__c (after update, after insert) {
    //after update
    if(trigger.isAfter && trigger.isUpdate) {
        String result = APT_CreditAssessmentTriggerHandler.afterUpdateEvent(trigger.new, trigger.oldMap);
        
        if(result != null && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
            for(APT_Credit_Assessment__c ca : trigger.new) {
                ca.addError(result);
            }
        }
    }
    
    //after insert
    if(trigger.isAfter && trigger.isInsert) {
        APT_CreditAssessmentTriggerHandler.afterInsertEvent(trigger.new, trigger.oldMap);
    }

}