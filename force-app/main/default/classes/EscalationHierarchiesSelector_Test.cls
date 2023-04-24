/***
 * @author Mahesh Parvathaneni
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering EscalationHierarchiesSelector
 */

@IsTest
public with sharing class EscalationHierarchiesSelector_Test {

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

		EscalationHierarchiesSelector selector = EscalationHierarchiesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Escalation_Hierarchy__c\\b').matcher(soql).find(), 'Resulting query does not select from Escalation_Hierarchy__c');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Escalation_Hierarchy__c.Facility_Tier_1__c) + '\\b').matcher(soql).find(), 'Facility_Tier_1__c field does not exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Escalation_Hierarchy__c.Customer_Tier_1__c) + '\\b').matcher(soql).find(), 'Customer_Tier_1__c field does not exists in query');

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
		
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EscalationHierarchiesSelector selector = EscalationHierarchiesSelector.newInstance();
		Map<Id, Escalation_Hierarchy__c> results = selector.selectById(new Set<Id> {ehRecs[0].Id});
		System.assert(results.size() >= 1, 'Expected result size greater than or equal to 1');

		EscalationHierarchiesSelector selectorLimit = EscalationHierarchiesSelector.newInstance(1);
		Map<Id, Escalation_Hierarchy__c> resultsLimit = selectorLimit.selectById(new Set<Id> {ehRecs[0].Id});
		System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

		Test.stopTest();

	}
}