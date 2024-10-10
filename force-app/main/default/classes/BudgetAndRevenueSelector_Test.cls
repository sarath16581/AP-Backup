/**
 * @changelog
 * 2024-10-10 - Swati Mogadala - New method added test_selectByDups()
 */
@isTest
public class BudgetAndRevenueSelector_Test {
	@isTest
	static void testSelectByOrganisationId() {
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
	static void testSelectByOrganisationIdWithFY() {
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
	@isTest
	static void testSelectByUniqueIds() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account testAcc = new Account(Name = 'test');

		insert testAcc;

		Budget_and_Revenue__c revenue = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAcc.Id, false)[0];
		revenue.uid__c = 'testuid';
		insert revenue;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BudgetAndRevenueSelector selector = BudgetAndRevenueSelector.newInstance();
		Map<Id,Budget_and_Revenue__c> results = selector.selectByUniqueIds(new Set<String>{revenue.uid__c});
		
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
	
	@isTest
	static void testSelectByOrganisationAndProduct() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account testAcc = new Account(Name = 'test');

		insert testAcc;

		Budget_and_Revenue__c revenue = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAcc.Id, false)[0];
		revenue.uid__c = 'testuid';
		revenue.Financial_Year__c ='2024';
		insert revenue;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BudgetAndRevenueSelector selector = BudgetAndRevenueSelector.newInstance();
		LIst<Budget_and_Revenue__c> results = selector.selectByOrganisationAndProduct(new Set<Id>{testAcc.Id}, new Set<Id>(), new Set<String>{revenue.Financial_Year__c}, new Set<Id>());
		
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
	
	@isTest
	static void testSelectByOrganisationAndProduct2() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account testAcc = new Account(Name = 'test');

		insert testAcc;

		Budget_and_Revenue__c revenue = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAcc.Id, false)[0];
		revenue.uid__c = 'testuid';
		revenue.Financial_Year__c ='2024';
		insert revenue;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BudgetAndRevenueSelector selector = BudgetAndRevenueSelector.newInstance();
		LIst<Budget_and_Revenue__c> results = selector.selectByOrganisationAndProduct(new Set<Id>{testAcc.Id}, new Set<Id>(), new Set<Integer>{2024}, new Set<Id>());
		
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
		@isTest
	static void testSelectByDups() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Account> testAcc = ApplicationTestDataFactory.getAccounts(1,false);

		insert testAcc;

		// Positive test case
		Budget_and_Revenue__c revenue = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAcc[0].Id, false)[0];
		revenue.Unique_Id__c=revenue.CustomerNumber__c + 'Test1';
		insert revenue;
		// Negative test case
		Budget_and_Revenue__c duplicate = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAcc[0].Id, false)[0];
		revenue.Financial_Year__c = '2024';
		revenue.Unique_Id__c='6000000Test1';
		insert duplicate;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BudgetAndRevenueSelector selector = BudgetAndRevenueSelector.newInstance();
		List<Budget_and_Revenue__c> results = selector.selectByDups();
		
		// Make sure we only get back the positive test record
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		Assert.areEqual(duplicate.Id, results[0].Id, 'Expected duplicate revenue record');

		Test.stopTest();
	}
}