/**
 * @author Harry Wang
 * @group Tests
 * @tag Batch
 * @domain Sales
 * @description Test class for SalesAPRSharingBatchable
 * @changelog
 * 2022-12-05 - Harry Wang - Created
 */
@IsTest
private class SalesAPRSharingBatchable_Test {
    /**
	 * Test:
	 *  Ensures that the concrete batch is working as expected
	 */
	@IsTest
    static void testAPRSharingBatch() {
        // =====================================
        // Data Preparation
        // =====================================
        String soql = 'SELECT Legal_Entity_Name_LookUp__c, Legal_Entity_Name_LookUp__r.SalesTeamType__c FROM APR__c WHERE Legal_Entity_Name_LookUp__c != NULL';

        // =====================================
        // Stubbing
        // =====================================
        APRsSelector mockSelector = (APRsSelector) MockUtility.mockSelector(APRsSelector.class);
        SalesRecordSharingService mockSharingService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByAccountRelationshipQueryLocator((set<Object>) fflib_Match.anyObject())).thenReturn(Database.getQueryLocator(soql));
        MockUtility.Mocks.when(mockSharingService.getSharingConfiguration((SObjectType)fflib_Match.anyObject())).thenAnswer(new AnswerMapping());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        SalesAPRSharingBatchable batchable = new SalesAPRSharingBatchable();
        Database.QueryLocator queryLocator = batchable.getQueryLocator();
        Test.stopTest();

        System.assertEquals(soql, queryLocator.getQuery(), 'Expected SOQL returned');
	}

    public class AnswerMapping implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            SalesRecordSharingService.SalesSharingObjectMapping mapping = new SalesRecordSharingService.SalesSharingObjectMapping
                    (APR__c.getSObjectType(), APR__c.Legal_Entity_Name_LookUp__c, 'Legal_Entity_Name_LookUp__r', 'reason');

            return mapping;
        }
    }
}