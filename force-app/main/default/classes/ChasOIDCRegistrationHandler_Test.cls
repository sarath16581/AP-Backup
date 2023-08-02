/**
 * @description Test class for covering ChasOIDCRegistrationHandler
 * @author Nathan Franklin
 * @date 2023-03-20
 * @changelog
 * 2023-08-01 Mahesh Parvathaneni - Commented the test methods for confirmUser
*/
@IsTest
private with sharing class ChasOIDCRegistrationHandler_Test {

	/**
	 * Test:
	 *  Making sure that create user functions as expected
	 *  Simply covering behavioural testing since the bulk is covered in other test classes
	 */
	@IsTest
	private static void testUnitCreateUser() {

		// =====================================
		// Data Preparation
		// =====================================
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
		});
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		Auth.UserData userData = getUserData(personAccount, user);
		String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);

		// =====================================
		// Stubbing
		// =====================================
		ChasRegHandlerService mockService = (ChasRegHandlerService)MockUtility.mockUtility(ChasRegHandlerService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.validateAssertion(fflib_Match.eqString(federationId), (Map<String, String>)fflib_Match.anyObject())).thenReturn(new List<String>());
		MockUtility.Mocks.when(mockService.matchOrCreate(fflib_Match.eqString(federationId), (Map<String, String>)fflib_Match.anyObject())).thenReturn(user);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasOIDCRegistrationHandler loginHandler = new ChasOIDCRegistrationHandler();

		// can ignore attributes that aren't being used by passing null

		User createdUser = loginHandler.createUser(null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================

		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);

		// VERIFY: validateAssertion
		((ChasRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).validateAssertion(fflib_Match.eqString(federationId), (Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(userData.email.toUpperCase(), String.valueOf(augmentedAttributes.get('augmented_email_uppercase')));
		System.assertEquals(federationId, String.valueOf(augmentedAttributes.get('augmented_username')));
		System.assertEquals(userData.email, String.valueOf(augmentedAttributes.get('email')));
		System.assertEquals(userData.attributeMap.get('https://auspost/apcn'), String.valueOf(augmentedAttributes.get('https://auspost/apcn')));
		System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));

		// VERIFY: matchOrCreate
		((ChasRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).matchOrCreate(fflib_Match.eqString(federationId), (Map<String, String>)augmentedAttributesCaptor.capture());
		augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(userData.email.toUpperCase(), String.valueOf(augmentedAttributes.get('augmented_email_uppercase')));
		System.assertEquals(federationId, String.valueOf(augmentedAttributes.get('augmented_username')));
		System.assertEquals(userData.email, String.valueOf(augmentedAttributes.get('email')));
		System.assertEquals(userData.attributeMap.get('https://auspost/apcn'), String.valueOf(augmentedAttributes.get('https://auspost/apcn')));
		System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));

		// PMD warning
		System.assert(true);
	}

	// /**
	//  * Scenario:
	//  * Ensure that confirmUser happy path that the current user the TPAL is linked to is the actual user record we need to authenticate to
	//  */
	// @IsTest
	// private static void testUnitConfirmUserIsCurrentHappyPath() {

	// 	// =====================================
	// 	// Data Preparation
	// 	// =====================================
	// 	Id tpalId = '0Jr000000000000001';

	// 	Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
	// 	Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
	// 	personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
	// 	User userRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
	// 	Id userId = userRecord.Id;
	// 	Auth.UserData userData = getUserData(personAccount, userRecord);
	// 	String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);

	// 	Map<SObjectType, SObject> foundRecords = new Map<SObjectType, SObject>{
	// 		Account.SObjectType => personAccount,
	// 		User.SObjectType => userRecord
	// 	};

	// 	// =====================================
	// 	// Stubbing
	// 	// =====================================
	// 	ChasRegHandlerService mockService = (ChasRegHandlerService)MockUtility.mockUtility(ChasRegHandlerService.class);

	// 	// set up our responses
	// 	MockUtility.Mocks.startStubbing();
	// 	MockUtility.Mocks.when(mockService.getExistingRecords(fflib_Match.eqString(federationId), (Map<String, String>)fflib_Match.anyObject())).thenReturn(foundRecords);
	// 	MockUtility.Mocks.stopStubbing();

	// 	// =====================================
	// 	// Testing
	// 	// =====================================
	// 	Test.startTest();

	// 	ChasOIDCRegistrationHandler loginHandler = new ChasOIDCRegistrationHandler();
	// 	Id foundUserId = loginHandler.confirmUser(userId, tpalId, null, userData);

	// 	Test.stopTest();

	// 	// =====================================
	// 	// VERIFY
	// 	// =====================================

	// 	fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);

	// 	// VERIFY: getExistingRecords
	// 	((ChasRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getExistingRecords(fflib_Match.eqString(federationId), (Map<String, String>)augmentedAttributesCaptor.capture());
	// 	Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
	// 	System.assertEquals(userData.email.toUpperCase(), String.valueOf(augmentedAttributes.get('augmented_email_uppercase')));
	// 	System.assertEquals(federationId, String.valueOf(augmentedAttributes.get('augmented_username')));
	// 	System.assertEquals(userData.email, String.valueOf(augmentedAttributes.get('email')));
	// 	System.assertEquals(userData.attributeMap.get('https://auspost/apcn'), String.valueOf(augmentedAttributes.get('https://auspost/apcn')));
	// 	System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));

	// 	System.assertEquals(userId, foundUserId);
	// }

	// /**
	//  * Scenario:
	//  * Irrespective of the TPAL record that exists we still check to see if the user record the user is trying to authenticate to is correct or not
	//  * In this scenario, the the original linked user record is incorrect, however the correct person account / user record exist in which we authenticate and link the user to.
	//  */
	// @IsTest
	// private static void testUnitConfirmUserCanStillAuthenticateToAlternateUserWhenRemenantsOfOriginalUserExist() {

	// 	// =====================================
	// 	// Data Preparation
	// 	// =====================================
	// 	Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
	// 	Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
	// 	personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
		
	// 	// the original user record the TPAL record is still linked to
	// 	User oldUserRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
	// 	Id oldUserId = oldUserRecord.Id;

	// 	// the user record found during the getExistingRecords call
	// 	User userRecordAssociatedToPersonAccount = ApplicationTestDataFactory.getUsers(1, true)[0];
	// 	Id userId = userRecordAssociatedToPersonAccount.Id;
	// 	Auth.UserData userData = getUserData(personAccount, userRecordAssociatedToPersonAccount);
	// 	String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);

	// 	// the data set return from getExistingRecords
	// 	Map<SObjectType, SObject> foundRecords = new Map<SObjectType, SObject>{
	// 		Account.SObjectType => personAccount,
	// 		User.SObjectType => userRecordAssociatedToPersonAccount // NOTE: <-- the id is different from the one passed in
	// 	};

	// 	Id tpalId = '0Jr000000000000001';
	// 	Id ssoProviderId = '0Jr000000000000001';
	// 	ThirdPartyAccountLink existingTPALRecord = new ThirdPartyAccountLink(Id = tpalId, SsoProviderId = ssoProviderId, UserId = oldUserId);

	// 	// =====================================
	// 	// Stubbing
	// 	// =====================================
	// 	ChasRegHandlerService mockService = (ChasRegHandlerService)MockUtility.mockUtility(ChasRegHandlerService.class);
	// 	ThirdPartyAccountLinksSelector mockTPALSelector = (ThirdPartyAccountLinksSelector)MockUtility.mockSelector(ThirdPartyAccountLinksSelector.class);
	// 	ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

	// 	// set up our responses
	// 	MockUtility.Mocks.startStubbing();
	// 	MockUtility.Mocks.when(mockService.getExistingRecords(fflib_Match.eqString(federationId), (Map<String, String>)fflib_Match.anyObject())).thenReturn(foundRecords);
	// 	MockUtility.Mocks.when(mockService.userIsFederatedMatch((User)fflib_Match.eq(userRecordAssociatedToPersonAccount), fflib_Match.eqString(federationId))).thenReturn(true);
	// 	MockUtility.Mocks.when(mockTPALSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{tpalId}))).thenReturn(new List<ThirdPartyAccountLink>{existingTPALRecord});
	// 	MockUtility.Mocks.when(mockDatabase.revokeTokenAccess(fflib_Match.eqId(existingTPALRecord.SsoProviderId), fflib_Match.eqString(userData.provider), fflib_Match.eqId(oldUserId), fflib_Match.eqString(userData.identifier))).thenReturn(true);
	// 	MockUtility.Mocks.stopStubbing();

	// 	// =====================================
	// 	// Testing
	// 	// =====================================
	// 	Test.startTest();

	// 	ChasOIDCRegistrationHandler loginHandler = new ChasOIDCRegistrationHandler();
	// 	Id foundUserId = loginHandler.confirmUser(oldUserId, tpalId, null, userData);

	// 	Test.stopTest();

	// 	// =====================================
	// 	// VERIFY
	// 	// =====================================

	// 	fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);

	// 	// VERIFY: getExistingRecords
	// 	((ChasRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getExistingRecords(fflib_Match.eqString(federationId), (Map<String, String>)augmentedAttributesCaptor.capture());
	// 	Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
	// 	System.assertEquals(userData.email.toUpperCase(), String.valueOf(augmentedAttributes.get('augmented_email_uppercase')));
	// 	System.assertEquals(federationId, String.valueOf(augmentedAttributes.get('augmented_username')));
	// 	System.assertEquals(userData.email, String.valueOf(augmentedAttributes.get('email')));
	// 	System.assertEquals(userData.attributeMap.get('https://auspost/apcn'), String.valueOf(augmentedAttributes.get('https://auspost/apcn')));
	// 	System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));

	// 	((ChasRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).userIsFederatedMatch((User)fflib_Match.eq(userRecordAssociatedToPersonAccount), fflib_Match.eqString(federationId));
	// 	((ThirdPartyAccountLinksSelector)MockUtility.Mocks.verify(mockTPALSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{tpalId}));
	// 	((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).revokeTokenAccess(fflib_Match.eqId(existingTPALRecord.SsoProviderId), fflib_Match.eqString(userData.provider), fflib_Match.eqId(oldUserId), fflib_Match.eqString(userData.identifier));

	// 	System.assertEquals(userId, foundUserId);
	// }

	// /**
	//  * Scenario:
	//  * Irrespective of the TPAL record that exists we still check to see if the user record the user is trying to authenticate to is correct or not
	//  * In this scenario, the the original linked user record is incorrect, and we haven't been able to find the correct user record to authenticate to
	//  */
	// @IsTest
	// private static void testUnitConfirmUserShouldThrowAnExceptionSinceNoSuitableUserFound() {

	// 	// =====================================
	// 	// Data Preparation
	// 	// =====================================
	// 	Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
	// 	Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
	// 	personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'PersonContactId' => personContact.Id});
		
	// 	// the original user record the TPAL record is still linked to
	// 	User oldUserRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
	// 	Id oldUserId = oldUserRecord.Id;

	// 	// the user record found during the getExistingRecords call
	// 	User userRecordAssociatedToPersonAccount = ApplicationTestDataFactory.getUsers(1, true)[0];
	// 	Id userId = userRecordAssociatedToPersonAccount.Id;
	// 	Auth.UserData userData = getUserData(personAccount, userRecordAssociatedToPersonAccount);
	// 	String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);

	// 	// the data set return from getExistingRecords
	// 	Map<SObjectType, SObject> foundRecords = new Map<SObjectType, SObject>();

	// 	Id tpalId = '0Jr000000000000001';
	// 	Id ssoProviderId = '0Jr000000000000001';
	// 	ThirdPartyAccountLink existingTPALRecord = new ThirdPartyAccountLink(Id = tpalId, SsoProviderId = ssoProviderId, UserId = oldUserId);

	// 	// =====================================
	// 	// Stubbing
	// 	// =====================================
	// 	ChasRegHandlerService mockService = (ChasRegHandlerService)MockUtility.mockUtility(ChasRegHandlerService.class);
	// 	ThirdPartyAccountLinksSelector mockTPALSelector = (ThirdPartyAccountLinksSelector)MockUtility.mockSelector(ThirdPartyAccountLinksSelector.class);
	// 	ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

	// 	// set up our responses
	// 	MockUtility.Mocks.startStubbing();
	// 	MockUtility.Mocks.when(mockService.getExistingRecords(fflib_Match.eqString(federationId), (Map<String, String>)fflib_Match.anyObject())).thenReturn(foundRecords);
	// 	MockUtility.Mocks.when(mockService.userIsFederatedMatch((User)fflib_Match.eq(userRecordAssociatedToPersonAccount), fflib_Match.eqString(federationId))).thenReturn(true);
	// 	MockUtility.Mocks.when(mockTPALSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{tpalId}))).thenReturn(new List<ThirdPartyAccountLink>{existingTPALRecord});
	// 	MockUtility.Mocks.when(mockDatabase.revokeTokenAccess(fflib_Match.eqId(existingTPALRecord.SsoProviderId), fflib_Match.eqString(userData.provider), fflib_Match.eqId(oldUserId), fflib_Match.eqString(userData.identifier))).thenReturn(true);
	// 	MockUtility.Mocks.stopStubbing();

	// 	// =====================================
	// 	// Testing
	// 	// =====================================
	// 	Test.startTest();

	// 	try {
	// 		ChasOIDCRegistrationHandler loginHandler = new ChasOIDCRegistrationHandler();
	// 		loginHandler.confirmUser(oldUserId, tpalId, null, userData);

	// 		System.assert(false, 'Expected exception to be thrown since no suitable user was found to authenticate to.');
	// 	} catch(ChasRegHandlerService.RegHandlerException ex) {
	// 		System.assert(true);
	// 	} catch(Exception ex) {
	// 		System.assert(false);
	// 	}

	// 	Test.stopTest();

	// 	// =====================================
	// 	// VERIFY
	// 	// =====================================

	// 	fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);

	// 	// VERIFY: getExistingRecords
	// 	((ChasRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getExistingRecords(fflib_Match.eqString(federationId), (Map<String, String>)augmentedAttributesCaptor.capture());
	// 	Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
	// 	System.assertEquals(userData.email.toUpperCase(), String.valueOf(augmentedAttributes.get('augmented_email_uppercase')));
	// 	System.assertEquals(federationId, String.valueOf(augmentedAttributes.get('augmented_username')));
	// 	System.assertEquals(userData.email, String.valueOf(augmentedAttributes.get('email')));
	// 	System.assertEquals(userData.attributeMap.get('https://auspost/apcn'), String.valueOf(augmentedAttributes.get('https://auspost/apcn')));
	// 	System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));

	// 	((ThirdPartyAccountLinksSelector)MockUtility.Mocks.verify(mockTPALSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{tpalId}));
	// 	((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).revokeTokenAccess(fflib_Match.eqId(existingTPALRecord.SsoProviderId), fflib_Match.eqString(userData.provider), fflib_Match.eqId(oldUserId), fflib_Match.eqString(userData.identifier));

	// 	//make user this method is never called
	// 	((ChasRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.never())).userIsFederatedMatch((User)fflib_Match.eq(userRecordAssociatedToPersonAccount), fflib_Match.eqString(federationId));
	// }

	/**
	 * Test:
	 *  Making sure that create user functions as expected
	 *  Simply covering behavioural testing since the bulk is covered in other test classes
	 */
	@IsTest
	private static void testUnitUpdateUser() {

		// =====================================
		// Data Preparation
		// =====================================
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
		});
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		Id userId = user.Id;
		Auth.UserData userData = getUserData(personAccount, user);
		String federationId = ChasRegHandlerService.generateFederationIdentifier(userData.email);

		// =====================================
		// Stubbing
		// =====================================
		// stub service class since we don't need to test it here
		ChasRegHandlerService mockService = (ChasRegHandlerService)MockUtility.mockUtility(ChasRegHandlerService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.updateForExistingUser(fflib_Match.eqId(userId), (Map<String, String>)fflib_Match.anyObject())).thenReturn(user);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChasOIDCRegistrationHandler loginHandler = new ChasOIDCRegistrationHandler();
		loginHandler.updateUser(user.Id, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================

		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);

		// VERIFY: updateForExistingUser
		((ChasRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).updateForExistingUser(fflib_Match.eqId(userId), (Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(userData.email.toUpperCase(), String.valueOf(augmentedAttributes.get('augmented_email_uppercase')));
		System.assertEquals(federationId, String.valueOf(augmentedAttributes.get('augmented_username')));
		System.assertEquals(userData.email, String.valueOf(augmentedAttributes.get('email')));
		System.assertEquals(userData.attributeMap.get('https://auspost/apcn'), String.valueOf(augmentedAttributes.get('https://auspost/apcn')));
		System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));

		// PMD warning
		System.assert(true);
	}

	private static Auth.UserData getUserData(Account personAccount, User personUser) {
		// set our user data mock from the Auth Provider
		Id networkId = '0DB000000000000001';
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => personAccount.LastName + ', ' + personAccount.FirstName,
			'given_name' => personAccount.FirstName,
			'family_name' => personAccount.LastName,
			'email' => personAccount.PersonEmail,
			'https://auspost/apcn' => '123',
			'https://auspost/cnumber' => 'C0000000001',
			'sfdc_networkid' => networkId
		};
		Auth.UserData userData = new Auth.UserData(identifier, personAccount.FirstName, personAccount.LastName, personAccount.FirstName + ' ' + personAccount.LastName,
													personAccount.PersonEmail, null, personUser.Username, null, 'Open ID Connect', 'https://communityurl/', attributeMap);
		return userData;
	}
}