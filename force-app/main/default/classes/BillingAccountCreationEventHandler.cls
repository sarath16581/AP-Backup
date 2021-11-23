/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description This is the Handler class for BillingAccountCreationEvent__e Trigger .Execute Method is called
 *              from the trigger .
 * @changelog
 * 2020-11-18 - shashwat.nath@auspost.com.au - Created
*/
public with sharing class BillingAccountCreationEventHandler {
    // Checks for the trigger Event and calls the respective handler method
    public static void execute() {
        if(Trigger.isAfter) {
            afterHandler();        
        }
    }
    //Method to handle after Trigger Events
    private static void afterHandler() {
        // Check for type of operation
        if (Trigger.isInsert) {
            BillingAccountCreationEventTriggerHelper.createBillingAccount(Trigger.New);
        }
    }
}