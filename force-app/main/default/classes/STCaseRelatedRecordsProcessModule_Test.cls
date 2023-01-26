/**
 * @description       : Test class for STCaseRelatedRecordsProcessModule
 * @author            : Dattaraj Deshmukh
 * @domain            : Case
 * @changelog
 * 2022-12-05 - Dattaraj Deshmukh - created
 **/
@IsTest
private class STCaseRelatedRecordsProcessModule_Test {

	/**
	*Testing whenever a case is closed, all its child case investigations need to be closed.  
	*/
    @IsTest
	static void onAfterUpdate() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
		
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		cases[0].Status = 'Closed'; //setting updated case status

		Case oldCase = cases[0];
		oldCase.Status = 'New'; //setting status of OLD Case record. (Trigger.Old)

        List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

        List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		caseInvestigations[0].Status__c = 'New';

		//assigning child CI records to case.
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'CaseInvestigations__r' => new List<SObject>{caseInvestigations[0]}});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();		
		STCaseInvestigationLifecycleModule mockModuleUtil = (STCaseInvestigationLifecycleModule) MockUtility.mockUtility(STCaseInvestigationLifecycleModule.class);
        
		MockUtility.Mocks.startStubbing();
		
		//mocking STCaseInvestigationLifecycleModule method call.
		((STCaseInvestigationLifecycleModule)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockModuleUtil)).updateAllCaseInvestigations((List<SObject>)fflib_Match.anyObject(),(Map<Id, Case>)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//passing updated value, old value and unit of work for case.
		STCaseRelatedRecordsProcessingModule.newInstance().onAfterUpdate(cases, new Map<Id, Case>{oldCase.Id => oldCase}, mockUow);

		Test.stopTest();

		//verify that STCaseInvestigationLifecycleModule is called once with expected list of jobs
		((STCaseInvestigationLifecycleModule) MockUtility.Mocks.verify(mockModuleUtil, MockUtility.Mocks.times(1))).updateAllCaseInvestigations(cases, new Map<Id, Case>{oldCase.Id => oldCase}, mockUow);
	}
}
