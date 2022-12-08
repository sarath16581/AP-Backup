/**
 * @author Harry Wang
 * @group Tests
 * @tag Batch
 * @domain Sales
 * @description Test class for SalesRecordSharingBatchable
 * @changelog
 * 2022-12-05 - Harry Wang - Created
 */
@IsTest
private class SalesRecordSharingBatchable_Test {
	@IsTest
	static void testBatch() {
		// =====================================
		// Data Preparation
		// =====================================
		String soql = 'SELECT Legal_Entity_Name_LookUp__c, Legal_Entity_Name_LookUp__r.SalesTeamType__c FROM APR__c WHERE Legal_Entity_Name_LookUp__c != NULL';
		List<APR__c> aprs = new List<APR__c>{new APR__c()};

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockSharingService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		SalesAPRSharingBatchable sharingBatchable = (SalesAPRSharingBatchable) MockUtility.mockUtility(SalesAPRSharingBatchable.class);
		ApplicationLogger mockLoggerService = (ApplicationLogger) MockUtility.mockUtility(ApplicationLogger.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSharingService.getSharingConfiguration((SObjectType)fflib_Match.anyObject())).thenAnswer(new AnswerMapping());
		MockUtility.Mocks.when(sharingBatchable.getQueryLocator()).thenReturn(Database.getQueryLocator(soql));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAPRSharingBatchable batch = new SalesAPRSharingBatchable();
		Database.QueryLocator ql = batch.start(null);
		batch.execute(null, aprs);
		batch.finish(null);

		Test.stopTest();

		System.assertNotEquals(null, ql, 'Expect a valid query locator to be returned');
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockSharingService, MockUtility.Mocks.times(0))).shareRecords((SObjectType)fflib_Match.anyObject(), (Map<Id, SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLoggerService, MockUtility.Mocks.times(1))).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLoggerService, MockUtility.Mocks.times(1))).logGenericMessage((List<String>)fflib_Match.anyList(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
	}

	public class AnswerMapping implements fflib_Answer {
		public Object answer(fflib_InvocationOnMock invocation) {
			SalesRecordSharingService.SalesSharingObjectMapping mapping = new SalesRecordSharingService.SalesSharingObjectMapping
					(APR__c.getSObjectType(), APR__c.Legal_Entity_Name_LookUp__c, 'Legal_Entity_Name_LookUp__r', 'reason');

			return mapping;
		}
	}

	private class MockException extends Exception{}
}