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

	/**
	 * Test:
	 *  When a case is updated and the article does not exist in Salesforce, the after update method will trigger a queueable to search the article in the tracking api
	 */
	@IsTest
	private static void testEnsureAfterInsertEnqueuesJobToQueryArticle() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, new Map<Id, Case>(cases).keySet(), articles[0], null, true);

		// this is our test data where 1 record has a reference ID and another article has the Id
		articles[0].ArticleID__c = 'REF1';
		caseInvestigations[0].ReferenceID__c = articles[0].ArticleID__c;
		caseInvestigations[0].Article__c = null;

		articles[1].ArticleID__c = 'REF2';
		caseInvestigations[1].ReferenceID__c = articles[1].ArticleID__c;
		caseInvestigations[1].Article__c = articles[1].Id;

		ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{'Consignment__r' => consignment});
		ApplicationTestDataFactory.setUnwritableFields(articles[1], new Map<String, Object>{'Consignment__r' => consignment});

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		CaseInvestigationsSelector mockCaseInvestigationSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>(caseInvestigations));
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<Database.SaveResult>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationArticleModule module = STCaseInvestigationArticleModule.newInstance();
		module.onAfterInsert(caseInvestigations, uow);

		System.assertEquals(1, Limits.getQueueableJobs(), 'Expected a queueable job');

		Test.stopTest();

		// these methods exist in the queueable
		((TIBCOArticleService)MockUtility.Mocks.verify(mockArticleService, 1)).search((List<String>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean());
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((CaseInvestigationsSelector)MockUtility.Mocks.verify(mockCaseInvestigationSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
	}

	/**
	 * Test:
	 *  When a case is updated and the article does not exist in Salesforce, the after update method will trigger a queueable to search the article in the tracking api
	 */
	@IsTest
	private static void testEnsureAfterUpdateEnqueuesJobToQueryArticle() {

		// =====================================
		// Data Preparation
		// =====================================

		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(2, new Map<Id, Case>(cases).keySet(), articles[0], null, true);

		// this is our test data where 1 record has a reference ID and another article has the Id
		articles[0].ArticleID__c = 'REF1';
		caseInvestigations[0].ReferenceID__c = articles[0].ArticleID__c;
		caseInvestigations[0].Article__c = null;

		articles[1].ArticleID__c = 'REF2';
		caseInvestigations[1].ReferenceID__c = articles[1].ArticleID__c;
		caseInvestigations[1].Article__c = articles[1].Id;

		List<CaseInvestigation__c> oldCaseInvestigations = caseInvestigations.deepClone(true, true, true);

		ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{'Consignment__r' => consignment});
		ApplicationTestDataFactory.setUnwritableFields(articles[1], new Map<String, Object>{'Consignment__r' => consignment});

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		CaseInvestigationsSelector mockCaseInvestigationSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCaseInvestigationSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>(caseInvestigations));
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<Database.SaveResult>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		STCaseInvestigationArticleModule module = STCaseInvestigationArticleModule.newInstance();
		module.onAfterUpdate(caseInvestigations, new Map<Id, CaseInvestigation__c>(oldCaseInvestigations), uow);

		System.assertEquals(1, Limits.getQueueableJobs(), 'Expected a queueable job');

		Test.stopTest();

		// these methods exist in the queueable
		((TIBCOArticleService)MockUtility.Mocks.verify(mockArticleService, 1)).search((List<String>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean());
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((CaseInvestigationsSelector)MockUtility.Mocks.verify(mockCaseInvestigationSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
	}

	/**
	 * Test:
	 *  When article id's and references are changed on cases, the before update method will keep both values on a case in sync
	 *  If the ReferenceID is updated, in the before update method, the ArticleTest will also be updated
	 *  If the ArticleTest is updated, in the before update method, the ReferenceID will also be updated
	 *  If the ReferenceID is removed, in the before update method, the ArticleTest will also be removed
	 *  If the ArticleTest is removed, in the before update method, the ReferenceID will also be removed
	 */
	@IsTest
	private static void testEnsureBeforeUpdateCorrectlySynchronisesArticleFields() {

		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, consignment.Id, true);

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(3, new Map<Id, Case>(cases).keySet(), articles[0], null, true);

		// this is our test data where 1 record has a reference ID and another article has the Id
		articles[0].ArticleID__c = 'REF1';
		caseInvestigations[0].ReferenceID__c = articles[0].ArticleID__c;
		caseInvestigations[0].Article__c = null;

		articles[1].ArticleID__c = 'REF2';
		caseInvestigations[1].ReferenceID__c = null;
		caseInvestigations[1].Article__c = articles[1].Id;

		List<CaseInvestigation__c> oldCaseInvestigations = caseInvestigations.deepClone(true, true, true);

		// swapping them around to simulate change
		oldCaseInvestigations[0].ReferenceID__c = articles[1].ArticleID__c;
		oldCaseInvestigations[1].Article__c = articles[0].Id;

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

		system.debug('>>>>>>>>>> caseInvestigations: ' + caseInvestigations);
		system.debug('>>>>>>>>>> oldCaseInvestigations: ' + oldCaseInvestigations);
		module.onBeforeUpdate(caseInvestigations, new Map<Id, CaseInvestigation__c>(oldCaseInvestigations), uow);

		// make sure the method behaved
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByIdOrTracking((Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// make sure fields were updated correctly
		System.assertEquals(articles[0].Id, caseInvestigations[0].Article__c, 'Expected Article Id field to be set on case');
		System.assertEquals(articles[1].ArticleID__c, caseInvestigations[1].ReferenceID__c, 'Expected Reference ID field to be set on case');

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
		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, consignment.Id, true);

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(3, new Map<Id, Case>(cases).keySet(), articles[0], null, true);

		// this is our test data where 1 record has a reference ID and another article has the Id
		articles[0].ArticleID__c = 'REF1';
		caseInvestigations[0].ReferenceID__c = articles[0].ArticleID__c;
		caseInvestigations[0].Article__c = null;

		articles[1].ArticleID__c = 'REF2';
		caseInvestigations[1].ReferenceID__c = null;
		caseInvestigations[1].Article__c = articles[1].Id;

		caseInvestigations[2].ReferenceID__c = null;
		caseInvestigations[2].Article__c = null;

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
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectOpenCaseInvestigationsByCaseArticleNetworkId((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseInvestigation__c>{existingCaseInvestigations[0].Id => existingCaseInvestigations[0]});
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