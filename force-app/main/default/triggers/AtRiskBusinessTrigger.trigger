/***
 * @description Trigger class for At_Risk_Business
 * @author Pratyush Chalasani
 * @group Trigger
 * @tag trigger
 * @domain AtRiskBusiness
 * @changelog
 * 2023-04-21 - Pratyush Chalasani - Created
 */
trigger AtRiskBusinessTrigger on At_Risk_Business__c (before insert, before update,after insert,after update, after delete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(At_Risk_Business__c.SObjectType))) {
		AtRiskBusinessTriggerHandler.newInstance().dispatch();
	}
}