/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag UserRole SObject
 * @domain Core
 * @description Test Class covering UserRolesSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 * 2020-05-01 - Dheeraj Mandavilli - Updated - Removed selectby Method.
 * 2023-05-04 - Ranjeewa Silva - Updated to test selectByPortalType
 */
@IsTest
public with sharing class UserRolesSelector_Test {

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

		UserRolesSelector selector = UserRolesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom userrole\\b').matcher(soql).find(), 'Resulting query does not select from UserRole');

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

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		UserRolesSelector selector = UserRolesSelector.newInstance(1);
		Map<Id, UserRole> results = selector.selectById(new Set<Id>{UserInfo.getUserRoleId()});
		System.assertEquals(1, results.size());

		results = selector.selectByDeveloperName(new Set<String>{'Business_Reporting'});
		System.assertEquals(1, results.size());

		results = new Map<Id, UserRole>(selector.selectByPortalType(new Set<String>{'None'}));
		System.assert(!results.isEmpty(), 'Expected all internal salesforce roles to be returned, but got none');

		Test.stopTest();

	}
}