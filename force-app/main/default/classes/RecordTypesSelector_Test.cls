/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag RecordType SObject
 * @domain Core
 * @description Test Class covering RecordTypesSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-08-02 - Nathan Franklin - Added test for selectByName
 */
@IsTest
public with sharing class RecordTypesSelector_Test {

	/**
	 * Test:
	 *  Testing selectBy[Method] methods.
	 */
	@IsTest
	public static void testSelectByMethods() {

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

		RecordTypesSelector selector = RecordTypesSelector.newInstance();
		Map<Id, RecordType> queryResults = selector.selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'});
		System.assertEquals(1, queryResults.size());

		queryResults = selector.selectByName('Case', new Set<String>{'Delivery Enquiry'});
		System.assertNotEquals(0, queryResults.size());

		queryResults = selector.selectByDeveloperNameLike('Case', 'SSSW');
		System.assertNotEquals(0, queryResults.size(), 'Expected no results');

		Test.stopTest();
	}

}