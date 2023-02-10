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

	/**
	 * Test to ensure start method calls the selector with appropriate parameters.
	 */
	@IsTest
	static void testBatchJobStart() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);
		APRsSelector mockSelector = (APRsSelector) MockUtility.mockSelector(APRsSelector.class);
		Database.QueryLocator mockQueryLocator = Database.getQueryLocator('Select Id from APR__c');

		SalesRecordSharingService.SalesSharingObjectMapping shareObjectMapping = new SalesRecordSharingService.SalesSharingObjectMapping(APR__c.SObjectType, APR__c.Legal_Entity_Name_LookUp__c, 'Legal_Entity_Name_LookUp__r', 'SalesTeamSharing__c');

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eq(APR__c.SObjectType))).thenReturn(shareObjectMapping);
		MockUtility.Mocks.when(mockSelector.selectByAccountOrderByAccountIdQueryLocator((Set<Id>) fflib_Match.anyObject(), (Set<Object>)fflib_Match.eq(new Set<Object>{APRsSelector.Options.WITH_ORGANISATION}))).thenReturn(mockQueryLocator);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Database.QueryLocator queryLocator = new SalesAPRSharingBatchable().start(null);

		Test.stopTest();

		// verify that the batch class is simply returning the query locator returned from the selector.
		System.assertEquals(mockQueryLocator, queryLocator, 'Batch class should simply return the query locator from selector');

		// verify field overrides are set on the selector
		fflib_ArgumentCaptor fieldOverridesCapture = fflib_ArgumentCaptor.forClass(Map<SObjectType, Set<SObjectField>>.class);
		((APRsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).setFieldOverrides((Map<SObjectType, Set<SObjectField>>)fieldOverridesCapture.capture());

		Map<SObjectType, Set<SObjectField>> fieldOverridesCaptured = (Map<SObjectType, Set<SObjectField>>) fieldOverridesCapture.getValue();
		System.assert(fieldOverridesCaptured != null, 'Expected to pass valid field overrides to selector method, but not supplied.');
		System.assertEquals(2, fieldOverridesCaptured.size(), 'Expected to pass field overrides for APR__c and Account.');
		System.assert(fieldOverridesCaptured.get(APR__c.SObjectType).contains(APR__c.Legal_Entity_Name_LookUp__c), 'Account lookup must be specified as a field override');
		System.assert(fieldOverridesCaptured.get(Account.SObjectType).contains(Account.SalesTeamType__c), 'SalesTeamType__c on Account must be specified as a field override');

		// verify select method is called with appropriate parameters
		fflib_ArgumentCaptor accountIdsCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((APRsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByAccountOrderByAccountIdQueryLocator((Set<Id>)accountIdsCapture.capture(), (Set<Object>)fflib_Match.anyObject());

		Set<Id> parentAccountIdsCaptured = (Set<Id>) accountIdsCapture.getValue();
		System.assertEquals(0, parentAccountIdsCaptured.size(), 'Expected to pass an empty account Ids set in to the selector when account ids are not specified on batch.');
	}

	/**
	 * Test to ensure start method throws any exceptions it encounters.
	 */
	@IsTest
	static void testBatchJobStartWhenSelectorThrowsException() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getSharingConfiguration((SObjectType)fflib_Match.eq(APR__c.SObjectType))).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			new SalesAPRSharingBatchable().start(null);
			System.assert(false, 'Expected to throw an exception when an exception is thrown from service');
		} catch (Exception ex) {
			// expected
		}

		Test.stopTest();
	}

	/**
	 * Test to ensure execute method calls the service with appropriate parameters.
	 */
	@IsTest
	static void testBatchJobExecute() {
		// =====================================
		// Data Preparation
		// =====================================
		List<APR__c> aprs = ApplicationTestDataFactory.getAPRs(3, null, null, true);

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = (SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class);

		//MockUtility.Mocks.startStubbing();
		//MockUtility.Mocks.when(mockService.shareRecords((SObjectType)fflib_Match.eq(APR__c.SObjectType), (Map<Id, SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(shareObjectMapping);
		//MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAPRSharingBatchable batch = new SalesAPRSharingBatchable();
		batch.execute(null, aprs);

		Test.stopTest();

		fflib_ArgumentCaptor shareRecordsCapture = fflib_ArgumentCaptor.forClass(Map<Id, SObject>.class);
		((SalesRecordSharingService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).shareRecords((SObjectType)fflib_Match.eq(APR__c.SObjectType),(Map<Id, SObject>) shareRecordsCapture.capture(), fflib_Match.eqBoolean(true));
		Map<Id, SObject> shareRecordsCaptured = (Map<Id, SObject>)shareRecordsCapture.getValue();

		System.assertEquals(3, shareRecordsCaptured.size(),'records should be submitted for sharing');
		System.assertEquals(3, batch.totalRecordsCount,'processed record count must be updated after processing each batch');
	}

	/**
	 * Test to ensure finish method logs the number of records processed.
	 */
	@IsTest
	static void testBatchJobFinish() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAPRSharingBatchable batch = new SalesAPRSharingBatchable();
		batch.totalRecordsCount = 100;
		batch.finish(null);

		Test.stopTest();

		// verify the processing summary is logged
		//((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logGenericMessage((List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (String)fflib_Match.anyObject(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
	}

	private class MockException extends Exception{}
}