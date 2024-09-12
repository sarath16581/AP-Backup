/**
 * @description Test class to cover GroupedLineItemSalesModule
 * @author Ken McGuire
 * @date 2023-11-20
 * @changelog
 * 2024-07-12  modify for line items of closed opportunities 
 */
@IsTest
public class GroupedLineItemSalesModule_Test {
	@IsTest
	private static void testAfterInsertPerformRevenueUpdates() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];        
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];
		Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry  = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];
		
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
		oli1 = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oli1,
				new Map<String, Object>{'Opportunity_Stage__c' => 'Identify'});
		List<OpportunityLineItem> records = new List<OpportunityLineItem>{oli1};
		
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
		ProductRevenueService revenueService = (ProductRevenueService)MockUtility.mockUtility(ProductRevenueService.class);
		
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(revenueService.getProductLineItemsForOpportunities((Set<id>)fflib_Match.anyObject())).thenReturn(records);
		MockUtility.Mocks.when(revenueService.reCalculateGroupRevenuesForLineItems((List<opportunityLineItem>)fflib_Match.anyObject())).thenReturn(new Map<String,GroupedAccountProductRevenue__c>{groupedRev2023.uid__c => groupedRev2023,groupedRev2024.uid__c => groupedRev2024});
		MockUtility.Mocks.stopStubbing();
		
		Test.startTest();
		GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();
		module.onAfterInsert(records, mockUow);
		Test.stopTest();
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow,2)).registerDirty((List<SObject>)fflib_Match.anyObject());
	}
	
	@IsTest
	static void testAfterUpdatePerformRevenueUpdates() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];        
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

	   	Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry  = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];
		
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
		oli1 = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oli1,
				new Map<String, Object>{'Opportunity_Stage__c' => 'Identify'});
		
		List<OpportunityLineItem> records = new List<OpportunityLineItem>{oli1};
			
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
		ProductRevenueService revenueService = (ProductRevenueService)MockUtility.mockUtility(ProductRevenueService.class);
		
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(revenueService.getProductLineItemsForOpportunities((Set<id>)fflib_Match.anyObject())).thenReturn(records);
		MockUtility.Mocks.when(revenueService.reCalculateGroupRevenuesForLineItems((List<opportunityLineItem>)fflib_Match.anyObject())).thenReturn(new Map<String,GroupedAccountProductRevenue__c>{groupedRev2023.uid__c => groupedRev2023,groupedRev2024.uid__c => groupedRev2024});
		MockUtility.Mocks.stopStubbing();
		
		Test.startTest();
		GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();
		module.onAfterUpdate(records, new Map<Id,OpportunityLineItem>{oli1.Id => oli1},mockUow);
		Test.stopTest();
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 2)).registerDirty((List<SObject>)fflib_Match.anyObject());
	}

	@IsTest
	static void testAfterUpdatePerformScheduleUpdates() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];        
		Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry  = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];
		
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

		GroupedRevenueSchedule__c groupedSched2023 = new GroupedRevenueSchedule__c(GroupedAccountProductRevenue__r = groupedRev2023,Opportunity__c =oppRec.id,OpportunityProduct__c = newOli.id);
		GroupedRevenueSchedule__c groupedSched2024 = new GroupedRevenueSchedule__c(GroupedAccountProductRevenue__r = groupedRev2024,Opportunity__c =oppRec.id,OpportunityProduct__c = newOli.id);
		


		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		ProductScheduleService scheduleService = (ProductScheduleService)MockUtility.mockUtility(ProductScheduleService.class);
		
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(scheduleService.createUpdateRevenueSchedules((Map<id,opportunitylineitem>)fflib_Match.anyObject())).thenReturn(new List<GroupedRevenueSchedule__c> {groupedSched2023,groupedSched2024});
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();
		module.onAfterUpdate(records, new Map<Id,OpportunityLineItem>{oldOli.Id => oldOli},mockUow);
		Test.stopTest();
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
	}
	
	@IsTest
	private static void testAfterInsertItemPerformRevenueUpdates() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];        
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];
		
	   	Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbEntry  = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
		oli1 = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oli1,
				new Map<String, Object>{'Opportunity_Stage__c' => 'Closed Won','CloseDate' => Date.today()});
		List<OpportunityLineItem> records = new List<OpportunityLineItem>{oli1};

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

		GroupedRevenueSchedule__c groupedSched2023 = new GroupedRevenueSchedule__c(GroupedAccountProductRevenue__r = groupedRev2023,Opportunity__c =oppRec.id,OpportunityProduct__c = oli1.id);
		GroupedRevenueSchedule__c groupedSched2024 = new GroupedRevenueSchedule__c(GroupedAccountProductRevenue__r = groupedRev2024,Opportunity__c =oppRec.id,OpportunityProduct__c = oli1.id);
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		ProductScheduleService scheduleService = (ProductScheduleService)MockUtility.mockUtility(ProductScheduleService.class);
		
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(scheduleService.createUpdateRevenueSchedules((Map<id,opportunitylineitem>)fflib_Match.anyObject())).thenReturn(new List<GroupedRevenueSchedule__c> {groupedSched2023,groupedSched2024});
		MockUtility.Mocks.stopStubbing();
		
		Test.startTest();
		GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();
		module.onAfterInsert(records, mockUow);
		Test.stopTest();
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow,1)).registerDirty((List<SObject>)fflib_Match.anyObject());
	}

}