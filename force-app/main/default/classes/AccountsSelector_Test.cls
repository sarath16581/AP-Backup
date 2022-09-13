/**
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
 * 2020-05-01 - Dheeraj Mandavilli - Updated - Removed selectbyId Method.
 * 2020-05-14 - Disha Kariya - Updated tests for membership query filter
 * 2020-10-18 - Nathan Franklin - Added tests for selectByAccountNumber
 * 2021-08-09 - Seth Heang - Added selectByLikedNameAndPersonAccountOrderByName test coverage
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52
 * 2022-07-19 - Sreenish Krishnan - Adding test methods to support search
 * 2022-08-16 - Kamil Szyc - Added test for post office assigned selector option
 */
@IsTest
public with sharing class AccountsSelector_Test {
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

		AccountsSelector selector = AccountsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(
			true,
			Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select from Account'
		);

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Account.Id, Account.Name
		};
		AccountsSelector selector1 = AccountsSelector.newInstance(1, fieldOverrides);
		QueryBuilder qb1 = selector1.newQueryBuilder();
		String soql1 = qb1.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');

		Map<SObjectType, Set<SObjectField>> fieldOverridesMap = new Map<SObjectType, Set<SObjectField>>{
			Account.getSObjectType() => new Set<SObjectField>{
				Account.Id, Account.Name
			}
		};
		AccountsSelector selector2 = AccountsSelector.newInstance(1, fieldOverridesMap);
		QueryBuilder qb2 = selector2.newQueryBuilder();
		String soql2 = qb2.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)\\bName\\b').matcher(soql2).find(),
			'Resulting query does not have fieldoverrides'
		);

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

		AccountsSelector selector = AccountsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_RECORDTYPE
		});
		String soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)RecordType\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select RecordType fields'
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_OWNER
		});
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)Owner\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select Owner fields'
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_RECORDTYPE, AccountsSelector.Options.WITH_OWNER
		});
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)RecordType\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select RecordType fields'
		);
		System.assertEquals(
			true,
			Pattern.compile('(?ism)Owner\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select Owner fields'
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS
		});
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom memberships__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select Articles__r child records: ' + soql
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_ORGANISATION_ROLES
		});
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Organisation_Roles__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not Organisation_Roles__r child records: ' + soql
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_ORGANISATION_ROLES_PROSPECT_KNOWN
		});
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Organisation_Roles__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not Organisation_Roles__r child records: ' + soql
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_HOLDINGROLE
		});
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?is)Holding_Role_Reference__r\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select Owner fields'
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

		Network__c networkFacility = ApplicationTestDataFactory.getLPONetwork(1, false)[0];
		networkFacility.Org_ID__c = 'test';
		insert networkFacility;

		Account grandparent = new Account(Name = 'Grandparent');
		insert grandparent;
		Account parent = new Account(Name = 'Parent', ParentId = grandparent.Id);
		insert parent;

		List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(2, false));
		orgAaccounts[0].LEGACY_ID__c = '6000000';
		orgAaccounts[0].ABN__c = '1234';
		orgAaccounts[0].Post_Office_Assigned__c = networkFacility.Id;
		orgAaccounts[0].ParentId = parent.Id;
		insert orgAaccounts;

		Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacility.Id, false)[0];
		insert facilityAccount;

		List<Account> accounts = new List<Account>(
			ApplicationTestDataFactory.getLPOAccounts(2, orgAaccounts[0].Id, facilityAccount.Id, false)
		);
		insert accounts;

		List<Account> consumers = new List<Account>(ApplicationTestDataFactory.getPersonAccounts(2, false));
		consumers[0].FirstName = 'Seth';
		consumers[0].APCN__c = '123456789';
		consumers[0].APCN__pc = '123456789';

		consumers[1].FirstName = 'Green';
		consumers[1].APCN__c = '987654321';
		consumers[1].APCN__pc = '987654321';

		insert consumers;

		Contact personContact = ApplicationTestDataFactory.getContacts(1, orgAaccounts[0].Id, false)[0];
		insert personContact;

		Membership__c member = ApplicationTestDataFactory.getMembership(
			1,
			'Active',
			'New Membership',
			accounts[0].Id,
			personContact.Id,
			false
		)[0];
		member.Member_Type__c = 'Sole Trader';
		member.Licensee_Type__c = 'New Membership';
		member.Date_Signed__c = Datetime.now().date();
		member.ABN__c = '1234';
		member.WCC__c = 'test';
		insert member;

		Map<Id, Account> mappedAccounts = new Map<Id, Account>(orgAaccounts);

		Set<String> accountnumbers = new Set<String>{
			'6000000'
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AccountsSelector selector = AccountsSelector.newInstance(1);
		AccountsSelector selector1 = AccountsSelector.newInstance(2);
		Map<Id, Account> results = selector.selectById(mappedAccounts.keySet());
		System.assertEquals(1, results.size(), 'Result count was wrong');

		results = selector.selectByAccountNumber(accountnumbers);
		System.assertEquals(1, results.size(), 'Result count  was wrong');

		results = selector.selectById(
			mappedAccounts.keySet(),
			new Set<Object>{
				AccountsSelector.Options.WITH_RECORDTYPE, AccountsSelector.Options.WITH_OWNER
			}
		);
		System.assertEquals(1, results.size(), 'Result count was wrong');
		System.assertNotEquals(null, results.values()[0].RecordType, 'Expected RecordType object');
		System.assertNotEquals(null, results.values()[0].Owner, 'Expected Owner object');

		results = selector.selectById(mappedAccounts.keySet(), new Set<Object>{
			AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS
		});

		System.assertNotEquals(null, results.values()[0].Memberships__r, 'Expected membership object');

		results = selector.selectById(new Set<Id> {orgAaccounts[0].Id}, new Set<Object>{
			AccountsSelector.Options.WITH_POSTOFFICEASSIGNED
		});
		System.assertNotEquals(null, results.values()[0].Post_Office_Assigned__r, 'Expected network record in Post Office Assigned field');

		results = selector.selectById(new Set<Id>{facilityAccount.Id}, new Set<Object>{
			AccountsSelector.Options.WITH_NETWORK
		});
		System.assertNotEquals(null, results.values()[0].Network_Facility__r, 'Expected network record in Network Facility field');

		results = selector.selectById(mappedAccounts.keySet(), new Set<Object>{
			AccountsSelector.Options.WITH_PARENT
		});
		System.assertNotEquals(null, results.values()[0].ParentId, 'Expected parent account Id field');

		results = selector.selectById(mappedAccounts.keySet(), new Set<Object>{
			AccountsSelector.Options.WITH_GRANDPARENT
		});
		System.assertNotEquals(null, results.values()[0].Parent.ParentId, 'Expected grandparent account Id field');

		results = selector.selectByLikedNameAndPersonAccountOrderByName('Seth', true);
		System.assertEquals(1, results.size(), 'Result count was wrong');

		Map<String, Object> searchParams = new Map<String, Object>{
			'apcn' => new Set<String>{
				consumers[0].APCN__c, consumers[1].APCN__c
			},
			'accId' => new Set<Id>{
				consumers[0].Id, consumers[1].Id
			},
			'isPersonAccount' => true
		};
		String searchConditions = '(1 OR 2) AND 3';
		Schema.SObjectField orderByField = Account.Integration_Service_Mod_Date__c;
		List<Account> results1 = selector1.selectByAPCNAndIdAndPersonAccount(searchParams, searchConditions, orderByField);
		System.assertEquals(2, results1.size(), 'Result count returned by selectByAPCNAndIdAndPersonAccount was wrong');

		Test.stopTest();
	}
}