/**************************************************
Type:         Test class for OpportunityRevenueReportController
History:
--------------------------------------------------
2024-01-22    Ken McGuire - Created
**************************************************/
@IsTest
private class OpportunityRevenueReportController_Test {
	@IsTest
	private static void testGetRevenueData() {
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Account parentAcc = ApplicationTestDataFactory.getAccounts(1, true)[0];

		AccountRelationship__c accRelation = new AccountRelationship__c(ParentAccount__c = parentAcc.Id, RelatedAccount__c = acc.Id, Relationship__c='OPC');

		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, acc.Id, true)[0];
		oppRec.AccountId = acc.Id;

		Product2 prod =  ApplicationTestDataFactory.getProducts(1,true)[0];

		PricebookEntry pbe = ApplicationTestDataFactorySales.getPriceBookEntries(1, Test.getStandardPricebookId(), prod.Id, true).get(0);

		OpportunityLineItem oppProd = ApplicationTestDataFactory.getOpportunityLineItems(1, oppRec.Id, pbe.Id, true).get(0);
		oppProd.Quantity = 1;
		oppProd = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(oppProd, new Map<String, Object>{'Product2Id' => prod.Id, 'Opportunity' => oppRec});

		OpportunityLineItemSelector oppProdSelector = (OpportunityLineItemSelector)MockUtility.mockSelector(OpportunityLineItemSelector.class);
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		AccountRelationshipSelector arSelector = (AccountRelationshipSelector)MockUtility.mockSelector(AccountRelationshipSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(oppProdSelector.selectByOpportunity((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<OpportunityLineItem>{oppProd});
		MockUtility.Mocks.when(accountsSelector.search((Map<String, Object>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(), (String)fflib_Match.anyObject(), (Schema.SObjectField)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenReturn(new List<Account>{acc});
		MockUtility.Mocks.when(arSelector.selectByParent((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<AccountRelationship__c>{accRelation});
		MockUtility.Mocks.when(arSelector.selectByOPCParentEndDateInFuture((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new List<AccountRelationship__c>{accRelation});
		MockUtility.Mocks.stopStubbing();

		List<OpportunityRevenueReportController.RevenueData> revData = OpportunityRevenueReportController.getRevenueData(String.valueOf(oppRec.Id));
		System.assert(!revData.isEmpty(), 'Controller failed to construct Revenue Data');
		System.assertEquals(acc.Name, revData.get(0).companyName, 'Returned revenue data did not match the intended.');
	}
}