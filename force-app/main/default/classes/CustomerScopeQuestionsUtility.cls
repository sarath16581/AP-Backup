/**************************************************
Type:           Utility Class for Customer Scoping Questionnaire (CSQ)
                related methods
History:
--------------------------------------------------
01.05.2019      RSolomon    Created
**************************************************/
public without sharing class CustomerScopeQuestionsUtility {

    /*------------------------------------------------------------
        Author:         RSolomon
        Description:    - Unlock CustomerScopeQuestionnaire record when Pick-up Location approval status is set to Rejected.
                        - Set the CustomerScopeQuestionnaire record status back to 'Draft'
                        - Method is called via Process Builder - CSQ Unlock Approval Record
        Inputs:         CustomerScopeQuestionnaire ID
        Returns:        None
        History:
        01.05.2019      Created
    ------------------------------------------------------------*/

    @InvocableMethod(label = 'Unlock CSQ Approval record'
        description = 'Unlocks the CSQ record related to the child Pick up Location record.')
    public static void unlockCSQApprovalRec(List<Id> LocationIdList) {

        System.debug('CSQ ID passed via the CSQ Approval Unlock Process Flow: ' + LocationIdList);

        // Retrieve details of the record passed, to evaluate and update when necessary
        List<Customer_Scoping_Questionnaire__c> CSQList = [SELECT Id, CSQ_Status__c FROM Customer_Scoping_Questionnaire__c WHERE Id IN: LocationIdList];
        System.debug('CSQ details: ' + CSQList);

        List<Customer_Scoping_Questionnaire__c> unlockCSQList = new List <Customer_Scoping_Questionnaire__c>();
        
        // Iterate through the list, and after confirming that the record is still locked, mark the record for unlocking
        for (Customer_Scoping_Questionnaire__c c: CSQList) {
            if (Approval.isLocked(c.id)) {
                unlockCSQList.add(c);
                // When the CSQ Approval record is unlocked, ensure the status of that record is reset to Draft
                if ((c.CSQ_Status__c.equals('Approved_by_SM')) || (c.CSQ_Status__c.equals('Pending National Operations Manager Approval'))) {
                    System.debug('Prior CSQ Status value: ' + c.CSQ_Status__c);
                    c.CSQ_Status__c = 'Draft';
                }
            }
        }
        
        // Unlock CSQ records that matched the entry criteria of the Process flow and have been marked for unlocking
        if (!unlockCSQList.isEmpty()) {
            
            List <Approval.UnlockResult> recListToUnlock = Approval.unlock(unlockCSQList, true);

            // Iterate through the returned results and output details around success/failure
            for (Approval.UnlockResult unlockedIDs: recListToUnlock) {
                if (unlockedIDs.isSuccess()) {
                    // Output ID's of the records that were successfully unlocked
                    System.debug('Successfully unlocked CSQ Record with ID: ' + unlockedIDs.getId());
                } else {
                    // Output errors related to when the record couldn't be unlocked               
                    for (Database.Error err: unlockedIDs.getErrors()) {
                        System.debug('The following error occurred:');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }

            // This is to update the CSQ Status of the Unlocked records back to Draft
            Update CSQList;
        }
    }
}