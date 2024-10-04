/**
 * @author Marcel HK
 * @date 2024-06-03
 * @description - Test class for the `UnifiedCustomerSearchController`
 * @changelog
 * 2024-06-03 - Marcel HK - Created
 * 2024-07-02 - Marcel HK - Corrected form validation logic to align with associated LWC (CSLU-438)
 * 2024-07-17 - Marcel HK - Add customer type parameters (CSLU-446) and refactor data transform into separate function
 * 2024-07-22 - Marcel HK - Added mailing address filters (CSLU-1072)
 * 2024-07-23 - Marcel HK - Removed 'Country' mailing address filters (CSLU-1072)
 * 2024-07-23 - Marcel HK - Added accountId and abn/acn properties (CSLU-447)
 * 2024-07-26 - Marcel HK - Add customer type (CSLU-449)
 * 2024-07-26 - Marcel HK - Add mailing address and related case count (CSLU-439)
 * 2024-08-05 - Marcel HK - Refactor to `CustomerSearchFormController` to `UnifiedCustomerSearchController`
 */
@IsTest
public class UnifiedCustomerSearchController_Test {
	static final Integer MAX_RESULTS = UnifiedCustomerSearchController.MAX_RESULTS;
	static final Set<Object> CONTACT_SELECTOR_OPTIONS = UnifiedCustomerSearchController.CONTACT_SELECTOR_OPTIONS;
	static final Map<SObjectType, Set<SObjectField>> SELECTOR_FIELDS = UnifiedCustomerSearchController.SELECTOR_FIELDS;
	static final String NOT_ENOUGH_PARAMS_ERROR_MSG = UnifiedCustomerSearchController.NOT_ENOUGH_PARAMS_ERROR_MSG;
	static final String TOO_MANY_RESULTS_WARNING_MSG = UnifiedCustomerSearchController.TOO_MANY_RESULTS_WARNING_MSG;
	static final String INVALID_ABN_ACN_ERROR_MSG = UnifiedCustomerSearchController.INVALID_ABN_ACN_ERROR_MSG;

	@IsTest
	static void testValidateSearchRequestWithFirstAndLastNameOnly() {
		try {
			UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
			req.firstName = 'Joan';
			req.lastName = 'Watson';

			Test.startTest();
			UnifiedCustomerSearchController.validateSearchRequest(req);
			Test.stopTest();
		} catch (UnifiedCustomerSearchController.SearchException e) {
			Assert.fail('Should not throw exception (' + e.toString() + ')');
		}
	}

	@IsTest
	static void testValidateSearchRequestWithEmailOnly() {
		try {
			UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
			req.emailAddress = 'sherlock@example.com';

			Test.startTest();
			UnifiedCustomerSearchController.validateSearchRequest(req);
			Test.stopTest();
		} catch (UnifiedCustomerSearchController.SearchException e) {
			Assert.fail('Should not throw exception (' + e.toString() + ')');
		}
	}

	@IsTest
	static void testValidateSearchRequestWithPhoneOnly() {
		try {
			UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
			req.phoneNumber = '0411 222 333';

			Test.startTest();
			UnifiedCustomerSearchController.validateSearchRequest(req);
			Test.stopTest();
		} catch (UnifiedCustomerSearchController.SearchException e) {
			Assert.fail('Should not throw exception (' + e.toString() + ')');
		}
	}

	@IsTest
	static void testValidateSearchRequestWithMissingAllFeilds() {
		try {
			UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
			Test.startTest();
			UnifiedCustomerSearchController.validateSearchRequest(req);
			Test.stopTest();

			Assert.fail('SearchException should have been thrown');
		} catch (UnifiedCustomerSearchController.SearchException e) {
			Assert.areEqual(
				NOT_ENOUGH_PARAMS_ERROR_MSG,
				e.getMessage(),
				'Incorrect exception message'
			);
		}
	}

	@IsTest
	static void testValidateSearchRequestWithMissingFirstNameError() {
		try {
			UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
			req.firstName = ' ';
			req.lastName = 'Holmes';

			Test.startTest();
			UnifiedCustomerSearchController.validateSearchRequest(req);
			Test.stopTest();

			Assert.fail('SearchException should have been thrown');
		} catch (UnifiedCustomerSearchController.SearchException e) {
			Assert.areEqual(
				NOT_ENOUGH_PARAMS_ERROR_MSG,
				e.getMessage(),
				'Incorrect exception message'
			);
		}
	}

	@IsTest
	static void testValidateSearchRequestWithMissingLastNameError() {
		try {
			UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
			req.firstName = 'Sherlock';
			req.lastName = null;

			Test.startTest();
			UnifiedCustomerSearchController.validateSearchRequest(req);
			Test.stopTest();

			Assert.fail('SearchException should have been thrown');
		} catch (UnifiedCustomerSearchController.SearchException e) {
			Assert.areEqual(
				NOT_ENOUGH_PARAMS_ERROR_MSG,
				e.getMessage(),
				'Incorrect exception message'
			);
		}
	}

	@IsTest
	static void testValidateSearchRequestWithInvalidAbnAcn() {
		try {
			UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
			req.firstName = 'Joan';
			req.lastName = 'Watson';
			req.abnAcn = '123';

			Test.startTest();
			UnifiedCustomerSearchController.validateSearchRequest(req);
			Test.stopTest();

			Assert.fail('SearchException should have been thrown');
		} catch (UnifiedCustomerSearchController.SearchException e) {
			Assert.areEqual(
				INVALID_ABN_ACN_ERROR_MSG,
				e.getMessage(),
				'Incorrect exception message'
			);
		}
	}

	@IsTest
	static void testCreateResponseWithContacts() {
		List<Contact> contacts = new List<Contact>();
		contacts.add(
			new Contact(
				FirstName = 'Sherlock',
				LastName = 'Holmes',
				Preferred_Name__c = 'S',
				Email = 'sherlock@example.com',
				VerifiedEmail__c = 'sherlock.verified@example.com',
				Phone = '03 9876 5432',
				MobilePhone = '0400111222',
				VerifiedMobile__c = '0499888777'
			)
		);
		contacts.add(
			new Contact(
				FirstName = 'Joan',
				LastName = 'Watson',
				Email = 'jwatson@example.com'
			)
		);

		Test.startTest();
		UnifiedCustomerSearchController.SearchResponse res;
		res = UnifiedCustomerSearchController.createResponse(contacts);
		Test.stopTest();

		Assert.isNotNull(res, 'Incorrect res object');
		Assert.areEqual(
			2,
			res.searchResults?.size(),
			'Incorrect number of search results'
		);
		Assert.isNull(res.warningMessage, 'Warning message should not be included');

		UnifiedCustomerSearchController.SearchResult sr1 = res.searchResults.get(0);
		Assert.isNotNull(res, 'SearchResult should not be null');
		Assert.areEqual('Sherlock', sr1.firstName, 'First Name should match');
		Assert.areEqual('Holmes', sr1.lastName, 'Last Name should match');
		Assert.areEqual('S', sr1.preferredName, 'Preferred Name should match');
		Assert.areEqual(
			'sherlock@example.com',
			sr1.emailAddress,
			'Email should match'
		);
		Assert.areEqual(
			'sherlock.verified@example.com',
			sr1.verifiedEmailAddress,
			'Verified Email should match'
		);
		Assert.areEqual('03 9876 5432', sr1.phone, 'Phone should match');
		Assert.areEqual('0400111222', sr1.mobilePhone, 'Mobile Phone should match');
		Assert.areEqual(
			'0499888777',
			sr1.verifiedMobilePhone,
			'Verified Mobile should match'
		);
	}

	@IsTest
	static void testSearchResultTransformWithMailingAddress() {
		Contact c = new Contact(
			MailingStreet = 'Level 9',
			MailingStreet2__c = '111 Bourke St',
			MailingCity = 'Melbourne',
			MailingState = 'VIC',
			MailingPostalCode = '3000',
			MailingCountry = 'AU'
		);

		Test.startTest();
		UnifiedCustomerSearchController.SearchResult sr;
		sr = new UnifiedCustomerSearchController.SearchResult(c);
		Test.stopTest();

		Assert.areEqual('Level 9', sr.mailingStreet, 'mailingStreet should match');
		Assert.areEqual(
			'111 Bourke St',
			sr.mailingStreet2,
			'mailingStreet2 should match'
		);
		Assert.areEqual('Melbourne', sr.mailingCity, 'mailingCity should match');
		Assert.areEqual('VIC', sr.mailingState, 'mailingState should match');
		Assert.areEqual(
			'3000',
			sr.mailingPostalCode,
			'mailingPostalCode should match'
		);
		Assert.areEqual('AU', sr.mailingCountry, 'mailingCountry should match');
	}

	@IsTest
	static void testSearchResultTransformWithRelatedCases() {
		// Prepare related cases
		List<Case> relatedCases = new List<Case>();
		// Create 2 open cases
		for (Case caseObj : ApplicationTestDataFactory.getCases(2, false)) {
			relatedCases.add(
				(Case) ApplicationTestDataFactory.setUnwritableFields(
					caseObj,
					new Map<String, Object>{ 'IsClosed' => false }
				)
			);
		}
		// Crate 3 closed cases
		for (Case caseObj : ApplicationTestDataFactory.getCases(3, false)) {
			relatedCases.add(
				(Case) ApplicationTestDataFactory.setUnwritableFields(
					caseObj,
					new Map<String, Object>{ 'IsClosed' => true }
				)
			);
		}

		// Create contact with related cases
		Contact contactObj = new Contact();
		contactObj = (Contact) ApplicationTestDataFactory.setChildRelationships(
			contactObj,
			new Map<String, List<SObject>>{ 'Cases' => relatedCases }
		);

		Test.startTest();
		UnifiedCustomerSearchController.SearchResult sr;
		sr = new UnifiedCustomerSearchController.SearchResult(contactObj);
		Test.stopTest();

		Assert.areEqual(2, sr.openCasesCount, 'Incorrect openCasesCount');
		Assert.areEqual(5, sr.totalCasesCount, 'Incorrect totalCasesCount');
	}

	@IsTest
	static void testSearchResultTransformWithConsumer() {
		Contact c = new Contact();
		Account acc = new Account(Name = 'Test Account');
		acc = (Account) ApplicationTestDataFactory.setUnwritableFields(acc, new Map<String, Object>{ 'IsPersonAccount' => true});
		c = (Contact) ApplicationTestDataFactory.setUnwritableFields(c, new Map<String, Object>{ 'Account' => acc});

		Test.startTest();
		UnifiedCustomerSearchController.SearchResult sr;
		sr = new UnifiedCustomerSearchController.SearchResult(c);
		Test.stopTest();

		Assert.areEqual('Consumer', sr.customerType, 'Incorrect Customer Type');
		Assert.isNull(sr.organisationName, 'Consumer should not have Organisation Name');
	}
	
	@IsTest
	static void testSearchResultTransformWithSMB() {
		Contact c = new Contact();
		Account acc = new Account(Name = 'Test Account');
		acc = (Account) ApplicationTestDataFactory.setUnwritableFields(acc, new Map<String, Object>{ 'IsPersonAccount' => false, 'Role_Type_Roll_Up__c' => 'Customer' });
		c = (Contact) ApplicationTestDataFactory.setUnwritableFields(c, new Map<String, Object>{ 'Account' => acc});

		Test.startTest();
		UnifiedCustomerSearchController.SearchResult sr;
		sr = new UnifiedCustomerSearchController.SearchResult(c);
		Test.stopTest();

		Assert.areEqual('SMB', sr.customerType, 'Incorrect Customer Type');
		Assert.areEqual('Test Account', sr.organisationName, 'Incorrect Organisation Name');
	}

	@IsTest
	static void testSearchResultTransformWithEnterprise() {
		Contact c = new Contact();
		Account acc = new Account(Name = 'Test Account', ServiceSLA__c = 'Enterprise');
		acc = (Account) ApplicationTestDataFactory.setUnwritableFields(acc, new Map<String, Object>{ 'IsPersonAccount' => false, 'Role_Type_Roll_Up__c' => 'Customer' });
		c = (Contact) ApplicationTestDataFactory.setUnwritableFields(c, new Map<String, Object>{ 'Account' => acc});

		Test.startTest();
		UnifiedCustomerSearchController.SearchResult sr;
		sr = new UnifiedCustomerSearchController.SearchResult(c);
		Test.stopTest();

		Assert.areEqual('Enterprise', sr.customerType, 'Incorrect Customer Type');
		Assert.areEqual('Test Account', sr.organisationName, 'Incorrect Organisation Name');
	}

	@IsTest
	static void testSearchResultTransformWithConsumerSMB() {
		Contact c = new Contact();
		Account acc = new Account(Name = 'Test Account');
		acc = (Account) ApplicationTestDataFactory.setUnwritableFields(acc, new Map<String, Object>{ 'IsPersonAccount' => false });
		c = (Contact) ApplicationTestDataFactory.setUnwritableFields(c, new Map<String, Object>{ 'Account' => acc});

		Test.startTest();
		UnifiedCustomerSearchController.SearchResult sr;
		sr = new UnifiedCustomerSearchController.SearchResult(c);
		Test.stopTest();

		Assert.areEqual('Consumer SMB', sr.customerType, 'Incorrect Customer Type');
		Assert.areEqual('Test Account', sr.organisationName, 'Incorrect Organisation Name');
	}

	@IsTest
	static void testCreateResponseWithNoContacts() {
		List<Contact> contacts = new List<Contact>();

		Test.startTest();
		UnifiedCustomerSearchController.SearchResponse res;
		res = UnifiedCustomerSearchController.createResponse(contacts);
		Test.stopTest();

		Assert.isNotNull(res, 'Incorrect res object');
		Assert.areEqual(
			0,
			res.searchResults?.size(),
			'Incorrect number of search results'
		);
		Assert.isNull(res.warningMessage, 'Warning message should not be included');
	}

	@IsTest
	static void testCreateResponseWithMaxResultsWarning() {
		// Create more Contact objects than the MAX_RESULTS value
		List<Contact> contacts = new List<Contact>();
		Integer numResults = MAX_RESULTS + 10;
		for (Integer i = 0; i < numResults; i++) {
			contacts.add(new Contact(LastName = 'Test ' + i));
		}

		Test.startTest();
		UnifiedCustomerSearchController.SearchResponse res;
		res = UnifiedCustomerSearchController.createResponse(contacts);
		Test.stopTest();

		Assert.isNotNull(res, 'Incorrect res object');
		Assert.areEqual(
			MAX_RESULTS,
			res.searchResults?.size(),
			'Incorrect number of search results'
		);
		Assert.areEqual(
			TOO_MANY_RESULTS_WARNING_MSG,
			res.warningMessage,
			'Incorrect warning message'
		);
	}

	@IsTest
	static void testSearchWithValidParameters() {
		// =====================================
		// Data Preparation
		// =====================================
		Map<Id, Contact> mockContactsMap = new Map<Id, Contact>();
		Contact c1 = new Contact(
			Id = fflib_IDGenerator.generate(Contact.getSObjectType()),
			FirstName = 'Joan',
			LastName = 'Watson'
		);
		mockContactsMap.put(c1.Id, c1);
		Contact c2 = new Contact(
			Id = fflib_IDGenerator.generate(Contact.getSObjectType()),
			FirstName = 'Johnathan',
			LastName = 'Watson'
		);
		mockContactsMap.put(c2.Id, c2);

		// =====================================
		// Stubbing
		// =====================================
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(
			ContactsSelector.class
		);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockContactsSelector.selectByCustomerSearchParams(
					(ContactsSelector.CustomerSearchParameters) fflib_Match.anyObject(),
					(Set<Object>) fflib_Match.anyObject()
				)
			)
			.thenReturn(mockContactsMap);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
		req.firstName = 'Jo';
		req.lastName = 'Watson';

		Test.startTest();
		UnifiedCustomerSearchController.SearchResponse res;
		res = UnifiedCustomerSearchController.search(req);
		Test.stopTest();

		Assert.isNotNull(res, 'Incorrect res object');
		Assert.areEqual(
			2,
			res.searchResults?.size(),
			'Incorrect number of search results'
		);

		// Verify the ContactsSelector instance was created correctly (stince we cannot mock static newInstance method)
		((ContactsSelector) MockUtility.Mocks.verify(mockContactsSelector))
			.setLimit(MAX_RESULTS + 1);
		((ContactsSelector) MockUtility.Mocks.verify(mockContactsSelector))
			.setFieldOverrides(SELECTOR_FIELDS);
	}

	@IsTest
	static void testSearchWithInvalidParameters() {
		try {
			UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();

			Test.startTest();
			UnifiedCustomerSearchController.search(req);
			Test.stopTest();

			Assert.fail('AuraHandledException should have been thrown');
		} catch (AuraHandledException e) {
			Assert.areEqual(
				NOT_ENOUGH_PARAMS_ERROR_MSG,
				e.getMessage(),
				'Incorrect exception message'
			);
		}
	}

	@IsTest
	static void testTransformSearchRequestWithBasicDetails() {
		UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
		req.firstName = 'John';
		req.lastName = 'Smith';
		req.emailAddress = 'john@smith.com';
		req.phoneNumber = '0412 345 678';

		Test.startTest();
		ContactsSelector.CustomerSearchParameters params = UnifiedCustomerSearchController.transformSearchRequest(
			req
		);
		Test.stopTest();

		Assert.isNotNull(params, 'Must return params object');
		Assert.areEqual('John', params.firstName, 'First name should match');
		Assert.areEqual('Smith', params.lastName, 'Last name should match');
		Assert.areEqual('john@smith.com', params.emailAddress, 'Email address should match');
		Assert.areEqual('0412 345 678', params.phoneNumber, 'Phone number should match');
		Assert.isNull(params.customerType, 'Customer type should not be set');
	}

	@IsTest
	static void testTransformSearchRequestWithConsumer() {
		UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
		req.customerType = 'CONSUMER';

		Test.startTest();
		ContactsSelector.CustomerSearchParameters params = UnifiedCustomerSearchController.transformSearchRequest(
			req
		);
		Test.stopTest();

		Assert.areEqual(
			ContactsSelector.CustomerSearchCustomerType.CONSUMER,
			params.customerType,
			'Customer type should match'
		);
	}

	@IsTest
	static void testTransformSearchRequestWithOrganisation() {
		UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
		req.customerType = 'ORGANISATION';

		Test.startTest();
		ContactsSelector.CustomerSearchParameters params = UnifiedCustomerSearchController.transformSearchRequest(
			req
		);
		Test.stopTest();

		Assert.areEqual(
			ContactsSelector.CustomerSearchCustomerType.ORGANISATION,
			params.customerType,
			'Customer type should match'
		);
	}

	@IsTest
	static void testTransformSearchRequestWithAddress() {
		UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
		req.addressStreet1 = '123 Example St';
		req.addressStreet2 = 'Example Line 2';
		req.addressCity = 'Example Town';
		req.addressState = 'VIC';
		req.addressPostalCode = '3999';

		Test.startTest();
		ContactsSelector.CustomerSearchParameters params = UnifiedCustomerSearchController.transformSearchRequest(
			req
		);
		Test.stopTest();

		Assert.areEqual('123 Example St', params.addressStreet1, 'Street1 should match');
		Assert.areEqual('Example Line 2', params.addressStreet2, 'Street2 should match');
		Assert.areEqual('Example Town', params.addressCity, 'City should match');
		Assert.areEqual('VIC', params.addressState, 'State should match');
		Assert.areEqual('3999', params.addressPostalCode, 'PostalCode should match');
	}

	@IsTest
	static void testTransformSearchRequestWithOrganisationDetails() {
		UnifiedCustomerSearchController.SearchRequest req = new UnifiedCustomerSearchController.SearchRequest();
		req.accountId = fflib_IDGenerator.generate(Account.getSObjectType());
		req.abnAcn = '11222333444';

		Test.startTest();
		ContactsSelector.CustomerSearchParameters params = UnifiedCustomerSearchController.transformSearchRequest(
			req
		);
		Test.stopTest();

		Assert.isNotNull(params.abnAcn, 'AccountId should be set');
		Assert.areEqual(req.accountId, params.accountId, 'AccountId should match');
		Assert.areEqual('11222333444', params.abnAcn, 'ABN/ACN should match');
	}
}