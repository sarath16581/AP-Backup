/**
 * @description       : Case Investigation Trigger
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * @Test CaseInvestigationTrigger_Test
 **/
trigger CaseInvestigationTrigger on CaseInvestigation__c(before insert,before update,before delete,after insert,after update,after delete,after undelete){

	if (!TriggerHelper.isTriggerDisabled(String.valueOf(CaseInvestigation__c.SObjectType))) {
		CaseInvestigationDomainTriggerHandler.newInstance().dispatch();
	}
}