/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag GroupMembers
 * @domain Core
 * @description Test Class covering GroupMembersSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 */
@IsTest
private with sharing class GroupMembersSelector_Test {

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

		GroupMembersSelector selector = GroupMembersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom groupmember\\b').matcher(soql).find(), 'Resulting query does not select from GroupMember');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		GroupMembersSelector selector = GroupMembersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{GroupMembersSelector.Options.WITH_GROUP});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Group\\..*?\\bfrom groupmember\\b').matcher(soql).find(), 'Resulting query does not select Group fields');

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

		User runningUser = ApplicationTestDataFactory.getUsers(1, false)[0];


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		System.runAs(runningUser) {

			// Insert a group and a group member so we can test it
			Group newGroup = ApplicationTestDataFactory.getGroups(1, false)[0];
			insert newGroup;

			GroupMember newGroupMember = ApplicationTestDataFactory.getGroupMembers(1, new List<Id>{newGroup.Id}, new List<Id>{UserInfo.getUserId()}, false)[0];
			insert newGroupMember;

			Test.startTest();

			GroupMembersSelector selector = GroupMembersSelector.newInstance();
			Map<Id, GroupMember> results = selector.selectById(new Set<Id>{newGroupMember.Id}, new Set<Object>{GroupMembersSelector.Options.WITH_GROUP});
			System.assertEquals(1, results.size(), 'Expected result size of 1');

			selector = GroupMembersSelector.newInstance();
			results = selector.selectByGroupIds(new Set<Id>{newGroup.Id}, new Set<Object>{GroupMembersSelector.Options.WITH_GROUP});
			System.assertEquals(1, results.size(), 'Expected result size of 1');

			selector = GroupMembersSelector.newInstance();
			results = selector.selectByMyGroups(null, new Set<Object>{GroupMembersSelector.Options.WITH_GROUP});
			System.assertEquals(1, results.size(), 'Expected result size of 1');

			selector = GroupMembersSelector.newInstance();
			results = selector.selectByMyGroups(new List<String>{String.valueOf(newGroup.Id), newGroup.Name}, new Set<Object>{GroupMembersSelector.Options.WITH_GROUP});
			System.assertEquals(1, results.size(), 'Expected result size of 1');

			selector = GroupMembersSelector.newInstance();
			Integer recordCount = selector.countByMyGroups();
			System.assertEquals(1, recordCount, 'Expected result size of 1');

			Test.stopTest();
		}

	}
}