@isTest
public class BudgetAndRevenueSelector_Test {
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

		BudgetAndRevenueSelector selector = BudgetAndRevenueSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom budget_and_revenue__c\\b').matcher(soql).find(), 'Resulting query does not select from Budget_and_Revenue__c');

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

		BudgetAndRevenueSelector selector = BudgetAndRevenueSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
			Budget_and_Revenue__c.SObjectType => new Set<SObjectField>{Budget_and_Revenue__c.Name}
		});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom budget_and_revenue__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

		Test.stopTest();

	}

	@isTest
	static void test_selectByOrganisationId() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account testAcc = new Account(Name = 'test');

		insert testAcc;

		Budget_and_Revenue__c revenue = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAcc.Id, false)[0];

		insert revenue;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BudgetAndRevenueSelector selector = BudgetAndRevenueSelector.newInstance();
		List<Budget_and_Revenue__c> results = selector.selectByOrganisationId(testAcc.Id);
		
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
	@isTest
	static void test_selectByOrganisationId_withFY() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account testAcc = new Account(Name = 'test');

		insert testAcc;

		// Positive test case
		Budget_and_Revenue__c revenue = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAcc.Id, false)[0];
		revenue.Financial_Year__c = '2023';
		insert revenue;

		// Negative test case
		Budget_and_Revenue__c invalid = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAcc.Id, false)[0];
		revenue.Financial_Year__c = '2024';
		insert invalid;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BudgetAndRevenueSelector selector = BudgetAndRevenueSelector.newInstance();
		List<Budget_and_Revenue__c> results = selector.selectByOrganisationId(new Set<Id>{testAcc.Id}, new Set<String>{'2023'});
		
		// Make sure we only get back the positive test record
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		Assert.areEqual(revenue.Id, results[0].Id, 'Expected 2023 revenue record');

		Test.stopTest();
	}
}