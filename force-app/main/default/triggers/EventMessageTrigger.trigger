/**
 * @author Unknown
 * @description Trigger on EventMessage__c. Delegate to trigger handler for all processing.
 * @date
 * @test EventMessageUtil_Test
 * @changelog
 * 2020-06-12 - arjun.singh@auspost.com.au - Added before update event as well to capture the Machine Details on upsert of
 *										   Event messages record as a part of MyNetwork Uplift
 * 2024-08-19 - Ranjeewa Silva - Uplifted to use ApplicationModule based trigger dispatch framework. All legacy code previously
 *								placed in trigger is moved to new module - EventMessageLegacyAutomationModule.
 */
trigger EventMessageTrigger on EventMessage__c (before insert, before update, before delete,
		after insert, after update, after delete, after undelete) {

	if (!TriggerHelper.isTriggerDisabled(String.valueOf(EventMessage__c.SObjectType))) {
		(new EventMessageTriggerHandler()).dispatch();
	}
}