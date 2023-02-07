/**
 * @description
 * Test class for SalesAccountChildSObjectSharingModule
 * @author Ranjeewa Silva
 * @group Tests
 * @domain Sales
 * @changelog
 * 2023-01-12 - Ranjeewa Silva - Created
 */
@IsTest
private class SalesAccChildSObjectSharingModule_Test {

	/**
	 * Test to ensure sharing recalculation for child objects only triggered for accounts moving Sales Team Types.
	 */
	@IsTest
	static void testAccountChildRecordSharingRecalculatedOnAccountsMovingSalesTeamTypes() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(2, true);
		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;
		parentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;

		List<Account> updatedParentAccounts = new List<Account>{parentAccounts[0].clone(true), parentAccounts[1].clone(true)};
		updatedParentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		updatedParentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;


		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = ((SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		((SalesRecordSharingService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAccountChildSObjectSharingModule module = SalesAccountChildSObjectSharingModule.newInstance();
		module.onAfterUpdate(updatedParentAccounts, new Map<Id, Account>(parentAccounts), mockUow);

		Test.stopTest();

		// verify new share records registered with unit of work are as expected
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockService, 1)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)sobjectCapture.capture());
		Set<Id> enqueuedAccountIds = (Set<Id>) sobjectCapture.getValue();

		System.assertEquals(1, enqueuedAccountIds.size(), 'Sharing recalculation required for child records only when sales team type is changing on parent accounts');
		System.assertEquals(updatedParentAccounts[0].Id, enqueuedAccountIds.iterator().next(), 'Sharing recalculation required for child records only when sales team type is changing on parent accounts');
	}

	/**
	 * Test to ensure sharing recalculation for child objects is done in the same transaction when already in an async
	 * context.
	 */
	@IsTest
	static void testAccountChildRecordSharingRecalculationWhenSalesTeamTypesUpdatedInAsyncContext() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(1, true);
		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;

		List<Account> updatedParentAccounts = new List<Account>{parentAccounts[0].clone(true)};
		updatedParentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;

		// setup the results returned by the service
		List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> recalculationResults = new List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult>();
		// parentAccounts[0] is processed fully
		recalculationResults.add(new SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult(parentAccounts[0].Id, parentAccounts[0].SalesTeamType__c, true, false, new Map<SObjectType, Integer>()));

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = ((SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		// set variable for mocking async context from the test
		SalesAccountChildSObjectSharingModule.mockAsyncContextInTests = true;

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.recalculateChildRecordSharing((Set<Id>)fflib_Match.anyObject(), (ApplicationUnitOfWork) fflib_Match.anyObject())).thenReturn(recalculationResults);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAccountChildSObjectSharingModule module = SalesAccountChildSObjectSharingModule.newInstance();
		module.onAfterUpdate(updatedParentAccounts, new Map<Id, Account>(parentAccounts), mockUow);
		Test.stopTest();

		// verify new share records registered with unit of work are as expected
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockService, 1)).recalculateChildRecordSharing((Set<Id>)sobjectCapture.capture(), (ApplicationUnitOfWork) fflib_Match.anyObject());
		Set<Id> accountIds = (Set<Id>) sobjectCapture.getValue();

		System.assertEquals(1, accountIds.size(), 'Sharing recalculation required for child records only when sales team type is changing on parent accounts');
		System.assertEquals(updatedParentAccounts[0].Id, accountIds.iterator().next(), 'Sharing recalculation required for child records only when sales team type is changing on parent accounts');
	}

	/**
	 * Test to ensure sharing recalculation for child objects is ignored (and logged) when queueable job has been reached already.
	 */
	@IsTest
	static void testAccountChildRecordSharingRecalculationInAsyncContextWhenNoMoreQueueableJobsCanBeEnqueued() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(2, true);
		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;
		parentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;

		List<Account> updatedParentAccounts = new List<Account>{parentAccounts[0].clone(true), parentAccounts[1].clone(true)};
		updatedParentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		updatedParentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_INTERMEDIARY;

		// setup the results returned by the service
		List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> recalculationResults = new List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult>();
		// parentAccounts[0] is processed fully
		recalculationResults.add(new SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult(parentAccounts[0].Id, parentAccounts[0].SalesTeamType__c, true, false, new Map<SObjectType, Integer>()));

		// parentAccounts[1] is not processed but does not require partial processing
		recalculationResults.add(new SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult(parentAccounts[1].Id, parentAccounts[1].SalesTeamType__c, false, false, new Map<SObjectType, Integer>{
				APR__c.getSObjectType() => 1000
		}));


		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = ((SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// set variable for mocking async context from the test
		SalesAccountChildSObjectSharingModule.mockAsyncContextInTests = true;
		// set variable for mocking the scenario where no more queueable jobs can be enqueued
		SalesAccountChildSObjectSharingModule.mockQueueableLimitReachedInTests = true;

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.recalculateChildRecordSharing((Set<Id>)fflib_Match.anyObject(), (ApplicationUnitOfWork) fflib_Match.anyObject())).thenReturn(recalculationResults);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAccountChildSObjectSharingModule module = SalesAccountChildSObjectSharingModule.newInstance();
		module.onAfterUpdate(updatedParentAccounts, new Map<Id, Account>(parentAccounts), mockUow);
		Test.stopTest();

		// verify new share records registered with unit of work are as expected for the account processed in the same context
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockService, 1)).recalculateChildRecordSharing((Set<Id>)sobjectCapture.capture(), (ApplicationUnitOfWork) fflib_Match.anyObject());
		Set<Id> accountIds = (Set<Id>) sobjectCapture.getValue();
		System.assertEquals(2, accountIds.size(), 'Sharing recalculation required for child records only when sales team type is changing on parent accounts');

		// make sure no new queueable jobs were enqueued for unprocessed accounts
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockService, 0)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)fflib_Match.anyObject());

		// verify excluded records are logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure sharing recalculation for child objects is not attempted again if already enqueued or processed.
	 */
	@IsTest
	static void testSharingRecalculationNotTriggeredAgainOnEnqueuedOrProcessedAccounts() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Account> parentAccounts = ApplicationTestDataFactory.getAccounts(4, true);
		parentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;
		parentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;
		parentAccounts[2].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;
		parentAccounts[3].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_HOLDING;

		List<Account> updatedParentAccounts = parentAccounts.deepClone(true);
		//List<Account> updatedParentAccounts = new List<Account>{parentAccounts[0].clone(true), parentAccounts[1].clone(true)};
		updatedParentAccounts[0].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		updatedParentAccounts[1].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		updatedParentAccounts[2].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;
		updatedParentAccounts[3].SalesTeamType__c = SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT;

		// =====================================
		// Stubbing
		// =====================================
		SalesRecordSharingService mockService = ((SalesRecordSharingService) MockUtility.mockUtility(SalesRecordSharingService.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		((SalesRecordSharingService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// set account ids enqueued in current transaction
		SalesAccountChildSObjectSharingModule.enqueuedAccountIds = new Set<Id>{parentAccounts[0].Id}; // parentAccount[0] is already enqueued and should be ignored
		// set account ids processed synchronously in current transaction
		SalesAccountChildSObjectSharingModule.accountIdsProcessedInCurrentTransaction = new Map<Id, String>{
				parentAccounts[1].Id => SalesRecordSharingService.SALES_TEAM_TYPE_DIRECT, // parentAccount[1] is processed previously for same sales team type. should be ignored.
				parentAccounts[2].Id => SalesRecordSharingService.SALES_TEAM_TYPE_INTERMEDIARY  // parentAccount[2] is processed previously for a different sales team type. should be processed again.
		};

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesAccountChildSObjectSharingModule module = SalesAccountChildSObjectSharingModule.newInstance();
		module.onAfterUpdate(updatedParentAccounts, new Map<Id, Account>(parentAccounts), mockUow);

		Test.stopTest();

		// verify new share records registered with unit of work are as expected
		fflib_ArgumentCaptor sobjectCapture = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((SalesRecordSharingService)MockUtility.Mocks.verify(mockService, 1)).enqueueChildRecordsSharingHandlerQueueable((Set<Id>)sobjectCapture.capture());
		Set<Id> enqueuedAccountIds = (Set<Id>) sobjectCapture.getValue();

		System.assertEquals(2, enqueuedAccountIds.size(), 'Accounts already enqueued or processed for the same sales team type should be ignored.');
		System.assertEquals(true, enqueuedAccountIds.contains(parentAccounts[3].Id), 'sharing must be recalculated for the account not enqueued/processed previously in same transaction.');
		System.assertEquals(true, enqueuedAccountIds.contains(parentAccounts[2].Id), 'sharing must be recalculated for the account processed previously but for a different sales team type.');
	}
}