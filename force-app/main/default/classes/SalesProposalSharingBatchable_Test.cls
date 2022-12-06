/**
 * @author Harry Wang
 * @group Tests
 * @tag Batch
 * @domain Sales
 * @description Test class for SalesProposalSharingBatchable
 * @changelog
 * 2022-12-05 - Harry Wang - Created
 */
@IsTest
private class SalesProposalSharingBatchable_Test {
    /**
	 * Test:
	 *  Ensures that the concrete batch is working as expected
	 */
    @IsTest
    static void testProposalSharingBatch() {
        // =====================================
        // Data Preparation
        // =====================================
        String soql = 'SELECT Apttus_Proposal__Account__c, Apttus_Proposal__Account__r.SalesTeamType__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Account__c != NULL';

        // =====================================
        // Stubbing
        // =====================================
        APT_ProposalObjectsSelector mockSelector = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
        SalesRecordSharingService mockSharingService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByAccountRelationshipQueryLocator((set<Object>) fflib_Match.anyObject())).thenReturn(Database.getQueryLocator(soql));
        MockUtility.Mocks.when(mockSharingService.getSharingConfiguration((SObjectType)fflib_Match.anyObject())).thenAnswer(new AnswerMapping());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        SalesProposalSharingBatchable batchable = new SalesProposalSharingBatchable();
        Database.QueryLocator queryLocator = batchable.getQueryLocator();
        Test.stopTest();

        System.assertEquals(soql, queryLocator.getQuery(), 'Expected SOQL returned');
    }

    public class AnswerMapping implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            SalesRecordSharingService.SalesSharingObjectMapping mapping = new SalesRecordSharingService.SalesSharingObjectMapping
                    (Apttus_Proposal__Proposal__c.getSObjectType(), Apttus_Proposal__Proposal__c.Apttus_Proposal__Account__c, 'Apttus_Proposal__Account__r', 'reason');

            return mapping;
        }
    }
}