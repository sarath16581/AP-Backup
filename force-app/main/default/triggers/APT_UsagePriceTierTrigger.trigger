/**
Created By - Mausam Padhiyar
Created Date - 21st June, 2016
*/
trigger APT_UsagePriceTierTrigger on Apttus_Config2__UsagePriceTier__c (before Update) {
    if(trigger.isBefore && trigger.isUpdate){
        String result = APT_UsagePriceTierTriggerHandler.beforeUpdateEvent(trigger.new);
        if(!String.isEmpty(result) && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)){
            for(Apttus_Config2__UsagePriceTier__c upt : trigger.new) {
                upt.addError(result);
            }
        }
    }
}