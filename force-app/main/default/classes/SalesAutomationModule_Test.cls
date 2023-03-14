/**
 * @description Test class for SalesAutomationModule
 * @author Harry Wang
 * @date 2022-11-08
 * @group Domain
 * @domain Sales
 * @changelog
 * 2022-11-08 - Harry Wang - Created
 * 2023-01-08 - Ranjeewa Silva - Refactored the tests and added more tests to cover insert scenario
*/
@IsTest
private class SalesAutomationModule_Test {

	/**
	*  Ensure Sales Team Type is populated based on Sales Team (Sales_Segment__c) on insert
	*/
	@IsTest
	public static void testEnsureSalesTeamTypePopulatedOnBeforeInsert() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].Sales_Segment__c = 'Holding Sales Team';
		accounts[1].Sales_Segment__c = 'InvalidSalesTeam';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAutomationModule.newInstance().onBeforeInsert(accounts, mockUow);

		Test.stopTest();

		System.assertEquals('Holding', accounts[0].SalesTeamType__c, 'Expected sales team type not populated');
		System.assertEquals(null, accounts[1].SalesTeamType__c, 'SalesTeamType__c should be set to null when Sales Team (Sales_Segment__c) value is unknown');

		// verify excluded records are logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

	}

	/**
	*  Ensure Sales Team Type is populated asynchronously when Sales Team (Sales_Segment__c) is updated
	*/
	@IsTest
	public static void testEnsureSalesTeamTypePopulationIsEnqueuedOnBeforeUpdate() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].Sales_Segment__c = 'Intermediaries';
		accounts[0].SalesTeamType__c = 'Intermediary';
		accounts[1].Sales_Segment__c = 'Intermediaries';
		accounts[1].SalesTeamType__c = 'Intermediary';

		List<Account> updatedAccounts = accounts.deepClone(true);
		updatedAccounts[0].Sales_Segment__c = 'InvalidSalesTeam';
		updatedAccounts[1].Sales_Segment__c = 'Holding Sales Team';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		ApplicationDatabase mockDatabase = (ApplicationDatabase) MockUtility.mockUtility(ApplicationDatabase.class);



		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAutomationModule.newInstance().onBeforeUpdate(updatedAccounts, new Map<Id, SObject>(accounts), mockUow);

		Test.stopTest();

		// verify SalesTeamType__c updates are enqueued for async processing as expected
		fflib_ArgumentCaptor queueableInstanceCapture = fflib_ArgumentCaptor.forClass(SalesAutomationModule.AsyncUpdateSalesTeamTypeQueueable.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).enqueueJob(queueableInstanceCapture.capture());
		SalesAutomationModule.AsyncUpdateSalesTeamTypeQueueable asyncSalesTeamTypeUpdateQueueable = (SalesAutomationModule.AsyncUpdateSalesTeamTypeQueueable) queueableInstanceCapture.getValue();

		System.assert(asyncSalesTeamTypeUpdateQueueable != null, 'Expected to enqueue a valid queueable instance; but got null');
		System.assertEquals(2, asyncSalesTeamTypeUpdateQueueable.accountSalesTeamTypeUpdates.size(), 'Expected asynchronously update SalesTeamType__c on 2 accounts.');
		System.assertEquals(null, asyncSalesTeamTypeUpdateQueueable.accountSalesTeamTypeUpdates.get(updatedAccounts[0].Id), 'SalesTeamType__c should be set to null when Sales Team (Sales_Segment__c) value is unknown');
		System.assertEquals('Holding', asyncSalesTeamTypeUpdateQueueable.accountSalesTeamTypeUpdates.get(updatedAccounts[1].Id), 'Expected sales team type not populated');

		// verify excluded records are logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
	}

	/**
	 * Ensure Sales Team Type is populated in same transaction when Sales Team (Sales_Segment__c) is updated by an async process.
	 */
	@IsTest
	static void testEnsureSalesTeamTypePopulatedWhenSalesTeamUpdatedInAsyncContext() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].Sales_Segment__c = 'Intermediaries';
		accounts[0].SalesTeamType__c = 'Intermediary';
		accounts[1].Sales_Segment__c = 'Intermediaries';
		accounts[1].SalesTeamType__c = 'Intermediary';

		List<Account> updatedAccounts = accounts.deepClone(true);
		updatedAccounts[0].Sales_Segment__c = 'InvalidSalesTeam';
		updatedAccounts[1].Sales_Segment__c = 'Holding Sales Team';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		ApplicationDatabase mockDatabase = (ApplicationDatabase) MockUtility.mockUtility(ApplicationDatabase.class);

		// simulate async context from the test
		SalesAutomationModule.mockAsyncContextInTests = true;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SalesAutomationModule.newInstance().onBeforeUpdate(updatedAccounts, new Map<Id, SObject>(accounts), mockUow);
		Test.stopTest();

		// verify records are updated
		System.assertEquals(null, updatedAccounts[0].SalesTeamType__c, 'SalesTeamType__c should be set to null when Sales Team (Sales_Segment__c) value is unknown');
		System.assertEquals('Holding', updatedAccounts[1].SalesTeamType__c, 'Expected sales team type not populated');

		// verify excluded records are logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// verify no queueable jobs are enqueued
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 0)).enqueueJob(fflib_Match.anyObject());
	}

	/**
	 * Ensure SalesTeamType__c updated as expected on the accounts passed in by the queueable job
	 */
	@IsTest
	static void testSalesTeamTypeUpdateQueueable() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(3, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockApplicationDatabase = (ApplicationDatabase) MockUtility.mockUtility(ApplicationDatabase.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockApplicationDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false))).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAutomationModule.AsyncUpdateSalesTeamTypeQueueable queueable = new SalesAutomationModule.AsyncUpdateSalesTeamTypeQueueable(new Map<Id, String>{
				parentAccounts[0].Id => 'Direct',
				parentAccounts[1].Id => 'Intermediary',
				parentAccounts[2].Id => 'Holding'
		});
		queueable.execute(null);

		Test.stopTest();

		// verify accounts passed in to for update
		fflib_ArgumentCaptor accountCaptor = fflib_ArgumentCaptor.forClass(List<Account>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockApplicationDatabase, 1)).dmlUpdate((List<Account>)accountCaptor.capture(), fflib_Match.eqBoolean(false));
		Map<Id, Account> accountsCaptured = new Map<Id, Account>((List<Account>) accountCaptor.getValue());
		System.assertEquals(3, accountsCaptured.size(), 'Expected accounts  not passed in for update');
		System.assertEquals('Direct', accountsCaptured.get(parentAccounts[0].Id).SalesTeamType__c, 'Expected to update the account with SalesTeamType__c passed in');
		System.assertEquals('Intermediary', accountsCaptured.get(parentAccounts[1].Id).SalesTeamType__c, 'Expected to update the account with SalesTeamType__c passed in');
		System.assertEquals('Holding', accountsCaptured.get(parentAccounts[2].Id).SalesTeamType__c, 'Expected to update the account with SalesTeamType__c passed in');
	}
}