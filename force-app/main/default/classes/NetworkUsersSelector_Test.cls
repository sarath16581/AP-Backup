/***
 * @author Dattaraj Deshmukh
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering NetworkUsersSelector
 */
@IsTest
public with sharing class NetworkUsersSelector_Test {
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
		NetworkUsersSelector selector = NetworkUsersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Facility_User__c\\b').matcher(soql).find(), 'Resulting query does not select from Facility_User__c');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Facility_User__c.Network__c) + '\\b').matcher(soql).find(), 'Network__c field does not exists in query');
		System.assertEquals(true, Pattern.compile('\\b' + String.valueOf(Facility_User__c.User__c) + '\\b').matcher(soql).find(), 'User__c field does not exists in query');
		Test.stopTest();
	}
	
}