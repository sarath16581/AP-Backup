/**
 * @author Harry Wang
 * @date 2022-06-21
 * @group Trigger
 * @domain ICPS
 * @description Trigger on ICPS__c Object to call the Handler class to perform necessary action
 * @changelog
 * 2022-06-21 - Harry Wang - Created
 */
trigger ICPSTrigger on ICPS__c (before insert, before update, before delete,
		after insert, after update, after delete, after undelete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(ICPS__c.SObjectType))){     // verify if triggers are disabled
		// New domain based trigger dispatch
		(new ICPSTriggerHandler()).dispatch();
	}
}