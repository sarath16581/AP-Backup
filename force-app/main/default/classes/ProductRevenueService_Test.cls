/**************************************************
Type:         Test Class for ProductRevenueService
History:
--------------------------------------------------
2023-09-21    Ken McGuire - Created
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
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        oppRec.AccountId = account.Id;
        Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

        
        Budget_and_Revenue__c budgrev = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year(),true)[0];
        budgrev.uid__c = ProductRevenueService.getUID(budgrev);
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
        budgrevp.uid__c = ProductRevenueService.getUID(budgrevp);
        
        PricebookEntry pbEntry = ApplicationTestDataFactory.getPriceBookEntries(1,prod.Id,true)[0];
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
		oli1.Product2 = prod;
		oli1.Opportunity = oppRec;
        APR__c apr = new APR__c(Legal_Entity_Name_LookUp__c = account.Id,MHS_Confirmed_Rate__c=0.10);
		ProductRevenueService serviceUnderTest = ProductRevenueService.newInstance();
        serviceUnderTest.calculationDate = dateOfTest;

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
        OpportunityLineItemSelector lineItemSelector =  (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
        APRsSelector  aprSelector =  (APRsSelector)MockUtility.mockSelector(APRsSelector.class);
        BudgetAndRevenueSelector revenueSelector = (BudgetAndRevenueSelector)MockUtility.mockSelector(BudgetAndRevenueSelector.class);
    	MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(relatedProductSelector.selectByParent((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<ProductRelationship__c>());
        MockUtility.Mocks.when(groupedRevenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,GroupedAccountProductRevenue__c>(new List<GroupedAccountProductRevenue__c>{groupedRev2023,groupedRev2024}));
        MockUtility.Mocks.when(revenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Budget_and_Revenue__c>{budgrev.Id => budgrev, budgrevp.Id => budgrevp});
        MockUtility.Mocks.when(lineItemSelector.selectByOpportunity((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oli1});
        MockUtility.Mocks.when(aprSelector.selectByAccount((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<APR__c>{apr});
        MockUtility.Mocks.stopStubbing();
        Test.startTest();
        	List<GroupedAccountProductRevenue__c> reCalculatedRevenues =  serviceUnderTest.reCalculateGroupRevenuesForOpportunities(new Set<Id>{oppRec.Id});
            System.assertEquals(2,reCalculatedRevenues.size(),'Grouped revenue for past two years should be created');
        	System.assertEquals(budgrev.Apr_Revenue_Amount__c,reCalculatedRevenues[0].Rev4__c,'Grouped revenue for April should be populated with correct value');
        	
        Test.stopTest();

    }
    
    @isTest
    private static void testGetSumOfPastTwelveMonths() {
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];        
        Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];
        GroupedAccountProductRevenue__c groupedRev2023 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
           	FinancialYear__c = 2023, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2023'),
            Rev1__c = 11,Rev2__c = 22,Rev3__c = 33,Rev4__c = 44,
            Rev5__c = 55,Rev6__c = 66,Rev7__c = 77,Rev8__c = 88,
            Rev9__c = 99,Rev10__c = 110,Rev11__c = 220,Rev12__c = 330);
		
		GroupedAccountProductRevenue__c groupedRev2024 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
           	FinancialYear__c = 2024, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2024'),
            Rev1__c = 440,Rev2__c = 550,Rev3__c = 660,Rev4__c = 770,
            Rev5__c = 880,Rev6__c = 990,Rev7__c = 1100,Rev8__c = 2200,
            Rev9__c = 3300,Rev10__c = 4400,Rev11__c = 5500,Rev12__c = 6600);
        
		ProductRevenueService serviceUnderTest = new ProductRevenueService();
		Date dateOfTest = Date.newInstance(2023, 11, 30);
		serviceUnderTest.calculationDate = dateOfTest;

		serviceUnderTest.groupedRevenues.put(groupedRev2023.UID__c,groupedRev2023);
		serviceUnderTest.groupedRevenues.put(groupedRev2024.UID__c,groupedRev2024);
		// need past 12 months sales
		//July through December fall in the fiscal year 2023 of the fy=2024 record. December and the first months are in the future so take five records
		Double expectedResult = groupedRev2024.Rev11__c+groupedRev2024.Rev10__c+groupedRev2024.Rev9__c+groupedRev2024.Rev8__c+groupedRev2024.Rev7__c;
		// jan - June fall in the fiscal year 2023 of the fy - 2023 record. Add these six.
		expectedResult += groupedRev2023.Rev6__c+groupedRev2023.Rev5__c+groupedRev2023.Rev4__c+groupedRev2023.Rev3__c+groupedRev2023.Rev2__c+groupedRev2023.Rev1__c;
		// December falls in the fiscal year 2022 of the fy=2023, add this month.
		expectedResult += groupedRev2023.Rev12__c;

		Double testResult = serviceUnderTest.getSumOfPastTwelveMonths(account.Id, prod.Id);
		System.assertEquals(expectedResult,testResult);
	}
}