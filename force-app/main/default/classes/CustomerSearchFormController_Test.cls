/**
 * @author Marcel HK
 * @date 2024-06-03
 * @group CustomerSearch
 * @tag CustomerSearch
 * @domain Core
 * @description - Test class for the `CustomerSearchFormController`
 * @changelog
 * 2024-06-03 - Marcel HK - Created
 */
@IsTest
public class CustomerSearchFormController_Test {
  static final Integer MAX_RESULTS = CustomerSearchFormController.MAX_RESULTS;
  static final String FIRST_LAST_NAME_REQ_ERROR_MSG = CustomerSearchFormController.FIRST_LAST_NAME_REQ_ERROR_MSG;
  static final String NOT_ENOUGH_PARAMS_ERROR_MSG = CustomerSearchFormController.NOT_ENOUGH_PARAMS_ERROR_MSG;
  static final String TOO_MANY_RESULTS_WARNING_MSG = CustomerSearchFormController.TOO_MANY_RESULTS_WARNING_MSG;

  @TestSetup
  static void makeData() {
    List<Account> accounts = new List<Account>{
      TestDataProvider.createBusinessAccount('Sherlock', null),
      TestDataProvider.createBusinessAccount('Joan', null),
      TestDataProvider.createBusinessAccount('Johnathan', null)
    };
    insert accounts;

    Contact c1 = TestDataProvider.createContact('', accounts.get(0).Id, null);
    c1.FirstName = 'Sherlock';
    c1.LastName = 'Holmes';

    Contact c2 = TestDataProvider.createContact('', accounts.get(1).Id, null);
    c2.FirstName = 'Joan';
    c2.LastName = 'Watson';

    Contact c3 = TestDataProvider.createContact('', accounts.get(2).Id, null);
    c3.FirstName = 'Johnathan';
    c3.LastName = 'Watson';

    List<Contact> contacts = new List<Contact>{ c1, c2, c3 };
    insert contacts;
  }

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
        FIRST_LAST_NAME_REQ_ERROR_MSG,
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
        FIRST_LAST_NAME_REQ_ERROR_MSG,
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

  @IsTest
  static void testExecuteSearch() {
    CustomerSearchFormController.SearchRequest req = new CustomerSearchFormController.SearchRequest();
    req.firstName = 'Sher';
    req.lastName = 'Hol';

    Test.startTest();
    Map<Id, Contact> res = CustomerSearchFormController.executeSearch(req);
    Test.stopTest();

    Assert.areEqual(1, res?.size(), 'Incorrect number of search results');
  }
}
