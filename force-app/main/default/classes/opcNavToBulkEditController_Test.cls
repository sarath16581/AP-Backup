@isTest
public class opcNavToBulkEditController_Test {
   

    @isTest
    static void testGetOpportunity() {
        // =====================================
        // Data Preparation
        // =====================================
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        // =====================================
        // Stubbing
        // =====================================
        OpportunitiesSelector oppSelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(oppSelector.selectbyId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,Opportunity>{oppRec.id =>oppRec});
        MockUtility.Mocks.stopStubbing();
        // Retrieve the Opportunity using the controller
        Test.startTest();
        Opportunity result = opcNavToBulkEditController.getOpportunity(oppRec.Id);
        Test.stopTest();

        // Verify the Opportunity is returned correctly
        System.assert(result != null, 'Expected Opportunity to be returned');
        System.assertEquals('test opportunity 1', result.Name, 'Opportunity name mismatch');
    }

    @isTest
    static void testRecalculateRevenueSuccess() {
        // =====================================
        // Data Preparation
        // =====================================
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        // =====================================
        // Stubbing
        // =====================================
        OpportunitySelector oppSelector = (OpportunitySelector)MockUtility.mockSelector(OpportunitySelector.class);
        GroupedLineItemSalesModule salesModule = (GroupedLineItemSalesModule)MockUtility.mockUtility(GroupedLineItemSalesModule.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(oppSelector.selectbyId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,Opportunity>{oppRec.id =>oppRec});
        //MockUtility.Mocks.when(salesModule.performRevenueUpdates((Set<Id>)fflib_Match.anyObject(),(ApplicationUnitOfWork)fflib_Match.anyObject()));
        MockUtility.Mocks.stopStubbing();

        // Test recalculateRevenue method
        Test.startTest();
        Boolean result = opcNavToBulkEditController.recalculateRevenue(oppRec.Id);
        Test.stopTest();
		List<SObjectType> obTypes = opcNavToBulkEditController.getUnitOfWorkSObjectTypes();
        // Verify the result
        System.assert(result, 'Expected revenue recalculation to be successful');
    }
}