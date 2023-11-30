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
 * 2023-03-17 - Naveen Rajanna - SMWD-397 - Modified to use Assert class for assertion, Added test for following enums - WITH_CREATEDBY_USER, WITH_LASTMODIFIEDBY_USER, WITH_FACILITY
 * 2023-05-01 - Naveen Rajanna - REQ2916371 - coverage for search() and new enums WITH_PARENT_2LEVELS, WITH_PARENT_3LEVELS, WITH_PARENT_4LEVELS, WITH_PARENT_5LEVELS
 * 2023-07-17 - Harry Wang - Added test for testSelectByIdWithContactsAndOpportunities
 * 2023-11-20 - StephenL - Added test for selectArchivedAccountsByClosureDateLessThanEqualNMonthsAgo
 */
@IsTest
public with sharing class AccountsSelector_Test {


	// Checks that the query params and condition orders are set correctly.
	@IsTest
	static void selectByPostOfficeAssigned() {
		String postOfficeOrgId = 'test2134123123123213213123';
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = postOfficeOrgId;
		insert networks;
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		accounts[0].Post_Office_Assigned__c = networks[0].Id;
		insert accounts;

		Map<Id, Account> actual = AccountsSelector.newInstance().selectByPostOfficeAssigned(new Set<String>{postOfficeOrgId}, new Set<Object>());
		System.Assert.isTrue(actual.size() == 1, 'Should only return one record');
		System.Assert.areEqual(accounts[0].Id, actual.values()[0].Id, 'Should match on the result');
	}


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

		System.Assert.isTrue(
			Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select from Account'
		);

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Account.Id, Account.Name
		};
		AccountsSelector selector1 = AccountsSelector.newInstance(1, fieldOverrides);
		QueryBuilder qb1 = selector1.newQueryBuilder();
		String soql1 = qb1.toSoqlString();

		System.Assert.isTrue(Pattern.compile('(?ism)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');

		Map<SObjectType, Set<SObjectField>> fieldOverridesMap = new Map<SObjectType, Set<SObjectField>>{
			Account.getSObjectType() => new Set<SObjectField>{
				Account.Id, Account.Name
			}
		};
		AccountsSelector selector2 = AccountsSelector.newInstance(1, fieldOverridesMap);
		QueryBuilder qb2 = selector2.newQueryBuilder();
		String soql2 = qb2.toSoqlString();
		System.Assert.isTrue(
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
		System.Assert.isTrue(
			Pattern.compile('(?ism)RecordType\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select RecordType fields'
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_OWNER
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('(?ism)Owner\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select Owner fields'
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_RECORDTYPE, AccountsSelector.Options.WITH_OWNER
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('(?ism)RecordType\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select RecordType fields'
		);
		System.Assert.isTrue(
			Pattern.compile('(?ism)Owner\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select Owner fields'
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom memberships__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select Articles__r child records: ' + soql
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_ORGANISATION_ROLES
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Organisation_Roles__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not Organisation_Roles__r child records: ' + soql
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_ORGANISATION_ROLES_PROSPECT_KNOWN
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('(?ism)Select.*?\\(Select.*?\\bfrom Organisation_Roles__r\\b.*?\\).*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not Organisation_Roles__r child records: ' + soql
		);

		qb = selector.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_HOLDINGROLE
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('(?is)Holding_Role_Reference__r\\..*?\\bfrom account\\b').matcher(soql).find(),
			'Resulting query does not select Owner fields'
		);

		/* Parent relation SOQL compile check - start */
		AccountsSelector selector1 = AccountsSelector.newInstance(
			0, new Set<SObjectField>{ Account.Id }
		);
		qb = selector1.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_PARENT_5LEVELS
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Parent.Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'5th level Parent fields not retrieved in WITH_PARENT_5LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'4th level Parent fields not retrieved in WITH_PARENT_5LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'3rd level Parent fields not retrieved in WITH_PARENT_5LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'2nd level Parent fields not retrieved in WITH_PARENT_5LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Id')+'\\b').matcher(soql).find(),
			'1st level Parent fields not retrieved in WITH_PARENT_5LEVELS'
		);

		qb = selector1.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_PARENT_4LEVELS
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'4th level Parent fields not retrieved in WITH_PARENT_4LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'3rd level Parent fields not retrieved in WITH_PARENT_4LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'2nd level Parent fields not retrieved in WITH_PARENT_4LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Id')+'\\b').matcher(soql).find(),
			'1st level Parent fields not retrieved in WITH_PARENT_4LEVELS'
		);

		qb = selector1.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_PARENT_3LEVELS
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'3rd level Parent fields not retrieved in WITH_PARENT_3LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'2nd level Parent fields not retrieved in WITH_PARENT_3LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Id')+'\\b').matcher(soql).find(),
			'1st level Parent fields not retrieved in WITH_PARENT_3LEVELS'
		);

		qb = selector1.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_PARENT_2LEVELS
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Parent.Id')+'\\b').matcher(soql).find(),
			'2nd level Parent fields not retrieved in WITH_PARENT_2LEVELS'
		);
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Id')+'\\b').matcher(soql).find(),
			'1st level Parent fields not retrieved in WITH_PARENT_2LEVELS'
		);

		qb = selector1.newQueryBuilder(new Set<Object>{
			AccountsSelector.Options.WITH_PARENT
		});
		soql = qb.toSoqlString();
		System.Assert.isTrue(
			Pattern.compile('\\b' +String.valueOf('Parent.Id')+'\\b').matcher(soql).find(),
			'1st level Parent fields not retrieved in WITH_PARENT'
		);
		/* Parent relation SOQL compile check - end */

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

		List<Account> orgAaccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(6, false));
		orgAaccounts[0].LEGACY_ID__c = '6000000';
		orgAaccounts[0].ABN__c = '1234';
		orgAaccounts[0].Post_Office_Assigned__c = networkFacility.Id;
		insert orgAaccounts;

		// Add Parent, GrandParent and so on
		orgAaccounts[0].ParentId = orgAaccounts[1].Id;
		orgAaccounts[1].ParentId = orgAaccounts[2].Id;
		orgAaccounts[2].ParentId = orgAaccounts[3].Id;
		orgAaccounts[3].ParentId = orgAaccounts[4].Id;
		orgAaccounts[4].ParentId = orgAaccounts[5].Id;
		update orgAaccounts;

		Account facilityAccount = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacility.Id, false)[0];
		insert facilityAccount;

		List<Account> accounts = new List<Account>(
			ApplicationTestDataFactory.getLPOAccounts(2, orgAaccounts[0].Id, facilityAccount.Id, false)
		);
		insert accounts;

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
		Map<Id, Account> results = selector.selectById(mappedAccounts.keySet());
		System.Assert.areEqual(1, results.size(), 'Result count was wrong');

		results = selector.selectByAccountNumber(accountnumbers);
		System.Assert.areEqual(1, results.size(), 'Result count  was wrong');

		results = selector.selectById(
			mappedAccounts.keySet(),
			new Set<Object>{
				AccountsSelector.Options.WITH_RECORDTYPE, AccountsSelector.Options.WITH_OWNER
			}
		);
		System.Assert.areEqual(1, results.size(), 'Result count was wrong');
		System.Assert.isNotNull(results.values()[0].RecordType, 'Expected RecordType object');
		System.Assert.isNotNull(results.values()[0].Owner, 'Expected Owner object');

		results = selector.selectById(mappedAccounts.keySet(), new Set<Object>{
			AccountsSelector.Options.WITH_ACTIVE_MEMBERSHIPS
		});

		System.Assert.isNotNull(results.values()[0].Memberships__r, 'Expected membership object');

		results = selector.selectById(new Set<Id> {orgAaccounts[0].Id}, new Set<Object>{
			AccountsSelector.Options.WITH_POSTOFFICEASSIGNED
		});
		System.Assert.isNotNull(results.values()[0].Post_Office_Assigned__r, 'Expected network record in Post Office Assigned field');

		results = selector.selectById(new Set<Id>{facilityAccount.Id}, new Set<Object>{
			AccountsSelector.Options.WITH_NETWORK
		});
		System.Assert.isNotNull(results.values()[0].Network_Facility__r, 'Expected network record in Network Facility field');

		results = selector.selectById(new Set<Id> {orgAaccounts[0].Id}, new Set<Object>{
			AccountsSelector.Options.WITH_PARENT
		});
		System.Assert.isNotNull(results.values()[0].ParentId, 'Expected parent account Id field');

		results = selector.selectById(new Set<Id> {orgAaccounts[0].Id}, new Set<Object>{
			AccountsSelector.Options.WITH_GRANDPARENT
		});
		System.Assert.isNotNull(results.values()[0].Parent.ParentId, 'Expected grandparent account Id field');

		results = selector.selectById(new Set<Id> {orgAaccounts[0].Id}, new Set<Object>{
			AccountsSelector.Options.WITH_CREATEDBY_USER
		});
		System.Assert.isNotNull(results.values()[0].CreatedBy.Name, 'Expected Created By Name field');

		results = selector.selectById(new Set<Id> {orgAaccounts[0].Id}, new Set<Object>{
			AccountsSelector.Options.WITH_LASTMODIFIEDBY_USER
		});
		System.Assert.isNotNull(results.values()[0].LastModifiedBy.Name, 'Expected LastModified By Name field');

		results = selector.selectById(new Set<Id> {accounts[0].Id}, new Set<Object>{
			AccountsSelector.Options.WITH_FACILITY
		});
		System.Assert.isNotNull(results.values()[0].Facility__r.Name, 'Expected related Facility Name field');

		Set<Id> parentIdSet = new Set<Id>{orgAaccounts[5].Id};
		List<Account> searchResults = AccountsSelector.newInstance(
			0, new Set<SObjectField>{ Account.Id, Account.ParentId }
		).search(
			new Map<String, Object>{
				'parentIds' => parentIdSet, 'parentIdsLevel2' => parentIdSet, 'parentIdsLevel3' => parentIdSet, 
				'parentIdsLevel4' => parentIdSet, 'parentIdsLevel5' => parentIdSet, 'parentIdsLevel6' => parentIdSet
			},
			new Set<Object>{AccountsSelector.Options.WITH_PARENT_5LEVELS}, '1 OR 2 OR 3 OR 4 OR 5 OR 6', Account.Name, 'ASC'
		);
		System.Assert.isTrue(searchResults.size() > 0, 'Expected searchResults size');

		Test.stopTest();
	}

	@isTest
	public static void testSearchAPCN() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		
		AccountsSelector selector = AccountsSelector.newInstance(0);
		List<Account> consumers = new List<Account>(ApplicationTestDataFactory.getPersonAccounts(2, false));
		consumers[0].FirstName = 'Seth';
		consumers[0].APCN__c = '123456789';
		consumers[0].APCN__pc = '123456789';
		consumers[0].Integration_Service_Mod_Date__c = System.Today().addDays(-1);
		consumers[1].FirstName = 'Green';
		consumers[1].APCN__c = '987654321';
		consumers[1].APCN__pc = '987654321';
		consumers[1].Integration_Service_Mod_Date__c = System.Today();
		insert consumers;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Object> searchParams = new Map<String, Object>{
			'apcn' => new Set<String>{consumers[0].APCN__c, consumers[1].APCN__c},
			'accId' => new Set<Id>{consumers[0].Id, consumers[1].Id},
			'isPersonAccount' => true
		};
		String searchConditions = '(1 OR 2) AND 3';
		Schema.SObjectField orderByField = Account.Integration_Service_Mod_Date__c;
		
		List<Account> results = selector.selectByAPCNAndIdAndPersonAccount(searchParams, searchConditions, orderByField);
		System.Assert.areEqual(2, results.size(), 'Result count returned by selectByAPCNAndIdAndPersonAccount was wrong');
		System.Assert.areEqual(consumers[1].Id, results[0].Id, 'Result is not sorted as expected');

		results = selector.selectByLikedNameAndPersonAccountOrderByName('Seth', true).values();
		System.Assert.areEqual(1, results.size(), 'Result count was wrong');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that selectByIdWithContactsAndOpportunities is returning expected results
	 */
	@IsTest
	public static void testSelectByIdWithContactsAndOpportunities() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
		insert contacts;
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(1, accounts[0].Id, false);
		insert opportunities;
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Account.SObjectType => new Set<SObjectField>{Account.ShippingStreet},
				Contact.SObjectType => new Set<SObjectField>{Contact.OtherStreet},
				Opportunity.SObjectType => new Set<SObjectField>{Opportunity.KeyContact__c}
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		AccountsSelector selector = AccountsSelector.newInstance(1, fieldOverrides);
		List<Account> results = selector.selectByIdWithContactsAndOpportunities(new Set<Id>{contacts[0].Id}, new Set<Id>{opportunities[0].Id}, new Set<Id>{accounts[0].Id}, new Set<Object>());
		Test.stopTest();
		System.assertEquals(accounts[0].Id, results[0].Id, 'Id not matched');
		System.assertEquals(1, results[0].Contacts.size(), 'One contact expected');
		System.assertEquals(1, results[0].Opportunities.size(), 'One opportunity expected');
	}

	/**
	 * Test:
	 *  Ensures that testSelectArchivedAccountsByClosureDateLessThanEqualNMonthsAgo is returning expected results
	 */
	@IsTest
	public static void testSelectArchivedAccountsByClosureDateLessThanEqualNMonthsAgo() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AccountsSelector selector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(selector.selectArchivedAccountsByClosureDateLessThanEqualNMonthsAgo((Integer)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(Database.getQueryLocator('SELECT Id FROM Account'));
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<Account> results = Database.query(selector.selectArchivedAccountsByClosureDateLessThanEqualNMonthsAgo(6, new Set<Object>()).getQuery());
		Test.stopTest();

		System.assertEquals(1, results.size(), 'Wrong number of Account records returned');
		System.assertEquals(accounts.get(0).Id, results.get(0).Id, 'Returned Account record does not match the test data');
	}
}