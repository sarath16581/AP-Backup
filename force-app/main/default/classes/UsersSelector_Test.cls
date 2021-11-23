/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Selector
 * @tag User SObject
 * @domain Core
 * @description Test Class covering UsersSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 * 2020-03-20 - Nathan Franklin - Added tests for selectByProfileId
 */
@IsTest
public with sharing class UsersSelector_Test {

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

		UsersSelector selector = UsersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select from User');

		qb = selector.newQueryBuilder(new Set<Object>{UsersSelector.Options.FILTER_EXTERNAL_USERS});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom user\\b.*IsPortalEnabled\\s*=\\s*true').matcher(soql).find(), 'Resulting query does not limit records to external users only');

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

		UsersSelector selector = UsersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{UsersSelector.Options.WITH_ROLE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)UserRole\\..*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select UserRole fields');

		qb = selector.newQueryBuilder(new Set<Object>{UsersSelector.Options.WITH_PROFILE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Profile\\..*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select Profile fields');

		qb = selector.newQueryBuilder(new Set<Object>{UsersSelector.Options.WITH_PROFILE, UsersSelector.Options.WITH_ROLE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)UserRole\\..*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select UserRole fields');
		System.assertEquals(true, Pattern.compile('(?ism)Profile\\..*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select Profile fields');

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

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		List<Contact> contacts = ApplicationTestDataFactory.getContacts(2, accounts[0].Id, false);
		insert contacts;

		Map<Id, Contact> mappedContacts = new Map<Id, Contact>(contacts);

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>(mappedContacts.keySet()), false);
		insert users;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
        
        UsersSelector selector = UsersSelector.newInstance(2);
        Map<Id, User> results = selector.selectById(new Set<Id>{UserInfo.getUserId()});
		System.assertEquals(1, results.size(), 'Expected 1 results');

		results = selector.selectById(new Set<Id>{UserInfo.getUserId()}, new Set<Object>{UsersSelector.Options.WITH_ROLE, UsersSelector.Options.WITH_PROFILE});
		System.assertEquals(1, results.size(), 'Expected 1 result');
		System.assertNotEquals(null, results.values()[0].UserRole, 'Expected UserRole object but got null');
		System.assertNotEquals(null, results.values()[0].Profile, 'Expected Profile object but got null');
		System.assertEquals(UserInfo.getFirstName(), results.get(UserInfo.getUserId()).FirstName, 'Expected first name to match current user');

        results = selector.selectByUsername(new Set<String>{users[0].Username, users[1].Username});
        System.assertEquals(2, results.size(), 'Expected 2 results');

        results = selector.selectByContactId(new Set<Id>{users[0].ContactId});
        System.assertEquals(1, results.size(), 'Expected 1 result');

        results = selector.selectByContactId(new Set<Id>{users[0].ContactId},new Set<Object>{UsersSelector.Options.WITH_CONTACT});
        System.assertEquals(1, results.size(), 'Expected 1 result');
		System.assertNotEquals(null, results.values()[0].Contact, 'Expected Contact object but got null');

		results = selector.selectByProfileId(new Set<Id>{users[0].ProfileId});
		System.assertEquals(2, results.size(), 'Expected 1 result');

		results = selector.selectByProfileId(new Set<Id>{users[0].ProfileId},new Set<Object>{UsersSelector.Options.WITH_CONTACT});
		System.assertEquals(2, results.size(), 'Expected 1 result');
		System.assertNotEquals(null, results.values()[0].Contact, 'Expected Contact object but got null');
        
		Test.stopTest();

	}
}