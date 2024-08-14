/**
 * @description test class fro the product schedule service
 * @author Ken McGuire
 * @date 2024-01-17
 * @changelog
*/
@isTest
public class ProductScheduleService_Test {
	@isTest 
	public static void testCreateRevenueSchedules() {
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
		'UniqueId__c' => ProductRevenueService.getUID(budgrev)
		});
		Budget_and_Revenue__c budgrevp = ApplicationTestDataFactory.getBudgetAndRevenue(1,account.Id,prod.Id,dateOfTest.year()-1,true)[0];
		budgrevp.uid__c = ProductRevenueService.getUID(budgrevp);
		budgrevp = (Budget_and_Revenue__c)ApplicationTestDataFactory.setUnwritableFields(budgrevp, new Map<String, Object>{
		'UniqueId__c' => ProductRevenueService.getUID(budgrevp)
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
		ProductRevenueService revenueServiceUnderTest = ProductRevenueService.newInstance();
		revenueServiceUnderTest.revenueCalculationContextDate = dateOfTest;

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
		GroupedRevenueScheduleSelector scheduleSelector = (GroupedRevenueScheduleSelector)MockUtility.mockSelector(GroupedRevenueScheduleSelector.class);
		GroupedAccountProductRevenueSelector revenueSelector = (GroupedAccountProductRevenueSelector)MockUtility.mockSelector(GroupedAccountProductRevenueSelector.class);
		OpportunityLineItemSelector lineItemSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(revenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, GroupedAccountProductRevenue__c>{groupedRev2023.Id=>groupedRev2023,groupedRev2024.Id=>groupedRev2024});
		MockUtility.Mocks.when(scheduleSelector.selectByOpportunityProductIds((Set<String>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<GroupedRevenueSchedule__c>()); 
		MockUtility.Mocks.when(lineItemSelector.selectByOPCCalculationOpportunityIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oli1});
		MockUtility.Mocks.stopStubbing();
		ProductScheduleService scheduleServiceUnderTest = ProductScheduleService.newInstance();
		scheduleServiceUnderTest.productRevenueServiceInstance = revenueServiceUnderTest;

		Test.startTest();
		List<GroupedRevenueSchedule__c> revenueSchedules = scheduleServiceUnderTest.createUpdateRevenueSchedules(new Set<Id>{oppRec.id});
		System.assertEquals(1, revenueSchedules.size(), 'createUpdateRevenueSchedules did not generate correct number of schedules');
		Double totalSchedules = 0;
		for (GroupedRevenueSchedule__c schedule : revenueSchedules) {
			for (Integer month=1; month<=12; month++) {
				Double value = (Double)schedule.get('For'+String.valueOf(month)+'__c');
				totalSchedules = totalSchedules + value;
			}
		}
		System.assertEquals(88, Math.round(totalSchedules), 'total schedule did not add up to 88');
		Test.stopTest();
	}

	@isTest
	public static void testRevenueScheduleCalculator() {
		Date contractStart = Date.newInstance(2023, 3, 15);
		Date contractEnd = Date.newInstance(2024,1,15);

		ProductScheduleService.RevenueScheduleCalculator calculator = new ProductScheduleService.RevenueScheduleCalculator(contractStart,contractEnd, ProductScheduleService.newInstance().defaultRevenueAllocation );

		Boolean insideTestAtStart = calculator.isYearMonthInRange(2023, 3);
		Boolean insideTestAtEnd = calculator.isYearMonthInRange(2024, 1);
		Boolean insideTestMiddle = calculator.isYearMonthInRange(2023, 6);
		Boolean outsideBefore = calculator.isYearMonthInRange(2023, 2);
		Boolean outsideAfter = calculator.isYearMonthInRange(2024, 2);
		System.assertEquals(insideTestAtStart,true);
		System.assertEquals(insideTestAtEnd,true);
		System.assertEquals(insideTestMiddle,true);
		System.assertEquals(outsideBefore,false);
		System.assertEquals(outsideAfter,false);
	}

}