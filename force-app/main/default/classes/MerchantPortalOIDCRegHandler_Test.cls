/**
 * @description Test class for covering MerchantPortalOIDCRegHandler
 * @author Mahesh Parvathaneni
 * @date 2023-08-08
 * @changelog
*/

@IsTest
private class MerchantPortalOIDCRegHandler_Test {

	/**
	 * Test:
	 * Making sure that create user functions as expected and matched user returned based on
	 * federation identifier
	 */
	@IsTest
	private static void testUnitCreateUserMatchActiveUserByFedId() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].LEGACY_ID__c =  '60000';
		accounts[1].LEGACY_ID__c =  '60001';
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts.addAll(ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true));
		contacts[0].Status__c = 'Active';
		contacts[1].Status__c = 'Active';
		contacts[0].OID_ID__c = 'C0000000001';
		contacts[1].OID_ID__c = 'C0000000001';
		contacts[0] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{'Account' => accounts[0]});
		contacts[1] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[1], new Map<String, Object>{'Account' => accounts[1]});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>{contacts[0].Id, contacts[1].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';
		//set fed id for the user for matching
		users[0].FederationIdentifier = fedId;
		users[0].IsActive = true;
		users[1].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});
		users[1] = (User) ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[1]});

		List<NetworkMember> networkMembers = ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[0].Id, true);
		networkMembers.addAll(ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[1].Id, true));


		// =====================================
		// Stubbing
		// =====================================
		MerchantPortalRegHandlerService mockService = (MerchantPortalRegHandlerService)MockUtility.mockUtility(MerchantPortalRegHandlerService.class);
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		NetworkMembersSelector mockNetworkMembersSelector = (NetworkMembersSelector) MockUtility.mockSelector(NetworkMembersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(userData.attributeMap);
		MockUtility.Mocks.when(mockService.validateAssertion((Map<String, String>)fflib_Match.anyObject())).thenReturn(new List<String>());
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(users);
		MockUtility.Mocks.when(mockNetworkMembersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkMembers);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
		// can ignore attributes that aren't being used by passing null
		User createdUser = loginHandler.createUser(null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================

		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(fedId, String.valueOf(augmentedAttributes.get('federation_identifier')));
		System.assertEquals(cNumber, String.valueOf(augmentedAttributes.get('cnumber')));

		// VERIFY: validateAssertion
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).validateAssertion((Map<String, String>)augmentedAttributesCaptor.capture());

		System.assertEquals(users[0].Id, createdUser.Id, 'Expected matched user returned based on FederationIdentifier');
		System.assertNotEquals(users[1].Id, createdUser.Id, 'Expected matched user returned based on FederationIdentifier');

	}

	/**
	 * Test:
	 * Making sure that create user functions as expected and matched user returned based on
	 * federation identifier and make the matched user active
	 */
	@IsTest
	private static void testUnitCreateUserMatchUserByFedIdAndMakeActive() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].LEGACY_ID__c =  '60000';
		accounts[1].LEGACY_ID__c =  '60001';
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts.addAll(ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true));
		contacts[0].Status__c = 'Active';
		contacts[1].Status__c = 'Active';
		contacts[0].OID_ID__c = 'C0000000001';
		contacts[1].OID_ID__c = 'C0000000001';
		contacts[0] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{'Account' => accounts[0]});
		contacts[1] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[1], new Map<String, Object>{'Account' => accounts[1]});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>{contacts[0].Id, contacts[1].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';
		//set fed id for the user for matching
		users[0].FederationIdentifier = fedId;
		users[0].IsActive = false; //user is inactive here
		users[1].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});
		users[1] = (User) ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[1]});

		List<NetworkMember> networkMembers = ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[0].Id, true);
		networkMembers.addAll(ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[1].Id, true));


		// =====================================
		// Stubbing
		// =====================================
		MerchantPortalRegHandlerService mockService = (MerchantPortalRegHandlerService)MockUtility.mockUtility(MerchantPortalRegHandlerService.class);
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		NetworkMembersSelector mockNetworkMembersSelector = (NetworkMembersSelector) MockUtility.mockSelector(NetworkMembersSelector.class);
		ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(userData.attributeMap);
		MockUtility.Mocks.when(mockService.validateAssertion((Map<String, String>)fflib_Match.anyObject())).thenReturn(new List<String>());
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(users);
		MockUtility.Mocks.when(mockNetworkMembersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkMembers);
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
		// can ignore attributes that aren't being used by passing null
		User createdUser = loginHandler.createUser(null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================

		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(fedId, String.valueOf(augmentedAttributes.get('federation_identifier')));
		System.assertEquals(cNumber, String.valueOf(augmentedAttributes.get('cnumber')));

		// VERIFY: validateAssertion
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).validateAssertion((Map<String, String>)augmentedAttributesCaptor.capture());

		System.assertEquals(users[0].Id, createdUser.Id, 'Expected matched user returned based on FederationIdentifier');
		System.assertNotEquals(users[1].Id, createdUser.Id, 'Expected matched user returned based on FederationIdentifier');

		// verify that updates has been done
		((ApplicationDatabase) MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>) fflib_Match.anyList());

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

		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts.addAll(ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true));
		contacts[0] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{'Account' => accounts[0]});
		contacts[1] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[1], new Map<String, Object>{'Account' => accounts[1]});
		contacts[0].OID_ID__c = 'C0000000001';
		contacts[1].OID_ID__c = 'C0000000001';
		contacts[0].Status__c = 'Active';
		contacts[1].Status__c = 'Active';

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>{contacts[0].Id, contacts[1].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';
		users[0].IsActive = true;
		users[1].IsActive = true;
		//set fed id for the user for matching
		users[1].FederationIdentifier = fedId;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});
		users[1] = (User) ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[1]});

		List<NetworkMember> networkMembers = ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[0].Id, true);
		networkMembers.addAll(ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[1].Id, true));


		// =====================================
		// Stubbing
		// =====================================
		MerchantPortalRegHandlerService mockService = (MerchantPortalRegHandlerService)MockUtility.mockUtility(MerchantPortalRegHandlerService.class);
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		NetworkMembersSelector mockNetworkMembersSelector = (NetworkMembersSelector) MockUtility.mockSelector(NetworkMembersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(userData.attributeMap);
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(users);
		MockUtility.Mocks.when(mockNetworkMembersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkMembers);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
		Id foundUserId = loginHandler.confirmUser(users[1].Id, tpalId, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(fedId, String.valueOf(augmentedAttributes.get('federation_identifier')));
		System.assertEquals(cNumber, String.valueOf(augmentedAttributes.get('cnumber')));

		System.assertEquals(users[1].Id, foundUserId, 'Expected matched user returned based on FederationIdentifier');
		System.assertNotEquals(users[0].Id, foundUserId, 'Expected matched user returned based on FederationIdentifier');

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
		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts.addAll(ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true));
		contacts[0].OID_ID__c = 'C0000000001';
		contacts[1].OID_ID__c = 'C0000000001';
		contacts[0].Status__c = 'Active';
		contacts[1].Status__c = 'Active';
		contacts[0] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{'Account' => accounts[0]});
		contacts[1] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[1], new Map<String, Object>{'Account' => accounts[1]});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>{contacts[0].Id, contacts[1].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';
		// the original user record the TPAL record is still linked to
		Id oldUserId = users[0].Id;
		// the user record found during the personas call
		// set fed id for the user for matching
		users[1].FederationIdentifier = fedId;
		users[1].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});
		users[1] = (User) ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[1]});

		List<NetworkMember> networkMembers = ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[0].Id, true);
		networkMembers.addAll(ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[1].Id, true));

		Id tpalId = '0Jr000000000000001';
		Id ssoProviderId = '0Jr000000000000001';
		ThirdPartyAccountLink existingTPALRecord = new ThirdPartyAccountLink(Id = tpalId, SsoProviderId = ssoProviderId, UserId = oldUserId);

		// =====================================
		// Stubbing
		// =====================================
		MerchantPortalRegHandlerService mockService = (MerchantPortalRegHandlerService)MockUtility.mockUtility(MerchantPortalRegHandlerService.class);
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		NetworkMembersSelector mockNetworkMembersSelector = (NetworkMembersSelector) MockUtility.mockSelector(NetworkMembersSelector.class);
		ThirdPartyAccountLinksSelector mockTPALSelector = (ThirdPartyAccountLinksSelector)MockUtility.mockSelector(ThirdPartyAccountLinksSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(userData.attributeMap);
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(users);
		MockUtility.Mocks.when(mockNetworkMembersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkMembers);
		MockUtility.Mocks.when(mockTPALSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{tpalId}))).thenReturn(new List<ThirdPartyAccountLink>{existingTPALRecord});
		MockUtility.Mocks.when(mockDatabase.revokeTokenAccess(fflib_Match.eqId(existingTPALRecord.SsoProviderId), fflib_Match.eqString(userData.provider), fflib_Match.eqId(oldUserId), fflib_Match.eqString(userData.identifier))).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
		Id foundUserId = loginHandler.confirmUser(oldUserId, tpalId, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================

		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(fedId, String.valueOf(augmentedAttributes.get('federation_identifier')));
		System.assertEquals(cNumber, String.valueOf(augmentedAttributes.get('cnumber')));

		((ThirdPartyAccountLinksSelector)MockUtility.Mocks.verify(mockTPALSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{tpalId}));
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).revokeTokenAccess(fflib_Match.eqId(existingTPALRecord.SsoProviderId), fflib_Match.eqString(userData.provider), fflib_Match.eqId(oldUserId), fflib_Match.eqString(userData.identifier));

		System.assertEquals(users[1].Id, foundUserId, 'Expected matched user returned based on FederationIdentifier');
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
		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts.addAll(ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true));
		contacts[0].OID_ID__c = 'C0000000001';
		contacts[1].OID_ID__c = 'C0000000001';
		contacts[0].Status__c = 'Active';
		contacts[1].Status__c = 'Active';
		contacts[0] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{'Account' => accounts[0]});
		contacts[1] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[1], new Map<String, Object>{'Account' => accounts[1]});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>{contacts[0].Id, contacts[1].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';

		// the user record found during the personas call
		// set fed id for the user for matching
		users[1].FederationIdentifier = fedId;
		users[1].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});
		users[1] = (User) ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[1]});

		List<NetworkMember> networkMembers = ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[0].Id, true);
		networkMembers.addAll(ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[1].Id, true));

		Id tpalId;
		Id ssoProviderId = '0Jr000000000000001';
		ThirdPartyAccountLink existingTPALRecord = new ThirdPartyAccountLink(Id = tpalId, SsoProviderId = ssoProviderId, UserId = users[1].Id);

		// =====================================
		// Stubbing
		// =====================================
		MerchantPortalRegHandlerService mockService = (MerchantPortalRegHandlerService)MockUtility.mockUtility(MerchantPortalRegHandlerService.class);
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		NetworkMembersSelector mockNetworkMembersSelector = (NetworkMembersSelector) MockUtility.mockSelector(NetworkMembersSelector.class);
		ThirdPartyAccountLinksSelector mockTPALSelector = (ThirdPartyAccountLinksSelector)MockUtility.mockSelector(ThirdPartyAccountLinksSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(userData.attributeMap);
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(users);
		MockUtility.Mocks.when(mockNetworkMembersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkMembers);
		MockUtility.Mocks.when(mockTPALSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<ThirdPartyAccountLink>{existingTPALRecord});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
		Id foundUserId = loginHandler.confirmUser(users[1].Id, tpalId, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================

		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(fedId, String.valueOf(augmentedAttributes.get('federation_identifier')));
		System.assertEquals(cNumber, String.valueOf(augmentedAttributes.get('cnumber')));

		((ThirdPartyAccountLinksSelector)MockUtility.Mocks.verify(mockTPALSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		System.assertEquals(users[1].Id, foundUserId, 'Expected matched user returned based on FederationIdentifier');
	}

	/**
	 * Scenario:
	 * Irrespective of the TPAL record that exists we still check to see if the user record the user is trying to authenticate to is correct or not
	 * In this scenario, the original linked user record is incorrect, and we haven't been able to find the correct user record to authenticate to
	 */
	@IsTest
	private static void testUnitConfirmUserShouldThrowAnExceptionSinceNoSuitableUserFound() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts.addAll(ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true));
		contacts[0] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{'Account' => accounts[0]});
		contacts[1] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[1], new Map<String, Object>{'Account' => accounts[1]});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>{contacts[0].Id, contacts[1].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';
		// the original user record the TPAL record is still linked to
		User oldUserRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		Id oldUserId = oldUserRecord.Id;
		// the user record returned from the personas call but they won't match because fed id is not set
		users[0].IsActive = true;
		users[1].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});
		users[1] = (User) ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[1]});

		List<NetworkMember> networkMembers = ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[0].Id, true);
		networkMembers.addAll(ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[1].Id, true));

		Id tpalId = '0Jr000000000000001';

		// =====================================
		// Stubbing
		// =====================================
		MerchantPortalRegHandlerService mockService = (MerchantPortalRegHandlerService)MockUtility.mockUtility(MerchantPortalRegHandlerService.class);
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		NetworkMembersSelector mockNetworkMembersSelector = (NetworkMembersSelector) MockUtility.mockSelector(NetworkMembersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(userData.attributeMap);
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(users);
		MockUtility.Mocks.when(mockNetworkMembersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkMembers);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
			loginHandler.confirmUser(oldUserId, tpalId, null, userData);

			System.assert(false, 'Expected exception to be thrown since no suitable user was found to authenticate to.');
		} catch(MerchantPortalRegHandlerService.RegHandlerException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false);
		}

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================

		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(fedId, String.valueOf(augmentedAttributes.get('federation_identifier')));
		System.assertEquals(cNumber, String.valueOf(augmentedAttributes.get('cnumber')));

	}

	/**
	 * Scenario:
	 * In this scenario, no personas are found for the cnumber and expected an exception
	 */
	@IsTest
	private static void testUnitConfirmUserShouldThrowAnExceptionSinceNoPersonasFound() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts.addAll(ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true));
		contacts[0] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{'Account' => accounts[0]});
		contacts[1] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[1], new Map<String, Object>{'Account' => accounts[1]});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>{contacts[0].Id, contacts[1].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		//changing the cnumber here  as it was cached
		userData.attributeMap.remove('cnumber');
		userData.attributeMap.put('cnumber', 'C00002');
		userData.attributeMap.remove('https://auspost/cnumber');
		userData.attributeMap.put('https://auspost/cnumber', 'C00002');
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		// the original user record the TPAL record is still linked to
		User oldUserRecord = ApplicationTestDataFactory.getUsers(1, true)[0];
		Id oldUserId = oldUserRecord.Id;
		// the user record returned from the personas call but they won't match because fed id is not set
		users[0].IsActive = true;
		users[1].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});
		users[1] = (User) ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[1]});

		//no personas will be found because we're not including the above users in NetworkMembers
		List<NetworkMember> networkMembers = ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), UserInfo.getUserId(), true);

		Id tpalId = '0Jr000000000000001';

		// =====================================
		// Stubbing
		// =====================================
		MerchantPortalRegHandlerService mockService = (MerchantPortalRegHandlerService)MockUtility.mockUtility(MerchantPortalRegHandlerService.class);
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		NetworkMembersSelector mockNetworkMembersSelector = (NetworkMembersSelector) MockUtility.mockSelector(NetworkMembersSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getAugmentedAttributes((Map<String, String>)fflib_Match.anyObject())).thenReturn(userData.attributeMap);
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(users);
		MockUtility.Mocks.when(mockNetworkMembersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkMembers);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
			loginHandler.confirmUser(oldUserId, tpalId, null, userData);

			System.assert(false, 'Expected exception to be thrown since no persona was found to authenticate to.');
		} catch(MerchantPortalRegHandlerService.RegHandlerException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false);
		}

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================

		fflib_ArgumentCaptor augmentedAttributesCaptor = fflib_ArgumentCaptor.forClass(Map<String, String>.class);
		
		// VERIFY: getAugmentedAttributes
		((MerchantPortalRegHandlerService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getAugmentedAttributes((Map<String, String>)augmentedAttributesCaptor.capture());
		Map<String, String> augmentedAttributes = (Map<String, String>)augmentedAttributesCaptor.getValue();
		System.assertEquals(cNumber, String.valueOf(augmentedAttributes.get('cnumber')));

	}

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
		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contacts[0].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';
		users[0].FederationIdentifier = fedId;
		users[0].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{users[0].Id => users[0]});
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
		loginHandler.updateUser(users[0].Id, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		// VERIFY: making sure update on user is not called as it is active user
		((ApplicationDatabase) MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(0))).dmlUpdate((List<SObject>) fflib_Match.anyList());
		

		// PMD warning
		System.assert(true);
	}

	/**
	 *  Test:
	 *  Making sure that create user functions as expected
	 *  Simply covering behavioural testing since the bulk is covered in other test classes
	 */
	@IsTest
	private static void testUnitUpdateUserAndMakeActive() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile merchantPortalProfile = [SELECT Id,Name FROM Profile where Name = 'Merchant Portal Community User' LIMIT 1];
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contacts[0].Id}, merchantPortalProfile.Id, true);
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');
		String fedId = cNumber + '.merchant';
		users[0].FederationIdentifier = fedId;
		users[0].IsActive = false; //user update should happen
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Profile' => merchantPortalProfile, 'Contact' => contacts[0]});

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase vMockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, User>{users[0].Id => users[0]});
		MockUtility.Mocks.when(vMockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MerchantPortalOIDCRegHandler loginHandler = new MerchantPortalOIDCRegHandler();
		loginHandler.updateUser(users[0].Id, null, userData);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		// VERIFY: making sure update on user is not called as it is active user
		((ApplicationDatabase) MockUtility.Mocks.verify(vMockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>) fflib_Match.anyList());
		

		// PMD warning
		System.assert(true);
	}

	private static Auth.UserData getUserData(Contact contact, User user) {
		// set our user data mock from the Auth Provider
		Id networkId = '0DB000000000000001';
		String cNumber = 'C0000000001';
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => contact.LastName + ', ' + contact.FirstName,
			'given_name' => contact.FirstName,
			'family_name' => contact.LastName,
			'email' => contact.Email,
			'https://auspost/apcn' => '123',
			'https://auspost/cnumber' => cNumber,
			'sfdc_networkid' => networkId,
			'federation_identifier' => cNumber + '.merchant',
			'cnumber' => cNumber
		};
		Auth.UserData userData = new Auth.UserData(identifier, contact.FirstName, contact.LastName, contact.FirstName + ' ' + contact.LastName,
													contact.Email, null, user.Username, null, 'Open ID Connect', 'https://communityurl/', attributeMap);
		return userData;
	}

}