/**
* @author Pratyush Chalasani
* @date 2023-04-21
* @group Selector
* @tag Selector
* @tag Profile SObject
* @domain Core
* @description Test class for AtRiskBusinessSelector
* @changelog
* 2023-04-21 - Pratyush Chalasani - Created
*/
@isTest
public with sharing class AtRiskBusinessSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

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

		AtRiskBusinessSelector selector = AtRiskBusinessSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom at_risk_business__c\\b').matcher(soql).find(), 'Resulting query does not select from At_Risk_Business__c');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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

		AtRiskBusinessSelector selector = AtRiskBusinessSelector.newInstance(new Set<SObjectField>{At_Risk_Business__c.Name});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom at_risk_business__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

		Test.stopTest();

	}

	@isTest
	static void testSelectById() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account testAcc = new Account(Name = 'test');

		insert testAcc;

		At_Risk_Business__c arb = ApplicationTestDataFactory.getAtRiskBusiness(1, testAcc.Id, false)[0];

		insert arb;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AtRiskBusinessSelector selector = AtRiskBusinessSelector.newInstance();
		List<At_Risk_Business__c> results = selector.selectById(new Set<Id>{arb.Id});
		
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}