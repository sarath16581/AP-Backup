/**
* @author Nathan Franklin
* @date 2020-04-10
* @group Tests
* @tag Selector
* @tag Contact SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - Nathan Franklin - Created
* 2020-04-30 - Dheeraj Mandavilli - Updated - Removed Mockdatabase stubbing logic.
* 2020-05-01 - Dheeraj Mandavilli - Updated - Removed selectbyId Method.
* 2021-08-09 - Seth Heang - Added selectByLikedNameOrderByConsumerAndNameNullFirst test coverage
* 2021-08-24 - Seth Heang - Uplift SF API Version to 52
* 2022-07-19 - Sreenish Krishnan - Added new fields
* 2023-07-05 - Mahesh Parvathaneni - Added tests for options WITH_BILLING_ACCOUNT
* 2024-01-31 - Hasantha L - added ConveyancerContact__c field update to testSelectorIntegration()
*/
@IsTest
private with sharing class ContactsSelector_Test {
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

		ContactsSelector selector = ContactsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select from Contact');

		ContactsSelector selector1 = ContactsSelector.newInstance(1);
		QueryBuilder qb1 = selector1.newQueryBuilder();
		String soql1 = qb1.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');

		Set<SObjectField> fieldOverrides=new Set<SObjectField>{Contact.Id, Contact.AccountId};
		ContactsSelector selector2 = ContactsSelector.newInstance(1,fieldOverrides);
		QueryBuilder qb2 = selector2.newQueryBuilder();
		String soql2 = qb2.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bid\\b').matcher(soql2).find(), 'Resulting query does not do filter overrides');

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

		ContactsSelector selector = ContactsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

		qb = selector.newQueryBuilder(new Set<Object>{ContactsSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Owner\\..*?\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		qb = selector.newQueryBuilder(new Set<Object>{ContactsSelector.Options.WITH_ACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Account\\..*?\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select Account fields');

		qb = selector.newQueryBuilder(new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE, ContactsSelector.Options.WITH_OWNER, ContactsSelector.Options.WITH_ACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)RecordType\\..*?\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
		System.assertEquals(true, Pattern.compile('(?is)Owner\\..*?\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');
		System.assertEquals(true, Pattern.compile('(?is)Account\\..*?\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select Account fields');

		qb = selector.newQueryBuilder(new Set<Object>{ContactsSelector.Options.WITH_BILLING_ACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)BillingAccount__r\\..*?\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select Billing Account fields');

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
		acc.LEGACY_ID__c = '60000000';
		insert acc;

		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'TEAM', false)[0];
		insert billingAcc;

		List<Contact> contacts = ApplicationTestDataFactory.getContacts(2, acc.Id, false);
		contacts[0].FirstName = 'Sim';
		contacts[0].Phone = '+61440123456';
		contacts[0].BillingAccount__c = billingAcc.Id;
		contacts[0].ConveyancerContact__c = true;
		contacts[1].MobilePhone = '+61440123456';
		insert contacts;


		Map<Id, Contact> mappedContacts = new Map<Id, Contact>(contacts);
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		ContactsSelector selector = ContactsSelector.newInstance(2);
		Map<Id, Contact> results = selector.selectById(mappedContacts.keySet());
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByAccount(new Set<Id> {contacts[0].AccountId});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectById(mappedContacts.keySet(), new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE, ContactsSelector.Options.WITH_OWNER, ContactsSelector.Options.WITH_ACCOUNT});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByAccount(new Set<Id> {contacts[0].AccountId}, new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE, ContactsSelector.Options.WITH_OWNER, ContactsSelector.Options.WITH_ACCOUNT});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByLikedNameOrderByConsumerAndNameNullFirst(contacts[0].FirstName);
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		
		results = selector.selectByLikedAnyPhoneOrderByName(contacts[0].phone);
		//System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectById(mappedContacts.keySet(), new Set<Object>{ContactsSelector.Options.WITH_BILLING_ACCOUNT});
		System.assertEquals(2, results.size(), 'Expected result size of 2');
		System.assertNotEquals(null, results.get(contacts[0].Id).BillingAccount__r, 'Expected billing account object');

		List<Contact> listResults = selector.selectPrimaryContactByAccount(new Set<Id> {acc.Id});
		System.assertEquals(1, listResults.size(), 'Expected result size of 1');

		Test.stopTest();

	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBNoParams() {
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ Contact.Id, Contact.FirstName };
		Set<Object> selectorOptions = new Set<Object>();
		ContactsSelector cs = ContactsSelector.newInstance(10, fieldOverrides);

		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();

		Test.StartTest();
		String actual = cs.selectByCustomerSearchParamsQB(params, selectorOptions).replace('\n','').trim();
		Test.StopTest();

		String expected = '';
		Assert.areEqual(actual, expected, 'Incorrect query string returned');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithFirstAndLastName() {
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ Contact.Id, Contact.FirstName };
		Set<Object> selectorOptions = new Set<Object>();
		ContactsSelector cs = ContactsSelector.newInstance(10, fieldOverrides);

		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.firstName = 'Sherlock';
		params.lastName = 'Holmes';

		Test.startTest();
		String actual = cs.selectByCustomerSearchParamsQB(params, selectorOptions).replace('\n','');
		Test.stopTest();

		String expected = 'SELECT Id, FirstName'
			+ ' FROM Contact'
			+ ' WHERE (FirstName LIKE \'Sherlock%\' OR Preferred_Name__c LIKE \'Sherlock%\')'
			+ ' AND (LastName LIKE \'Holmes%\')'
			+ ' ORDER BY VerifiedMobile__c ASC NULLS LAST, Name ASC NULLS LAST'
			+ ' LIMIT 10';
		Assert.areEqual(expected, actual, 'Incorrect query string returned');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithPhoneAndEmail() {
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ Contact.Id, Contact.FirstName };
		Set<Object> selectorOptions = new Set<Object>();
		ContactsSelector cs = ContactsSelector.newInstance(10, fieldOverrides);

		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.phoneNumber = '0400111222';
		params.emailAddress = 'jwatson@example.com';

		Test.startTest();
		String actual = cs.selectByCustomerSearchParamsQB(params, selectorOptions).replace('\n','');
		Test.stopTest();

		String expected = 'SELECT Id, FirstName'
			+ ' FROM Contact'
			+ ' WHERE (Email = \'jwatson@example.com\' OR VerifiedEmail__c = \'jwatson@example.com\')'
			+ ' AND (ReverseMobilePhone__c = \'222111004\' OR ReverseVerifiedMobile__c = \'222111004\''
			+ ' OR ReversePhone__c = \'222111004\' OR ReverseHomePhone__c = \'222111004\' OR ReverseOtherPhone__c = \'222111004\')'
			+ ' ORDER BY VerifiedMobile__c ASC NULLS LAST, Name ASC NULLS LAST'
			+ ' LIMIT 10';
		Assert.areEqual(expected, actual, 'Incorrect query string returned');
	}
}