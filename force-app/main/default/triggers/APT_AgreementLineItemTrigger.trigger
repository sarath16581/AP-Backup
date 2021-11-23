/**
Description: This apex class if handler class for apex trigger - APT_AgreementLineItemTrigger.
Created By: Garvita Rai
Created Date: 3rd Dec, 2015
Last Modified By: Mausam Padhiyar
Last Modified Date: 21st July, 2016
*/
trigger APT_AgreementLineItemTrigger  on Apttus__AgreementLineItem__c (before insert, after insert) {
    if(trigger.isBefore){
        if(trigger.isInsert) {
            String result = APT_AgreementLineItemTriggerHandler.beforeInsertEvent(trigger.new);
             
            if(result != APT_Constants.SUCCESS_LABEL){
                for(Apttus__AgreementLineItem__c agreementLineItem : trigger.new) {
                    agreementLineItem.addError(result);
                }             
            } 
        }
    }
    
    if(trigger.isAfter){
         if(trigger.isInsert || trigger.isDelete){
            //APT_AgreementLineItemTriggerHandler.createAgreementChildRecords(trigger.new);
            String result = APT_AgreementLineItemTriggerHandler.afterInsertOrDeleteEvent(trigger.new, trigger.isInsert, trigger.isDelete);
             
            if(result != APT_Constants.SUCCESS_LABEL){
                for(Apttus__AgreementLineItem__c agreementLineItem : trigger.new) {
                    agreementLineItem.addError(result);
                }             
            } 
         }
     }
}