/**
 * @author Mahesh Parvathaneni
 * @date 2023-07-14
 * @description Trigger on BAMApplication__c object. Dispatch to module based trigger handler to handle all trigger events.
 * @changelog
 */

trigger BAMApplicationTrigger on BAMApplication__c (before insert, before update, before delete,
after insert, after update, after delete, after undelete) {

	// check if trigger is enabled
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(BAMApplication__c.SObjectType))) {
		// module based trigger dispatch
		(new BAMApplicationAutomationTriggerHandler()).dispatch();
   }

}