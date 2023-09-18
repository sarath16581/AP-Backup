/***
 * @description Trigger class for CreditSuspect__c
 * @author George Nguyen
 * @group CreditSuspect__c
 * @tag CreditSuspect__c
 * @domain CreditSuspect__c
 **/
trigger CreditSuspectTrigger on CreditSuspect__c (before insert, before update,after insert,after update, after delete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(CreditSuspect__c.SObjectType))) {
		CreditSuspectTriggerHandler.newInstance().dispatch();
	}
}