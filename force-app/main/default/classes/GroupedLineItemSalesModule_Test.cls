/**
 * @description Test class to cover GroupedLineItemSalesModule
 * @author Ken McGuire
 * @date 2023-11-20
 * @changelog
 */
@IsTest
public class GroupedLineItemSalesModule_Test {
	@IsTest
	static void testAfterInsert() {
        Date dateOfTest = Date.newInstance(2023, 4, 1);
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];        
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];
        
        PricebookEntry pbEntry = ApplicationTestDataFactory.getPriceBookEntries(1,prod.id,true)[0];
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
        


        // =====================================
		// Stubbing
		// =====================================
		ProductRevenueService mockService = (ProductRevenueService)MockUtility.mockUtility(ProductRevenueService.class);
		MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.reCalculateGroupRevenues((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<GroupedAccountProductRevenue__c>());
        MockUtility.Mocks.when(mockService.reCalculateRetainedIncremental()).thenReturn(new List<OpportunityLineItem>{oli1});
		MockUtility.Mocks.stopStubbing();

        Test.startTest();

        	// Given
        	GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();

			// When
        	module.onAfterInsert( new List<OpportunityLineItem>{oli1}, null);

        Test.stopTest();

        // Then ???
    }
    
    @IsTest
	static void testAfterUpdate() {
        Date dateOfTest = Date.newInstance(2023, 4, 1);
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];        
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];
        
        PricebookEntry pbEntry = ApplicationTestDataFactory.getPriceBookEntries(1,prod.id,true)[0];
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
        


        // =====================================
		// Stubbing
		// =====================================
		ProductRevenueService mockService = (ProductRevenueService)MockUtility.mockUtility(ProductRevenueService.class);
		MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.reCalculateGroupRevenues((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<GroupedAccountProductRevenue__c>());
        MockUtility.Mocks.when(mockService.reCalculateRetainedIncremental()).thenReturn(new List<OpportunityLineItem>{oli1});
		MockUtility.Mocks.stopStubbing();

        Test.startTest();

        	// Given
        	GroupedLineItemSalesModule module = GroupedLineItemSalesModule.newInstance();

			// When
        module.onAfterUpdate(new List<OpportunityLineItem>{oli1}, new Map<Id,OpportunityLineItem>{oli1.id => oli1},null);

        Test.stopTest();

        // Then ???
    }
}