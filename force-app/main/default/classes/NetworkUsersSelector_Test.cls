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

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {
		// =====================================
		// Data Preparation
		// =====================================
		
		MockUtility.disableTriggerExecution();
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';
		insert networks;

		List<Facility_User__c> networkUsers = ApplicationTestDataFactory.getNetworkUsers(1, networks[0].Id, UserInfo.getUserId(), false);
		insert networkUsers;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		NetworkUsersSelector selector = NetworkUsersSelector.newInstance(10);
		Map<Id, Facility_User__c> results = selector.selectById(new Set<Id>{networkUsers[0].Id});
		System.assertEquals(1, results.values().size(), 'Expected result size of 1');

		results = selector.selectByUserId(new Set<Id>{UserInfo.getUserId()});
		System.assertEquals(1, results.values().size(), 'Expected result size of 1');
		
		Test.stopTest();
	}
	
}