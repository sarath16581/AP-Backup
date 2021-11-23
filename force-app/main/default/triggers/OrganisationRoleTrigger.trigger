/**
 * @description Trigger that populates Legacy Id after insert of organisation role.
 * @author SH
 * @date 17.May.2012
 */

trigger OrganisationRoleTrigger on Organisation_Role__c (after insert) {
	if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
    	if (trigger.isAfter && trigger.isInsert){
    		RoleTriggerManager.PopulateLegacyIdOnAccount(trigger.new);	
    	}
	}
}