/**
 * @description Test class for covering MerchantPortalRegHandlerService
 * @author Mahesh Parvathaneni
 * @date 2023-08-24
 * @changelog
*/

@IsTest
private with sharing class MPBRegHandlerService_Test {
    /**
	 * Scenario:
	 * Makes sure that augmented attributes are populated from the attribute map
	 */
	@IsTest
	private static void testGetAugmentedAttributes() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		Auth.UserData userData = getUserData(contacts[0], user);
		String cNumber = userData.attributeMap.get('https://auspost/cnumber');

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MPBRegHandlerService service = MPBRegHandlerService.getInstance();
		Map<String, String> augmentedAttributes = service.getAugmentedAttributes(userData.attributeMap);

		Test.stopTest();

		// =====================================
		// VERIFY
		// =====================================
		System.assertEquals(true, augmentedAttributes.containsKey('cnumber'), 'Expected cnumber attribute in augmentedAttributes');
		System.assertEquals(augmentedAttributes.get('cnumber'), cNumber, 'Incorrect cnumber attribute returned');
	}

	/**
	 * Scenario:
	 * Makes sure that attributes are populated for reg handler to match the user
	 */
	@IsTest
	private static void testValidateAssertion() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		Auth.UserData userData = getUserData(contacts[0], user);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MPBRegHandlerService service = MPBRegHandlerService.getInstance();
		List<String> validationErrors = service.validateAssertion(new Map<String, String>{ 'test_key' => 'test_value' });

		// =====================================
		// VERIFY
		// =====================================
		//no valid attributes are passed, expected validation errors
		System.assert(validationErrors.size() > 0, 'Expected validation errors to be returned');
		System.assertEquals(true, validationErrors.contains('First Name attribute is missing'), 'Expected validation error for First Name');
		System.assertEquals(true, validationErrors.contains('Last Name attribute is missing'), 'Expected validation error for Last Name');

		//test again with attributes
		validationErrors = service.validateAssertion(userData.attributeMap);
		// cnumber attribute is missing, expected validation errors
		System.assertEquals(1, validationErrors.size(), 'Expected validation errors to be returned');
		System.assertEquals(true, validationErrors.contains('CNumber attribute is missing'), 'Expected validation error for CNumber');

		//test again with augmented attributes
		Map<String, String> augmentedAttributes = service.getAugmentedAttributes(userData.attributeMap);
		validationErrors = service.validateAssertion(augmentedAttributes);
		// cnumber attribute is populated, expected no validation errors
		System.assertEquals(0, validationErrors.size(), 'Expected validation errors to be returned');
		System.assertEquals(false, validationErrors.contains('CNumber attribute is missing'), 'Expected validation error for CNumber');
	}

	/**
	 * Scenario:
	 * Makes sure the user returned satisfying all the criteria from matchUser method
	 */
	@IsTest
	private static void testMatchUser() {

		// =====================================
		// Data Preparation
		// =====================================
		Profile mpbProfile = [SELECT Id,Name FROM Profile where Name = 'Mypost Business Help & Support Community User' LIMIT 1];
		List<Product2> prod = ApplicationTestDataFactory.getPSRProducts(1, true);
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		contacts[0].Status__c = 'Active';
		contacts[0].OID_ID__c = 'C0000000001';
		//get assets
		List<Asset> assets = ApplicationTestDataFactory.getPSRTransactionalAssets(1, accounts[0].Id, prod[0].Id, false,'Agreed', true);
		assets.addAll(ApplicationTestDataFactory.getPSRTransactionalAssets(1, accounts[0].Id, prod[0].Id, false,'Agreed', true));
		assets[0].Name = 'PSRTandC';
		//relate the assets and account to contact
		contacts[0] = (Contact) ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{'Account' => accounts[0]});
		contacts[0] = (Contact)ApplicationTestDataFactory.setChildRelationships(contacts[0], new Map<String, List<SObject>>{'Assets' => assets});
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contacts[0].Id}, mpbProfile.Id, true);
		users[0].IsActive = true;
		users[0] = (User) ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Contact' => contacts[0]});
		Auth.UserData userData = getUserData(contacts[0], users[0]);
		Map<String, String> attributeMap = userData.attributeMap;
		attributeMap.put('cnumber', 'C0000000001');

		List<NetworkMember> networkMembers = ApplicationTestDataFactory.getNetworkMembers(1, Network.getNetworkId(), users[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		AssetsSelector mockAssetsSelector = (AssetsSelector) MockUtility.mockSelector(AssetsSelector.class);
		NetworkMembersSelector mockNetworkMembersSelector = (NetworkMembersSelector) MockUtility.mockSelector(NetworkMembersSelector.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(users);
		MockUtility.Mocks.when(mockAssetsSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<Asset>{assets[0]});
		MockUtility.Mocks.when(mockNetworkMembersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(networkMembers);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MPBRegHandlerService service = MPBRegHandlerService.getInstance();
		User user = service.matchUser(attributeMap);

		// =====================================
		// VERIFY
		// =====================================
		fflib_ArgumentCaptor usersSearchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, 1)).search((Map<String, Object>)usersSearchParamsCaptor.capture(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		Map<String, Object> userSearchParameters = (Map<String, Object>) usersSearchParamsCaptor.getValue();

		System.assert(userSearchParameters.containsKey('isPersonAccount'), 'Expected to pass isPersonAccount as a parameters into search method');
		System.assertEquals(contacts[0].OID_ID__c, userSearchParameters.get('contactCNumbers'), 'Expected to pass correct cNumber for a contact');

		fflib_ArgumentCaptor assetsSearchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((AssetsSelector)MockUtility.Mocks.verify(mockAssetsSelector, 1)).search((Map<String, Object>)assetsSearchParamsCaptor.capture(), fflib_Match.anyBoolean());
		Map<String, Object> assetsSearchParameters = (Map<String, Object>) assetsSearchParamsCaptor.getValue();

		System.assert(assetsSearchParameters.containsKey('assetNames'), 'Expected to pass assetNames as a parameters into search method');

		System.assertEquals(user.Id, users[0].Id, 'Expected correct user to be returned');
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