/**
 * @author Harry Wang
 * @date 2022-06-30
 * @group Trigger
 * @domain ICPS
 * @description Trigger on ICPSArticle__c Object to call the Handler class to perform necessary action
 * @changelog
 * 2022-06-30 - Harry Wang - Created
 */
trigger ICPSArticleTrigger on ICPSArticle__c (before insert, before update, before delete,
		after insert, after update, after delete, after undelete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(ICPSArticle__c.SObjectType))){     // verify if triggers are disabled
		// New domain based trigger dispatch
		ICPSArticleTriggerHandler.getInstance().dispatch();
	}
}