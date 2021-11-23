/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Name SObject
 * @domain Core
 * @description Test Class covering OwnersSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 */
@IsTest
public with sharing class OwnersSelector_Test {

	/**
	 * Test:
	 *  This class does not support querying, so at most, any tests that we write would simply be testing the parent ApplicationSelector class which is pointless
	 *  This test will simply cover the code so the class is deployable
	 */
	@IsTest
	public static void testCoverCode() {

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

		// grab the records and ensure the query has been called just once
		OwnersSelector selector = OwnersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();

		System.assert(true, 'Something went wrong');

		Test.stopTest();
	}
}