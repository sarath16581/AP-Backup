/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag Group SOBject
 * @domain Core
 * @description Test Class covering GroupsSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 * 2020-05-01 - Dheeraj Mandavilli - Updated - Removed selectbyId Method.
 * 2020-11-02 - Ranjeewa Silva	- Added tests for 'selectByDeveloperName'.
 * 2020-12-18 - Seth Heang - Added tests for selectbyGroupTypeAndName
 * 2021-02-17 - Seth Heang - Updated - Add coverage for selectByGroupTypeAndDeveloperName method
 * 2023-05-04 - Ranjeewa Silva - Updated to test selector option - 'WITH_DIRECT_MEMBERS'
 */
@IsTest
public with sharing class GroupsSelector_Test {
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

		GroupsSelector selector = GroupsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom group\\b').matcher(soql).find(), 'Resulting query does not select from Group');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		GroupsSelector selector = GroupsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{GroupsSelector.Options.WITH_OWNER});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Owner\\..*?\\bfrom group\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		qb = selector.newQueryBuilder(new Set<Object>{GroupsSelector.Options.WITH_DIRECT_MEMBERS});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom groupmembers\\b.*?\\).*?\\bfrom group\\b').matcher(soql).find(),
				'Resulting query does not select GroupMember child records: ' + soql
		);

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

		Map<Id, Group> groups = new Map<Id, Group>([Select Id, DeveloperName From Group Limit 10]);

		Group testGroup = ApplicationTestDataFactory.getGroups(1,'queue', false)[0];
		testGroup.Name = 'Test Group';
		testGroup.DeveloperName = 'Test_Group';
		insert testGroup;
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		GroupsSelector selector = GroupsSelector.newInstance();
		Map<Id, Group> results = selector.selectById(groups.keySet());
		System.assertEquals(10, results.size(), 'Expected result size of 10');

		results = selector.selectById(groups.keySet(), new Set<Object>{GroupsSelector.Options.WITH_OWNER});
		System.assertEquals(10, results.size(), 'Expected result size of 10');

		results = selector.selectByDeveloperName(new Set<String>{groups.values()[0].DeveloperName});
		System.assert(results.size() >= 1, 'Expected result size of more than 1');
		
		results = selector.selectByGroupTypeAndName(new set<String>{'queue'}, new set<String>{testGroup.Name});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		results = selector.selectByGroupTypeAndDeveloperName(new set<String>{'queue'}, new set<String>{testGroup.DeveloperName});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();

	}
}