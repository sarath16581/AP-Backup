/**************************************************
Type:       Trigger for Billing Account Staging Object
Purpose:    After a Billing Account is loaded into the staging object,
            check if record exists in Billing Account. If yes, obtain 
            FK value to Account, otherwise set to 'Temporary Customer'.
            Move data across from staging to Billing Account and then
            delete record in staging.
History:
--------------------------------------------------
14.10.2011    Richard Enojas(Salesforce.com)    Created
17.10.2011    Richard Enojas(Salesforce.com)    Added checking for custom setting
**************************************************/
trigger BillingAccountStagingTrigger on Billing_Account_Staging__c (after insert) {
    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        if (trigger.isAfter && trigger.isInsert){
            List<Id> stgBAForTransfer = new List<Id>();
            List<String> stgBALegacyIds = new List<String>();
            
            for (Billing_Account_Staging__c bas : trigger.new){
                stgBAForTransfer.add(bas.id);
                stgBALegacyIds.add(BAS.legacy_id__c.replaceFirst('^0+(?!$)', ''));
            }
            
            if(!stgBAForTransfer.isEmpty())
                    BillingAccountStagingUtil.moveBillingAccounts(stgBAForTransfer, stgBALegacyIds); 
        }
    }
}