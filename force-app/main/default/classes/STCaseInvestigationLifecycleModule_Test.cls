/**
 * @description       : Test class for STCaseInvestigationLifecycleModule
 * @author            : Dattaraj Deshmukh
 * @domain            : Case
 * @changelog
 * 2023-01-18 - Dattaraj Deshmukh- created
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
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectOpenCaseInvestigationsByCaseIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0]});
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
}