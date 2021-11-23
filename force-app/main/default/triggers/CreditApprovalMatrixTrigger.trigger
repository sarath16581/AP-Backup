/**
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @domain Core
 * @description Trigger on CreditApprovalMatrix__c object. Dispatch to domain base trigger handler to handle all trigger events.
 * @changelog
 * 2021-05-13 - Ranjeewa Silva - Created
 */

trigger CreditApprovalMatrixTrigger on CreditApprovalMatrix__c (before insert, before update, before delete,
        after insert, after update, after delete, after undelete) {

    // check if trigger is enabled
    if(!TriggerHelper.isTriggerDisabled(String.valueOf(CreditApprovalMatrix__c.sObjectType))) {
        // domain base trigger dispatch
        (new CreditApprovalMatrixTriggerHandler()).dispatch();
    }
}