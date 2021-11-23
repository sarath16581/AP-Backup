/**
 * @author Ranjeewa Silva
 * @date 2021-08-12
 * @domain PUD
 * @description Trigger on PUD_Job__c object. Dispatch to domain base trigger handler to handle all trigger events.
 * @changelog
 * 2021-08-12 - Ranjeewa Silva - Created
 */

trigger PUDJobTrigger on PUD_Job__c (before insert, before update, before delete,
		after insert, after update, after delete, after undelete) {

	// check if trigger is enabled
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(PUD_Job__c.SObjectType))) {
		// domain base trigger dispatch
		(new PUDJobTriggerHandler()).dispatch();
	}
}