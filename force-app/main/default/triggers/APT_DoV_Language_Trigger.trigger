trigger APT_DoV_Language_Trigger on APT_DoV_Language__c (after insert,after update) {
    if(Trigger.isAfter && Trigger.isInsert){
        APT_DovLanguageTriggerHandler.afterInsert(Trigger.new);
    }
    else if(Trigger.isAfter && Trigger.isUpdate){
        APT_DovLanguageTriggerHandler.afterUpdate(Trigger.oldMap,Trigger.newMap);
    }
}