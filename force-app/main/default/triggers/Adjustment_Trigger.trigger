/**
 * Date             Version         Owner                 Desription
 * 03-Mar-17         1.1            Adrian R              Created Adjustment Trigger                                                     
 */ 
trigger Adjustment_Trigger on Adjustment__c (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
        	AdjustmentTriggerHandler.afterInsertTriggerHandler(trigger.New); 
        }else if(trigger.isUpdate){
            AdjustmentTriggerHandler.afterUpdateTriggerHandler(trigger.OldMap, trigger.New);
        }
    }
    /* 
    if(trigger.isBefore){
        if(trigger.isInsert){
        }else if(trigger.isUpdate){
        }
    }
	*/

    /*
    if(trigger.isBefore){
        if(trigger.isDelete){
            AdjustmentTriggerHandler.beforeDeleteTriggerHandler(trigger.oldMap,trigger.old);
        }
    }
    */
}