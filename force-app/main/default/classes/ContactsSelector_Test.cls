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
* 2024-05-21 - Marcel HK - Added tests for new selector method `selectByCustomerSearchParams` for Customer Search (CSLU-107)
* 2024-07-05 - Marcel HK - Updated tests for selector method `selectByCustomerSearchParamsQB` (CSLU-955)
* 2024-07-15 - Marcel HK - Added selector option WITH_RELATED_CASES to include related cases sub-query (CSLU-439)
* 2024-07-15 - Marcel HK - Added enum `CustomerSearchCustomerType` and customer type filters (CSLU-446)
* 2024-07-22 - Marcel HK - Added mailing address filters for the selector method `selectByCustomerSearchParamsQB` (CSLU-1072)
* 2024-07-23 - Marcel HK - Removed 'Country' mailing address filters (CSLU-1072)
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
	static void testSelectByCustomerSearchParamsQBWithNoParams() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.StartTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.StopTest();

		List<String> orderBy = new List<String>{
			'UnifiedDataScore__c DESC NULLS LAST',
			'FirstName ASC NULLS LAST',
			'LastName ASC NULLS LAST'
		};
		Assert.isTrue(Pattern.compile('(?is)ORDER BY ' + String.join(orderBy, ',\\s?')).matcher(soql).find(), 'Query did not include correct ORDER BY statement. ' + soql.replaceAll('\n',''));
		Assert.isFalse(Pattern.compile('(?is)FROM Contact\\bWHERE\\b').matcher(soql).find(), 'Query should not include any WHERE clause');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithFirstAndLastName() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.firstName = 'Sherlock';
		params.lastName = 'Holmes';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)\\bWHERE\\b.*?\\(FirstName LIKE \'Sherlock%\' OR Preferred_Name__c LIKE \'Sherlock%\'\\)').matcher(soql).find(), 'Query did not include correct WHERE clause for FirstName');
		Assert.isTrue(Pattern.compile('(?is)\\bAND\\b.*?\\(LastName LIKE \'Holmes%\'\\)').matcher(soql).find(), 'Query did not include correct WHERE clause for LastName');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithPhoneAndEmail() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.phoneNumber = '0400111222';
		params.emailAddress = 'jwatson@example.com';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.stopTest();

		// Verify email fields in the WHERE clause
		List<String> emailFields = new List<String> { 'Email', 'VerifiedEmail__c' };
		String emailPattern = String.format('{0} = \'jwatson@example.com\' OR {1} = \'jwatson@example.com\'', emailFields);
		Assert.isTrue(Pattern.compile('(?is)\\(' + emailPattern + '\\)').matcher(soql).find(), 'Query did not include correct WHERE clause for email addresses. ' + soql);

		// Verify phone fields in the WHERE clause
		List<String> phoneFields = new List<String> {'ReverseMobilePhone__c', 'ReverseVerifiedMobile__c', 'ReversePhone__c' };
		String phonePattern = String.format('{0} = \'222111004\' OR {1} = \'222111004\' OR {2} = \'222111004\'', phoneFields);
		Assert.isTrue(Pattern.compile('(?is)\\(' + phonePattern + '\\)').matcher(soql).find(), 'Query did not include correct WHERE clause for phone numbers. ' + soql);

		// Verify the WHERE clause uses AND between phone and email condition groups
		Assert.isTrue(Pattern.compile('(?is)\\(' + emailPattern + '\\)\\sAND\\s\\(' + phonePattern + '\\)').matcher(soql).find(), 'Query did not include correct WHERE clause for (Email AND Phone)');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithoutCustomerType() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.firstName = 'Sherlock';
		params.lastName = 'Holmes';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.stopTest();

		Assert.isFalse(Pattern.compile('(?is)(IsPersonAccount = TRUE|IsPersonAccount = FALSE)').matcher(soql).find(), 'Query should not filter on IsPersonAccount');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithCustomerTypeConsumer() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.firstName = 'Sherlock';
		params.lastName = 'Holmes';
		params.customerType = ContactsSelector.CustomerSearchCustomerType.CONSUMER;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)IsPersonAccount = TRUE').matcher(soql).find(), 'Query should filter on IsPersonAccount = TRUE');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithCustomerTypeOrganisation() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.firstName = 'Sherlock';
		params.lastName = 'Holmes';
		params.customerType = ContactsSelector.CustomerSearchCustomerType.ORGANISATION;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)IsPersonAccount = FALSE').matcher(soql).find(), 'Query should filter on IsPersonAccount = FALSE');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithAddress() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.addressStreet1 = '123 Example St';
		params.addressCity = 'Example Town';
		params.addressState = 'VIC';
		params.addressPostalCode = '3999';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)MailingStreet = \'123 Example St\'').matcher(soql).find(), 'Query should filter MailingStreet');
		Assert.isTrue(Pattern.compile('(?is)MailingCity = \'Example Town\'').matcher(soql).find(), 'Query should filter MailingCity');
		Assert.isTrue(Pattern.compile('(?is)MailingState = \'VIC\'').matcher(soql).find(), 'Query should filter MailingState');
		Assert.isTrue(Pattern.compile('(?is)MailingPostalCode = \'3999\'').matcher(soql).find(), 'Query should filter MailingPostalCode');
	}

	@IsTest
	static void testSelectByCustomerSearchParamsQBWithAddressLine1And2() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.addressStreet1 = 'U 3';
		params.addressStreet2 = '123 Example St';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)\\(MailingStreet = \'U 3\' AND MailingStreet2__c = \'123 Example St\'\\)').matcher(soql).find(), 'Query should filter MailingStreet AND MailingStreet2__c');
		Assert.isTrue(Pattern.compile('(?is)\\bOR MailingStreet = \'U 3 123 Example St\'').matcher(soql).find(), 'Query should filter MailingStreet with AddressLine1+AddressLine2');
	}
	
	@IsTest
	static void testSelectByCustomerSearchParamsQBWithAddressLine2() {
		// =====================================
		// Data Preparation
		// =====================================
		ContactsSelector cs = ContactsSelector.newInstance();
		ContactsSelector.CustomerSearchParameters params = new ContactsSelector.CustomerSearchParameters();
		params.addressStreet2 = '123 Example St';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		String soql = cs.selectByCustomerSearchParamsQB(params, new Set<Object>());
		Test.stopTest();

		Assert.isTrue(Pattern.compile('(?is)\\bMailingStreet2__c = \'123 Example St\'').matcher(soql).find(), 'Query should filter MailingStreet2__c');
	}

	@IsTest
	static void testWithRelatedCasesOption() {
		// =====================================
		// Data Preparation
		// =====================================
		Set<Object> selectorOptions = new Set<Object>{ ContactsSelector.Options.WITH_RELATED_CASES };
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>> {
			Contact.SObjectType => new Set<SObjectField> { Contact.Id, Contact.Name },
			Case.SObjectType => new Set<SObjectField> { Case.Id, Case.Status }
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ContactsSelector selector = ContactsSelector.newInstance(0, fieldOverrides);
		String soql = selector.newQueryBuilder(selectorOptions).toSoqlString();
		
		Test.stopTest();

		// Verify the SELECT includes the sub-query
		String subQueryPattern = '\\(SELECT Id, Status\\s+FROM Cases\\s+ORDER BY CreatedDate Desc\\)';
		String subQueryExMsg = 'Did not match the Cases sub-query pattern.' + soql.replaceAll('\n','');
		Assert.isTrue(Pattern.compile('(?is)' + subQueryPattern).matcher(soql).find(), subQueryExMsg);
	}
}