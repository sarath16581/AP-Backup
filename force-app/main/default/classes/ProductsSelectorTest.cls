/**
* @author Seth Heang
* @date 2022-06-28
* @group Tests
* @tag Selector
* @tag Product2 SObject
* @domain Apttus
* @description A very simple selector class that sits in the base domain
* @changelog
* 2022-06-28 - Seth Heang - Created
* 2023-04-21 - Pratyush Chalasani - Added test for selectByIdOrderByName
*/
@IsTest
private with sharing class ProductsSelectorTest {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedList() {

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

		ProductsSelector selector = ProductsSelector.newInstance();
			ProductsSelector.newInstance(1, new Map<Schema.SObjectType,Set<Schema.SObjectField>>{
			Product2.SObjectType => new Set<SObjectField>{Product2.Name
			}});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Product2\\b').matcher(soql).find(), 'Resulting query does not select from Product2 object');

		Test.stopTest();

	}

	@isTest
	private static void testSelectByIdOrderByName() {
		// =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

		Product2 testProduct = ApplicationTestDataFactory.getProducts(1, false)[0];

		insert testProduct;

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

		ProductsSelector selector = ProductsSelector.newInstance();
		List<Product2> results = selector.selectByIdOrderByName(new Set<Id>{testProduct.Id}, new Set<Object>());
        
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}