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
        
		// Make sure we only get back the positive test record
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		Assert.areEqual(revenue.Id, results[0].Id, 'Expected 2023 revenue record');

		Test.stopTest();
	}
}