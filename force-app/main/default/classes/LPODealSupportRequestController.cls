/* @author Mav3rik
 * @date 2020-10-27
 * @group Deal_Support_Request__c
 * @tag Deal_Support_Request__c
 * @domain Core
 * @description Controller class for lpoCreateNewDealSupportRequest lwc component
 * @changelog
 * 2020-10-27 - Mav3rik - Created
 */
public with sharing class LPODealSupportRequestController {

    /**
     * @description Get the Opportunity record
     *
     * ## recordId (Id): recordId - Opportunity record Id
     * @@ Return Opportunity: Returns the Opportunity record
     */
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunity(String recordId) {
        if (recordId == null || recordId == '') {
            return null;
        }
        return [SELECT Id, Name, Account.Id, Account.Name FROM Opportunity WHERE Id =: recordId LIMIT 1];
    }

    /**
     * @description Inserts a new Deal_Support_Request__c
     *
     * ## record (Deal_Support_Request__c): record - The record to be inserts
     * @@ Return String: Returns the Deal_Support_Request__c Record Id
     */
    @AuraEnabled
    public static String saveRecord(Deal_Support_Request__c record){
        try {
            List<Database.SaveResult> saveResult = ApplicationDatabase.getInstance().dmlInsert(new List<Deal_Support_Request__c>{record});
            return saveResult[0].getId();
        } catch(Exception e) {
            throw e;
        }
    }

    /**
     * @description Query the custom setting LPO_Work_Type__c for work type values
     *
     * @@ Return String: Returns a string of work type values
     */
    @AuraEnabled(cacheable=true)
    public static String getWorkTypeValues() {
        try {
            LPO_Work_Type__c workType = [SELECT LPO_Work_Type_Values__c FROM LPO_Work_Type__c WHERE Profile_ID__c =: UserInfo.getProfileId() LIMIT 1];
            return workType.LPO_Work_Type_Values__c;
        } catch(Exception e) {
            return null;
        }
    }
}