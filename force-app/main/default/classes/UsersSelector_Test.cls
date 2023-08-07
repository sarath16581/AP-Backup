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
 * 2022-02-22 - Nathan Franklin - Added field override tests
 * 2022-03-14 - Nathan Franklin - uplifted to version 52
 * 2022-04-24 - Nathan Franklin - Added test methods for search and selectActiveUserByProfileName
 * 2022-08-25 - Mahesh Parvathaneni - Added test methods for selectByName
 * 2022-08-31 - Nathan Franklin - Add tests for Map<> field overrides
 * 2023-01-27 - Naveen Rajanna - Updated api version and test methods for selectUsersEligibleForDeactivationQueryLocator
 * 2022-02-01 - Noel Lim - updated testSelectorIntegration method, added test for new selectActiveUserById()
 * 2023-08-04 - Mahesh Parvathaneni - Added tests for search params
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

		selector = UsersSelector.newInstance(0, new Set<SObjectField>{User.TimeZoneSidKey});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(false, Pattern.compile('(?ism)\\bUsername\\b.*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query selected a field it was not meant to');

		qb = selector.newQueryBuilder(new Set<Object>{UsersSelector.Options.WITH_PROFILE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Profile\\..*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select Profile fields');

		qb = selector.newQueryBuilder(new Set<Object>{UsersSelector.Options.WITH_PROFILE, UsersSelector.Options.WITH_ROLE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)UserRole\\..*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select UserRole fields');
		System.assertEquals(true, Pattern.compile('(?ism)Profile\\..*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select Profile fields');

		selector = UsersSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{User.SObjectType => new Set<SObjectField>{User.TimeZoneSidKey}, Contact.SObjectType => new Set<SObjectField>{Contact.Email}});
		qb = selector.newQueryBuilder(new Set<Object>{UsersSelector.Options.WITH_CONTACT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Contact\\.Email.*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select Contact fields');
		System.assertEquals(false, Pattern.compile('(?ism)Contact\\.Phone.*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query selects Phone field on Contact');
		System.assertEquals(true, Pattern.compile('(?ism)TimeZoneSidKey.*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query does not select TimeZoneSidKey field');
		System.assertEquals(false, Pattern.compile('(?ism)Username.*?\\bfrom user\\b').matcher(soql).find(), 'Resulting query selects Username field');

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
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureSearchMethodProducesCorrectString() {

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

		Map<String, Object> searchParams;

		UsersSelector selector = UsersSelector.newInstance(1);

		searchParams = new Map<String, Object>{
			'profileIds' => new Set<Id>{'00e000000000000'},
			'contactIds' => new Set<Id>{'003000000000000'},
			'roleIds' => new Set<Id>{'00E000000000000'},
			'federationIds' => new Set<String>{'federation1@auspost.com.au'},
			'profileNames' => new Set<String>{'System Administrator'},
			'usernames' => new Set<String>{'randomuser@auspost.com.au'},
			'isActive' => true
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bProfileId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit ProfileId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bContactId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit ContactId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bUserRoleId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit UserRoleId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bFederationIdentifier\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit FederationIdentifier');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bProfile\\.Name\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Profile.Name');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bUsername\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Username');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bIsActive\\s*=\\s*').matcher(soql).find(), 'Resulting query does not limit IsActive');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		// search by network Id to ensure the correct inner soql is produced
		searchParams = new Map<String, Object>{
			'networkIds' => new Set<Id>{'0DB000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bId\\s+In\\s*\\(\\s*SELECT\\s+MemberId\\s+FROM\\s+NetworkMember\\s+WHERE\\s+NetworkId\\s+IN\\s*\\(.*?\\)\\s*\\)').matcher(soql).find(), 'Resulting query does not limit Networks');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'userTypes' => new Set<String>{'CspLitePortal'},
			'isPersonAccount' => false,
			'contactCNumbers'  => new Set<String>{'C12345'},
			'contactStatuses' => new  Set<String>{'Active'},
			'activeOrMerchantPortalProfile' => true
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bUserType\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit UserType');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bContact.IsPersonAccount\\s*=\\s*').matcher(soql).find(), 'Resulting query does not limit Contact.IsPersonAccount');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bContact\\.Status__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Contact.Status__c');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bContact\\.OID_ID__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Contact.OID_ID__c');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		// final test is to test OR conditions
		searchParams = new Map<String, Object>{
			'profileIds' => new Set<Id>{'00e000000000000'},
			'contactIds' => new Set<Id>{'003000000000000'},
			'roleIds' => new Set<Id>{'00E000000000000'},
			'federationIds' => new Set<String>{'federation1@auspost.com.au'},
			'profileNames' => new Set<String>{'System Administrator'},
			'usernames' => new Set<String>{'randomuser@auspost.com.au'},
			'isActive' => true
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bProfileId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit ProfileId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bContactId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit ContactId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bUserRoleId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit UserRoleId');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bFederationIdentifier\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit FederationIdentifier');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bProfile\\.Name\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Profile.Name');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bUsername\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit Username');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bIsActive\\s*=\\s*').matcher(soql).find(), 'Resulting query does not limit IsActive');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from user\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not limit by ANY');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, false);

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

		results = selector.selectActiveUserById(new Set<Id>{UserInfo.getUserId()}); 
		System.assertEquals(1, results.size(), 'Expected 1 result');
		System.assertEquals(true, results.values()[0].IsActive, 'Expected active User');

		results = selector.selectActiveUserByProfileName(mappedContacts.keySet(), 'BSP Community User', new Set<Object>{UsersSelector.Options.WITH_CONTACT});
		System.assertEquals(2, results.size(), 'Expected 2 results');
		System.assertNotEquals(null, results.values()[0].Contact, 'Expected Contact object but got null');

		String name = users[0].FirstName + ' ' + users[0].LastName;
		results = selector.selectByName(new Set<String>{name});
		System.assertEquals(1, results.size(), 'Expected 1 result');

		Database.QueryLocator queryLocator = selector.selectUsersEligibleForDeactivationQueryLocator(new Set<String>{'Standard'}, 0, 0, new Set<String>(), new Set<Object>());
        System.assert(queryLocator != null, 'Expected a valid query locator');
        System.assert(queryLocator.iterator().hasNext(), 'Expected a valid query locator');

		Test.stopTest();

	}
}