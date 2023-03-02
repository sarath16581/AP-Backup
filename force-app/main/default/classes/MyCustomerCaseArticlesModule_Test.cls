/**
 * @description
 * Test class for MyCustomerCaseArticlesModule
 * @author Nathan Franklin
 * @date 2020-07-22
 * @group Tests
 * @domain SSSW
 * @changelog
 * SaiSwetha Pingali - Removed the test method for SnapIt cases as it is no longer required.
 * 2022-10-31	Noel Lim - Updated tests relating to strategic rules, as case re-routing logic during the async call need to be in the holding Queue to be re-routed
 * 2023-02-16	Noel Lim - Update testEnsureStrategicCaseIsReroutedInQueueable method to assert Case.PreferredAgentExpiry is set
 * 2023-03-02	Noel Lim - Add testAsyncLinkArticlesToCasesWorker method
 */
@IsTest
private class MyCustomerCaseArticlesModule_Test {

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

		// set up billing account on articles
		articles[0].Billing_Account__c = billingAccount.Id;
		articles[1].Billing_Account__c = billingAccount.Id;

		// this is our test data where 1 record has a reference ID and another article has the Id
		cases[0].ReferenceID__c = articles[0].ArticleID__c;
		cases[1].ArticleTest__c = articles[1].Id;

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

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();

		module.onBeforeInsert(cases, uow);

		// make sure the method behaved
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByIdOrTracking((Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// make sure fields were updated correctly
		System.assertEquals(articles[0].Id, cases[0].ArticleTest__c, 'Expected Article Id field to be set on case');
		System.assertEquals(articles[1].ArticleID__c, cases[1].ReferenceID__c, 'Expected Reference ID field to be set on case');

		// make sure case was not updated
		System.assertEquals(null, cases[2].ReferenceID__c, 'Expected Reference Id field to be empty');
		System.assertEquals(null, cases[2].ArticleTest__c, 'Expected Article Id field to be empty');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  When a case is insert and the article does not exist in Salesforce, the after update method will trigger a queueable to search the article in the tracking api
	 */
	@IsTest
	private static void testEnsureAfterInsertEnqueuesJobToQueryArticle() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, null, true);
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);

		// this is our test data where 1 record has a reference ID and another article has the Id
		cases[0].ReferenceID__c = 'ART1231';
		cases[1].ReferenceID__c = 'ART1232';

		List<String> caseIds = new List<String>{cases[0].Id, cases[1].Id};

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		SSSWCasesSelector mockCaseSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.when(mockCaseSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();
		module.queueAsyncArticleToCases(cases, uow);

		System.assertEquals(1, Limits.getQueueableJobs(), 'Expected a queueable job');

		Test.stopTest();

		// these methods exist in the queueable
		((TIBCOArticleService)MockUtility.Mocks.verify(mockArticleService, 1)).search((List<String>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean());
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((SSSWCasesSelector)MockUtility.Mocks.verify(mockCaseSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());
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
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(4, null, true);
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(5, true);
		List<Case> oldCases = new List<Case>{cases[0].clone(true),cases[1].clone(true), cases[2].clone(true), cases[3].clone(true), cases[4].clone(true)};

		// set the article id/reference id values of the old cases to be different from the new ones

		// on case0, Reference id was changed from article0 to article1
		// on case1, Article id was changed from article2 to article3
		cases[0].ReferenceID__c = articles[1].ArticleID__c;
		oldCases[0].ReferenceID__c = articles[0].ArticleID__c;

		cases[1].ArticleTest__c = articles[3].Id;
		oldCases[1].ArticleTest__c = articles[2].Id;

		// testing when a the user removes a value to make sure the other field unsets too
		// case2, the reference id has been removed.
		// case3, the article id has been removed.
		cases[2].ReferenceID__c = '';
		cases[2].ArticleTest__c = articles[3].Id;
		oldCases[2].ReferenceID__c = articles[3].ArticleID__c;
		oldCases[2].ArticleTest__c = articles[3].Id;

		cases[3].ReferenceID__c = articles[3].ArticleID__c;
		cases[3].ArticleTest__c = null;
		oldCases[3].ReferenceID__c = articles[3].ArticleID__c;
		oldCases[3].ArticleTest__c = articles[3].Id;

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

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();
		module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		Test.stopTest();

		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByIdOrTracking((Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		System.assertEquals(articles[1].Id, cases[0].ArticleTest__c, 'Expected case0 to be synced with article1');
		System.assertEquals(articles[3].ArticleID__c, cases[1].ReferenceID__c, 'Expected case1 to be synced with article3');
		System.assertEquals(null, cases[2].ArticleTest__c, 'Expected case2 article id to be cleared');
		System.assertEquals(null, cases[3].ReferenceID__c, 'Expected case3 reference id to be cleared');
	}

	/**
	 * Test:
	 *  When ArticleTest changes (either by the user or in the before update method), a workflow rule will check if that article has been subscribe to or not
	 *		  If not, the Workflow will trigger an outbound message, and will set the Subscribed flag on Case
	 *		  the before update method will reset that flag and queue a job to asynchronously update the article to be subscribed
	 */
	@IsTest
	private static void testEnsureBeforeUpdateEnqueuesSubscribedArticleUpdate() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, null, true);
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<Case> oldCases = new List<Case>{cases[0].clone(true)};

		// set the article id/reference id values of the old cases to be different from the new ones

		// on case0, Article id was changed from article0 to article1
		//	  additionally, Subscribed was set in SSSW - Article Subscription (the case was changed to an article that was currently not subscribed)
		cases[0].ArticleTest__c = articles[1].Id;
		cases[0].Subscribed__c = true;
		oldCases[0].ArticleTest__c = articles[0].Id;
		oldCases[0].Subscribed__c = false;

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleSelector.selectByIdOrTracking((Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();
		module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		System.assertEquals(1, Limits.getQueueableJobs(), 'Expected a queueable job');

		Test.stopTest();

		System.assertEquals(false, cases[0].Subscribed__c, 'Expected Subscribed field to be reset');

		// this method would be called in the AsyncSubscribeArticlesQueueable queueable
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
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, null, true);
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);

		// this is our test data where 1 record has a reference ID and another article has the Id
		cases[0].ReferenceID__c = 'ART1231';
		cases[1].ReferenceID__c = 'ART1232';

		List<String> caseIds = new List<String>{cases[0].Id, cases[1].Id};

		List<Case> oldCases = new List<Case>{cases[0].clone(true), cases[1].clone(true)};

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		SSSWCasesSelector mockCaseSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.when(mockCaseSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();
		module.queueAsyncArticleToCases(cases, uow);

		System.assertEquals(1, Limits.getQueueableJobs(), 'Expected a queueable job');

		Test.stopTest();

		// these methods exist in the queueable
		((TIBCOArticleService)MockUtility.Mocks.verify(mockArticleService, 1)).search((List<String>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean());
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((SSSWCasesSelector)MockUtility.Mocks.verify(mockCaseSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
	}

	/**
	 * Test:
	 * Ensures a case being handled asynchronously that is flagged for rerouting is correctly routed into the strategic queue
	 *
	 * NOTE: This calls SSSW_Routing which isn't correctly setup for mocking....It does however call ArticlesSelector -> selectByTracking which we will mock here
	 *		  It's slightly confusing to take this approach, however its better then running full end to end tests for every scenario
	 */
	@IsTest
	private static void testEnsureStrategicCaseIsReroutedInQueueable() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountRecords = ApplicationTestDataFactory.getAccounts(2, true);
		accountRecords[0] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountRecords[0], new Map<String, Object>{'IsStrategicSupportCustomer__c' => true});
		accountRecords[1] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountRecords[1], new Map<String, Object>{'IsStrategicSupportCustomer__c' => false});

		List<Billing_Account__c> billingAccountRecords = new List<Billing_Account__c>();
		billingAccountRecords.add(ApplicationTestDataFactory.getBillingAccounts(1, accountRecords[0].Id, 'SAP ERP', true)[0]);
		billingAccountRecords.add(ApplicationTestDataFactory.getBillingAccounts(1, accountRecords[1].Id, 'SAP ERP', true)[0]);
		billingAccountRecords[0] = (Billing_Account__c)ApplicationTestDataFactory.setUnwritableFields(billingAccountRecords[0], new Map<String, Object>{'Organisation__c' => accountRecords[0].Id, 'Organisation__r' => accountRecords[0]});
		billingAccountRecords[1] = (Billing_Account__c)ApplicationTestDataFactory.setUnwritableFields(billingAccountRecords[1], new Map<String, Object>{'Organisation__c' => accountRecords[1].Id, 'Organisation__r' => accountRecords[1]});
		// ^^ Billing Accounts should now be populated with Organisation__r (we use this in the routing method)

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, null, true);
		articles[0] = (Article__c)ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{'Billing_Account__c' => billingAccountRecords[0].Id, 'Billing_Account__r' => billingAccountRecords[0]});
		articles[1] = (Article__c)ApplicationTestDataFactory.setUnwritableFields(articles[1], new Map<String, Object>{'Billing_Account__c' => billingAccountRecords[1].Id, 'Billing_Account__r' => billingAccountRecords[1]});
		// ^^ Articles should now be populated with Billing_Account__r.Organisation__r (we use this in the routing method)

		//For tests where cases are put in a holding queue to fetch articles and re-route the case asyncronously
		QM__c custSetting = new QM__c();
		List<QueueSobject> routingHoldingQueueList = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Holding_Queue' AND SobjectType = 'Case' LIMIT 1]);
		Id holdingQueue = routingHoldingQueueList[0].QueueId;
		custSetting.HoldingQueueId__c = holdingQueue;
		Insert custSetting;

		//Cases that need an article for routing are placed in a holding queue
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].ReferenceID__c = 'ART1231'; // links to articles[0]
		cases[0].Origin = 'Email';
		cases[0].OwnerId = holdingQueue;
		cases[0].BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
		cases[1].ReferenceID__c = 'ART1232';  // links to articles[1]
		cases[1].Origin = 'Phone';
		cases[1].OwnerId = holdingQueue;

		List<String> caseIds = new List<String>{cases[0].Id, cases[1].Id};

		// create an old state
		List<Case> oldCases = new List<Case>{cases[0].clone(true), cases[1].clone(true)};

		// TODO: move SSSWRouting generation into ApplicationTestDataFactory
		// create a new routing rule in teh database for SSSW_Routing to pick up
		// NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		List<QueueSobject> queues = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.Name LIKE 'SSSW%' AND SobjectType = 'Case' LIMIT 2]);

		List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

		// Setup a rule that will match case[0] based on Origin / IsStrategic (Case article has a billing account/organisation with IsStrategicSupportCustomer__c = true)
		SSSWRouting__c routingRule = new SSSWRouting__c();
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.IsActive__c = true;
		routingRule.IsStrategic__c = true;
		routingRule.Queue_ID__c = queues[0].QueueId;
		routingRule.Sequence__c = 1;
		routingRule.PreferredAgentExpiry__c = 1;
		routesToInsert.add(routingRule);

		insert routesToInsert;

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		SSSWCasesSelector mockCaseSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// SPECIAL NOTE: This is triggered in both MyCustomerCaseArticlesModule AND SSSW_Routing.getStrategicCustomerMappings
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));

		MockUtility.Mocks.when(mockCaseSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();
		module.queueAsyncArticleToCases(cases, uow);

		System.assertEquals(1, Limits.getQueueableJobs(), 'Expected a queueable job');

		Test.stopTest();

		// these methods exist in the queueable
		((TIBCOArticleService)MockUtility.Mocks.verify(mockArticleService, 1)).search((List<String>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean());
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 2)).selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((SSSWCasesSelector)MockUtility.Mocks.verify(mockCaseSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify the owner of case[0] has changed and the owner of case[1] hasn't
		System.assertEquals(queues[0].QueueId, ((Case)MockUtility.mockDMLUpdatedRecords[0]).OwnerId, 'Expected case to be rerouted to strategic queue');
		System.assert(((Case)MockUtility.mockDMLUpdatedRecords[0]).PreferredAgentExpiry__c != null, 'Expected case PreferredAgentExpiry to be set');
		System.assertEquals(holdingQueue, ((Case)MockUtility.mockDMLUpdatedRecords[1]).OwnerId, 'Expected case to be in the holding Queue');
	}

	/**
	 * Test:
	 * Ensures that when there is no billing account return for a case that is flagged for rerouting, it does not cause any errors
	 */
	@IsTest
	private static void testEnsureStrategicReroutingDoesNotErrorWithoutBillingAccountOnArticle() {
		// =====================================
		// Data Preparation
		// =====================================
		
		//For tests where cases are put in a holding queue to fetch articles and re-route the case asyncronously
		QM__c custSetting = new QM__c();
		List<QueueSobject> routingHoldingQueueList = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Holding_Queue' AND SobjectType = 'Case' LIMIT 1]);
		Id holdingQueue = routingHoldingQueueList[0].QueueId;
		custSetting.HoldingQueueId__c = holdingQueue;
		Insert custSetting;

		//Cases that need an article for routing are placed in a holding queue
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, null, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ReferenceID__c = 'ART1231'; // links to articles[0]
		cases[0].Origin = 'Phone';
		cases[0].Type = 'Investigation';
		cases[0].OwnerId = holdingQueue;

		List<String> caseIds = new List<String>{cases[0].Id};

		// create an old state
		List<Case> oldCases = new List<Case>{cases[0].clone(true)};

		// TODO: move SSSWRouting generation into ApplicationTestDataFactory
		// create a new routing rule in teh database for SSSW_Routing to pick up
		// NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		List<QueueSobject> queues = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.Name LIKE 'SSSW%' AND SobjectType = 'Case' LIMIT 2]);

		List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

		// Setup a rule that will match case[0] based on Origin / IsStrategic (Case article has a billing account/organisation with IsStrategicSupportCustomer__c = true)
		SSSWRouting__c routingRule = new SSSWRouting__c();
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.CaseType__c = 'General Enquiry';
		routingRule.IsActive__c = true;
		routingRule.IsStrategic__c = true;
		routingRule.Queue_ID__c = queues[0].QueueId;
		routingRule.Sequence__c = 1;
		routesToInsert.add(routingRule);

		insert routesToInsert;

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		SSSWCasesSelector mockCaseSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// SPECIAL NOTE: This is triggered in both MyCustomerCaseArticlesModule AND SSSW_Routing.getStrategicCustomerMappings
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));

		MockUtility.Mocks.when(mockCaseSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();
		module.queueAsyncArticleToCases(cases, uow);

		System.assertEquals(1, Limits.getQueueableJobs(), 'Expected a queueable job');

		Test.stopTest();

		// these methods exist in the queueable
		((TIBCOArticleService)MockUtility.Mocks.verify(mockArticleService, 1)).search((List<String>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean());
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 2)).selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((SSSWCasesSelector)MockUtility.Mocks.verify(mockCaseSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify the owner did not change since the linked article did not have a billing account
		System.assertEquals(holdingQueue, ((Case)MockUtility.mockDMLUpdatedRecords[0]).OwnerId, 'Expected case to not be rerouted to strategic queue');
	}
	
	/**
	 * Test:
	 *	  When a consignment that only contains 1 article is set on the case, the module logic should rewrite the case values to the article rather than the consignment
	 */
	@IsTest
	private static void testEnsureSingleArticleConsignmentsRewriteToArticle() {

		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1, account.Id, 'SAP ERP', true)[0];
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, consignment.Id, true);

		// set up billing account on articles
		articles[0].Billing_Account__c = billingAccount.Id;
		consignment.Billing_Account__c = billingAccount.Id;

		consignment = (Article__c)((List<SObject>)fflib_ApexMocksUtils.makeRelationship(List<Article__c>.class, new List<Article__c>{consignment}, Article__c.Consignment__c, new List<List<Article__c>> { articles }))[0];
		consignment = (Article__c)ApplicationTestDataFactory.setUnwritableFields(consignment, new Map<String, Object>{'RecordType' => ApplicationTestDataFactory.articleConsignmentRecordType});

		// this is our test data where 1 record has a reference ID and another article has the Id
		cases[0].ReferenceID__c = consignment.ArticleID__c;

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleSelector.selectByIdOrTracking((Set<String>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>{consignment.Id => consignment});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();

		module.onBeforeInsert(cases, uow);

		// make sure fields were updated correctly
		System.assertEquals(articles[0].Id, cases[0].ArticleTest__c, 'Expected Consignment Id to be rewritten to Article Id on Case');
		System.assertEquals(articles[0].ArticleID__c, cases[0].ReferenceID__c, 'Expected Consignment Id to be rewritten to Article Id on Case');

		Test.stopTest();
	}

	/************
	 *  Scenario:
	 *	  A case is inserted without having the article queried.
	 *	  This will invoke a queueable that will performt he article search
	 *
	 *	  NOTE: This references TIBCO_Test for some test methods
	 ***********/
	public static testMethod void testEndToEndFlowIntegration() {
		System.Debug('TEST: testCaseInsertInvokeTibco');

		Test.setMock(WebServiceMock.class, new AuspostTrackEventServiceMockImpl());

		Test.startTest();

		// create a case to assert that ArticleTest__c is updated with the correct value
		Case myCase = TestDataProvider.createCase('My Subject', 'My Description', 'SSSW General Enquiry');
		myCase.ReferenceID__c = '12345';
		insert myCase;

		Test.stopTest();

		List<Article__c> articles = [Select Id, Name, TrackingID__c, ArticleID__c From Article__c];
		System.assertEquals(1, articles.size());

		myCase = [Select ArticleTest__c From Case];
		System.assertEquals(articles[0].Id, myCase.ArticleTest__c);

		// CaseArticleUtility async queueable should only be queued once for this transaction
		Integer queueableCount = [Select COUNT() From AsyncApexJob Where ApexClass.Name = 'MyCustomerCaseArticlesModule'];
		System.assertEquals(1, queueableCount);

	}

	@IsTest
	static void testAsyncLinkArticlesToCasesWorker() {
		
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, null, true);
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);

		// this is our test data where 1 record has a reference ID and another article has the Id
		cases[0].ReferenceID__c = 'ART1231';

		Set<String> caseIds = new Set<String>{cases[0].Id};

		List<Case> oldCases = new List<Case>{cases[0].clone(true)};

		MyCustomerCaseArticlesModule.AsyncLinkArticlesToCasesWorker worker = new MyCustomerCaseArticlesModule.AsyncLinkArticlesToCasesWorker();
		Map<String,Set<String>> params = new Map<String,Set<String>>{'caseIds' => caseIds, 'referenceIds' =>  new Set<String>{'ART1231'}};


		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		SSSWCasesSelector mockCaseSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.when(mockCaseSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		System.assertEquals(MyCustomerCaseArticlesModule.AsyncLinkArticlesToCasesWorker.class, worker.getClassType(), 'matching type');
		System.assertEquals(Case.SObjectType, worker.getSObjectTypeGroup(), 'matching type');
		worker.deserialiseParams(JSON.serialize(params));
		System.assert(worker.caseIds.contains(cases[0].Id), 'CaseIds should be passed in via the params');
		System.assert(worker.referenceIds.contains('ART1231'), 'ReferenceIds should be passed in via the params');

		worker.execute(uow);

		Test.stopTest();

		((TIBCOArticleService)MockUtility.Mocks.verify(mockArticleService, 1)).search((List<String>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean());
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByTracking((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((SSSWCasesSelector)MockUtility.Mocks.verify(mockCaseSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
	}	

	/**
	 * test the Exception handling on the module onBeforeInsert and onBeforeUpdate methods
	 */
	@isTest
	static void testExceptionHandling(){

		// =====================================
		// Data Preparation
		// =====================================
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		 // =====================================
		// Testing
		// =====================================
		Test.startTest();

		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();
		module.onBeforeInsert(null,null);
		module.onBeforeUpdate(null,null,null);
		module.onAfterInsert(null,null);
		module.onAfterUpdate(null,null,null);

		Test.stopTest();

		//An exception should be created when thre are invalid parameters in the onBeforeInsert, onBeforeUpdate, onAfterInsert, onAfterUpdate
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 4)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
		
		// PMD warning
		System.assert(true);
	}
}