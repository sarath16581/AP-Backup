/**
  * @author       : Ashapriya Gadi
  * @date         : 15/12/2021
  * @description  : Trigger on CampaignContactAssignment__c Object to call the Handler class to perform necessary action
  */
trigger CampaignContactAssignmentTrigger on CampaignContactAssignment__c (before insert,before update,before delete,
                                    after insert,after update,after delete,after undelete) {
	if(!TriggerHelper.isTriggerDisabled(String.valueOf(CampaignContactAssignment__c.SObjectType))){     // verify if triggers are disabled
		// New domain based trigger dispatch
		(new CampaignContactAssignmentTriggerHandler()).dispatch();
	}
}