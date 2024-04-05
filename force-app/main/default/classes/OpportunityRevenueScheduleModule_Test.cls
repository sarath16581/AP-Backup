/***
 * @author Steve L.
 * @date 2024-02-12
 * @description Test Class covering OpportunityRevenueScheduleModule
 * @changelog
 * 2024-02-12- Steve L - Created
 */

@IsTest
private class OpportunityRevenueScheduleModule_Test {
	@IsTest
	private static void testAfterUpdateCreateUpdateRevenueSchedules() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		oppRec.AccountId = account.Id;

		Opportunity changedOppRec = oppRec.clone(true,true);
		changedOppRec.StageName = 'Closed Won';

		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

		PricebookEntry pbe = ApplicationTestDataFactorySales.getPriceBookEntries(1, Test.getStandardPricebookId(), prod.Id, true).get(0);

		OpportunityLineItem oppProd = ApplicationTestDataFactory.getOpportunityLineItems(1, oppRec.Id, pbe.Id, true).get(0);
		oppProd.Quantity = 1;
		oppProd = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oppProd, new Map<String, Object>{'Product2Id' => prod.Id, 'Opportunity' => oppRec});

		GroupedAccountProductRevenue__c groupedRev2023 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
				FinancialYear__c = 2023, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2023'),
				Rev1__c = 11,Rev2__c = 22,Rev3__c = 33,Rev4__c = 44,
				Rev5__c = 55,Rev6__c = 66,Rev7__c = 77,Rev8__c = 88,
				Rev9__c = 99,Rev10__c = 110,Rev11__c = 220,Rev12__c = 330);
		ApplicationTestDataFactory.generateRecordIds(new List<GroupedAccountProductRevenue__c> {groupedRev2023});
		GroupedRevenueSchedule__c revSch = new  GroupedRevenueSchedule__c(GroupedAccountProductRevenue__c = groupedRev2023.Id, OpportunityProduct__c = oppProd.Id);

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		OpportunityLineItemSelector oppProdSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
		GroupedAccountProductRevenueSelector gapSelector = (GroupedAccountProductRevenueSelector) MockUtility.mockSelector(GroupedAccountProductRevenueSelector.class);
		GroupedRevenueScheduleSelector greSelector = (GroupedRevenueScheduleSelector) MockUtility.mockSelector(GroupedRevenueScheduleSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(oppProdSelector.selectByOpportunity((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oppProd});
		MockUtility.Mocks.when(oppProdSelector.selectByOPCCalculationOpportunityIds((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oppProd});
		MockUtility.Mocks.when(gapSelector.selectByUniqueIds((Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, GroupedAccountProductRevenue__c>{groupedRev2023.Id=>groupedRev2023});
		MockUtility.Mocks.when(greSelector.selectByOpportunityProductIds((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<GroupedRevenueSchedule__c>{revSch});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		OpportunityRevenueScheduleModule module = OpportunityRevenueScheduleModule.newInstance();
		module.onAfterUpdate(new List<Opportunity>{changedOppRec}, new Map<Id,Opportunity>{oppRec.Id=>oppRec}, mockUow);
		Test.stopTest();

		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 2)).registerNew((List<SObject>)fflib_Match.anyObject());
	}

}