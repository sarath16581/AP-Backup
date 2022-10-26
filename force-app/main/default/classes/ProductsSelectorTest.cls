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
}