/**
 * @description       : Test class for STCaseInvestigationArticleModule
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2022-12-13 - Mahesh Parvathaneni - Added test methods for beforeInsert events
 **/
@IsTest
private class STCaseInvestigationArticleModule_Test {
	
	@IsTest
	static void onAfterInsert() {

		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
		Case aCase = ApplicationTestDataFactory.getCases(1, true)[0];
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[0], null, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[1], null, true));

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		STCaseInvestigationArticleModule.newInstance().onAfterInsert(records, mockUow);

		Test.stopTest();

	}

	@IsTest
	static void onAfterUpdate() {
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
		Case aCase = ApplicationTestDataFactory.getCases(1, true)[0];
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[0], null, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[1], null, true));

		Map<Id, CaseInvestigation__c> existingRecords = new Map<Id, CaseInvestigation__c>(records.deepClone(true, true, true));
		existingRecords.get(records[1].Id).ReferenceID__c = 'something diff';

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		STCaseInvestigationArticleModule.newInstance().onAfterUpdate(records, existingRecords, mockUow);

		Test.stopTest();

	}

	@IsTest
	static void onBeforeInsert() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		Case aCase = ApplicationTestDataFactory.getCases(1, true)[0];
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[1], networks[0].Id, true));

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationArticleModule.newInstance().onBeforeInsert(records, mockUow);

		Test.stopTest();

		// make sure there is no validation error
		System.assertEquals(false, records[0].hasErrors(), 'Expected no validation error for case investigation record');
		System.assertEquals(false, records[1].hasErrors(), 'Expected no validation error for case investigation record');
	}

	@IsTest
	static void testBeforeInsertCheckDuplicateCaseInvestigationRecords() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		Case aCase = ApplicationTestDataFactory.getCases(1, true)[0];
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		List<CaseInvestigation__c> records = ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[0], networks[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[1], networks[0].Id, true));
		List<CaseInvestigation__c> existingCaseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, aCase.Id, articles[1], networks[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectOpenCaseInvestigationsByCaseArticleNetworkId((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{existingCaseInvestigations[0].Id => existingCaseInvestigations[0]});
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationArticleModule.newInstance().onBeforeInsert(records, mockUow);

		// make sure new case investigation creation is prevented under same case, article reference and network.
		System.assertEquals(true, records[1].hasErrors(), 'Expected validation error duplicated case investigation is being created');

		Test.stopTest();
	}

}
