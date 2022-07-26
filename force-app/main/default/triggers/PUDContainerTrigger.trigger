/**
 * @author Dattaraj Deshmukh
 * @date 2022-06-23
 * @tag Container Types
 * @description Trigger for PUD_Container__c object
 * @changelog
 * 2022-06-23 - Dattaraj Deshmukh - Created
 */

trigger PUDContainerTrigger on PUD_Container__c (after update, after insert, before insert, after delete) {
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(PUD_Container__c.SObjectType))) {
		(new PUDContainerTriggerHandler()).dispatch();
	}
    
}