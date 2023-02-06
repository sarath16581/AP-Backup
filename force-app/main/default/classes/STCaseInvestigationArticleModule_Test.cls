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

	
/**
	 * Test:
	 *  When a case is inserted, the before insert will try and match the ReferenceID or ArticleTest field to their corresponding records in Article__c
	 */
	@IsTest
	private static void testEnsureBeforeInsertPopulatesArticleAndReferenceIds() {

		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1, account.Id, 'SAP ERP', true)[0];
		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(3, new Map<Id, Case>(cases).keySet(), articles[0], null, true);

		// set up billing account on articles
		articles[0].Billing_Account__c = billingAccount.Id;
		articles[1].Billing_Account__c = billingAccount.Id;

		// this is our test data where 1 record has a reference ID and another article has the Id
		caseInvestigations[0].ReferenceID__c = articles[0].ArticleID__c;
		caseInvestigations[1].Article__c = articles[1].Id;

		ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{'Consignment__r' => consignment});
		ApplicationTestDataFactory.setUnwritableFields(articles[1], new Map<String, Object>{'Consignment__r' => consignment});

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleSelector.selectByIdOrTracking((Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationArticleModule module = STCaseInvestigationArticleModule.newInstance();

		module.onBeforeInsert(caseInvestigations, uow);

		// make sure the method behaved
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByIdOrTracking((Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// make sure fields were updated correctly
		System.assertEquals(articles[0].Id, caseInvestigations[0].Article__c, 'Expected Article Id field to be set on case');
		System.assertEquals(articles[1].ArticleID__c, caseInvestigations[1].ReferenceID__c, 'Expected Reference ID field to be set on case');

		// make sure case was not updated
		System.assertEquals(null, caseInvestigations[2].ReferenceID__c, 'Expected Reference Id field to be empty');
		System.assertEquals(null, caseInvestigations[2].Article__c, 'Expected Article Id field to be empty');

		Test.stopTest();
	}


}
