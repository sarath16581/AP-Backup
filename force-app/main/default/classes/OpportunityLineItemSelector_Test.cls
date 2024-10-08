/**
* @author Harry Wang
* @date 2023-04-12
* @group Tests
* @tag Selector
* @domain Core
* @description Test class for OpportunityLineItemSelector
* @changelog
* 2023-04-12 - Harry Wang - Created
* 2024-09-12 - Harry Wang - Added tests for selectByOPCCalculationOpportunityIds
*/
@IsTest
public with sharing class OpportunityLineItemSelector_Test {
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

		OpportunityLineItemSelector selector = OpportunityLineItemSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom OpportunityLineItem\\b').matcher(soql).find(), 'Resulting query does not select from OpportunityLineItem');

		Test.stopTest();

	}
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		OpportunityLineItemSelector selector = OpportunityLineItemSelector.newInstance(1);

		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{OpportunityLineItemSelector.Options.WITH_PRODUCT});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Product2\\..*?\\bfrom OpportunityLineItem\\b').matcher(soql).find(), 'Resulting query does not select Product2 field');
		System.assertEquals(false, Pattern.compile('(?ism)Opportunity\\..*?\\bfrom OpportunityLineItem\\b').matcher(soql).find(), 'Resulting query should not select Opportunity field');

		Set<SObjectField> fieldOverridesSet = new Set<SObjectField>{OpportunityLineItem.Id, OpportunityLineItem.Name, OpportunityLineItem.Quantity};
		selector = OpportunityLineItemSelector.newInstance(1, fieldOverridesSet);
		soql = selector.newQueryBuilder().toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom OpportunityLineItem\\b').matcher(soql).find(), 'Resulting query does not select Name field');
		System.assertEquals(true, Pattern.compile('(?ism)Quantity.*?\\bfrom OpportunityLineItem\\b').matcher(soql).find(), 'Resulting query does not select Quantity field');

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				OpportunityLineItem.SObjectType => new Set<SObjectField>{
						OpportunityLineItem.Id, OpportunityLineItem.Name, OpportunityLineItem.Quantity},
						Opportunity.SObjectType => new Set<SObjectField>{Opportunity.Name}
		};
		selector = OpportunityLineItemSelector.newInstance(1, fieldOverrides);
		qb = selector.newQueryBuilder(new Set<Object>{OpportunityLineItemSelector.Options.WITH_OPPORTUNITY});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Quantity.*?\\bfrom OpportunityLineItem\\b').matcher(soql).find(), 'Resulting query does not select Quantity field');
		System.assertEquals(true, Pattern.compile('(?ism)Opportunity\\.Name.*?\\bfrom OpportunityLineItem\\b').matcher(soql).find(), 'Resulting query does not select Opportunity field');
		System.assertEquals(false, Pattern.compile('(?ism)Product2\\..*?\\bfrom OpportunityLineItem\\b').matcher(soql).find(), 'Resulting query should not select Product field');

		Test.stopTest();

	}
	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<Account> accountList = ApplicationTestDataFactory.getAccounts(1, false);
		insert accountList;

		List<Opportunity> oppList = ApplicationTestDataFactory.getOpportunities(2, accountList[0].Id, false);
		oppList[0].OverrideOPCCalculation__c = false;
		insert oppList;

		Product2 product = APT_TestUtils.createInternationalProduct('Test Product','26940998','Postal Services');
		insert product;

		Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry  priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId, product.Id);
		insert priceBookEntry;

		List<OpportunityLineItem> oppLIList = ApplicationTestDataFactorySales.getOpportunityLineItems(2, oppList[0].Id, priceBookEntry.Id, false);
		oppLIList.addAll(ApplicationTestDataFactorySales.getOpportunityLineItems(2, oppList[1].Id, priceBookEntry.Id, false));
		insert oppLIList;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		OpportunityLineItemSelector selector = OpportunityLineItemSelector.newInstance(0);

		List<OpportunityLineItem> results = selector.selectById(new Set<Id>{oppLIList[0].Id});
		System.assertEquals(1, results.size(), 'Result count was wrong');

		results = selector.selectById(new Set<Id>{oppLIList[0].Id}, new Set<Object>{OpportunityLineItemSelector.Options.WITH_PRODUCT});
		System.assertEquals(1, results.size(), 'Result count was wrong');
		System.assertNotEquals(null, results[0].Product2.Id, 'Expected product Id');

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				OpportunityLineItem.SObjectType => new Set<SObjectField>{OpportunityLineItem.Name},
				Product2.SObjectType => new Set<SObjectField>{Product2.Name},
				Opportunity.SObjectType => new Set<SObjectField>{Opportunity.Name}
		};
		selector = OpportunityLineItemSelector.newInstance(0, fieldOverrides);
		results = selector.selectByOpportunity(new Set<Id>{oppList[0].Id}, new Set<Object>{OpportunityLineItemSelector.Options.WITH_PRODUCT, OpportunityLineItemSelector.Options.WITH_OPPORTUNITY});
		System.assertEquals(2, results.size(), 'Result count was wrong');
		System.assertNotEquals(null, results[0].Name, 'Expected name');
		System.assertNotEquals(null, results[0].Opportunity.Name, 'Expected opportunity name');
		System.assertNotEquals(null, results[0].Product2.Name, 'Expected product name');

		selector.selectByOPCCalculationOpportunityIds(new Set<Id>{oppList[0].Id},new Set<Object>{});
		System.assertEquals(2, results.size(), 'Result count was wrong');

		Test.stopTest();
	}
}