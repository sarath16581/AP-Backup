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
	 * test: Whenever a case is closed, all its child case investigations should be closed.
	 * Expected: On Closure of case, All CaseInvestigation.Status = Waiting on Operations.
	 */
	@IsTest
	static void updateAllCaseInvestigationsTest() {

		// =====================================
		// Data Preparation
		// =====================================

		Id stCaseInvestigationRecordTypeId = Schema.SObjectType.CaseInvestigation__c.getRecordTypeInfosByDeveloperName()
		.get('StarTrack_MyNetwork').getRecordTypeId();

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		//Map<Id, Case> casesMap = new Map<Id, Case>(ApplicationTestDataFactory.getCases(2, true));

		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		cases[0].Status = 'Closed';
		
		Case oldCase = cases[0].clone(true);
		oldCase.Status = 'New';

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, new Set<Id>{cases[0].Id, cases[1].Id}, articles[0], networks[0].Id, true);
		caseInvestigations[0].Status__c = 'New';
		caseInvestigations[0].RecordTypeId = stCaseInvestigationRecordTypeId;
		
		//assigning child CI records to case.
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => new List<SObject>{caseInvestigations[0]}});
		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1], new Map<String, List<SObject>>{'CaseInvestigations__r' => new List<SObject>{caseInvestigations[1]}});
		
		//assigning formula field as it is referred in logic.
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'StarTrack_RecordType__c' => true});

		//mock
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CaseInvestigationsSelector mockCaseInvestigationSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);

		// =====================================
		// Stubbing
		// =====================================

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectOpenCaseInvestigationsByCaseIds(new Set<Id>{cases[0].Id}, new Set<Id>{stCaseInvestigationRecordTypeId})).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		STCaseInvestigationLifecycleModule.newInstance().updateAllCaseInvestigations(cases, new Map<Id, Case>{oldCase.Id => oldCase, cases[1].Id => cases[1]}, mockUow);
		Test.stopTest();

		//verify registerDirty() is called.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<CaseInvestigation__c>) fflib_Match.eq(new List<CaseInvestigation__c>{new CaseInvestigation__c(Id = caseInvestigations[0].Id, Status__c = MyNetworkConstants.CASE_INVESTIGATION_CLOSED_STATUS)}));

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
