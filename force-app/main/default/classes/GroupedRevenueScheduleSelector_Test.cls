/***
 * @author SteveL
 * @date 2024-02-12
 * @group Tests
 * @tag Selector
 * @tag GroupedRevenueSchedule__c SObject
 * @domain Core
 * @description Test Class covering GroupedRevenueScheduleSelector
 * @changelog
 * 2020-2024-02-12 - SteveL - Created
 */
@IsTest
public with sharing class GroupedRevenueScheduleSelector_Test{
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		GroupedRevenueScheduleSelector selector = GroupedRevenueScheduleSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom GroupedRevenueSchedule__c\\b').matcher(soql).find(), 'Resulting query does not select from GroupedRevenueSchedule__c');

		selector = GroupedRevenueScheduleSelector.newInstance();
		qb = selector.newQueryBuilder(new Set<Object>{GroupedRevenueScheduleSelector.Options.WITH_PRODUCT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)OpportunityProduct__r\\..*?\\bfrom GroupedRevenueSchedule__c\\b').matcher(soql).find(), 'Resulting query does not select OpportunityProduct__c fields');

		qb = selector.newQueryBuilder(new Set<Object>{GroupedRevenueScheduleSelector.Options.WITH_REVENUE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)GroupedAccountProductRevenue__r\\..*?\\bfrom GroupedRevenueSchedule__c\\b').matcher(soql).find(), 'Resulting query does not select GroupedAccountProductRevenue__c fields');

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorSpecificMethods() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
		Opportunity oppRec = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
		oppRec.AccountId = account.Id;
		insert oppRec;
		Product2 prod =  ApplicationTestDataFactory.getProducts(1,false)[0];
		insert prod;
		PricebookEntry pbe = ApplicationTestDataFactorySales.getPriceBookEntries(1, Test.getStandardPricebookId(), prod.Id, false).get(0);
		insert pbe;
		OpportunityLineItem oppProd = ApplicationTestDataFactory.getOpportunityLineItems(1, oppRec.Id, pbe.Id, false).get(0);
		oppProd.Quantity = 1;
		insert oppProd;

		GroupedAccountProductRevenue__c groupedRev2023 = new GroupedAccountProductRevenue__c( AnchorOrganisation__c = account.Id, PrimaryProduct__c = prod.Id,
				FinancialYear__c = 2023, UID__c = ProductRevenueService.getUID(account.Id,prod.Id,'2023'),
				Rev1__c = 11,Rev2__c = 22,Rev3__c = 33,Rev4__c = 44,
				Rev5__c = 55,Rev6__c = 66,Rev7__c = 77,Rev8__c = 88,
				Rev9__c = 99,Rev10__c = 110,Rev11__c = 220,Rev12__c = 330);
		insert groupedRev2023;

		GroupedRevenueSchedule__c revSch = new  GroupedRevenueSchedule__c(GroupedAccountProductRevenue__c = groupedRev2023.Id, OpportunityProduct__c = oppProd.Id);
		insert revSch;

		// =====================================
		// Stubbing
		// =====================================
		GroupedRevenueScheduleSelector scheduleSelector = GroupedRevenueScheduleSelector.newInstance();

		Test.startTest();
		Map<Id,GroupedRevenueSchedule__c> results = scheduleSelector.selectById(new Set<Id>{revSch.Id});
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(groupedRev2023.Id, results.values().get(0).GroupedAccountProductRevenue__c, 'Query did not return the correct GroupedAccountProductRevenue__c Id');
		System.assertEquals(oppProd.Id, results.values().get(0).OpportunityProduct__c, 'Query did not return the correct OpportunityProduct__c Id');

		List<GroupedRevenueSchedule__c> results2 = scheduleSelector.selectByOpportunityProductIds(new Set<String>{String.valueOf(oppProd.Id)}, new Set<Object>());
		System.assertEquals(1, results2.size(), 'Expected result size of 1');
		System.assertEquals(oppProd.Id, results2.get(0).OpportunityProduct__c, 'Query did not return the correct OpportunityProduct__c Id');
		Test.stopTest();
	}
}