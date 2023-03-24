/**
 * @description       : Test class for STCaseInvestigationLifecycleModule
 * @author            : Dattaraj Deshmukh
 * @domain            : Case
 * @changelog
 * 2023-01-18 - Dattaraj Deshmukh- created
 * 2023-02-14 - Mahesh Parvathaneni - updated tests for setCaseInvestigationClosureDate method
 * 2023-02-20 - Dattaraj Deshmukh - Added and passed 'stCaseInvestigationRecordTypeId' to CI selectors.
 **/
@IsTest
private class  STCaseInvestigationLifecycleModule_Test {

	@IsTest
	static void beforeUpdateResetValuesOnNetworkChange() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].OwnerId = ApplicationTestDataFactory.getUsers(1, true)[0].Id;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[1].Id, true));
		records[0].RequireMoreInformation__c = true;
		records[0].StillUnderInvestigation__c = true;
		records[0].IsPrinted__c = true;
		records[0].Status__c = 'New';
		records[0].OwnerId = UserInfo.getUserId();
		records[0].Network__c = networks[0].Id; // doens't change

		records[1].RequireMoreInformation__c = true;
		records[1].StillUnderInvestigation__c = true;
		records[1].IsPrinted__c = true;
		records[1].Status__c = 'New';
		records[1].OwnerId = UserInfo.getUserId();
		records[1].Network__c = networks[1].Id; // is changed

		List<CaseInvestigation__c> oldRecords = records.deepClone(true, true, true);
		oldRecords[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(oldRecords[0], new Map<String, Object>{'Case__r' => cases[0]});
		oldRecords[0].RequireMoreInformation__c = false;
		oldRecords[0].StillUnderInvestigation__c = false;
		oldRecords[0].IsPrinted__c = false;
		oldRecords[0].Status__c = 'New';
		oldRecords[0].OwnerId = UserInfo.getUserId();
		oldRecords[0].Network__c = networks[0].Id;

		oldRecords[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(oldRecords[1], new Map<String, Object>{'Case__r' => cases[0]});
		oldRecords[1].RequireMoreInformation__c = false;
		oldRecords[1].StillUnderInvestigation__c = false;
		oldRecords[1].IsPrinted__c = false;
		oldRecords[1].Status__c = 'New';
		oldRecords[1].OwnerId = UserInfo.getUserId();
		oldRecords[1].Network__c = networks[0].Id;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CaseInvestigationsSelector ciSelectorMock = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(ciSelectorMock.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{records[1].Id}),(Set<Object>)fflib_Match.eq(new Set<Object>{ CaseInvestigationsSelector.Options.WITH_CASE_DETAILS }))).thenReturn(new Map<Id, CaseInvestigation__c>{oldRecords[1].id => oldRecords[1]});
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationLifecycleModule.newInstance().onBeforeUpdate(records, new Map<Id, CaseInvestigation__c>(oldRecords), mockUow);

		System.assertEquals(true, records[0].RequireMoreInformation__c, 'Should not change');
		System.assertEquals(true, records[0].StillUnderInvestigation__c, 'Should not change');
		System.assertEquals(true, records[0].IsPrinted__c, 'Should not change');
		System.assertEquals('New', records[0].Status__c, 'Should not change');
		System.assertEquals(UserInfo.getUserId(), records[0].OwnerId, 'Should not change');

		System.assertEquals(false, records[1].RequireMoreInformation__c, 'Should reset to false');
		System.assertEquals(false, records[1].StillUnderInvestigation__c, 'Should reset to false');
		System.assertEquals(false, records[1].IsPrinted__c, 'Should reset to false');
		System.assertEquals('In Progress', records[1].Status__c, 'Should reset to In Progress');
		System.assertEquals(records[1].CreatedById, records[1].OwnerId, 'Should reset to case owner id');

		Test.stopTest();
	}

	/**
	 * test: Whenever new case investigation is created, case status should be updated to 'Waiting on operations'.
	 * Expected: On insert of case investigation record, Case.Status = Waiting on Operations.
	 */
	@IsTest
	static void onAfterInsert() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, cases.keySet(), articles[0], networks[0].Id, true);
		caseInvestigations[0].Status__c = 'New';
		caseInvestigations[1].Status__c = 'In Progress';

		//mock
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Stubbing
		// =====================================

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		STCaseInvestigationLifecycleModule.newInstance().onAfterInsert(caseInvestigations, mockUow);
		Test.stopTest();

		//verify registerDirty() is called.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<Case>) fflib_Match.eq(new List<Case>{new Case(Id = caseInvestigations[0].Case__c, Status = MyNetworkConstants.CASE_STATUS_WAITING_ON_OPERATIONS)}));

		// PMD by-pass
		System.assert(true, 'PMD by-pass');

	}

	/**
	 * Scenario: Testing the before insert trigger event
	 * Test to ensure the case investigation closure date is set on the records before insert when records are in closed statuses
	 */
	@IsTest
	static void testBeforeInsertSetCaseInvestigationClosureDate() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[1].Id, true));
		records[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'IsClosed__c' => true});
		records[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'IsClosed__c' => true});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationLifecycleModule.newInstance().onBeforeInsert(records, mockUow);

		// make sure case investigation closure date has been populated
		System.assertNotEquals(null, records[0].CaseInvestigationClosureDate__c, 'Expected case investigation closure date set on case investigation but returned null');
		System.assertNotEquals(null, records[1].CaseInvestigationClosureDate__c, 'Expected case investigation closure date set on case investigation but returned null');

		Test.stopTest();
	}

	/**
	* Scenario: Testing the before update trigger event
	* Test to ensure the case investigation closure date is set on the records before update when records are in closed statuses 
	*/
	@IsTest
	static void testBeforeUpdateSetCaseInvestigationClosureDate() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, cases[1].Id, articles[1], networks[1].Id, true));
		records[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object>{'IsClosed__c' => false});
		records[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object>{'IsClosed__c' => true});

		List<CaseInvestigation__c> oldRecords = new List<CaseInvestigation__c>{records[0].clone(true),records[1].clone(true)};
		oldRecords[0] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(oldRecords[0], new Map<String, Object>{'IsClosed__c' => true});
		oldRecords[1] = (CaseInvestigation__c)ApplicationTestDataFactory.setUnwritableFields(oldRecords[1], new Map<String, Object>{'IsClosed__c' => false});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationLifecycleModule.newInstance().onBeforeUpdate(records, new Map<Id, CaseInvestigation__c>(oldRecords), mockUow);

		// make sure case investigation closure date has been set
		System.assertEquals(null, records[0].CaseInvestigationClosureDate__c, 'Expected case investigation closure date reset on case investigation but returned value');
		System.assertNotEquals(null, records[1].CaseInvestigationClosureDate__c, 'Expected case investigation closure date set on case investigation but returned null');

		Test.stopTest();
	}
}