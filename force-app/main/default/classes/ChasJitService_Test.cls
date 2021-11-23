/**
 * @description Test class for covering ChasJitService
 * @author Nathan Franklin
 * @date 2020-04-24
 * @group Tests
 * @tags Service, Chas, Help and Support, H&S, Jit, login, login handler
 * @domain Help and Support
 * @changelog
 * 2020-08-02 - Nathan Franklin - Updated for new return values in ApplicationDatabase
 */
@IsTest
private with sharing class ChasJitService_Test {

	/**
	 * Test:
	 *  Making sure the validation is successful based on a valid set of attributes
	 */
	@IsTest
	private static void testUnitValidateAssertionIsSuccessful() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<String, String> attributes = getSuccessSAMLAttributes();

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByUsername((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitService service = new ChasJitService();
		List<String> errors = service.validateAssertion(attributes.get('User.FederationIdentifier'), attributes);
		System.assertEquals(0, errors.size(), 'Did not expected validation errors: ' + String.join(errors, ', '));

		// make sure the method behaved
		((UsersSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByUsername((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Making sure the validation fails when invalid attributes are passed in
	 */
	@IsTest
	private static void testUnitValidateAssertionFails() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<String, String> attributes = getSuccessSAMLAttributes();
		attributes.keySet().remove('User.Username');
		attributes.keySet().remove('User.Email');
		attributes.keySet().remove('User.LastName');

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockUtility(UsersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByUsername((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitService service = new ChasJitService();
		List<String> errors = service.validateAssertion(attributes.get('User.FederationIdentifier'), attributes);
		System.assertNotEquals(0, errors.size(), 'Expected validation errors but got none');

		// make sure the method behaved
		((UsersSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(0))).selectByUsername((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Making sure when matchOrCreate is called that it existing PersonAccount and User pathway is followed
	 */
	@IsTest
	private static void testUnitSuccessMatchOrCreateMatchesExistingPersonAccountAndUser() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<String, String> attributes = getSuccessSAMLAttributes();

		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{'ContactId' => personContact.Id});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAPCN((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
		MockUtility.Mocks.when(mockUsersSelector.selectByContactId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{user.Id => user});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitService service = new ChasJitService();
		User newUser = service.matchOrCreate(attributes.get('User.FederationIdentifier'), attributes);

		// these attributes are not updated if an existing User record is already associated to the PersonAccount record
		System.assertEquals(null, newUser.APCN__c, 'Expected valid APCN');
		System.assertEquals(null, newUser.OID_ID__c, 'Expected valid OID');
		System.assertEquals(null, newUser.Username, 'Expected valid Username');
		System.assertEquals(null, newUser.FederationIdentifier, 'Expected valid FederationIdentifier');

		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_FIRSTNAME_MAPPING), newUser.FirstName, 'Expected valid FirstName');
		System.assertEquals(attributes.get('User.LastName'), newUser.LastName, 'Expected valid LastName');
		System.assertEquals(attributes.get('User.Email'), newUser.Email, 'Expected valid Email');
		System.assertEquals(true, newUser.IsActive, 'Expected valid IsActive');

		// make sure the method behaved
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert((List<SObject>)fflib_Match.anyObject());

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Making sure when matchOrCreate is called that it existing PersonAccount new User pathway is followed
	 */
	@IsTest
	private static void testUnitSuccessMatchOrCreateMatchesExistingPersonAccountButRequiresNewUser() {

		// =====================================
		// Data Preparation
		// =====================================

		// grab the profile id before we mock the database
		// this store it so it's retrieved later on in the provision call
		Id profileId = ChasConstants.CONSUMER_COMMUNITY_PROFILE_ID;

		Map<String, String> attributes = getSuccessSAMLAttributes();

		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAPCN((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
		MockUtility.Mocks.when(mockUsersSelector.selectByContactId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitService service = new ChasJitService();
		User newUser = service.matchOrCreate(attributes.get('User.FederationIdentifier'), attributes);

		System.assertNotEquals(null, newUser.Alias, 'Expected valid Alias but got null');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_APCN_MAPPING), newUser.APCN__c, 'Expected valid APCN');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_CNUMBER_MAPPING), newUser.OID_ID__c, 'Expected valid OID');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_FIRSTNAME_MAPPING), newUser.FirstName, 'Expected valid FirstName');
		System.assertEquals(attributes.get('User.LastName'), newUser.LastName, 'Expected valid LastName');
		System.assertEquals(attributes.get('User.Email'), newUser.Email, 'Expected valid Email');
		System.assertEquals(attributes.get('User.Username'), newUser.Username, 'Expected valid Username');
		System.assertEquals(attributes.get('User.FederationIdentifier'), newUser.FederationIdentifier, 'Expected valid FederationIdentifier');
		System.assertEquals(ChasJitService.DEFAULT_LOCALESIDKEY, newUser.LocaleSidKey, 'Expected valid LocaleSidKey');
		System.assertEquals(ChasJitService.DEFAULT_LANGUAGELOCALEKEY, newUser.LanguageLocaleKey, 'Expected valid LanguageLocaleKey');
		System.assertEquals(ChasJitService.DEFAULT_TIMEZONESIDKEY, newUser.TimeZoneSidKey, 'Expected valid TimeZoneSidKey');
		System.assertEquals(ChasJitService.DEFAULT_EMAILENCODINGKEY, newUser.EmailEncodingKey, 'Expected valid EmailEncodingKey');
		System.assertEquals(true, newUser.IsActive, 'Expected valid IsActive');

		// make sure the method behaved
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Making sure when matchOrCreate is called that it existing PersonAccount new User pathway is followed
	 */
	@IsTest
	private static void testUnitSuccessWithSpecialAttributesMatchOrCreateMatchesExistingPersonAccountButRequiresNewUser() {

		// =====================================
		// Data Preparation
		// =====================================

		// grab the profile id before we mock the database
		// this store it so it's retrieved later on in the provision call
		Id profileId = ChasConstants.CONSUMER_COMMUNITY_PROFILE_ID;

		Map<String, String> attributes = getSuccessSAMLAttributesWithSpecialFields();

		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		SSSWAccountsSelector mockAccountsSelector = (SSSWAccountsSelector)MockUtility.mockSelector(SSSWAccountsSelector.class);
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAPCN((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{personAccount.Id => personAccount});
		MockUtility.Mocks.when(mockUsersSelector.selectByContactId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitService service = new ChasJitService();
		User newUser = service.matchOrCreate(attributes.get('User.FederationIdentifier'), attributes);
		System.assertEquals(attributes.get('User.LocaleSidKey'), newUser.LocaleSidKey, 'Expected valid LocaleSidKey');
		System.assertEquals(attributes.get('User.LanguageLocaleKey'), newUser.LanguageLocaleKey, 'Expected valid LanguageLocaleKey');
		System.assertEquals(attributes.get('User.TimeZoneSidKey'), newUser.TimeZoneSidKey, 'Expected valid TimeZoneSidKey');
		System.assertEquals(attributes.get('User.EmailEncodingKey'), newUser.EmailEncodingKey, 'Expected valid EmailEncodingKey');
		System.assertEquals(true, newUser.IsActive, 'Expected valid IsActive');

		// make sure the method behaved
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Making sure that an update user is successful
	 */
	@IsTest
	private static void testUnitUpdateExistingUserEnsureDirtyRecord() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<String, String> attributes = getSuccessSAMLAttributes();

		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{'ContactId' => personContact.Id});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{user.Id => user});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitService service = new ChasJitService();
		User newUser = service.updateExistingUser(user.Id, attributes.get('User.FederationIdentifier'), attributes);

		System.assertEquals(attributes.get('User.Email'), newUser.Email, 'Expected valid Email');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_FIRSTNAME_MAPPING), newUser.FirstName, 'Expected valid FirstName');
		System.assertEquals(attributes.get('User.LastName'), newUser.LastName, 'Expected valid LastName');
		System.assertEquals(true, newUser.IsActive, 'Expected valid IsActive');

		// make sure the method behaved
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Making sure that an update user method is successful but no user update occurs since all the attributes match what is in the user record
	 */
	@IsTest
	private static void testUnitUpdateExistingUserEnsureRecordIsNotDirty() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<String, String> attributes = getSuccessSAMLAttributes();

		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{'ContactId' => personContact.Id});

		//mimic the attributes in the SAML assertion
		user.FirstName = attributes.get(ChasJitService.ATTRIBUTE_FIRSTNAME_MAPPING);
		user.LastName = attributes.get('User.LastName');
		user.Email = attributes.get('User.Email');
		user.Username = attributes.get('User.Username');
		user.FederationIdentifier = attributes.get('User.FederationIdentifier');
		user.APCN__c = attributes.get(ChasJitService.ATTRIBUTE_APCN_MAPPING);
		user.OID_ID__c = attributes.get(ChasJitService.ATTRIBUTE_CNUMBER_MAPPING);
		user.IsActive = true;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{user.Id => user});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitService service = new ChasJitService();
		service.updateExistingUser(user.Id, attributes.get('User.FederationIdentifier'), attributes);

		// make sure the method behaved
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Test the end to end flow of provisioning a new user when a saml assertion is received
	 */
	@IsTest
	private static void testJitHandlerProvisionIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<String, String> attributes = getSuccessSAMLAttributes();

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitLoginHandler loginHandler = new ChasJitLoginHandler();
		User newUser = loginHandler.createUser(null, null, null, attributes.get('User.FederationIdentifier'), attributes, '');

		newUser = [Select Id, ContactId, Contact.APCN__c, Contact.OID_ID__c, Contact.FirstName, Contact.LastName, Contact.Email,
							FirstName, LastName, Email, Username, FederationIdentifier, IsActive, APCN__c, OID_ID__c
							From User Where Id = :newUser.Id];

		// verify
		System.assertEquals(attributes.get('User.Email').toLowerCase(), newUser.Email, 'Expected valid Email');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_FIRSTNAME_MAPPING), newUser.FirstName, 'Expected valid FirstName');
		System.assertEquals(attributes.get('User.LastName'), newUser.LastName, 'Expected valid LastName');
		System.assertEquals(attributes.get('User.FederationIdentifier'), newUser.FederationIdentifier, 'Expected valid FederationIdentifier');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_APCN_MAPPING), newUser.APCN__c, 'Expected valid APCN');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_CNUMBER_MAPPING), newUser.OID_ID__c, 'Expected valid OID');
		System.assertEquals(true, newUser.IsActive, 'Expected valid IsActive');
		System.assertEquals(attributes.get('User.Email').toLowerCase(), newUser.Contact.Email, 'Expected valid Email');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_FIRSTNAME_MAPPING), newUser.Contact.FirstName, 'Expected valid FirstName');
		System.assertEquals(attributes.get('User.LastName'), newUser.Contact.LastName, 'Expected valid LastName');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_APCN_MAPPING), newUser.Contact.APCN__c, 'Expected valid APCN');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_CNUMBER_MAPPING), newUser.Contact.OID_ID__c, 'Expected valid OID');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Test the end to end flow of updating a new user when a saml assertion is received
	 */
	@IsTest
	private static void testJitHandlerUpdateUserIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<String, String> attributes = getSuccessSAMLAttributes();
		attributes.put(ChasJitService.ATTRIBUTE_FIRSTNAME_MAPPING, 'Nathan2');
		attributes.put('User.LastName', 'Franklin2');
		attributes.put('User.Email', 'XXtest1@test1.test1.com');

		User usr = ApplicationTestDataFactory.getUsers(1, false)[0];
		insert usr;


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasJitLoginHandler loginHandler = new ChasJitLoginHandler();

		// update the user end-to-end
		loginHandler.updateUser(usr.Id, null, null, null, attributes.get('User.FederationIdentifier'), attributes, '');

		// verify
		usr = [Select Id, FirstName, LastName, Email
					From User Where Id = :usr.Id];

		System.assertEquals(attributes.get('User.Email').toLowerCase(), usr.Email, 'Expected valid Email');
		System.assertEquals(attributes.get(ChasJitService.ATTRIBUTE_FIRSTNAME_MAPPING), usr.FirstName, 'Expected valid FirstName');
		System.assertEquals(attributes.get('User.LastName'), usr.LastName, 'Expected valid LastName');

		Test.stopTest();
	}

	private static Map<String, String> getSuccessSAMLAttributes() {
		return new Map<String, String>{
				'https://saml.auspost.com.au/core/attributes/firstName' => 'Nathan',
				'https://saml.auspost.com.au/core/attributes/lastName' => 'Franklin',
				'User.LastName' => 'Franklin',
				'User.Email' => 'XXtest1@test1.test1.com',
				'User.IsActive' => '1',
				'User.Username' => 'XXtest1@test1.test1.com.community',
				'User.FederationIdentifier' => 'XXtest1@test1.test1.com.community',
				'https://saml.auspost.com.au/core/attributes/apcn' => '123456789',
				'https://saml.auspost.com.au/core/attributes/cnumber' => 'C123456789'
		};
	}

	private static Map<String, String> getSuccessSAMLAttributesWithSpecialFields() {
		return new Map<String, String>{
				'https://saml.auspost.com.au/core/attributes/firstName' => 'Nathan',
				'https://saml.auspost.com.au/core/attributes/lastName' => 'Franklin',
				'User.LastName' => 'Franklin',
				'User.Email' => 'XXtest1@test1.test1.com',
				'User.IsActive' => '1',
				'User.Username' => 'XXtest1@test1.test1.com.community',
				'User.FederationIdentifier' => 'XXtest1@test1.test1.com.community',
				'https://saml.auspost.com.au/core/attributes/apcn' => '123456789',
				'https://saml.auspost.com.au/core/attributes/cnumber' => 'C123456789',
				'User.LocaleSidKey' => 'en_US',
				'User.LanguageLocaleKey' => 'de',
				'User.TimeZoneSidKey' => 'Pacific/Fiji',
				'User.EmailEncodingKey' => 'ISO-8859-1',
				'User.Alias' => 'NFrank11'
		};
	}
}