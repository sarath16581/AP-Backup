/* @author Mav3rik
 * @date 2020-10-27
 * @group Deal_Support_Request__c
 * @tag Deal_Support_Request__c
 * @domain Core
 * @description Test class for LPODealSupportRequestController
 * @changelog
 * 2020-10-27 - Mav3rik - Created
 */
@IsTest
public class LPODealSupportRequestController_Test {
    
    /**
     * Test when retrieving the Opportunity record
     */
    @IsTest
    static void testGetOpportunityPositive() {
        Account givenAccount = new Account();
        givenAccount.Name = 'Test Account';
        insert givenAccount;

        Opportunity givenOpportunity = new Opportunity();
        givenOpportunity.Name = 'Test Opportunity';
        givenOpportunity.AccountId = givenAccount.Id;
        givenOpportunity.StageName = 'New';
        givenOpportunity.CloseDate = Date.today() + 1;
        insert givenOpportunity;

        Test.startTest();
        Opportunity actualOpportunity = LPODealSupportRequestController.getOpportunity(givenOpportunity.Id);
        Test.stopTest();

        System.assertEquals(givenOpportunity.Id, actualOpportunity.Id, 'Matches the Opportunity ID');
        System.assertEquals(givenOpportunity.Name, actualOpportunity.Name, 'Matches the Opportunity Name');
        System.assertEquals(givenAccount.Name, actualOpportunity.Account.Name, 'Matches the Account Name');
    }

    /**
     * Test when the getOpportunity input is null
     */
    @IsTest
    static void testGetOpportunityNull() {
        Test.startTest();
        Opportunity actualOpportunity = LPODealSupportRequestController.getOpportunity(null);
        Test.stopTest();

        System.assert(actualOpportunity == null, 'No Opportunity should be found');
    }

    /**
     * Test when the getOpportunity input is empty
     */
    @IsTest
    static void testGetOpportunityEmpty() {
        Test.startTest();
        Opportunity actualOpportunity = LPODealSupportRequestController.getOpportunity('');
        Test.stopTest();

        System.assert(actualOpportunity == null, 'No Opportunity should be found');
    }

    /**
     * Test when all validations passed and the Deal Support Request record is inserted
     */
    @IsTest
    static void testSaveRecordPositive() {
        Deal_Support_Request__c givenRecord = new Deal_Support_Request__c();
        givenRecord.Stage__c = 'New';

        Test.startTest();
        String recordId = LPODealSupportRequestController.saveRecord(givenRecord);
        Test.stopTest();

        System.assert(recordId != null, 'The record should be inserted and returns a Record ID');
    }

    /**
     * Test when there is an exception and the Deal Support Request record is not inserted
     */
    @IsTest
    static void testSaveLeadNegative() {
        Deal_Support_Request__c givenRecord = new Deal_Support_Request__c();
        givenRecord.Stage__c = '===================================================================================================Some string which is longer than 255 characters================================================================================================================';

        Test.startTest();
        Boolean isExceptionFound = false;
        try {
            LPODealSupportRequestController.saveRecord(givenRecord);
        } catch(Exception e) {
            isExceptionFound = true;
        }
        Test.stopTest();

        System.assert(isExceptionFound, 'There should be an exception');
    }

    /**
     * Test when retrieving work type picklist values
     */
    @IsTest
    static void testGetWorkTypeValuesPositive() {
        String givenWorkTypes = 'New Account,Existing Account';
        LPO_Work_Type__c setting = new LPO_Work_Type__c();
        setting.Profile_Id__c = UserInfo.getProfileId();
        setting.LPO_Work_Type_Values__c = givenWorkTypes;
        insert setting;

        Test.startTest();
        String actualWorkTypes = LPODealSupportRequestController.getWorkTypeValues();
        Test.stopTest();

        System.assertEquals(givenWorkTypes, actualWorkTypes, 'It should match the value of work types');
    }

    /**
     * Test when retrieving work type picklist values but the profile is not valid
     */
    @IsTest
    static void testGetWorkTypeValuesNegative() {
        String givenWorkTypes = 'New Account,Existing Account';
        LPO_Work_Type__c setting = new LPO_Work_Type__c();
        setting.Profile_Id__c = 'Invalid';
        setting.LPO_Work_Type_Values__c = givenWorkTypes;
        insert setting;
        
        Test.startTest();
        String actualWorkTypes = LPODealSupportRequestController.getWorkTypeValues();
        Test.stopTest();

        System.assert(actualWorkTypes == null, 'It should have no work types');
    }
}