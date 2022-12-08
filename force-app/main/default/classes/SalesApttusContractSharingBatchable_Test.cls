/**
 * @author Harry Wang
 * @group Tests
 * @tag Batch
 * @domain Sales
 * @description Test class for SalesApttusContractSharingBatchable
 * @changelog
 * 2022-12-05 - Harry Wang - Created
 */
@IsTest
private class SalesApttusContractSharingBatchable_Test {
	/**
	 * Test:
	 *  Ensures that the concrete batch is working as expected
	 */
	@IsTest
	static void testContractSharingBatch() {
		// =====================================
		// Data Preparation
		// =====================================
		String soql = 'SELECT Id, Apttus__Account__c, Apttus__Account__r.SalesTeamType__c FROM Apttus__APTS_Agreement__c WHERE Apttus__Account__c != NULL';

		// =====================================
		// Stubbing
		// =====================================
		ApttusContractsSelector mockSelector = (ApttusContractsSelector) MockUtility.mockSelector(ApttusContractsSelector.class);
		SalesRecordSharingService mockSharingService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByAccountRelationshipQueryLocator((set<Object>) fflib_Match.anyObject())).thenReturn(Database.getQueryLocator(soql));
		MockUtility.Mocks.when(mockSharingService.getSharingConfiguration((SObjectType)fflib_Match.anyObject())).thenAnswer(new AnswerMapping());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SalesApttusContractSharingBatchable batchable = new SalesApttusContractSharingBatchable();
		Database.QueryLocator queryLocator = batchable.getQueryLocator();
		Test.stopTest();

		System.assertEquals(soql, queryLocator.getQuery(), 'Expected SOQL returned');
	}

	public class AnswerMapping implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			SalesRecordSharingService.SalesSharingObjectMapping mapping = new SalesRecordSharingService.SalesSharingObjectMapping
					(Apttus__APTS_Agreement__c.getSObjectType(), Apttus__APTS_Agreement__c.Apttus__Account__c, 'Apttus__Account__r', 'reason');

			return mapping;
		}
	}
}