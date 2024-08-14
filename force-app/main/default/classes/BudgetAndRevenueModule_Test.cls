/***
 * @author Ken McGuire
 * @description Test class for BudgetAndRevenueModule
 * @changelog
 * 2/11/2023 created
 * 2024-07-09modify for line items of closed opportunities 
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
		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];

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
		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];

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
		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];

		Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
		List<Budget_and_Revenue__c> records = new List<Budget_and_Revenue__c>{budgrev,budgrevp};

		GroupedAccountProductRevenue__c groupedRev2023 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
				FinancialYear__c = 2023, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2023'), Id = fflib_IDGenerator.generate(GroupedAccountProductRevenue__c.getSObjectType()),
				Rev1__c = 11,Rev2__c = 22,Rev3__c = 33,Rev4__c = 44,
				Rev5__c = 55,Rev6__c = 66,Rev7__c = 77,Rev8__c = 88,
				Rev9__c = 99,Rev10__c = 110,Rev11__c = 220,Rev12__c = 330);

		GroupedAccountProductRevenue__c groupedRev2024 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
				FinancialYear__c = 2024, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2024'), Id = fflib_IDGenerator.generate(GroupedAccountProductRevenue__c.getSObjectType()),
				Rev1__c = 440,Rev2__c = 550,Rev3__c = 660,Rev4__c = 770,
				Rev5__c = 880,Rev6__c = 990,Rev7__c = 1100,Rev8__c = 2200,
				Rev9__c = 3300,Rev10__c = 4400,Rev11__c = 5500,Rev12__c = 6600);
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ProductRevenueService mockService = (ProductRevenueService)MockUtility.mockUtility(ProductRevenueService.class);
		GroupedAccountProductRevenueSelector groupedRevenueSelector = (GroupedAccountProductRevenueSelector)MockUtility.mockSelector(GroupedAccountProductRevenueSelector.class);
		BudgetAndRevenueSelector revenueSelector = (BudgetAndRevenueSelector)MockUtility.mockSelector(BudgetAndRevenueSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(groupedRevenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,GroupedAccountProductRevenue__c>(new List<GroupedAccountProductRevenue__c>{groupedRev2023,groupedRev2024}));
		MockUtility.Mocks.when(revenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Budget_and_Revenue__c>{budgrev.Id => budgrev, budgrevp.Id => budgrevp});
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BudgetAndRevenueModule module = new BudgetAndRevenueModule();
		module.onAfterInsert(records, mockUow);
		Test.stopTest();

		// only verifying the invoke times for ProductRevenueService.updateGroupedRevenues, the actual logic for this is tested in the ProductRevenueService_Test class
		((ProductRevenueService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).updateGroupedRevenues(records,null);

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
		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];

		Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
		List<Budget_and_Revenue__c> records = new List<Budget_and_Revenue__c>{budgrev,budgrevp};
		GroupedAccountProductRevenue__c groupedRev2023 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
				FinancialYear__c = 2023, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2023'), Id = fflib_IDGenerator.generate(GroupedAccountProductRevenue__c.getSObjectType()),
				Rev1__c = 11,Rev2__c = 22,Rev3__c = 33,Rev4__c = 44,
				Rev5__c = 55,Rev6__c = 66,Rev7__c = 77,Rev8__c = 88,
				Rev9__c = 99,Rev10__c = 110,Rev11__c = 220,Rev12__c = 330);

		GroupedAccountProductRevenue__c groupedRev2024 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
				FinancialYear__c = 2024, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2024'), Id = fflib_IDGenerator.generate(GroupedAccountProductRevenue__c.getSObjectType()),
				Rev1__c = 440,Rev2__c = 550,Rev3__c = 660,Rev4__c = 770,
				Rev5__c = 880,Rev6__c = 990,Rev7__c = 1100,Rev8__c = 2200,
				Rev9__c = 3300,Rev10__c = 4400,Rev11__c = 5500,Rev12__c = 6600);


		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ProductRevenueService mockService = (ProductRevenueService)MockUtility.mockUtility(ProductRevenueService.class);
		GroupedAccountProductRevenueSelector groupedRevenueSelector = (GroupedAccountProductRevenueSelector)MockUtility.mockSelector(GroupedAccountProductRevenueSelector.class);
		BudgetAndRevenueSelector revenueSelector = (BudgetAndRevenueSelector)MockUtility.mockSelector(BudgetAndRevenueSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(groupedRevenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,GroupedAccountProductRevenue__c>(new List<GroupedAccountProductRevenue__c>{groupedRev2023,groupedRev2024}));
		MockUtility.Mocks.when(revenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Budget_and_Revenue__c>{budgrev.Id => budgrev, budgrevp.Id => budgrevp});
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BudgetAndRevenueModule module = new BudgetAndRevenueModule();
		module.onAfterUpdate(records, null, mockUow);
		Test.stopTest();

		// only verifying the invoke times for ProductRevenueService.updateGroupedRevenues, the actual logic for this is tested in the ProductRevenueService_Test class
		((ProductRevenueService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).updateGroupedRevenues(records,null);
	}
}