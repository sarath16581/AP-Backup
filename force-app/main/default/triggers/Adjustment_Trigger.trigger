/**
 * Date			 	Version		Owner				 	Desription
 * 03-Mar-17		1.1			Adrian R			 	Created Adjustment Trigger
 * 2023-06-30		2.0			Pratyush Chalasani		Refactored into new framework
 */ 
trigger Adjustment_Trigger on Adjustment__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
	if (!TriggerHelper.isTriggerDisabled(String.valueOf(Adjustment__c.sObjectType))) { // verify if triggers are disabled
		(new AdjustmentTriggerHandler()).dispatch();
	}
}