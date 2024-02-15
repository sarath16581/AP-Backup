/***
 * @author Ken McGuire
 * @description Test class for BudgetAndRevenueModule
 * @changelog
 * 2/11/2023 created
 */
@IsTest
private class BudgetAndRevenueModule_Test{
	/**
		* Testing of field updates on the module for before insert
	*/
	@IsTest
	private static void testBeforeInsertPopulateUID() {
		// =====================================
		// Data Preparation
		// =====================================
		Date dateOfTest = Date.newInstance(2024, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		oppRec.AccountId = account.Id;
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

		Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
		List<Budget_and_Revenue__c> records = new List<Budget_and_Revenue__c>{budgrev,budgrevp};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BudgetAndRevenueModule module = BudgetAndRevenueModule.newInstance();
		module.onBeforeInsert(records, mockUow);

		System.assertEquals(ProductRevenueService.getUID(budgrev), records[0].uid__c, 'The module logic did not update uid field on before insert.');
		System.assertEquals(ProductRevenueService.getUID(budgrevp), records[1].uid__c, 'The module logic did not update uid field on before insert.');

		Test.stopTest();
	}

	/**
	 	* Testing of field updates on the module for before update
	 */
	@IsTest
	private static void testBeforeUpdatePopulateUID() {
		// =====================================
		// Data Preparation
		// =====================================
		Date dateOfTest = Date.newInstance(2024, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		oppRec.AccountId = account.Id;
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

		Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
		List<Budget_and_Revenue__c> records = new List<Budget_and_Revenue__c>{budgrev,budgrevp};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BudgetAndRevenueModule module = new BudgetAndRevenueModule();
		module.onBeforeUpdate(records, null, mockUow);

		System.assertEquals(ProductRevenueService.getUID(budgrev), records[0].uid__c, 'The module logic did not update uid field on before insert.');
		System.assertEquals(ProductRevenueService.getUID(budgrevp), records[1].uid__c, 'The module logic did not update uid field on before insert.');

		Test.stopTest();
	}

	/**
	 	* Testing of field updates on the module for after insert
	 */
	@IsTest
	private static void testAfterInsertUpdateGroupedRevenues() {
		// =====================================
		// Data Preparation
		// =====================================
		Date dateOfTest = Date.newInstance(2024, 4, 1);
		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		account.ParentId = parentAccount.Id;

		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		oppRec.AccountId = account.Id;
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

		Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
		List<Budget_and_Revenue__c> records = new List<Budget_and_Revenue__c>{budgrev,budgrevp};
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BudgetAndRevenueModule module = new BudgetAndRevenueModule();
		module.onAfterInsert(records, mockUow);
		Test.stopTest();
	}

	/**
		* Testing of field updates on the module for after update
	*/
	@IsTest
	private static void testAfterUpdateUpdateGroupedRevenues() {
		// =====================================
		// Data Preparation
		// =====================================
		Date dateOfTest = Date.newInstance(2024, 4, 1);
		Account parentAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		account.ParentId = parentAccount.Id;

		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		oppRec.AccountId = account.Id;
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

		Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
		List<Budget_and_Revenue__c> records = new List<Budget_and_Revenue__c>{budgrev,budgrevp};
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BudgetAndRevenueModule module = new BudgetAndRevenueModule();
		module.onAfterUpdate(records, null, mockUow);
		Test.stopTest();
	}
}