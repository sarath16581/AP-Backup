/*** 
 * @author Noel Lim
 * @date 2022-10-11
 * @group Utility
 * @domain Routing 
 * @description Test class for the SSSW_Routing class
 * @changelog
 * 2022-10-11	Noel Lim - Created
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
		List<QueueSobject> routingHoldingQueueList = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Holding_Queue' AND SobjectType = 'Case' LIMIT 1]);
        custSetting.HoldingQueueId__c = routingHoldingQueueList[0].QueueId;
        Insert custSetting;


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseCommonUtility caseUtility = new CaseCommonUtility();

		//Attempt to route the case with an Article that is not in the database, which will assign it to the SSSW Routing Holding Queue
		caseUtility.routeCase(cases, null, true); 

		Test.stopTest();

		//Verify the case is assigned to the SSSW Routing Holding Queue
		System.assertEquals( custSetting.HoldingQueueId__c, cases[0].OwnerId, 'Expected case is assigned to the SSSW Routing Holding Queue');
    
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
		List<QueueSobject> routingHoldingQueueList = new List<QueueSobject>([SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Holding_Queue' AND SobjectType = 'Case' LIMIT 1]);
        custSetting.HoldingQueueId__c = routingHoldingQueueList[0].QueueId;
        Insert custSetting;


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		//Attempt to re-route cases as a final pass via the 5th param
		SSSW_Routing.assignCasesAndDescription(cases, null, false, true, true);		

		Test.stopTest();

		//Verify the case is assigned to the SSSW Routing Holding Queue
		System.assert( SSSW_Routing.casesForReroutingAttempt.size() <= 0, 'Expected the list casesForReroutingAttempt is empty');
    
    }

}