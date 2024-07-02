/**
 * @author Marcel HK
 * @date 2024-06-03
 * @description - Test class for the `CustomerSearchFormController`
 * @changelog
 * 2024-06-03 - Marcel HK - Created
 */
@IsTest
public class CustomerSearchFormController_Test {
	static final Integer MAX_RESULTS = CustomerSearchFormController.MAX_RESULTS;
	static final Set<Object> CONTACT_SELECTOR_OPTIONS = CustomerSearchFormController.CONTACT_SELECTOR_OPTIONS;
	static final Set<SObjectField> CONTACT_FIELDS = CustomerSearchFormController.CONTACT_FIELDS;
	static final String NOT_ENOUGH_PARAMS_ERROR_MSG = CustomerSearchFormController.NOT_ENOUGH_PARAMS_ERROR_MSG;
	static final String TOO_MANY_RESULTS_WARNING_MSG = CustomerSearchFormController.TOO_MANY_RESULTS_WARNING_MSG;

	@IsTest
	static void testValidateSearchRequestWithFirstAndLastNameOnly() {
		try {
			CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();
			req.firstName = 'Joan';
			req.lastName = 'Watson';

			Test.startTest();
			CustomerSearchFormController.validateSearchRequest(req);
			Test.stopTest();
		} catch (CustomerSearchFormController.SearchException e) {
			Assert.fail('Should not throw exception (' + e.toString() + ')');
		}
	}

	@IsTest
	static void testValidateSearchRequestWithEmailOnly() {
		try {
			CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();
			req.emailAddress = 'sherlock@example.com';

			Test.startTest();
			CustomerSearchFormController.validateSearchRequest(req);
			Test.stopTest();
		} catch (CustomerSearchFormController.SearchException e) {
			Assert.fail('Should not throw exception (' + e.toString() + ')');
		}
	}

	@IsTest
	static void testValidateSearchRequestWithPhoneOnly() {
		try {
			CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();
			req.phoneNumber = '0411 222 333';

			Test.startTest();
			CustomerSearchFormController.validateSearchRequest(req);
			Test.stopTest();
		} catch (CustomerSearchFormController.SearchException e) {
			Assert.fail('Should not throw exception (' + e.toString() + ')');
		}
	}

	@IsTest
	static void testValidateSearchRequestWithMissingAllFeilds() {
		try {
			CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();
			Test.startTest();
			CustomerSearchFormController.validateSearchRequest(req);
			Test.stopTest();

			Assert.fail('SearchException should have been thrown');
		} catch (CustomerSearchFormController.SearchException e) {
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
			CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();
			req.firstName = ' ';
			req.lastName = 'Holmes';

			Test.startTest();
			CustomerSearchFormController.validateSearchRequest(req);
			Test.stopTest();

			Assert.fail('SearchException should have been thrown');
		} catch (CustomerSearchFormController.SearchException e) {
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
			CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();
			req.firstName = 'Sherlock';
			req.lastName = null;

			Test.startTest();
			CustomerSearchFormController.validateSearchRequest(req);
			Test.stopTest();

			Assert.fail('SearchException should have been thrown');
		} catch (CustomerSearchFormController.SearchException e) {
			Assert.areEqual(
				NOT_ENOUGH_PARAMS_ERROR_MSG,
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
		CustomerSearchFormController.SearchResponse res;
		res = CustomerSearchFormController.createResponse(contacts);
		Test.stopTest();

		Assert.isNotNull(res, 'Incorrect res object');
		Assert.areEqual(
			2,
			res.searchResults?.size(),
			'Incorrect number of search results'
		);
		Assert.isNull(res.warningMessage, 'Warning message should not be included');

		CustomerSearchFormController.SearchResult sr1 = res.searchResults.get(0);
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
	static void testCreateResponseWithNoContacts() {
		List<Contact> contacts = new List<Contact>();

		Test.startTest();
		CustomerSearchFormController.SearchResponse res;
		res = CustomerSearchFormController.createResponse(contacts);
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
		CustomerSearchFormController.SearchResponse res;
		res = CustomerSearchFormController.createResponse(contacts);
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
		CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();
		req.firstName = 'Jo';
		req.lastName = 'Watson';

		Test.startTest();
		CustomerSearchFormController.SearchResponse res;
		res = CustomerSearchFormController.search(req);
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
			.setFieldOverrides(CONTACT_FIELDS);
	}

	@IsTest
	static void testSearchWithInvalidParameters() {
		try {
			CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();

			Test.startTest();
			CustomerSearchFormController.search(req);
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
}
