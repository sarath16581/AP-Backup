/**
 * @description       : Test class for STCaseInvestigationLifecycleModule
 * @author            : Dattaraj Deshmukh
 * @domain            : Case
 * @changelog
 * 2023-01-18 - Dattaraj Deshmukh- created
 **/
@IsTest
private class  STCaseInvestigationLifecycleModule_Test {
    @IsTest
	static void onAfterInsert() {
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

        List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

        List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations[0].Status__c = 'New';
		//assigning child CI records to case.
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => new List<SObject>{caseInvestigations[0]}});


		//mock
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Stubbing
		// =====================================

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();
        STCaseInvestigationLifecycleModule.newInstance().onAfterInsert(caseInvestigations, mockUow);
        Test.stopTest();

		//asserting time in minutes changed after DSR Implementation stage is updated.
		System.assertEquals(MyNetworkConstants.CASE_STATUS_WAITING_ON_OPERATIONS,((Case)MockUtility.mockUnitOfWorkDMLs[0]).Status);

		//verify registerDirty() is called.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
	}


	@IsTest
	static void updateAllCaseInvestigationsTest() {
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		cases[0].Status = 'Closed';

		Case oldCase = cases[0];
		oldCase.Status = 'New';

        List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

        List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations[0].Status__c = 'New';
		//assigning child CI records to case.
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => new List<SObject>{caseInvestigations[0]}});


		//mock
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CaseInvestigationsSelector mockCaseInvestigationSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);

		// =====================================
		// Stubbing
		// =====================================

        MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectOpenCaseInvestigationsByCaseIds((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0]});
        MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		STCaseInvestigationLifecycleModule.newInstance().updateAllCaseInvestigations(cases, new Map<Id, Case>{oldCase.Id => oldCase}, mockUow);
		Test.stopTest();

		//asserting time in minutes changed after DSR Implementation stage is updated.
		System.assertEquals(MyNetworkConstants.CASE_INVESTIGATION_CLOSED_STATUS,((CaseInvestigation__c)MockUtility.mockUnitOfWorkDMLs[0]).Status__c);

		//verify registerDirty() is called.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
	}
}
