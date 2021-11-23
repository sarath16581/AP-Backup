/**
 * @changelog
 * 2017-02-01 - Bharat P - Initial Version - Calls DisputedItemTriggerHandler for performing necessary actions.
 * 2017-03-03 - Adrian R - Update to remove after trigger events since it is not needed for current phase requirements
 * 2021-06-02 - Ranjeewa Silva - Added after update trigger handler
 */ 
trigger Disputed_Item_Trigger on Disputed_Item__c (before insert, before update, before delete, after update){
    if(trigger.isBefore){
        if(trigger.isInsert){
            DisputedItemTriggerHandler.beforeInsertTriggerHandler(trigger.New); 
        }else if(trigger.isUpdate){
            DisputedItemTriggerHandler.beforeUpdateTriggerHandler(trigger.OldMap, trigger.New);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        DisputedItemTriggerHandler.afterUpdateTriggerHandler(trigger.new, trigger.oldMap);
    }
     
    if(trigger.isBefore){
        if(trigger.isDelete){
            DisputedItemTriggerHandler.beforeDeleteTriggerHandler(trigger.oldMap,trigger.old);
        }
    }
}