/***
 * @author Mahesh Parvathaneni
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering EntitlementRulesSelector
 */

@IsTest
public with sharing class EntitlementRulesSelector_Test {

	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EntitlementRulesSelector selector = EntitlementRulesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Entitlement_Rule__c\\b').matcher(soql).find(), 'Resulting query does not select from Entitlement_Rule__c');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Entitlement_Rule__c.Escalation_Hierarchy__c) + '\\b').matcher(soql).find(), 'Escalation_Hierarchy__c field does not exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Entitlement_Rule__c.Rule__c) + '\\b').matcher(soql).find(), 'Rule__c field does not exists in query');

		qb = selector.newQueryBuilder(new Set<Object>{EntitlementRulesSelector.Options.WITH_ESCALATION_HIERARCHY});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Escalation_Hierarchy__r\\..*?\\bfrom Entitlement_Rule__c\\b').matcher(soql).find(), 'Resulting query does not select Escalation_Hierarchy__r fields: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test:
	 * Executes a query to ensure it returns expected results
	 */
	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		//create test data
		List<Escalation_Hierarchy__c> ehRecs = ApplicationTestDataFactory.getEscalationHierarchies(1, 'Test Escalation Hierarchy', false);
		insert ehRecs;

		List<Entitlement_Rule__c> eRules = ApplicationTestDataFactory.getEntitlementRules(1, 'Test Entitlement Rule', ehRecs[0].Id, false);
		eRules[0].RecordTypeId = Schema.SObjectType.Entitlement_Rule__c.getRecordTypeInfosByDeveloperName().get('Case_Investigation').getRecordTypeId();
		insert eRules;
		
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EntitlementRulesSelector selector = EntitlementRulesSelector.newInstance();
		Map<Id, Entitlement_Rule__c> results = selector.selectActiveRulesByRecordTypeDevNames(new Set<String> {'Case_Investigation'});
		System.assert(results.size() >= 1, 'Expected result size greater than or equal to 1');

		EntitlementRulesSelector selectorLimit = EntitlementRulesSelector.newInstance(1);
		Map<Id, Entitlement_Rule__c> resultsLimit = selectorLimit.selectActiveRulesByRecordTypeDevNames(new Set<String> {'Case_Investigation'});
		System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

		Test.stopTest();

	}
}