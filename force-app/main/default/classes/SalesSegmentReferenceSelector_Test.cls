/**
* @author Pratyush Chalasani
* @date 2023-07-12
* @group Tests
* @tag Selector
* @tag Sales_Segment_Reference__c SObject
* @domain Core
* @description Test class for SalesSegmentReferenceSelector class
* @changelog
* 2023-07-12 - Pratyush Chalasani - Created
*/
@IsTest
private with sharing class SalesSegmentReferenceSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {

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

		SalesSegmentReferenceSelector selector = SalesSegmentReferenceSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Sales_Segment_Reference__c\\b').matcher(soql).find(), 'Resulting query does not select from Sales_Segment_Reference__c');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures the selector is returning the correct results
	 */
	@IsTest
	private static void testSelectByName() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Sales_Segment_Reference__c testSSR = ApplicationTestDataFactorySales.getSalesSegmentReferences(1, false)[0];

		testSSR.Sales_Segment__c = 'Holding Sales Team';

		insert testSSR;
		
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SalesSegmentReferenceSelector selector = SalesSegmentReferenceSelector.newInstance();
		List<Sales_Segment_Reference__c> results = selector.selectByName(new Set<String>{'Holding Sales Team'});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}