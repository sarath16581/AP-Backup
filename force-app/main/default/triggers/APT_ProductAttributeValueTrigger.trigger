/**
Description: set flag fall rate and per kg rate.
Created By - Mausam Padhiyar
Created Date - 16th Oct, 2015
Last Modified By -
Last Modified Date - 
Mathew Jose - 29/05/2021 - Added afterUpdateEvent method as part of STP-5812 (Shopping Cart Performance)
Mathew Jose - 29/05/2021 - Updated beforeInsert method call as part of STP-5812 (Shopping Cart Performance)
**/
trigger APT_ProductAttributeValueTrigger on Apttus_Config2__ProductAttributeValue__c (before insert,before update, after update) {
    
    //Calculate Band when Volume Data = No based on Revenue Committment selected on attributes
    //before insert and update both
    //APT_ProductAttributeValueTriggerHandler.bandInfo(trigger.new);
    
    
    
    if(trigger.isBefore && trigger.isInsert) {
        /*String result = APT_ProductAttributeValueTriggerHandler.beforeInsertEvent(trigger.new);
        if(result != APT_Constants.SUCCESS_LABEL){
            for(Apttus_Config2__ProductAttributeValue__c pav : trigger.new) {
                pav.addError(result);
            }               
        }*/
        //Removing the addError logic from trigger as exceptions can be handled within the handler itself.
        APT_ProductAttributeValueTriggerHandler.beforeInsertEvent(trigger.new);
    }
    
    

    if(trigger.isBefore == true && trigger.isUpdate == true) {
        String result;
        /*
        //APOST-924: not required
        result =  APT_ProductAttributeValueTriggerHandler.populateFieldValues(trigger.new,trigger.oldMap);
        if(result != APT_Constants.SUCCESS_LABEL){
            for(Apttus_Config2__ProductAttributeValue__c pav : trigger.new) {
                pav.addError(result);
            }               
        }
        */
        system.debug('*** PAV before Update ***');
        //result = APT_ProductAttributeValueTriggerHandler.beforeUpdateEvent(trigger.new);
       // Code added for International CO - By Akansha
        result = APT_ProductAttributeValueTriggerHandler.beforeUpdateEvent(trigger.new,trigger.oldMap,trigger.newMap);
        if(result != APT_Constants.SUCCESS_LABEL){
            for(Apttus_Config2__ProductAttributeValue__c pav : trigger.new) {
                pav.addError(result);
            }               
        }
    }

    //STP-5812 - Mathew Jose - Shopping Cart performance.
    if(trigger.isAfter && trigger.isUpdate) {
        APT_ProductAttributeValueTriggerHandler.afterUpdateEvent(trigger.newMap, trigger.oldMap);
    }


}