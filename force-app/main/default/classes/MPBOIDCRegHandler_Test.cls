/**
 * @description Test class for covering MPBOIDCRegHandler
 * @author Mahesh Parvathaneni
 * @date 2023-08-29
 * @changelog
*/

@IsTest
private with sharing class MPBOIDCRegHandler_Test {

	/**
	 * Test:
	 *  Making sure that create user functions as expected
	 *  Simply covering behavioural testing since the bulk is covered in other test classes
	 */
	@IsTest
	private static void testUnitCreateUserMatchActiveUser() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile mpbProfile = [SELECT Id,Name FROM Profile where Name = 'Mypost Business Help & Support Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts[0].Status__c = 'Active';
		contacts[0].OID_ID__c = 'C0000000001';
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contacts[0].Id}, mpbProfile.Id, true);
		users[0].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Contact' => contacts[0]});
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		Map<String, String> attributeMap = userData.attributeMap;
		attributeMap.put('cnumber', 'C0000000001');

		// =====================================
		// Stubbing
		// =====================================
		MPBRegHandlerService mockService = (MPBRegHandlerService)MockUtility.mockUtility(MPBRegHandlerService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(attributeMap);
		MockUtility.Mocks.when(mockService.validateAssertion((Map<String, String>)fflib_Match.anyObject())).thenReturn(new List<String>());
		MockUtility.Mocks.when(mockService.matchUser((Map<String, String>)fflib_Match.anyObject())).thenReturn(users[0]);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MPBOIDCRegHandler loginHandler = new MPBOIDCRegHandler();
		// can ignore attributes that aren't being used by passing null
		User matchedUser = loginHandler.createUser(null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());

		// VERIFY: validateAssertion
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).validateAssertion((Map<String, String>)augmentedAttributesCaptor.capture());

		// VERIFY: matchUser
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).matchUser((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));
		System.assertEquals(contacts[0].OID_ID__c, String.valueOf(augmentedAttributes.get('cnumber')));
		System.assertEquals(users[0].Id, matchedUser.Id, 'Expected matched user returned based on key criteria');
	}

	/**
	 * Scenario:
	 * Ensure that confirmUser happy path that the current user the TPAL is linked to is the actual user record we need to authenticate to
	 */
	@IsTest
	private static void testUnitConfirmUserIsCurrentHappyPath() {

		// =====================================
		// Data Preparation
		// =====================================
		Id tpalId = '0Jr000000000000001';

		Profile mpbProfile = [SELECT Id,Name FROM Profile where Name = 'Mypost Business Help & Support Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts[0].Status__c = 'Active';
		contacts[0].OID_ID__c = 'C0000000001';
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contacts[0].Id}, mpbProfile.Id, true);
		users[0].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Contact' => contacts[0]});
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		Map<String, String> attributeMap = userData.attributeMap;
		attributeMap.put('cnumber', 'C0000000001');

		// =====================================
		// Stubbing
		// =====================================
		MPBRegHandlerService mockService = (MPBRegHandlerService)MockUtility.mockUtility(MPBRegHandlerService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(attributeMap);
		MockUtility.Mocks.when(mockService.matchUser((Map<String, String>)fflib_Match.anyObject())).thenReturn(users[0]);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MPBOIDCRegHandler loginHandler = new MPBOIDCRegHandler();
		Id foundUserId = loginHandler.confirmUser(users[0].Id, tpalId, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());

		// VERIFY: matchUser
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).matchUser((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));
		System.assertEquals(contacts[0].OID_ID__c, String.valueOf(augmentedAttributes.get('cnumber')));
		System.assertEquals(users[0].Id, foundUserId, 'Expected matched user returned based on key criteria');

	}

	/**
	 * Scenario:
	 * Irrespective of the TPAL record that exists we still check to see if the user record the user is trying to authenticate to is correct or not
	 * In this scenario, the original linked user record is incorrect, however the correct user record exist in which we authenticate and link the user to.
	 */
	@IsTest
	private static void testUnitConfirmUserCanStillAuthenticateToAlternateUserWhenRemenantsOfOriginalUserExist() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile mpbProfile = [SELECT Id,Name FROM Profile where Name = 'Mypost Business Help & Support Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts.addAll(ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true));
		contacts[1].Status__c = 'Active';
		contacts[1].OID_ID__c = 'C0000000001';
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>{contacts[0].Id, contacts[1].Id}, mpbProfile.Id, true);
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Contact' => contacts[0]});
		users[1].IsActive = true;
		users[1] = (User) ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Contact' => contacts[1]});
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		Map<String, String> attributeMap = userData.attributeMap;
		attributeMap.put('cnumber', 'C0000000001');

		// the original user record the TPAL record is still linked to
		Id oldUserId = users[0].Id; //inactive user

		Id tpalId = '0Jr000000000000001';
		Id ssoProviderId = '0Jr000000000000001';
		ThirdPartyAccountLink existingTPALRecord = new ThirdPartyAccountLink(Id = tpalId, SsoProviderId = ssoProviderId, UserId = oldUserId);

		// =====================================
		// Stubbing
		// =====================================
		MPBRegHandlerService mockService = (MPBRegHandlerService)MockUtility.mockUtility(MPBRegHandlerService.class);
		ThirdPartyAccountLinksSelector mockTPALSelector = (ThirdPartyAccountLinksSelector)MockUtility.mockSelector(ThirdPartyAccountLinksSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(attributeMap);
		MockUtility.Mocks.when(mockService.matchUser((Map<String, String>)fflib_Match.anyObject())).thenReturn(users[1]);
		MockUtility.Mocks.when(mockTPALSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{tpalId}))).thenReturn(new List<ThirdPartyAccountLink>{existingTPALRecord});
		MockUtility.Mocks.when(mockDatabase.revokeTokenAccess(fflib_Match.eqId(existingTPALRecord.SsoProviderId), fflib_Match.eqString(userData.provider), fflib_Match.eqId(oldUserId), fflib_Match.eqString(userData.identifier))).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MPBOIDCRegHandler loginHandler = new MPBOIDCRegHandler();
		Id foundUserId = loginHandler.confirmUser(oldUserId, tpalId, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());

		// VERIFY: matchUser
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).matchUser((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));
		System.assertEquals(contacts[1].OID_ID__c, String.valueOf(augmentedAttributes.get('cnumber')));
		System.assertEquals(users[1].Id, foundUserId, 'Expected matched user returned based on key criteria');

		((ThirdPartyAccountLinksSelector)MockUtility.Mocks.verify(mockTPALSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{tpalId}));
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).revokeTokenAccess(fflib_Match.eqId(existingTPALRecord.SsoProviderId), fflib_Match.eqString(userData.provider), fflib_Match.eqId(oldUserId), fflib_Match.eqString(userData.identifier));

		System.assertEquals(users[1].Id, foundUserId, 'Expected matched user returned based on key criteria');
	}

	/**
	 * Scenario:
	 * When the TPAL record is empty, make sure we get the existing TPAL record for the user and provider
	 */
	@IsTest
	private static void testUnitConfirmUserCanStillAuthenticateWhenTPALIdIsEmpty() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile mpbProfile = [SELECT Id,Name FROM Profile where Name = 'Mypost Business Help & Support Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts[0].Status__c = 'Active';
		contacts[0].OID_ID__c = 'C0000000001';
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contacts[0].Id}, mpbProfile.Id, true);
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Contact' => contacts[0]});
		users[0].IsActive = true;
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		Map<String, String> attributeMap = userData.attributeMap;
		attributeMap.put('cnumber', 'C0000000001');

		Id tpalId;
		Id ssoProviderId = '0Jr000000000000001';
		ThirdPartyAccountLink existingTPALRecord = new ThirdPartyAccountLink(Id = tpalId, SsoProviderId = ssoProviderId, UserId = users[0].Id);

		// =====================================
		// Stubbing
		// =====================================
		MPBRegHandlerService mockService = (MPBRegHandlerService)MockUtility.mockUtility(MPBRegHandlerService.class);
		ThirdPartyAccountLinksSelector mockTPALSelector = (ThirdPartyAccountLinksSelector)MockUtility.mockSelector(ThirdPartyAccountLinksSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(attributeMap);
		MockUtility.Mocks.when(mockService.matchUser((Map<String, String>)fflib_Match.anyObject())).thenReturn(users[0]);
		MockUtility.Mocks.when(mockTPALSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<ThirdPartyAccountLink>{existingTPALRecord});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MPBOIDCRegHandler loginHandler = new MPBOIDCRegHandler();
		Id foundUserId = loginHandler.confirmUser(users[0].Id, tpalId, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());

		// VERIFY: matchUser
		((MPBRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).matchUser((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(userData.attributeMap.get('https://auspost/cnumber'), String.valueOf(augmentedAttributes.get('https://auspost/cnumber')));
		System.assertEquals(contacts[0].OID_ID__c, String.valueOf(augmentedAttributes.get('cnumber')));
		System.assertEquals(users[0].Id, foundUserId, 'Expected matched user returned based on key criteria');

		((ThirdPartyAccountLinksSelector)MockUtility.Mocks.verify(mockTPALSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		System.assertEquals(users[0].Id, foundUserId, 'Expected matched user returned based on key criteria');

	}

	private static Auth.UserData getUserData(Contact contact, User user) {
		// set our user data mock from the Auth Provider
		Id networkId = '0DB000000000000001';
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => contact.LastName + ', ' + contact.FirstName,
			'given_name' => contact.FirstName,
			'family_name' => contact.LastName,
			'email' => contact.Email,
			'https://auspost/apcn' => '123',
			'https://auspost/cnumber' => 'C0000000001',
			'sfdc_networkid' => networkId
		};
		Auth.UserData userData = new Auth.UserData(identifier, contact.FirstName, contact.LastName, contact.FirstName + ' ' + contact.LastName,
													contact.Email, null, user.Username, null, 'Open ID Connect', 'https://communityurl/', attributeMap);
		return userData;
	}
	
}