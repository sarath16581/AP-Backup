@isTest
public class ProductScheduleService_Test {
	@isTest 
    public static void testCreateRevenueSchedules() {
        // =====================================
		// Data Preparation
		// =====================================
		Date dateOfTest = Date.newInstance(2023, 4, 1);
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];        
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        oppRec.AccountId = account.Id;
        Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];
        PricebookEntry pbEntry = ApplicationTestDataFactory.getPriceBookEntries(1,prod.id,true)[0];
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
        TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(365));
		oli1.Product2 = prod;
		oli1.Opportunity = oppRec;
        ProductScheduleService serviceUnderTest = ProductScheduleService.newInstance();
        
        // =====================================
		// Stubbing
		// =====================================
		GroupedRevenueScheduleSelector scheduleSelector = (GroupedRevenueScheduleSelector)MockUtility.mockSelector(GroupedRevenueScheduleSelector.class);
        GroupedAccountProductRevenueSelector revenueSelector = (GroupedAccountProductRevenueSelector)MockUtility.mockSelector(GroupedAccountProductRevenueSelector.class);
        OpportunityLineItemSelector lineItemSelector =  (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);

    	MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(revenueSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,GroupedAccountProductRevenue__c>());
        MockUtility.Mocks.when(scheduleSelector.selectByOpportunityProductIds((Set<String>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<GroupedRevenueSchedule__c>());  
     	MockUtility.Mocks.when(lineItemSelector.selectByOpportunity((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oli1});
        MockUtility.Mocks.stopStubbing();
        
        Test.startTest();
         	List<GroupedRevenueSchedule__c> revenueSchedules = serviceUnderTest.createUpdateRevenueSchedules(new Set<Id>{oppRec.id});
			System.assertEquals(2, revenueSchedules.size(), 'createUpdateRevenueSchedules did not generate correct number of schedules');
        	Double totalSchedules = 0;
        	for (GroupedRevenueSchedule__c schedule : revenueSchedules) {
            	for (Integer month=1; month<=12; month++) {
                    Double value = (Double)schedule.get('For'+String.valueOf(month)+'__c');
                	totalSchedules = totalSchedules + value;
            	}
            }
			System.assertEquals(100, Math.round(totalSchedules), 'total schedule did not add up to 100');
		Test.stopTest();
    }
    
    @isTest
    public static void testRevenueScheduleCalculator() {
        Date contractStart = Date.newInstance(2023, 3, 15);
        Date contractEnd = Date.newInstance(2024,1,15);
        
        ProductScheduleService.RevenueScheduleCalculator calculator = new ProductScheduleService.RevenueScheduleCalculator(contractStart,contractEnd, ProductScheduleService.newInstance().defaultRevenueAllocation );
        
        Boolean insideTestAtStart = calculator.isYearMonthInRange(2023, 3);
		Boolean insideTestAtEnd =  calculator.isYearMonthInRange(2024, 1);
		Boolean insideTestMiddle =  calculator.isYearMonthInRange(2023, 6);
		Boolean outsideBefore =  calculator.isYearMonthInRange(2023, 2);
		Boolean outsideAfter =  calculator.isYearMonthInRange(2024, 2);
		System.assertEquals(insideTestAtStart,true);
		System.assertEquals(insideTestAtEnd,true);
		System.assertEquals(insideTestMiddle,true);
		System.assertEquals(outsideBefore,false);
		System.assertEquals(outsideAfter,false);
    }

}