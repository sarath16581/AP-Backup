/**
 * @description Test class to cover GroupedLineItemSalesModule
 * @author Ken McGuire
 * @date 2023-11-20
 * @changelog
 */
@IsTest
public class GroupedLineItemSalesModule_Test {
	@IsTest
	private static void testAfterInsertPerformRevenueUpdates() {
        Date dateOfTest = Date.newInstance(2023, 4, 1);
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];        
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];
        
        PricebookEntry pbEntry = ApplicationTestDataFactory.getPriceBookEntries(1,prod.Id,true)[0];
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
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
        Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];
        
        PricebookEntry pbEntry = ApplicationTestDataFactory.getPriceBookEntries(1,prod.Id,true)[0];
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));
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
}