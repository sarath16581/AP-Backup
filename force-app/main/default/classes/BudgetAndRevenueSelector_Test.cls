@isTest
public class BudgetAndRevenueSelector_Test {
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
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		Assert.areEqual(revenue.Id, results[0].Id, 'Expected 2023 revenue record');

		BudgetAndRevenueSelector selector2 = BudgetAndRevenueSelector.newInstance();
		List<Budget_and_Revenue__c> results2 = selector2.selectByOrganisationAndProduct(new Set<Id>{testAcc.Id}, new Set<Id>(), new Set<Integer>{2023}, new Set<Id>());
		Assert.areEqual(1, results2.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}