/**
 * @author SteveL
 * @date 2023-01-30
 * @description Trigger on Customer_Scoping_Questionnaire__c (CSQ) object. Dispatch to module based trigger handler to handle all trigger events.
 * @changelog
 */

trigger CSQTrigger on Customer_Scoping_Questionnaire__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(Customer_Scoping_Questionnaire__c.SObjectType))) {
		(new BAMApplicationAutomationTriggerHandler()).dispatch();
	}
}