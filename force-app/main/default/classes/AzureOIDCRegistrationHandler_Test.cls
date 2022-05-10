/***
 * @description Test Scenarios for AzureOIDCRegistrationHandler
 * @author Nathan Franklin
 * @date 2022-04-26
 * @changelog
 */
@IsTest
private class AzureOIDCRegistrationHandler_Test {

	/**
	 * Scenario: When a user flow into the createUser flow from OIDC provider, we need to match the user to their appropriate profile. This is within a network context
	 */
	@IsTest
	private static void testEnsureUserIsMatchedFromFederationIdWithNetwork() {
		// =====================================
		// Data Preparation
		// =====================================

		Id networkId = '0DB000000000000001';
		SSOAttributeMapping__mdt mapping = SSOTestDataFactory.getSSOAttributeMappings(1, networkId, true)[0];
		mapping.FederationField__c = 'Username';

		User matchedUser = ApplicationTestDataFactory.getUsers(1,true)[0];

		// set our user data mock from the Auth Provider
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => matchedUser.LastName + ', ' + matchedUser.FirstName,
			'given_name' => matchedUser.FirstName,
			'family_name' => matchedUser.LastName,
			'email' => matchedUser.Email,
			'sfdc_networkid' => networkId
		};
		Auth.UserData userData = new Auth.UserData(identifier, matchedUser.FirstName, matchedUser.LastName, matchedUser.FirstName + ' ' + matchedUser.LastName,
													matchedUser.Email, null, matchedUser.Username, null, null, null, attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		SSOAttributeMappingsSelector mockSSOAttributesSelector = (SSOAttributeMappingsSelector)MockUtility.mockSelector(SSOAttributeMappingsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>{matchedUser});
		MockUtility.Mocks.when(mockSSOAttributesSelector.selectByNetworkIds((Set<String>)fflib_Match.anyObject())).thenReturn(new List<SSOAttributeMapping__mdt>{mapping});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AzureOIDCRegistrationHandler handler = new AzureOIDCRegistrationHandler();
		handler.createUser(null, userData);

		Test.stopTest();

		// make sure that our search method was called
		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((UsersSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), fflib_Match.eqBoolean(true));

		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		System.assertEquals(networkId, searchParams.get('networkIds'));
		System.assertEquals(matchedUser.Email, searchParams.get('federationIds'));
		System.assertEquals(User.Username, searchParams.get('federationField'));
		System.assertEquals(true, searchParams.get('isActive'));

		// verify our SSO attribute mappings selector was called
		fflib_ArgumentCaptor ssoAttributesCaptor = fflib_ArgumentCaptor.forClass(Set<String>.class);
		((SSOAttributeMappingsSelector)MockUtility.Mocks.verify(mockSSOAttributesSelector, MockUtility.Mocks.times(1))).selectByNetworkIds((Set<String>)ssoAttributesCaptor.capture());

		Set<String> ssoAttributesParams = (Set<String>)ssoAttributesCaptor.getValue();
		System.assertEquals(networkId, new List<String>(ssoAttributesParams)[0]);
		System.assertEquals(1, ssoAttributesParams.size());

	}

	/**
	 * Scenario: When a user flow into the createUser flow from OIDC provider, we need to match the user to their appropriate profile. This is outside a network context
	 */
	@IsTest
	private static void testEnsureUserIsMatchedFromFederationIdWithoutNetwork() {
		// =====================================
		// Data Preparation
		// =====================================
		SSOAttributeMapping__mdt mapping = SSOTestDataFactory.getSSOAttributeMappings(1, null, true)[0];

		User matchedUser = ApplicationTestDataFactory.getUsers(1,true)[0];

		// set our user data mock from the Auth Provider
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => matchedUser.LastName + ', ' + matchedUser.FirstName,
			'given_name' => matchedUser.FirstName,
			'family_name' => matchedUser.LastName,
			'email' => matchedUser.Email
		};
		Auth.UserData userData = new Auth.UserData(identifier, matchedUser.FirstName, matchedUser.LastName, matchedUser.FirstName + ' ' + matchedUser.LastName,
														matchedUser.Email, null, matchedUser.Username, null, null, null, attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		SSOAttributeMappingsSelector mockSSOAttributesSelector = (SSOAttributeMappingsSelector)MockUtility.mockSelector(SSOAttributeMappingsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>{matchedUser});
		MockUtility.Mocks.when(mockSSOAttributesSelector.selectByNetworkIds((Set<String>)fflib_Match.anyObject())).thenReturn(new List<SSOAttributeMapping__mdt>{mapping});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AzureOIDCRegistrationHandler handler = new AzureOIDCRegistrationHandler();
		handler.createUser(null, userData);

		Test.stopTest();

		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);

		// make sure that our search method was called
		((UsersSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), fflib_Match.eqBoolean(true));

		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		System.assertEquals(false, searchParams.containsKey('networkIds')); // make sure network isn't present
		System.assertEquals(matchedUser.Email, searchParams.get('federationIds'));
		System.assertEquals(User.FederationIdentifier, searchParams.get('federationField'));
		System.assertEquals(true, searchParams.get('isActive'));

		// verify our SSO attribute mappings selector was called
		fflib_ArgumentCaptor ssoAttributesCaptor = fflib_ArgumentCaptor.forClass(Set<String>.class);
		((SSOAttributeMappingsSelector)MockUtility.Mocks.verify(mockSSOAttributesSelector, MockUtility.Mocks.times(1))).selectByNetworkIds((Set<String>)ssoAttributesCaptor.capture());

		Set<String> ssoAttributesParams = (Set<String>)ssoAttributesCaptor.getValue();
		System.assertEquals(null, new List<String>(ssoAttributesParams)[0]);
		System.assertEquals(1, ssoAttributesParams.size());

	}

	/**
	 * Scenario: Ensures that a match is not attempted when the IdP does not provide a matching subject (the email address)
	 */
	@IsTest
	private static void testEnsureUserMatchNotAttemptedWithoutValidSubject() {
		// =====================================
		// Data Preparation
		// =====================================
		SSOAttributeMapping__mdt mapping = SSOTestDataFactory.getSSOAttributeMappings(1, null, true)[0];

		User matchedUser = ApplicationTestDataFactory.getUsers(1,true)[0];

		// set our user data mock from the Auth Provider
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => matchedUser.LastName + ', ' + matchedUser.FirstName,
			'given_name' => matchedUser.FirstName,
			'family_name' => matchedUser.LastName
		};
		Auth.UserData userData = new Auth.UserData(identifier, matchedUser.FirstName, matchedUser.LastName, matchedUser.FirstName + ' ' + matchedUser.LastName,
														null, null, null, null, null, null, attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		SSOAttributeMappingsSelector mockSSOAttributesSelector = (SSOAttributeMappingsSelector)MockUtility.mockSelector(SSOAttributeMappingsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSSOAttributesSelector.selectByNetworkIds((Set<String>)fflib_Match.anyObject())).thenReturn(new List<SSOAttributeMapping__mdt>{mapping});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			AzureOIDCRegistrationHandler handler = new AzureOIDCRegistrationHandler();
			handler.createUser(null, userData);

			System.assert(false, 'Expected an exception to be thrown since no user subject was provided');
		} catch(AzureOIDCRegistrationHandler.HandlerException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Expected AzureOIDCRegistrationHandler.HandlerException');
		}

		Test.stopTest();

		// make sure that our search method was NOT called
		((UsersSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(0))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify our SSO attribute mappings selector was called
		((SSOAttributeMappingsSelector)MockUtility.Mocks.verify(mockSSOAttributesSelector, MockUtility.Mocks.times(1))).selectByNetworkIds((Set<String>)fflib_Match.anyObject());

	}

	/**
	 * Scenario: Ensures that a match is not attempted when the IdP does not provide a matching subject (this time First Name field)
	 */
	@IsTest
	private static void testEnsureUserMatchNotAttemptedWithoutValidSubject2() {
		// =====================================
		// Data Preparation
		// =====================================
		SSOAttributeMapping__mdt mapping = SSOTestDataFactory.getSSOAttributeMappings(1, null, true)[0];
		mapping.SubjectAttribute__c = 'given_name';

		User matchedUser = ApplicationTestDataFactory.getUsers(1,true)[0];

		// set our user data mock from the Auth Provider
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => matchedUser.LastName + ', ' + matchedUser.FirstName,
			'family_name' => matchedUser.LastName,
			'email' => matchedUser.Email
		};
		Auth.UserData userData = new Auth.UserData(identifier, null, matchedUser.LastName, matchedUser.FirstName + ' ' + matchedUser.LastName,
													matchedUser.Email, null, null, null, null, null, attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		SSOAttributeMappingsSelector mockSSOAttributesSelector = (SSOAttributeMappingsSelector)MockUtility.mockSelector(SSOAttributeMappingsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSSOAttributesSelector.selectByNetworkIds((Set<String>)fflib_Match.anyObject())).thenReturn(new List<SSOAttributeMapping__mdt>{mapping});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			AzureOIDCRegistrationHandler handler = new AzureOIDCRegistrationHandler();
			handler.createUser(null, userData);

			System.assert(false, 'Expected an exception to be thrown since no user subject was provided (given_name)');
		} catch(AzureOIDCRegistrationHandler.HandlerException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Expected AzureOIDCRegistrationHandler.HandlerException');
		}

		Test.stopTest();

		// make sure that our search method was NOT called
		((UsersSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(0))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify our SSO attribute mappings selector was called
		((SSOAttributeMappingsSelector)MockUtility.Mocks.verify(mockSSOAttributesSelector, MockUtility.Mocks.times(1))).selectByNetworkIds((Set<String>)fflib_Match.anyObject());

	}

	/**
	 * Scenario: Ensures that an exception is thrown if no match is found based on the search
	 */
	@IsTest
	private static void testEnsureUserMatchThrowsExceptionWithoutValidResult() {

		// =====================================
		// Data Preparation
		// =====================================
		Id networkId = '0DB000000000000001';
		SSOAttributeMapping__mdt mapping = SSOTestDataFactory.getSSOAttributeMappings(1, networkId, true)[0];

		User matchedUser = ApplicationTestDataFactory.getUsers(1,true)[0];

		// set our user data mock from the Auth Provider
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => matchedUser.LastName + ', ' + matchedUser.FirstName,
			'given_name' => matchedUser.FirstName,
			'family_name' => matchedUser.LastName,
			'email' => matchedUser.Email,
			'sfdc_networkid' => networkId
		};
		Auth.UserData userData = new Auth.UserData(identifier, matchedUser.FirstName, matchedUser.LastName, matchedUser.FirstName + ' ' + matchedUser.LastName,
														matchedUser.Email, null, matchedUser.Username, null, null, null, attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		SSOAttributeMappingsSelector mockSSOAttributesSelector = (SSOAttributeMappingsSelector)MockUtility.mockSelector(SSOAttributeMappingsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>());
		MockUtility.Mocks.when(mockSSOAttributesSelector.selectByNetworkIds((Set<String>)fflib_Match.anyObject())).thenReturn(new List<SSOAttributeMapping__mdt>{mapping});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			AzureOIDCRegistrationHandler handler = new AzureOIDCRegistrationHandler();
			handler.createUser(null, userData);

			System.assert(false, 'Expected an exception to be thrown since no user subject was provided');
		} catch(AzureOIDCRegistrationHandler.HandlerException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Expected AzureOIDCRegistrationHandler.HandlerException');
		}

		Test.stopTest();

		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);

		// make sure that our search method was called
		((UsersSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), fflib_Match.eqBoolean(true));

		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		System.assertEquals(networkId, searchParams.get('networkIds'));
		System.assertEquals(matchedUser.Email, searchParams.get('federationIds'));
		System.assertEquals(true, searchParams.get('isActive'));

		// verify our SSO attribute mappings selector was called
		fflib_ArgumentCaptor ssoAttributesCaptor = fflib_ArgumentCaptor.forClass(Set<String>.class);
		((SSOAttributeMappingsSelector)MockUtility.Mocks.verify(mockSSOAttributesSelector, MockUtility.Mocks.times(1))).selectByNetworkIds((Set<String>)ssoAttributesCaptor.capture());

		Set<String> ssoAttributesParams = (Set<String>)ssoAttributesCaptor.getValue();
		System.assertEquals(networkId, new List<String>(ssoAttributesParams)[0]);
		System.assertEquals(1, ssoAttributesParams.size());

	}

	/**
	 * Scenario: The updateUser is not currently used, but this is included for coverage
	 */
	@IsTest
	private static void testEnsureUserUpdateIsCalledToCoverCode() {
		// =====================================
		// Data Preparation
		// =====================================

		User matchedUser = ApplicationTestDataFactory.getUsers(1,true)[0];

		// set our user data mock from the Auth Provider
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => matchedUser.LastName + ', ' + matchedUser.FirstName,
			'given_name' => matchedUser.FirstName,
			'family_name' => matchedUser.LastName
		};
		Auth.UserData userData = new Auth.UserData(identifier, matchedUser.FirstName, matchedUser.LastName, matchedUser.FirstName + ' ' + matchedUser.LastName,
													null, null, null, null, null, null, attributeMap);

		// =====================================
		// Stubbing
		// =====================================

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AzureOIDCRegistrationHandler handler = new AzureOIDCRegistrationHandler();
		handler.updateUser(matchedUser.Id, null, userData);

		Test.stopTest();

		System.assert(true);

	}

	/**
	 * Scenario: When a user flow into the createUser flow from OIDC provider, there is no mappings for a particular network and an exception should be thrown
	 */
	@IsTest
	private static void testEnsureExceptionIsThrownWhenNoSSOMappingsAreFound() {
		// =====================================
		// Data Preparation
		// =====================================

		Id networkId = '0DB000000000000001';
		SSOAttributeMapping__mdt mapping = SSOTestDataFactory.getSSOAttributeMappings(1, networkId, true)[0];

		User matchedUser = ApplicationTestDataFactory.getUsers(1,true)[0];

		// set our user data mock from the Auth Provider
		String identifier = '_randomIdentifier' + Datetime.now().getTime();
		Map<String, String> attributeMap = new Map<String, String>{
			'sub' => identifier,
			'name' => matchedUser.LastName + ', ' + matchedUser.FirstName,
			'given_name' => matchedUser.FirstName,
			'family_name' => matchedUser.LastName,
			'email' => matchedUser.Email,
			'sfdc_networkid' => networkId
		};
		Auth.UserData userData = new Auth.UserData(identifier, matchedUser.FirstName, matchedUser.LastName, matchedUser.FirstName + ' ' + matchedUser.LastName,
													matchedUser.Email, null, matchedUser.Username, null, null, null, attributeMap);

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		SSOAttributeMappingsSelector mockSSOAttributesSelector = (SSOAttributeMappingsSelector)MockUtility.mockSelector(SSOAttributeMappingsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSSOAttributesSelector.selectByNetworkIds((Set<String>)fflib_Match.anyObject())).thenReturn(new List<SSOAttributeMapping__mdt>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			AzureOIDCRegistrationHandler handler = new AzureOIDCRegistrationHandler();
			handler.createUser(null, userData);

			System.assert(false, 'Expected an exception to be thrown since no mappings where found');
		} catch(AzureOIDCRegistrationHandler.HandlerException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Expected AzureOIDCRegistrationHandler.HandlerException');
		}

		Test.stopTest();

		// make sure that our search method was NOT called
		((UsersSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(0))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify our SSO attribute mappings selector was called
		fflib_ArgumentCaptor ssoAttributesCaptor = fflib_ArgumentCaptor.forClass(Set<String>.class);
		((SSOAttributeMappingsSelector)MockUtility.Mocks.verify(mockSSOAttributesSelector, MockUtility.Mocks.times(1))).selectByNetworkIds((Set<String>)ssoAttributesCaptor.capture());

		Set<String> ssoAttributesParams = (Set<String>)ssoAttributesCaptor.getValue();
		System.assertEquals(networkId, new List<String>(ssoAttributesParams)[0]);
		System.assertEquals(1, ssoAttributesParams.size());

	}

}