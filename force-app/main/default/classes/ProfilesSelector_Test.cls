/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Profile SObject
 * @domain Core
 * @description Test Class covering ProfilesSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 * 2020-05-01 - Dheeraj Mandavilli - Updated - Removed selectby Method.
 */
@IsTest
public with sharing class ProfilesSelector_Test {

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

		ProfilesSelector selector = ProfilesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom profile\\b').matcher(soql).find(), 'Resulting query does not select from Profile');

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
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ProfilesSelector selector = ProfilesSelector.newInstance(1);
		Map<Id, Profile> results = selector.selectById(new Set<Id>{ApplicationTestDataFactory.defaultUserProfileId});
		System.assertEquals(1, results.size(), 'Expected a single result');
		System.assertEquals('System Administrator', results.get(ApplicationTestDataFactory.defaultUserProfileId).Name, 'Expected Admin profile');

		selector = ProfilesSelector.newInstance();
		results = selector.selectByName(new Set<String>{'System Administrator'});
		System.assertEquals(1, results.size(), 'Expected a single result');
		System.assertEquals('System Administrator', results.get(ApplicationTestDataFactory.defaultUserProfileId).Name, 'Expected Admin profile');

		selector = ProfilesSelector.newInstance();
		results = selector.selectByType(new Set<String>{'Standard'});
		System.assertNotEquals(0, results.size(), 'Expected a result');

		Test.stopTest();

	}
}