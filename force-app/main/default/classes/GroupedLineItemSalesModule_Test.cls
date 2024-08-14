/**
 * @description Test class to cover GroupedLineItemSalesModule
 * @author Ken McGuire
 * @date 2023-11-20
 * @changelog
 * 2024-07-12modify for line items of closed opportunities 
 */
@IsTest
public class GroupedLineItemSalesModule_Test {
	@IsTest
	private static void testAfterInsertPerformRevenueUpdates() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];
	 	Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry= ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];
		
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
		oli1 = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oli1,
				new Map<String, Object>{'Opportunity_Stage__c' => 'Identify'});
		List<OpportunityLineItem> records = new List<OpportunityLineItem>{oli1};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		Test.startTest();
		GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();
		module.onAfterInsert(records, mockUow);
		Test.stopTest();
	}
	
	@IsTest
	static void testAfterUpdatePerformRevenueUpdates() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];

	 	Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry= ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];
		
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
		oli1 = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oli1,
				new Map<String, Object>{'Opportunity_Stage__c' => 'Identify'});
		List<OpportunityLineItem> records = new List<OpportunityLineItem>{oli1};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		Test.startTest();
		GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();
		module.onAfterUpdate(records, new Map<Id,OpportunityLineItem>{oli1.Id => oli1},mockUow);
		Test.stopTest();
	}

	@IsTest
	static void testAfterUpdatePerformScheduleUpdates() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];
	 	Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry= ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];

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

		OpportunityLineItem newOli = new OpportunityLineItem(Id = fflib_IDGenerator.generate(OpportunityLineItem.SObjectType), OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				Product2Id = prod.Id,TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addYears(2));
		newOli = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(newOli,
				new Map<String, Object>{
						'Opportunity_Stage__c' => 'Closed Won',
						'Opportunity.AccountId' => account.Id,
						'Product2.Id' => prod.Id
				});
		newOli.Product2 = prod;
		newOli.Opportunity = oppRec;
		OpportunityLineItem oldOli = new OpportunityLineItem(Id = newOli.Id, Product2Id = prod.Id,OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest.addDays(5),Contract_End_Date__c = dateOfTest.addDays(8));
		oldOli = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oldOli,
				new Map<String, Object>{
						'Opportunity_Stage__c' => 'Closed Won',
						'Opportunity.AccountId' => account.Id,
						'Product2.Id' => prod.Id
				});

		List<OpportunityLineItem> records = new List<OpportunityLineItem>{newOli};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		OpportunityLineItemSelector oppProdSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
		GroupedAccountProductRevenueSelector groupedRevenueSelector = (GroupedAccountProductRevenueSelector)MockUtility.mockSelector(GroupedAccountProductRevenueSelector.class);
		GroupedRevenueScheduleSelector scheduleSelector = (GroupedRevenueScheduleSelector)MockUtility.mockSelector(GroupedRevenueScheduleSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(oppProdSelector.selectByOpportunity((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{newOli});
		MockUtility.Mocks.when(groupedRevenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,GroupedAccountProductRevenue__c>(new List<GroupedAccountProductRevenue__c>{groupedRev2023,groupedRev2024}));
		MockUtility.Mocks.when(oppProdSelector.selectByOPCCalculationOpportunityIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{newOli});
		MockUtility.Mocks.when(scheduleSelector.selectByOpportunityProductIds((Set<String>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<GroupedRevenueSchedule__c>());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();
		module.onAfterUpdate(records, new Map<Id,OpportunityLineItem>{oldOli.Id => oldOli},mockUow);
		Test.stopTest();

		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerNew((List<SObject>)fflib_Match.anyObject());
	}
	
	@IsTest
	private static void testAfterInsertItemPerformRevenueUpdates() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];
		
	 	Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry= ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
		oli1 = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oli1,
				new Map<String, Object>{'Opportunity_Stage__c' => 'Closed Won','CloseDate' => Date.today()});
		List<OpportunityLineItem> records = new List<OpportunityLineItem>{oli1};


		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		Test.startTest();
		GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();
		module.onAfterInsert(records, mockUow);
		Test.stopTest();
	}

}