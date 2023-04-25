/***
 * @description Test Scenarios for Auth0OIDCAuthProvider
 * @author Nathan Franklin
 * @date 2023-03-22
 * @changelog
 */
@IsTest
private class Auth0OIDCAuthProvider_Test {

	public static String mockAccessToken = 'JKhRGwUxFwFNd_QEYVfCCTjKalZ9g_t7g.JKhRGwUxFwFNd_QEYVfCCTjKalZ9g_t7g.JKhRGwUxFwFNd_QEYVfCCTjKalZ9g_t7g';

	/**
	 * Scenario: Ensures that the correct url is generated that redirects the user to Auth0 so they can log in
	 */
	@IsTest
	private static void testEnsureCorrectInitialiseUrlIsGenerated() {
		// =====================================
		// Data Preparation
		// =====================================

		String encryptionKey = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
		String state = 'nothingmeangingful';
		Map<String, String> customMetadataValues = new Map<String, String>{
			'PKCEEncryptionKey__c' => encryptionKey,
			'ClientId__c' => 'client-id-1234',
			'Audience__c' => 'https://auspost.com.au',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'id openid profile email',
			'URLSuffix__c' => 'Auth0Consumer',
			'ExternalCredentialName__c' => 'externalcred1',
			'TokenEndpointUrl__c' => 'https://my-authorisation-end-point.com/token',
			'UserInfoEndpointUrl__c' => 'https://my-authorisation-end-point.com/userinfo'
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Auth0OIDCAuthProvider authprovider = new Auth0OIDCAuthProvider();
		authprovider.NETWORK_ID = [Select Id From Network LIMIT 1].Id;
		authprovider.COMMUNITY_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport';
		authprovider.COMMUNITY_LOGIN_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport/login';

		PageReference redirect = authprovider.initiate(customMetadataValues, state);
		String url = redirect.getUrl();
		Map<String, String> params = redirect.getParameters();

		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		System.assertEquals(true, Pattern.compile('(?is)^https:\\/\\/my-authorisation-end-point.com\\/authorise').matcher(url).find(), 'Authorise URL was not present: ' + url);
		System.assertEquals('id openid profile email', params.get('scope'));
		System.assertEquals('https://auspost.com.au', params.get('audience'));
		System.assertEquals(true, params.get('redirect_uri').endsWith('Auth0Consumer'));
		System.assertEquals('S256', params.get('code_challenge_method'));
		System.assertEquals('code', params.get('response_type'));
		System.assertEquals('client-id-1234', params.get('client_id'));
		System.assertEquals('nothingmeangingful', params.get('state'));

	}

	/**
	 * Scenario: Makes sure a successful end-to-end callback payload is processed
	 */
	@IsTest
	private static void testEnsureCallbackMethodIsSuccessful() {
		// =====================================
		// Data Preparation
		// =====================================

		String encryptionKey = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
		Map<String, String> customMetadataValues = new Map<String, String>{
			'PKCEEncryptionKey__c' => encryptionKey,
			'ClientId__c' => 'client-id-1234',
			'Audience__c' => 'https://auspost.com.au',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'id openid profile email',
			'URLSuffix__c' => 'Auth0Consumer',
			'ExternalCredentialName__c' => 'externalcred1',
			'TokenEndpointUrl__c' => 'https://my-authorisation-end-point.com/token',
			'UserInfoEndpointUrl__c' => 'https://my-authorisation-end-point.com/userinfo'
		};

		Map<String, String> headers = new Map<String, String>{
			'Accept' => 'text/html',
			'Accept-Encoding' => 'gzip',
			'doesnothing' => 'pointless'
		};
		Map<String, String> queryParameters = new Map<String, String>{
			'code' => '0AWcADu-vQZ56hEWduo',
			'state' => 'nothingmeangingful'
		};
		Auth.AuthProviderCallbackState callbackState = new Auth.AuthProviderCallbackState(headers, null, queryParameters);

		List<String> pkceValues = (new Auth0OIDCAuthProvider()).getPKCECode(queryParameters.get('state'), EncodingUtil.base64Decode(customMetadataValues.get('PKCEEncryptionKey__c')));

		// =====================================
		// Stubbing
		// =====================================
		SuccessfulAccessTokenHttpMock httpMock = new SuccessfulAccessTokenHttpMock();
		Test.setMock(HttpCalloutMock.class, httpMock);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Auth0OIDCAuthProvider authprovider = new Auth0OIDCAuthProvider();
		authprovider.NETWORK_ID = [Select Id From Network LIMIT 1].Id;
		authprovider.COMMUNITY_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport';
		authprovider.COMMUNITY_LOGIN_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport/login';

		Auth.AuthProviderTokenResponse tokenResponse = authprovider.handleCallback(customMetadataValues, callbackState);

		Test.stopTest();

		// =====================================
		// Verification
		// =====================================

		System.assertEquals(mockAccessToken, tokenResponse.oauthToken);
		System.assertEquals(queryParameters.get('state'), tokenResponse.state);

		Pagereference pageRef = new PageReference(httpMock.requestEndpoint + '?' + httpMock.requestBody);
		Map<String, String> params = pageRef.getParameters();
		String url = pageRef.getUrl();

		System.assertEquals(true, Pattern.compile('(?is)^https:\\/\\/my-authorisation-end-point.com\\/token').matcher(url).find(), 'Token URL was not present: ' + url);
		System.assertEquals(customMetadataValues.get('ClientId__c'), params.get('client_id'));
		System.assertEquals('{!$Credential.' + customMetadataValues.get('ExternalCredentialName__c') + '.secret}', params.get('client_secret'));
		System.assertEquals(pkceValues[1], params.get('code_verifier'));
		System.assertEquals('authorization_code', params.get('grant_type'));

	}

	/**
	 * Scenario: callback fails because of an unexpected error from Auth0 token endpoint
	 */
	@IsTest
	private static void testEnsureCallbackMethodFailsAsExpected() {

		// =====================================
		// Data Preparation
		// =====================================
		String encryptionKey = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
		Map<String, String> customMetadataValues = new Map<String, String>{
			'PKCEEncryptionKey__c' => encryptionKey,
			'ClientId__c' => 'client-id-1234',
			'Audience__c' => 'https://auspost.com.au',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'id openid profile email',
			'URLSuffix__c' => 'Auth0Consumer',
			'ExternalCredentialName__c' => 'externalcred1',
			'TokenEndpointUrl__c' => 'https://my-authorisation-end-point.com/token',
			'UserInfoEndpointUrl__c' => 'https://my-authorisation-end-point.com/userinfo'
		};

		Map<String, String> headers = new Map<String, String>{};
		Map<String, String> queryParameters = new Map<String, String>{
			'code' => '0AWcADu-vQZ56hEWduo',
			'state' => 'nothingmeangingful'
		};
		Auth.AuthProviderCallbackState callbackState = new Auth.AuthProviderCallbackState(headers, null, queryParameters);

		// =====================================
		// Stubbing
		// =====================================
		FailedAccessTokenHttpMock httpMock = new FailedAccessTokenHttpMock();
		Test.setMock(HttpCalloutMock.class, httpMock);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			Auth0OIDCAuthProvider authprovider = new Auth0OIDCAuthProvider();
			authprovider.NETWORK_ID = [Select Id From Network LIMIT 1].Id;
			authprovider.COMMUNITY_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport';
			authprovider.COMMUNITY_LOGIN_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport/login';
			authprovider.handleCallback(customMetadataValues, callbackState);

			System.assert(false, 'Expected exception');
		} catch(Auth0OIDCAuthProvider.OAuthException ex) {
			// this is from the failed mock
			System.assertEquals(true, ex.getMessage().contains('Token API:'), 'Expected error message but got: ' + ex.getMessage());
		} catch(Exception ex) {
			System.assert(false, 'Expected OAuthException: ' + ex.getMessage());
		}

		Test.stopTest();

	}

	/**
	 * Scenario: access token was not return in payload so we throw an exception
	 */
	@IsTest
	private static void testEnsureCallbackMethodFailsSinceAccessTokenIsMissing() {

		// =====================================
		// Data Preparation
		// =====================================
		String encryptionKey = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
		Map<String, String> customMetadataValues = new Map<String, String>{
			'PKCEEncryptionKey__c' => encryptionKey,
			'ClientId__c' => 'client-id-1234',
			'Audience__c' => 'https://auspost.com.au',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'id openid profile email',
			'URLSuffix__c' => 'Auth0Consumer',
			'ExternalCredentialName__c' => 'externalcred1',
			'TokenEndpointUrl__c' => 'https://my-authorisation-end-point.com/token',
			'UserInfoEndpointUrl__c' => 'https://my-authorisation-end-point.com/userinfo'
		};

		Map<String, String> headers = new Map<String, String>{};
		Map<String, String> queryParameters = new Map<String, String>{
			'code' => '0AWcADu-vQZ56hEWduo',
			'state' => 'nothingmeangingful'
		};
		Auth.AuthProviderCallbackState callbackState = new Auth.AuthProviderCallbackState(headers, null, queryParameters);

		// =====================================
		// Stubbing
		// =====================================
		PartialSuccessfulAccessTokenWithoutAccessTokenHttpMock httpMock = new PartialSuccessfulAccessTokenWithoutAccessTokenHttpMock();
		Test.setMock(HttpCalloutMock.class, httpMock);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			Auth0OIDCAuthProvider authprovider = new Auth0OIDCAuthProvider();
			authprovider.NETWORK_ID = [Select Id From Network LIMIT 1].Id;
			authprovider.COMMUNITY_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport';
			authprovider.COMMUNITY_LOGIN_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport/login';
			authprovider.handleCallback(customMetadataValues, callbackState);

			System.assert(false, 'Expected exception');
		} catch(Auth0OIDCAuthProvider.OAuthException ex) {
			// exception thrown since access token was missing
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Expected OAuthException: ' + ex.getMessage());
		}

		Test.stopTest();

	}

	/**
	 * Scenario: UserInfo api call is successful and the users details are returned
	 */
	@IsTest
	private static void testEnsureUserInfoMethodIsSuccessful() {

		// =====================================
		// Data Preparation
		// =====================================
		String encryptionKey = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
		Map<String, String> customMetadataValues = new Map<String, String>{
			'PKCEEncryptionKey__c' => encryptionKey,
			'ClientId__c' => 'client-id-1234',
			'Audience__c' => 'https://auspost.com.au',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'id openid profile email',
			'URLSuffix__c' => 'Auth0Consumer',
			'ExternalCredentialName__c' => 'externalcred1',
			'TokenEndpointUrl__c' => 'https://my-authorisation-end-point.com/token',
			'UserInfoEndpointUrl__c' => 'https://my-authorisation-end-point.com/userinfo'
		};

		String state = 'nothingmeanginful';
		String accessToken = mockAccessToken;
		Auth.AuthProviderTokenResponse tokenResponse = new Auth.AuthProviderTokenResponse('Auth0', accessToken, '', state);

		// =====================================
		// Stubbing
		// =====================================
		SuccessfulUserInfoHttpMock httpMock = new SuccessfulUserInfoHttpMock();
		Test.setMock(HttpCalloutMock.class, httpMock);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Auth0OIDCAuthProvider authprovider = new Auth0OIDCAuthProvider();
		authprovider.NETWORK_ID = [Select Id From Network LIMIT 1].Id;
		authprovider.COMMUNITY_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport';
		authprovider.COMMUNITY_LOGIN_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport/login';
		Auth.UserData userData = authprovider.getUserInfo(customMetadataValues, tokenResponse);

		Test.stopTest();

		String requestBody = EncodingUtil.urlDecode(httpMock.requestBody, 'UTF-8');

		System.assertEquals(userData.firstName, 'ew1gkwerj1oiwjeroij343434j43u4u');
		System.assertEquals(userData.lastName, 'ew1gkwerj1oiwjeroij343434j43u4u');
		System.assertEquals(userData.fullName, 'ew1gkwerj1oiwjeroij343434j43u4u ew1gkwerj1oiwjeroij343434j43u4u');
		System.assertEquals(userData.username, 'ew1gkwerj1oiwjeroij343434j43u4u@yopmail.com');
		System.assertEquals(userData.email, 'ew1gkwerj1oiwjeroij343434j43u4u@yopmail.com');
		System.assertEquals('C32000007149', userData.attributeMap.get('https://auspost/cnumber'));
		System.assertEquals('1027144339', userData.attributeMap.get('https://auspost/apcn'));
	}

	/**
	 * Scenario: UserInfo api call fails due to an error from Auth0
	 */
	@IsTest
	private static void testEnsureUserInfoMethodFailsAsExpectedWhenInvalidResponseIsReceived() {

		// =====================================
		// Data Preparation
		// =====================================
		String encryptionKey = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
		Map<String, String> customMetadataValues = new Map<String, String>{
			'PKCEEncryptionKey__c' => encryptionKey,
			'ClientId__c' => 'client-id-1234',
			'Audience__c' => 'https://auspost.com.au',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'id openid profile email',
			'URLSuffix__c' => 'Auth0Consumer',
			'ExternalCredentialName__c' => 'externalcred1',
			'TokenEndpointUrl__c' => 'https://my-authorisation-end-point.com/token',
			'UserInfoEndpointUrl__c' => 'https://my-authorisation-end-point.com/userinfo'
		};

		String state = 'nothingmeanginful';
		String accessToken = 'my-access-token';
		Auth.AuthProviderTokenResponse tokenResponse = new Auth.AuthProviderTokenResponse('Auth0', accessToken, '', state);

		// =====================================
		// Stubbing
		// =====================================
		FailedUserInfoHttpMock httpMock = new FailedUserInfoHttpMock();
		Test.setMock(HttpCalloutMock.class, httpMock);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Auth0OIDCAuthProvider authprovider = new Auth0OIDCAuthProvider();
		authprovider.NETWORK_ID = [Select Id From Network LIMIT 1].Id;
		authprovider.COMMUNITY_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport';
		authprovider.COMMUNITY_LOGIN_URL = 'https://auspost--devnathan.sandbox.my.site.com/HelpAndSupport/login';

		try {

			authprovider.getUserInfo(customMetadataValues, tokenResponse);

			System.assert(false, 'Expected exception');
		} catch(Auth0OIDCAuthProvider.OAuthException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Expected OAuthException: ' + ex.getMessage());
		}

		Test.stopTest();

	}

	/**
	 * Scenario: get the custom metadata for auth provider
	 */
	@isTest
	private static void testGetCustomMetadataType() {
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

		Auth0OIDCAuthProvider authprovider = new Auth0OIDCAuthProvider();
        String actual = authprovider.getCustomMetadataType();
        System.assertEquals('Auth0OIDCAuthProvider__mdt', actual, 'Incorrect metadata returned');

		Test.stopTest();
	}

	private class PartialSuccessfulAccessTokenWithoutAccessTokenHttpMock implements HttpCalloutMock {
		public String requestBody = '';
		public String requestEndpoint = '';

		public HTTPResponse respond(HTTPRequest req) {
			requestBody = req.getBody();
			requestEndpoint = req.getEndpoint();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"token_type":"Bearer","scope":"email openid profile","expires_in":3739,"ext_expires_in":3739}');
			res.setStatusCode(200);
			return res;
		}
	}
	private class SuccessfulAccessTokenHttpMock implements HttpCalloutMock {
		public String requestBody = '';
		public String requestEndpoint = '';

		public HTTPResponse respond(HTTPRequest req) {
			requestBody = req.getBody();
			requestEndpoint = req.getEndpoint();

			String accessToken = mockAccessToken;

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"access_token":"' + mockAccessToken + '","id_token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InE0ZGNLb21ydzNrdHNUOENoNGQ1UyJ9.eyJodHRwczovL2F1c3Bvc3QvY251bWJlciI6IkMzMjAwMDAwNzE0OSIsImh0dHBzOi8vYXVzcG9zdC9hcGNuIjoiMTAyNzE0NDMzOSIsImdpdmVuX25hbWUiOiJldzFna3dlcmoxb2l3amVyb2lqMzQzNDM0ajQzdTR1IiwiZmFtaWx5X25hbWUiOiJldzFna3dlcmoxb2l3amVyb2lqMzQzNDM0ajQzdTR1Iiwibmlja25hbWUiOiJldzFna3dlcmoxb2l3amVyb2lqMzQzNDM0ajQzdTR1IiwibmFtZSI6ImV3MWdrd2VyajFvaXdqZXJvaWozNDM0MzRqNDN1NHVAeW9wbWFpbC5jb20iLCJwaWN0dXJlIjoiaHR0cHM6Ly9zLmdyYXZhdGFyLmNvbS9hdmF0YXIvYzVmNmZiYWNhY2JkM2I4ZGFlOGNlMjA4ZWE4OWM4ZGU_cz00ODAmcj1wZyZkPWh0dHBzJTNBJTJGJTJGY2RuLmF1dGgwLmNvbSUyRmF2YXRhcnMlMkZldy5wbmciLCJ1cGRhdGVkX2F0IjoiMjAyMy0wMy0yOFQyMDowNzo1My4zNzFaIiwiZW1haWwiOiJldzFna3dlcmoxb2l3amVyb2lqMzQzNDM0ajQzdTR1QHlvcG1haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlzcyI6Imh0dHBzOi8vd2VsY29tZS5wdGVzdC5hdXNwb3N0LmNvbS5hdS8iLCJhdWQiOiI4TGtWWE5JWWxUUzJTMDVRTVhDblZjNzNtQW15amxtNSIsImlhdCI6MTY4MDAzNDEzNCwiZXhwIjoxNjgwMDcwMTM0LCJzdWIiOiJhdXRoMHw2M2ZiZmMwYzgyMzFiMjk3Y2UzNjk4ZDYiLCJzaWQiOiJaYkpiRkw3VlFDUW13NFdqU0VQYzhFWk16ZVNzcUhxRSJ9.oXvBlDE7UYKPXaVaCy2270Cc4CZQojPHd_6RxPyuyS9FvVXcc-hC1AlYkKR7iJ01V1Alz47fFmcWAK4B5ci2wkNymswqGGhngmk5jpfULd4RoWRFUTL25lvMFBLA24dkMcGZgapWu8Zut87BlSp1Haqec34wJel72y5abDsz48WfQi86T_KJQBM5ydaJB-Wz6Gv9uXHV38TQUChxhfneneGI8ZfCDg2U3tgZNN5I5Z-MngFuqh35v1eiWV6045qnnk-Y2d7OLiwczOsrrEqahEFtdV7YGA2MBMKp1s0_elbsv1pNv14qrSZwHEpuXcUqdfBgODGKO-OB6g4pfQKUyw","scope":"openid profile email","expires_in":14400,"token_type":"Bearer"}');
			res.setStatusCode(200);
			return res;
		}
	}
	private class FailedAccessTokenHttpMock implements HttpCalloutMock {
		public String requestBody = '';
		public String requestEndpoint = '';

		public HTTPResponse respond(HTTPRequest req) {
			requestBody = req.getBody();
			requestEndpoint = req.getEndpoint();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"error":"invalid_grant","error_description":"Unable to verify code verifier"}');
			res.setStatusCode(400);
			res.setStatus('Bad Request');
			return res;
		}
	}
	private class SuccessfulUserInfoHttpMock implements HttpCalloutMock {
		public String requestBody = '';
		public String requestEndpoint = '';

		public HTTPResponse respond(HTTPRequest req) {
			requestBody = req.getBody();
			requestEndpoint = req.getEndpoint();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"sub":"auth0&#124;63fbfc0c8231b297ce3698d6","given_name":"ew1gkwerj1oiwjeroij343434j43u4u","family_name":"ew1gkwerj1oiwjeroij343434j43u4u","nickname":"ew1gkwerj1oiwjeroij343434j43u4u","name":"ew1gkwerj1oiwjeroij343434j43u4u@yopmail.com","picture":"https://s.gravatar.com/avatar/c5f6fbacacbd3b8dae8ce208ea89c8de?s=480&r=pg&d=https%3A%2F%2Fcdn.auth0.com%2Favatars%2Few.png","updated_at":"2023-03-28T20:07:53.371Z","email":"ew1gkwerj1oiwjeroij343434j43u4u@yopmail.com","email_verified":true,"https://auspost/cnumber":"C32000007149","https://auspost/apcn":"1027144339"}');
			res.setStatusCode(200);
			return res;
		}
	}
	private class FailedUserInfoHttpMock implements HttpCalloutMock {
		public String requestBody = '';
		public String requestEndpoint = '';

		public HTTPResponse respond(HTTPRequest req) {
			requestBody = req.getBody();
			requestEndpoint = req.getEndpoint();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"status":"BAD_REQUEST","code":"INVALID_REQUEST","detail":"Required header is missing"}');
			res.setStatusCode(401);
			res.setStatus('Unauthorized');
			return res;
		}
	}
}