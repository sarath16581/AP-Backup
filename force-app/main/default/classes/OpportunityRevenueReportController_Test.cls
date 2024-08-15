/**************************************************
Type: Test class for OpportunityRevenueReportController
History:
--------------------------------------------------
2024-01-22Ken McGuire - Created
2024-07-31 		Ken McGuire	- added refresh revenue capability.
**************************************************/
@IsTest
private class OpportunityRevenueReportController_Test {
	@IsTest
	private static void testGetRevenueDataWithAccountHierarchy() {
		Account parentAcc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account relatedAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account childAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		childAccount.ParentId = parentAcc.Id;

		AccountRelationship__c accRelation = new AccountRelationship__c(ParentAccount__c = parentAcc.Id, RelatedAccount__c = relatedAccount.Id, Relationship__c='OPC');

		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, parentAcc.Id, true)[0];
		oppRec.AccountId = parentAcc.Id;
		oppRec.DoNotUseAccountHierarchy__c = false;

		Product2 prod =ApplicationTestDataFactory.getProducts(1,true)[0];

	 	Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pbe= ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, prod.Id, true)[0];

		OpportunityLineItem oppProd = ApplicationTestDataFactory.getOpportunityLineItems(1, oppRec.Id, pbe.Id, true).get(0);
		oppProd.Quantity = 1;
		oppProd = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oppProd, new Map<String, Object>{'Product2Id' => prod.Id, 'Opportunity' => oppRec, 'Product2'=>prod});

		OpportunityLineItemSelector oppProdSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
		ProductRevenueService revenueService = (ProductRevenueService)MockUtility.mockUtility(ProductRevenueService.class);
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		AccountRelationshipSelector arSelector = (AccountRelationshipSelector)MockUtility.mockSelector(AccountRelationshipSelector.class);
		OpportunitiesSelector oppSelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(oppProdSelector.selectByOpportunity((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oppProd});
		MockUtility.Mocks.when(accountsSelector.search((Map<String, Object>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(), (String)fflib_Match.anyObject(), (Schema.SObjectField)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenReturn(new List<Account>{parentAcc});
		MockUtility.Mocks.when(arSelector.selectByParent((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<AccountRelationship__c>{accRelation});
		MockUtility.Mocks.when(arSelector.selectByOPCParentEndDateInFuture((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<AccountRelationship__c>{accRelation});
		MockUtility.Mocks.when(oppSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,Opportunity>{oppRec.Id => oppRec});
		MockUtility.Mocks.when(revenueService.loadOpportunityInfo((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,Opportunity>{oppRec.Id => oppRec});
		MockUtility.Mocks.stopStubbing();

		List<OpportunityRevenueReportController.RevenueData> revData = OpportunityRevenueReportController.getRevenueData(String.valueOf(oppRec.Id));
		System.assert(!revData.isEmpty(), 'Controller failed to construct Revenue Data');
		System.assertEquals(parentAcc.Name, revData.get(0).companyName, 'Returned revenue data did not match the intended.');
	}
}