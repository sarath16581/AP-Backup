/**
 * @author Harry Wang
 * @group Tests
 * @tag Batch
 * @domain Sales
 * @description Test class for SalesSAPContractSharingBatchable
 * @changelog
 * 2022-12-05 - Harry Wang - Created
 */
@IsTest
private class SalesSAPContractSharingBatchable_Test {
    /**
	 * Test:
	 *  Ensures that the concrete batch is working as expected
	 */
    @IsTest
    static void testSAPContractSharingBatch() {
        // =====================================
        // Data Preparation
        // =====================================
        String soql = 'SELECT Organisation__c, Organisation__r.SalesTeamType__c FROM APT_SAP_Contracts__c WHERE Organisation__c != NULL';

        // =====================================
        // Stubbing
        // =====================================
        SAPContractsSelector mockSelector = (SAPContractsSelector) MockUtility.mockSelector(SAPContractsSelector.class);
        SalesRecordSharingService mockSharingService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByAccountRelationshipQueryLocator((set<Object>) fflib_Match.anyObject())).thenReturn(Database.getQueryLocator(soql));
        MockUtility.Mocks.when(mockSharingService.getSharingConfiguration((SObjectType)fflib_Match.anyObject())).thenAnswer(new AnswerMapping());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        SalesSAPContractSharingBatchable batchable = new SalesSAPContractSharingBatchable();
        Database.QueryLocator queryLocator = batchable.getQueryLocator();
        Test.stopTest();

        System.assertEquals(soql, queryLocator.getQuery(), 'Expected SOQL returned');
    }

    public class AnswerMapping implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            SalesRecordSharingService.SalesSharingObjectMapping mapping = new SalesRecordSharingService.SalesSharingObjectMapping
                    (APT_SAP_Contracts__c.getSObjectType(), APT_SAP_Contracts__c.Organisation__c, 'Organisation__r', 'reason');

            return mapping;
        }
    }
}