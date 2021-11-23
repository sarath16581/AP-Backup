/**
 * Apex Trigger on object - Apttus__AsyncMergeCall__c. 
 * Task - 1: Merge Documents
 * Created By - Mausam Padhiyar
 * Created Date - 24th June, 2016
 */
trigger APT_AsyncMergeCallTrigger on Apttus__AsyncMergeCall__c (before Update) {
    
    //before update
    if(trigger.isBefore && trigger.isUpdate) {
        String result = APT_AsyncMergeCallTriggerHandler.beforeUpdateEvent(trigger.new, trigger.oldMap);
        if(result != null && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
            for(Apttus__AsyncMergeCall__c asyncMergeCall : trigger.new) {
                asyncMergeCall.addError(result);
            }
        }
    }
}