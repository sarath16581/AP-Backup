/**************************************************
Type: Test Class for ProductRevenueService
History:
--------------------------------------------------
2023-09-21 Ken McGuire - Created

**************************************************/
@IsTest
private class ProductRevenueService_Test {
@IsTest
private static void testRecalculateGroupedRevenues() {
	// =====================================
	// Data Preparation
	// =====================================
	Date dateOfTest = Date.newInstance(2024, 4, 1);
	Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
	Account parentAcc = ApplicationTestDataFactory.getAccounts(1, true)[0];
	AccountRelationship__c accRelation = new AccountRelationship__c(ParentAccount__c = parentAcc.Id, RelatedAccount__c = account.Id, Relationship__c='OPC');

	Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
	oppRec.AccountId = account.Id;
	oppRec.DoNotUseAccountHierarchy__c = false;
	Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];

	Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
	budgrev.uid__c = ProductRevenueService.getUID(budgrev);
	budgrev = (Budget_and_Revenue__c)ApplicationTestDataFactory.setUnwritableFields(budgrev, new Map<String, Object>{
		'uid__c' => ProductRevenueService.getUID(budgrev)
	});
	Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
	budgrevp.uid__c = ProductRevenueService.getUID(budgrevp);
	budgrevp = (Budget_and_Revenue__c)ApplicationTestDataFactory.setUnwritableFields(budgrevp, new Map<String, Object>{
		'uid__c' => ProductRevenueService.getUID(budgrevp)
	});

	Id priceBookId = Test.getStandardPricebookId();
	PricebookEntry pbEntry = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];

	OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
	TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
	oli1 = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oli1, new Map<String, Object>{
		'Annualised_Value__c' => 5000,
		'Product2Id' => prod.Id
	});
	oli1.Product2 = prod;
	oli1.Opportunity = oppRec;
	APR__c apr = new APR__c(Legal_Entity_Name_LookUp__c = account.Id,MHS_Confirmed_Rate__c=0.10);
	ProductRevenueService serviceUnderTest = ProductRevenueService.newInstance();
	serviceUnderTest.revenueCalculationContextDate = dateOfTest;

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
	ProductRelationshipsSelector relatedProductSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class);
	GroupedAccountProductRevenueSelector groupedRevenueSelector = (GroupedAccountProductRevenueSelector)MockUtility.mockSelector(GroupedAccountProductRevenueSelector.class);
	OpportunityLineItemSelector lineItemSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
	APRsSelector aprSelector = (APRsSelector)MockUtility.mockSelector(APRsSelector.class);
	BudgetAndRevenueSelector revenueSelector = (BudgetAndRevenueSelector)MockUtility.mockSelector(BudgetAndRevenueSelector.class);
	AccountRelationshipSelector arSelector = (AccountRelationshipSelector)MockUtility.mockSelector(AccountRelationshipSelector.class);
	MockUtility.Mocks.startStubbing();
	MockUtility.Mocks.when(relatedProductSelector.selectByParent((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<ProductRelationship__c>());
	MockUtility.Mocks.when(groupedRevenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,GroupedAccountProductRevenue__c>(new List<GroupedAccountProductRevenue__c>{groupedRev2023,groupedRev2024}));
	MockUtility.Mocks.when(revenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Budget_and_Revenue__c>{budgrev.Id => budgrev, budgrevp.Id => budgrevp});
	MockUtility.Mocks.when(lineItemSelector.selectByOPCCalculationOpportunityIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oli1});
	//MockUtility.Mocks.when(aprSelector.selectByAccount((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<APR__c>{apr});
	MockUtility.Mocks.when(arSelector.selectByOPCParentEndDateInFuture((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<AccountRelationship__c>{accRelation});
	MockUtility.Mocks.stopStubbing();
	Test.startTest();
	List<OpportunityLineItem> lineItems = serviceUnderTest.getProductLineItemsForOpportunities(new Set<Id>{oppRec.Id});
	Map<String,GroupedAccountProductRevenue__c> reCalculatedRevenues = serviceUnderTest.reCalculateGroupRevenuesForLineItems(lineItems);
	System.assertEquals(6,reCalculatedRevenues.size(),'Grouped revenue for past two years should be created');
	//System.assertEquals(budgrev.Apr_Revenue_Amount__c,reCalculatedRevenues.values()[0].Rev4__c,'Grouped revenue for April should be populated with correct value');

	serviceUnderTest.reCalculateRetainedIncremental(lineItems);
	System.assertEquals(1, lineItems.size(), 'Returned wrong number of Opp Line Items');
	System.assertEquals(lineItems[0].X3MonthAverageActual__c, 1000.0, 'Incorrect 3 month average value');
	System.assert(lineItems[0].IncrementalRevenue__c > 0, 'IncrementalRevenue__c should be greater than 0');
	List<OpportunityLineItem> reClassifiedItems = serviceUnderTest.calculateClassification(lineItems,true);
	System.assertEquals(ProductRevenueService.CLASSIFICATION_NEW_BUSINESS, reClassifiedItems.get(0).Classification__c, 'Opp line is set to match the unique id of customer revenue record. The last 12 month value is greater than 0 and the Incremental Revenue is greater than 0, so should be Growth');
	Test.stopTest();
}

	@isTest
	private static void testGetSumOfPastTwelveMonths() {
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0]; 
		Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];
		GroupedAccountProductRevenue__c groupedRev2023 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
		FinancialYear__c = 2023, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2023'),
		Rev1__c = 1000,Rev2__c = 1000,Rev3__c = 1000,Rev4__c = 1000,
		Rev5__c = 1000,Rev6__c = 1000,Rev7__c = 5000,Rev8__c = 5000,
		Rev9__c = 5000,Rev10__c = 5000,Rev11__c = 5000,Rev12__c = 5000);

		GroupedAccountProductRevenue__c groupedRev2024 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
		FinancialYear__c = 2024, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2024'),
		Rev1__c = 5000,Rev2__c = 2500,Rev3__c = 0,Rev4__c = 0,
		Rev5__c = 0,Rev6__c = 0,Rev7__c = 5000,Rev8__c = 5000,
		Rev9__c = 5000,Rev10__c = 5000,Rev11__c = 5000,Rev12__c = 5000);

		ProductRevenueService serviceUnderTest = new ProductRevenueService();
		Date dateOfTest = Date.newInstance(2024, 2, 28);
		serviceUnderTest.revenueCalculationContextDate = dateOfTest;

		serviceUnderTest.groupedRevenues.put(groupedRev2023.UID__c,groupedRev2023);
		serviceUnderTest.groupedRevenues.put(groupedRev2024.UID__c,groupedRev2024);
		// need past 12 months sales
		// only want jan 2024, as test date of is on feb 2024
		Double expectedResult = groupedRev2024.Rev1__c;
		// want feb 2023 to dec 2023
		expectedResult += groupedRev2023.Rev2__c + groupedRev2023.Rev3__c + groupedRev2023.Rev4__c + groupedRev2023.Rev5__c + groupedRev2023.Rev6__c
			+ groupedRev2023.Rev7__c + groupedRev2023.Rev8__c + groupedRev2023.Rev9__c + groupedRev2023.Rev10__c + groupedRev2023.Rev11__c + groupedRev2023.Rev12__c;

		Double testResult = serviceUnderTest.getSumOfPastTwelveMonths(account.Id, prod.Id, System.today());
		System.assertEquals(expectedResult,testResult);
	}

	@IsTest
	private static void testCalculateMissingGroupedRevenues() {
		// =====================================
		// Data Preparation
		// =====================================
		Date dateOfTest = Date.newInstance(2024, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account parentAcc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		AccountRelationship__c accRelation = new AccountRelationship__c(ParentAccount__c = parentAcc.Id, RelatedAccount__c = account.Id, Relationship__c='OPC');

		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		oppRec.AccountId = account.Id;
		oppRec.DoNotUseAccountHierarchy__c = false;
		Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];

		Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
		budgrev.uid__c = ProductRevenueService.getUID(budgrev);
		budgrev = (Budget_and_Revenue__c)ApplicationTestDataFactory.setUnwritableFields(budgrev, new Map<String, Object>{
			'uid__c' => ProductRevenueService.getUID(budgrev)
		});
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
		budgrevp.uid__c = ProductRevenueService.getUID(budgrevp);
		budgrevp = (Budget_and_Revenue__c)ApplicationTestDataFactory.setUnwritableFields(budgrevp, new Map<String, Object>{
			'uid__c' => ProductRevenueService.getUID(budgrevp)
		});

		Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
		TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
		oli1 = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oli1, new Map<String, Object>{
			'Annualised_Value__c' => 5000,
			'Product2Id' => prod.Id
		});
		oli1.Product2 = prod;
		oli1.Opportunity = oppRec;
		APR__c apr = new APR__c(Legal_Entity_Name_LookUp__c = account.Id,MHS_Confirmed_Rate__c=0.10);
		ProductRevenueService serviceUnderTest = ProductRevenueService.newInstance();
		serviceUnderTest.revenueCalculationContextDate = dateOfTest;


		// =====================================
		// Stubbing
		// =====================================
		ProductRelationshipsSelector relatedProductSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class);
		GroupedAccountProductRevenueSelector groupedRevenueSelector = (GroupedAccountProductRevenueSelector)MockUtility.mockSelector(GroupedAccountProductRevenueSelector.class);
		OpportunityLineItemSelector lineItemSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
		APRsSelector aprSelector = (APRsSelector)MockUtility.mockSelector(APRsSelector.class);
		BudgetAndRevenueSelector revenueSelector = (BudgetAndRevenueSelector)MockUtility.mockSelector(BudgetAndRevenueSelector.class);
		AccountRelationshipSelector arSelector = (AccountRelationshipSelector)MockUtility.mockSelector(AccountRelationshipSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(relatedProductSelector.selectByParent((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<ProductRelationship__c>());
		MockUtility.Mocks.when(groupedRevenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,GroupedAccountProductRevenue__c>());
		MockUtility.Mocks.when(revenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Budget_and_Revenue__c>{budgrev.Id => budgrev, budgrevp.Id => budgrevp});
		MockUtility.Mocks.when(lineItemSelector.selectByOPCCalculationOpportunityIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oli1});
		//MockUtility.Mocks.when(aprSelector.selectByAccount((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<APR__c>{apr});
		MockUtility.Mocks.when(arSelector.selectByOPCParentEndDateInFuture((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<AccountRelationship__c>{accRelation});
		MockUtility.Mocks.stopStubbing();
		Test.startTest();
		List<OpportunityLineItem> lineItems = serviceUnderTest.getProductLineItemsForOpportunities(new Set<Id>{oppRec.Id});
		Map<String,GroupedAccountProductRevenue__c> reCalculatedRevenues = serviceUnderTest.reCalculateGroupRevenuesForLineItems(lineItems);
		System.assertEquals(6,reCalculatedRevenues.size(),'Grouped revenue for past two years should be created');
		//System.assertEquals(budgrev.Apr_Revenue_Amount__c,reCalculatedRevenues.values()[0].Rev4__c,'Grouped revenue for April should be populated with correct value');

		serviceUnderTest.reCalculateRetainedIncremental(lineItems);
		System.assertEquals(1, lineItems.size(), 'Returned wrong number of Opp Line Items');
		System.assertEquals(lineItems[0].X3MonthAverageActual__c, 1000.0, 'Incorrect 3 month average value');
		System.assert(lineItems[0].IncrementalRevenue__c > 0, 'IncrementalRevenue__c should be greater than 0');
		List<OpportunityLineItem> reCalculatedOppLines = serviceUnderTest.calculateClassification(lineItems,true);
		System.assertEquals(ProductRevenueService.CLASSIFICATION_NEW_BUSINESS, reCalculatedOppLines.get(0).Classification__c, 'Opp line is set to match the unique id of customer revenue record. The last 12 month value is greater than 0 and the Incremental Revenue is greater than 0, so should be Growth');
		Test.stopTest();
	}
}