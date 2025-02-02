/**************************************************
Type:         Provides test converage  for GroupedAccountProductRevenueSelector
@test OppProductRevForecastSelector_Test
History:
--------------------------------------------------
2023-09-21    Ken McGuire - Created
**************************************************/
@IsTest
public with sharing class GroupedAccountProductRevSelector_Test {
	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {

		// Testing
		Test.startTest();

		GroupedAccountProductRevenueSelector selector = GroupedAccountProductRevenueSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom GroupedAccountProductRevenue__c\\b').matcher(soql).find(), 'Resulting query does not select from GroupedAccountProductRevenue__c');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(GroupedAccountProductRevenue__c.Rev1__c) + '\\b').matcher(soql).find(), 'Rev1__c field does not exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(GroupedAccountProductRevenue__c.AnchorOrganisation__c) + '\\b').matcher(soql).find(), 'AnchorOrganisation__c field does not exists in query');

		Test.stopTest();

	}

	/**
	 * Test:
	 * Executes a query to ensure it returns expected results
	 */
	@IsTest
	private static void testSelectorIntegration() {

		// Data Preparation
		MockUtility.disableTriggerExecution();

		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;

		//Create your product
		Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
		insert prod1;

		// Create test data
		GroupedAccountProductRevenue__c groupedRev2023 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod1.Id,
				FinancialYear__c = 2023, UID__c = ProductRevenueService.getUID(account.Id,prod1.Id,'2023'),
				Rev1__c = 11,Rev2__c = 22,Rev3__c = 33,Rev4__c = 44,
				Rev5__c = 55,Rev6__c = 66,Rev7__c = 77,Rev8__c = 88,
				Rev9__c = 99,Rev10__c = 110,Rev11__c = 220,Rev12__c = 330);
        List<GroupedAccountProductRevenue__c> gaprRecs =  new List<GroupedAccountProductRevenue__c>{groupedRev2023};
		insert gaprRecs;

		// Testing
		Test.startTest();

		GroupedAccountProductRevenueSelector selector = GroupedAccountProductRevenueSelector.newInstance();
		Map<Id, GroupedAccountProductRevenue__c> results = selector.selectById(new Set<Id> {gaprRecs[0].Id});
		System.assert(results.size() >= 1, 'Expected result size greater than or equal to 1');

		GroupedAccountProductRevenueSelector selectorLimit = GroupedAccountProductRevenueSelector.newInstance(1);
		Map<Id, GroupedAccountProductRevenue__c> resultsLimit = selectorLimit.selectById(new Set<Id> {gaprRecs[0].Id});
		System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

		GroupedAccountProductRevenueSelector selector3 = GroupedAccountProductRevenueSelector.newInstance(1);
		Map<Id, GroupedAccountProductRevenue__c> result3 = selector3.selectByAnchorOrganisationAndProductForFY(new Set<Id> {account.Id}, new Set<Id>{prod1.Id}, 2023);
		System.assertEquals(1, result3.size(), 'Expected result size of 1');

		GroupedAccountProductRevenueSelector selector4 = GroupedAccountProductRevenueSelector.newInstance(1);
		String targetUID = ProductRevenueService.getUID(account.Id,prod1.Id,String.valueOf(2023));
		Map<Id, GroupedAccountProductRevenue__c> result4 = selector4.selectByUniqueIds(new Set<String>{targetUID});
		System.assertEquals(1, result4.size(), 'Expected result size of 1');
		System.assertEquals(targetUID, result4.values().get(0).UID__c, 'Selector did not select by the correct UID');

		GroupedAccountProductRevenueSelector selector5 = GroupedAccountProductRevenueSelector.newInstance(1);
		Map<Id, GroupedAccountProductRevenue__c> result5 = selector5.selectByAnchorOrganisationIds(new Set<Id>{account.Id});
		System.assertEquals(1, result5.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}