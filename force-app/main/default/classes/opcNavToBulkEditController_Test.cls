@IsTest
private class opcNavToBulkEditController_Test {
	/**
	 * @description test the recalculateRevenue method. Only asserting the result as the actual logic is being tested ing ProductRevenueService_Test abd GroupedLineItemSalesModule_Test
	 */
	@IsTest
	private static void testRecalculateRevenue() {
		Date dateOfTest = Date.newInstance(2023, 4, 1);
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

		PricebookEntry pbEntry = ApplicationTestDataFactory.getPriceBookEntries(1,prod.Id,true)[0];
		OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = oppRec.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
				TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = dateOfTest,Contract_End_Date__c = dateOfTest.addDays(3));

		OpportunitiesSelector oppSelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(oppSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,Opportunity>{oppRec.Id=>oppRec});
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		Boolean result = opcNavToBulkEditController.recalculateRevenue(oppRec.Id);
		System.assert(result, 'GroupedLineItemSalesModule.performRevenueUpdates failed to perform expected updates.');

		Opportunity oppResult = opcNavToBulkEditController.getOpportunity(oppRec.Id);
		System.assertEquals(oppRec.Id, oppResult.Id, 'selector returned unexpected result.');
		Test.stopTest();
	}
}