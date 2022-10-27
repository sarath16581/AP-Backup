/*** 
 * @author Noel Lim
 * @date 2022-10-11
 * @group Utility
 * @domain Routing 
 * @description Test class for the SSSW_Routing class
 * @changelog
 * 2022-10-11 - Noel Lim - Created
 */
@IsTest
private class SSSW_Routing_Test {

	/**
	 * Covers 2 test scenarios:
	 * a) When a case has an Article with Extra Cover and is in the Salesforce database, ensure the Case HasExtraCover field is marked true 
	 * b) When a case has an Article with Extra Cover but does not exist in the Salesforce database, ensure that the Case HasExtraCover field is marked true after the Queueable 
	 *
	 * Scenario a) is simulated by processing the Case in CaseUtility.routeCase()
	 * Scenario b) is sumulated by processing the Case in MyCustomerCaseArticlesModule.afterUpdate()
	 * 
	 * NOTE: This calls SSSW_Routing which isn't correctly setup for mocking....It does however call ArticlesSelector -> selectByTracking which we will mock here
	 *          It's slightly confusing to take this approach, however its better then running full end to end tests for every scenario
	 */
	@IsTest
	private static void testEnsureCaseHasExtraCover() {
		// =====================================
		// Data Preparation
		// =====================================
		
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, null, true);    
        // Extra cover is  indicated by an amount > 0 and Blank merchant location id.
        articles[0].InsuranceAmount__c = 200;
        articles[0].ArticleID__c = 'ART1231';

		// Extra cover is  indicated by an amount > 0 and Blank merchant location id.
        articles[1].InsuranceAmount__c = 200;
        articles[1].ArticleID__c = 'ART1232';

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].ReferenceID__c = 'ART1231'; // links to articles[0]
		cases[0].Origin = 'Email';		
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;
        cases[1].ReferenceID__c = 'ART1232'; // links to articles[1]
		cases[1].Origin = 'Email';
		cases[1].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[1].IsNewForRouting__c  = true;
		cases[1].AllocateToQueue__c = true;

		
		List<Case> caseArticleInDatabase = new List<Case>();
		caseArticleInDatabase.add(cases[0]);
		List<Case> caseArticleNotInDatabase = new List<Case>();
		caseArticleNotInDatabase.add(cases[1]);
		

		// create an old state
		List<Case> oldCases = new List<Case>{cases[0].clone(true), cases[1].clone(true)};

		// TODO: move SSSWRouting generation into ApplicationTestDataFactory
		// create a new routing rule in teh database for SSSW_Routing to pick up
		// NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		List<QueueSobject> queues = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.Name LIKE 'SSSW%' AND SobjectType = 'Case' LIMIT 1]);

		List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

		// Setup a rule that will match case[0]
		SSSWRouting__c routingRule = new SSSWRouting__c();
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.IsActive__c = true;
		//To reach the routing logic where a Case is flagged for Queuable and rerouting, formula field SSSW_Routing__r.RuleRequiresArticleAttributes__c needs to be true
		routingRule.HasExtraCover__c = true; 
		routingRule.Queue_ID__c = queues[0].QueueId;
		routingRule.Sequence__c = 1;
		routesToInsert.add(routingRule);

		Insert routesToInsert;

		// populate the data to trigger a rerouting attempt
		// in an end to end process, this data gets populated in the SSSW_Routing.assignCasesAndDescription method
		// we fake it here for mocking and brevity
		SSSW_Routing.casesForReroutingAttempt = new List<Case>{
				new Case(Id = cases[1].Id)
		};

		SSSW_Routing.casesWithOriginalValues = new List<Map<String, Object>>{
				new Map<String, Object>{
					'Origin' => 'Email',
					'Type' => 'General Enquiry',
					'ReferenceID__c' => 'ART1232'
				}
		};

		// =====================================
		// Stubbing
		// =====================================
		TIBCOArticleService mockArticleService = (TIBCOArticleService)MockUtility.mockUtility(TIBCOArticleService.class);
		SSSWCasesSelector mockCaseSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		ArticlesSelector mockArticleSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		//Article 
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.eq(new Set<String>{articles[0].ArticleID__c}), (Set<Object>)fflib_Match.eq(new Set<Object>{ArticlesSelector.Options.WITH_BILLINGACCOUNT, BillingAccountsSelector.Options.WITH_ORGANISATION}),(Boolean)fflib_Match.eq(false))).thenReturn(new Map<Id, Article__c>(new List<Article__c>{articles[0]}));
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.eq(new Set<String>{articles[1].ArticleID__c}), (Set<Object>)fflib_Match.eq(new Set<Object>{ArticlesSelector.Options.WITH_CHILDARTICLES, ArticlesSelector.Options.WITH_RECORDTYPE}),(Boolean)fflib_Match.eq(false))).thenReturn(new Map<Id, Article__c>(new List<Article__c>{articles[1]}));
		MockUtility.Mocks.when(mockArticleSelector.selectByTracking((Set<String>)fflib_Match.eq(new Set<String>{articles[1].ArticleID__c}), (Set<Object>)fflib_Match.eq(new Set<Object>{ArticlesSelector.Options.WITH_BILLINGACCOUNT, BillingAccountsSelector.Options.WITH_ORGANISATION}),(Boolean)fflib_Match.eq(false))).thenReturn(new Map<Id, Article__c>(new List<Article__c>{articles[1]}));
		MockUtility.Mocks.when(mockCaseSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{cases[1].Id}))).thenReturn(new Map<Id, Case>(new List<Case>{cases[1]}));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
		MyCustomerCaseArticlesModule module = MyCustomerCaseArticlesModule.newInstance();
		CaseCommonUtility caseUtility = new CaseCommonUtility();

		//Scenario whera a Case references an Article that is in database
		caseUtility.routeCase(caseArticleInDatabase, null, true); 

		//Scenario where a Case references an Article that is not in the database and requires a Queueable to retrieve it
		module.onAfterUpdate(caseArticleNotInDatabase, new Map<Id, Case>(oldCases), uow);

		System.assertEquals(1, Limits.getQueueableJobs(), 'Expected a queueable job');

		Test.stopTest();

		//Called from caseUtility.routeCase()
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByTracking((Set<String>)fflib_Match.eq(new Set<String>{articles[0].ArticleID__c}),  (Set<Object>)fflib_Match.eq(new Set<Object>{ArticlesSelector.Options.WITH_BILLINGACCOUNT, BillingAccountsSelector.Options.WITH_ORGANISATION}), (Boolean)fflib_Match.eq(false));

		//Called from the Queueable triggered in moduleonAfterUpdate() 
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByTracking((Set<String>)fflib_Match.eq(new Set<String>{articles[1].ArticleID__c}),  (Set<Object>)fflib_Match.eq(new Set<Object>{ArticlesSelector.Options.WITH_CHILDARTICLES, ArticlesSelector.Options.WITH_RECORDTYPE}), (Boolean)fflib_Match.eq(false));
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticleSelector, 1)).selectByTracking((Set<String>)fflib_Match.eq(new Set<String>{articles[1].ArticleID__c}),  (Set<Object>)fflib_Match.eq(new Set<Object>{ArticlesSelector.Options.WITH_BILLINGACCOUNT, BillingAccountsSelector.Options.WITH_ORGANISATION}), (Boolean)fflib_Match.eq(false));
		((TIBCOArticleService)MockUtility.Mocks.verify(mockArticleService, 1)).search((List<String>)fflib_Match.anyObject(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean(), fflib_Match.anyBoolean());
		((SSSWCasesSelector)MockUtility.Mocks.verify(mockCaseSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{cases[1].Id}));

		// verify case HasExtraCover has been stamped 
		System.assertEquals( true, caseArticleNotInDatabase[0].HasExtraCover__c, 'Expected Case with Article not in Database - HasExtraCover marked as true');
		System.assertEquals( true, ((Case)MockUtility.mockDMLUpdatedRecords[0]).HasExtraCover__c, 'Expected Case with Article in Database - HasExtraCover marked as true');
        
	}

	/**
	 * When a Case requires an Article that is not in the database, ensure it is assigned to the Omni Routing Default queue as a holding queue.
	 * 
	 * The above test Scenario is simulated via the CaseUtility.routeCase() and not having an Article record that matches the Case Reference_ID__c
	 *
	 */
    @IsTest
	private static void testEnsureCaseInOmniDefaultQueue() {
		// =====================================
		// Data Preparation
		// =====================================

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ReferenceID__c = 'ART1231'; // links to articles[0]
		cases[0].Origin = 'Email';		
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;

		// TODO: move SSSWRouting generation into ApplicationTestDataFactory
		// create a new routing rule in teh database for SSSW_Routing to pick up
		// NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		List<QueueSobject> queues = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.Name LIKE 'SSSW%' AND SobjectType = 'Case' LIMIT 1]);

		List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

		// Setup a rule that will match case[0] and allow rule routing logic to execute
		SSSWRouting__c routingRule = new SSSWRouting__c();
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.IsActive__c = true;
		//To reach the routing logic where a Case is flagged for Queuable and rerouting, formula field SSSW_Routing__r.RuleRequiresArticleAttributes__c needs to be true
		routingRule.HasExtraCover__c = true; 
		routingRule.Queue_ID__c = queues[0].QueueId;
		routingRule.Sequence__c = 1;
		routesToInsert.add(routingRule);
		Insert routesToInsert;


		QM__c custSetting = QM__c.getOrgDefaults();
		List<QueueSobject> omniDefaultRoutingQueueList = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'Omni_Routing_Default' AND SobjectType = 'Case' LIMIT 1]);
        custSetting.OmniDefaultQueueId__c = omniDefaultRoutingQueueList[0].QueueId;
        Insert custSetting;


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseCommonUtility caseUtility = new CaseCommonUtility();

		//Attempt to route the case with an Article that is not in the database, which will assign it to the Omni Routing Default queue
		caseUtility.routeCase(cases, null, true); 

		Test.stopTest();

		//Verify the case is assigned to the Omni Routing Default Queue
		System.assertEquals( custSetting.OmniDefaultQueueId__c, cases[0].OwnerId, 'Expected case is assigned to the Omni Routing Default Queue');
    
    }

	/**
	 * When re-routing Cases from MyCustomerCaseArticlesModule, ensure there are no cases for re-routing
	 * 
	 * The above test Scenario is simulated by having a rule that requires an article (for both ALL and ANY match), and a case with a Reference Id
	 *
	 */
    @IsTest
	private static void testEnsureNoCaseForRerouteWhenFinalPass() {
		// =====================================
		// Data Preparation
		// =====================================

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].ReferenceID__c = 'ART1231'; 
		cases[0].Origin = 'Email';		
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;

		cases[0].ReferenceID__c = 'ART1232'; 
		cases[0].Origin = 'Phone';		
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;

		// TODO: move SSSWRouting generation into ApplicationTestDataFactory
		// create a new routing rule in teh database for SSSW_Routing to pick up
		// NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		List<QueueSobject> queues = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.Name LIKE 'SSSW%' AND SobjectType = 'Case' LIMIT 1]);

		List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

		// Setup a rule that will match cases[0] and allow rule routing logic to execute
		SSSWRouting__c routingRule = new SSSWRouting__c();
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.IsActive__c = true;
		//To reach the routing logic where a Case is flagged for Queuable and rerouting, formula field SSSW_Routing__r.RuleRequiresArticleAttributes__c needs to be true
		routingRule.HasExtraCover__c = true; 
		routingRule.Queue_ID__c = queues[0].QueueId;
		routingRule.Sequence__c = 1;
		routesToInsert.add(routingRule);

		// Setup a rule that will match cases[1] and allow rule routing logic to execute
		SSSWRouting__c routingRule2 = new SSSWRouting__c();
		routingRule2.RecordTypeId = routingRuleRecordTypeId;
		routingRule2.Match_Rules_On__c = 'Any';
		routingRule2.Origin__c = 'Phone';
		routingRule2.IsActive__c = true;
		//To reach the routing logic where a Case is flagged for Queuable and rerouting, formula field SSSW_Routing__r.RuleRequiresArticleAttributes__c needs to be true
		routingRule2.HasExtraCover__c = true; 
		routingRule2.Queue_ID__c = queues[0].QueueId;
		routingRule2.Sequence__c = 2;
		routesToInsert.add(routingRule2);

		Insert routesToInsert;


		QM__c custSetting = QM__c.getOrgDefaults();
		List<QueueSobject> omniDefaultRoutingQueueList = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'Omni_Routing_Default' AND SobjectType = 'Case' LIMIT 1]);
        custSetting.OmniDefaultQueueId__c = omniDefaultRoutingQueueList[0].QueueId;
        Insert custSetting;


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//Attempt to re-route cases as a final pass via the 5th param
		SSSW_Routing.assignCasesAndDescription(cases, null, false, true, true);		

		Test.stopTest();

		//Verify the case is assigned to the Omni Routing Default Queue
		System.assert( SSSW_Routing.casesForReroutingAttempt.size() <= 0, 'Expected the list casesForReroutingAttempt is empty');
    
    }

	/**
	 * When there is no Omni Routing Default Queue, ensure an Exception is thrown and a log is created
	 */
    @IsTest
	private static void testMissingOmniDefaultQueue() {
		// =====================================
		// Data Preparation
		// =====================================

		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		Insert logLevel;

		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ReferenceID__c = 'ART1231'; // links to articles[0]
		cases[0].Origin = 'Email';	
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;	

		// TODO: move SSSWRouting generation into ApplicationTestDataFactory
		// create a new routing rule in teh database for SSSW_Routing to pick up
		// NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		List<QueueSobject> queues = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.Name LIKE 'SSSW%' AND SobjectType = 'Case' LIMIT 1]);

		List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

		// Setup a rule that will match case[0] and allow rule routing logic to execute
		SSSWRouting__c routingRule = new SSSWRouting__c();
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.IsActive__c = true;
		//To reach the routing logic where a Case is flagged for Queuable and rerouting, formula field SSSW_Routing__r.RuleRequiresArticleAttributes__c needs to be true
		routingRule.HasExtraCover__c = true; 
		routingRule.Queue_ID__c = queues[0].QueueId;
		routingRule.Sequence__c = 1;
		routesToInsert.add(routingRule);
		Insert routesToInsert;


		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseCommonUtility caseUtility = new CaseCommonUtility();

		//Attempt to route the case with an Article that is not in the database, which will assign it to the Omni Routing Default queue
		caseUtility.routeCase(cases, null, true); 
		

		Test.stopTest();
		
        // Exception is caught in caseUtility and logged
		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
		System.assertEquals(true, logResult.size() > 0, 'Expected an Exception to be thrown');
	
    }
}