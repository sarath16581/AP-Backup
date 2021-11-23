/**
Populate Site Inspection record ids on Operation Schedule
Created By - Mausam Padhiyar
Created Date - 19th Aug, 2016
*/
trigger APT_SiteInspectionTrigger on APT_Site_Inspection__c (after insert) {
    if(trigger.isInsert && trigger.isAfter){
        String result = APT_SiteInspectionTriggerHandler.afterInsertEvent(trigger.new);
        
        if(String.isNotBlank(result) && !result.equalsIgnoreCase(APT_Constants.SUCCESS_LABEL)) {
            for(APT_Site_Inspection__c si : trigger.new) {
                si.addError(result);
            }
        }
    }
}