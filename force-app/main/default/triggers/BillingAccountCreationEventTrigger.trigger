/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Trigger for BillingAccountCreationEvent__e . These platform events are published by Camunda
 *              as part of SF-SAP Integration for creation of billing accounts in Salesforce
 * @changelog
 * 2020-11-18 - shashwat.nath@auspost.com.au - Created
*/

trigger BillingAccountCreationEventTrigger on BillingAccountCreationEvent__e (after insert ) {
    // Calling the exceute method in the handler
    BillingAccountCreationEventHandler.execute();
}