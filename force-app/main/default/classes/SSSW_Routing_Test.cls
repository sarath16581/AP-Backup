/*** 
 * @author Noel Lim
 * @date 2022-10-11
 * @group Utility
 * @domain Routing 
 * @description Test class for the SSSW_Routing class
 * @changelog
 * 2022-10-11	Noel Lim - Created
 * 2023-03-02	Noel Lim - Updated method to testEnsureNoCaseForRerouteWhenFinalPass, to cover new Default Omni Queue logic
 */
@IsTest
private class SSSW_Routing_Test {

	/**
	 * When a Case requires an Article that is not in the database, ensure it is assigned to the SSSW Routing Holding Queue as a holding queue.
	 * 
	 * The above test Scenario is simulated via the CaseUtility.routeCase() and not having an Article record that matches the Case Reference_ID__c
	 *
	 */
	@IsTest
	private static void testEnsureCaseInHoldingQueue() {
		// =====================================
		// Data Preparation
		// =====================================

		//setup Queues
		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(2, 'Queue', true));	

		QM__c custSetting = QM__c.getOrgDefaults();
		List<QueueSobject> routingHoldingQueueList = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Holding_Queue' AND SobjectType = 'Case' LIMIT 1]);
		custSetting.HoldingQueueId__c = routingHoldingQueueList[0].QueueId;
		Insert custSetting;
		
		//setup Case
		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ReferenceID__c = 'ART1231'; // links to articles[0]
		cases[0].Origin = 'Email';		
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;
		cases[0].OwnerId = queues.values()[0].Id;

		


		// TODO: move SSSWRouting generation into ApplicationTestDataFactory
		// create a new routing rule in teh database for SSSW_Routing to pick up
		// NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;

		List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

		// Setup a rule that will match case[0] and allow rule routing logic to execute
		SSSWRouting__c routingRule = new SSSWRouting__c();
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.IsActive__c = true;
		//To reach the routing logic where a Case is flagged for Queuable and rerouting, formula field SSSW_Routing__r.RuleRequiresArticleAttributes__c needs to be true
		routingRule.HasExtraCover__c = true; 
		routingRule.Queue_ID__c = queues.values()[1].Id;
		routingRule.Sequence__c = 1;
		routesToInsert.add(routingRule);
		Insert routesToInsert;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//Attempt to route the case with an Article that is not in the database, which will assign it to the SSSW Routing Holding Queue
		CaseRoutingService.getInstance().routeCase(cases, null, true); 

		Test.stopTest();

		//Verify the case is assigned to the SSSW Routing Holding Queue
		System.assertEquals( custSetting.HoldingQueueId__c, cases[0].OwnerId, 'Expected case is assigned to the SSSW Routing Holding Queue');
	}

	/**
	 * Test Scenarios:
	 * a) Test that isFinalPass flag is working, and that if a Case doesn not match a rule, assign it to a default Omni queue.
	 * 
	 * The above test Scenario is simulated by having a 2 rules, cruicially the rule with a lower sequence needs to require an article. 
	 * The routing engine will route a Case to the Holding queue when an rule that requires an Article is reached, regardless of other rules after it.
	 * With IsFinalPass set to true, the Holding Queue is skipped, and the Case is allowed to be matched to rules following the rule that required an article.
	 *
	 * 	 
	 * b) Default Queue
	 * When a Case does not meet any Routing rule, it will be assigned to a default Omni queue that is defined in Custom Settings
	 *
	 */
	@IsTest
	private static void testEnsureNoCaseForRerouteWhenFinalPass() {
		// =====================================
		// Data Preparation
		// =====================================

		//For tests where cases are put in a holding queue to fetch articles and re-route the case asyncronously
		QM__c custSetting = QM__c.getOrgDefaults();
		QueueSobject routingHoldingQueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Holding_Queue' AND SobjectType = 'Case' LIMIT 1];
		custSetting.HoldingQueueId__c = routingHoldingQueue.QueueId;
		QueueSobject defaultOmnniQueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_BOH_Group_4' AND SobjectType = 'Case' LIMIT 1];
		custSetting.DefaultOmniQueueId__c = defaultOmnniQueue.QueueId;
		Insert custSetting;

		//Cases that need an article for routing are placed in a holding queue
		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].ReferenceID__c = 'ART1231'; 
		cases[0].Origin = 'Email';		
		cases[0].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[0].IsNewForRouting__c  = true;
		cases[0].AllocateToQueue__c = true;
		cases[0].ArticleTest__c = 'a1h000000000000000'; 
		cases[0].LinkedArticleHasExtraCover__c = true; 

		cases[1].ReferenceID__c = 'ART1232'; 
		cases[1].Origin = 'Phone';	
		cases[1].RecordTypeId = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId();
		cases[1].IsNewForRouting__c  = true;
		cases[1].AllocateToQueue__c = true;
		cases[1].ArticleTest__c = 'a1h000000000000001'; 
		cases[1].LinkedArticleHasExtraCover__c = true; 

		// TODO: move SSSWRouting generation into ApplicationTestDataFactory
		// create a new routing rule in teh database for SSSW_Routing to pick up
		// NOTE: we only do this because we currently haven't enabled SSSW_Routing for mocking
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		List<QueueSobject> queues = [SELECT QueueId FROM QueueSobject WHERE Queue.Name LIKE 'SSSW%' AND SobjectType = 'Case' LIMIT 2];

		List<SSSWRouting__c> routesToInsert = new List<SSSWRouting__c>();

		SSSWRouting__c routingRuleRequireArticle = new SSSWRouting__c(); 
		routingRuleRequireArticle.RecordTypeId = routingRuleRecordTypeId;
		routingRuleRequireArticle.Match_Rules_On__c = 'All';
		routingRuleRequireArticle.Origin__c = 'Email';
		routingRuleRequireArticle.IsActive__c = true;
		routingRuleRequireArticle.HasExtraCover__c = true; //require an article
		routingRuleRequireArticle.Queue_ID__c = queues[0].QueueId;
		routingRuleRequireArticle.Sequence__c = 1;
		routesToInsert.add(routingRuleRequireArticle);

		SSSWRouting__c routingRuleNoArticle = new SSSWRouting__c();
		routingRuleNoArticle.RecordTypeId = routingRuleRecordTypeId;
		routingRuleNoArticle.Match_Rules_On__c = 'Any';
		routingRuleNoArticle.Origin__c = 'Email';
		routingRuleNoArticle.IsActive__c = true;
		routingRuleNoArticle.Queue_ID__c = queues[1].QueueId;
		routingRuleNoArticle.Sequence__c = 2;
		routesToInsert.add(routingRuleNoArticle);

		Insert routesToInsert;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//Attempt to re-route cases with IsFinalPass = true
		SSSW_Routing.assignCasesAndDescription(cases, null, false, true, true);		

		Test.stopTest();

		System.assertEquals( queues[1].QueueId, cases[0].OwnerId, 'Expected the case is not assigned to the Holding Queue');
		System.assertEquals( custSetting.DefaultOmniQueueId__c, cases[1].OwnerId, 'Expected case is assigned to the Default Omni Queue');
	
	}

}