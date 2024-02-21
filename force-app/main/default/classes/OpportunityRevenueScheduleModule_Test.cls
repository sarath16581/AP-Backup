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

		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		OpportunityLineItemSelector oppProdSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(oppProdSelector.selectByOpportunity((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oppProd});
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