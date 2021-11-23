/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Credit_ApprovalTrigger on Credit_Approval__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
	//AdjustmentTriggerHandler.adjRecursiveFlag = true;

    dlrs.RollupService.triggerHandler();
}