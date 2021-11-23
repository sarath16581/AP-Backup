/**
 * @domain Core
 * @description Trigger on Credit_Approval__c object. Dispatch to domain base trigger handler to handle all trigger events.
 * @changelog
 * 2017-02-01 - Bharat P - Initial Version - Calls CreditApprovalTriggerHandler for performing necessary actions.
 * 2021-06-02 - Ranjeewa Silva - Refactored to dispatch trigger events to domain base trigger handler.
 */
trigger Credit_Approval_Trigger on Credit_Approval__c (before insert,before update,before delete,
                                                        after insert,after update,after delete,after undelete){

    // check if trigger is enabled
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(Credit_Approval__c.sObjectType))) {
        // dispatch
        (new CreditApprovalTriggerHandler()).dispatch();
    }
}