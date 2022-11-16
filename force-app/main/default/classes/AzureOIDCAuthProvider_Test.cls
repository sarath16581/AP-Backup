/***
 * @description Test Scenarios for AzureOIDCAuthProvider
 * @author Nathan Franklin
 * @date 2022-11-09
 * @changelog
 */
@IsTest
private class AzureOIDCAuthProvider_Test {

	/**
	 * Scenario: Ensures that the correct url is generated that redirects the user to azure so they can log in
	 */
	@IsTest
	private static void testEnsureCorrectInitialiseUrlIsGenerated() {
		// =====================================
		// Data Preparation
		// =====================================

		String state = 'nothingmeangingful';
		Map<String, String> customMetadataValues = new Map<String, String>{
			'ClientId__c' => 'client-id-1234',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'openid profile email',
			'RedirectUrl__c' => 'https://my-redirect-url.com/authcallback'
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AzureOIDCAuthProvider authprovider = new AzureOIDCAuthProvider();
		PageReference redirect = authprovider.initiate(customMetadataValues, state);
		String url = redirect.getUrl();

		Test.stopTest();

		url = EncodingUtil.urlDecode(url, 'UTF-8');

		System.assertEquals(true, Pattern.compile('(?is)^https:\\/\\/my-authorisation-end-point.com\\/authorise').matcher(url).find(), 'Authorise URL was not present: ' + url);
		System.assertEquals(true, Pattern.compile('(?is)\\?.*?scope=openid profile email').matcher(url).find(), 'Scope was not present: ' + url);
		System.assertEquals(true, Pattern.compile('(?is)\\?.*?client_id=client-id-1234').matcher(url).find(), 'Client Id was not present: ' + url);
		System.assertEquals(true, Pattern.compile('(?is)\\?.*?redirect_uri=https:\\/\\/my-redirect-url\\.com\\/authcallback').matcher(url).find(), 'Redirect URL was not present: ' + url);

	}

	/**
	 * Scenario: Makes sure a successful end-to-end callback payload is processed
	 */
	@IsTest
	private static void testEnsureCallbackMethodIsSuccessful() {
		// =====================================
		// Data Preparation
		// =====================================

		Map<String, String> customMetadataValues = new Map<String, String>{
			'ClientId__c' => 'client-id-1234',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'openid profile email',
			'RedirectUrl__c' => 'https://my-redirect-url.com/authcallback'
		};

		Map<String, String> headers = new Map<String, String>{
			'Accept' => 'text/html',
			'Accept-Encoding' => 'gzip',
			'doesnothing' => 'pointless'
		};
		Map<String, String> queryParameters = new Map<String, String>{
			'code' => '0AWcADu-vQZ56hEWduo',
			'state' => 'nothingmeangingful',
			'session_state' => '7874d0e9-5044-4267-9 (16 more) ...'
		};
		Auth.AuthProviderCallbackState callbackState = new Auth.AuthProviderCallbackState(headers, null, queryParameters);

		// =====================================
		// Stubbing
		// =====================================
		SuccessfulAccessTokenHttpMock httpMock = new SuccessfulAccessTokenHttpMock();
		Test.setMock(HttpCalloutMock.class, httpMock);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AzureOIDCAuthProvider authprovider = new AzureOIDCAuthProvider();
		Auth.AuthProviderTokenResponse tokenResponse = authprovider.handleCallback(customMetadataValues, callbackState);
		
		Test.stopTest();

		String requestBody = EncodingUtil.urlDecode(httpMock.requestBody, 'UTF-8');

		System.assertEquals(mockAccessToken, tokenResponse.oauthToken);
		System.assertEquals(true, Pattern.compile('(?is)code=0AWcADu-vQZ56hEWduo').matcher(requestBody).find(), 'Auth Code was not present: ' + requestBody);
		System.assertEquals(true, Pattern.compile('(?is)scope=openid profile email').matcher(requestBody).find(), 'Scope was not present: ' + requestBody);
		System.assertEquals(true, Pattern.compile('(?is)grant_type=authorization_code').matcher(requestBody).find(), 'Authorisation Type was not present: ' + requestBody);
		System.assertEquals(true, Pattern.compile('(?is)client_id=client-id-1234').matcher(requestBody).find(), 'Client Id was not present: ' + requestBody);
		System.assertEquals(true, Pattern.compile('(?is)client_secret=').matcher(requestBody).find(), 'Client Secret was not present: ' + requestBody);

	}

	/**
	 * Scenario: callback fails because of an unexpected error from Azure token endpoint
	 */
	@IsTest
	private static void testEnsureCallbackMethodFailsAsExpected() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<String, String> customMetadataValues = new Map<String, String>{
			'ClientId__c' => 'client-id-1234',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'openid profile email',
			'RedirectUrl__c' => 'https://my-redirect-url.com/authcallback'
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
			AzureOIDCAuthProvider authprovider = new AzureOIDCAuthProvider();
			authprovider.handleCallback(customMetadataValues, callbackState);

			System.assert(false, 'Expected exception');
		} catch(AzureOIDCAuthProvider.OAuthException ex) {
			// this is from the failed mock
			System.assertEquals(true, ex.getMessage().contains('AADSTS700009: Reply address must be provided when presenting an autho-bf98-83ccd72c9600Correlation ID: d85ff88d-c192-4802-bbad-29Z'), 'Expected error message but got: ' + ex.getMessage());
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
		Map<String, String> customMetadataValues = new Map<String, String>{
			'ClientId__c' => 'client-id-1234',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'openid profile email',
			'RedirectUrl__c' => 'https://my-redirect-url.com/authcallback'
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
			AzureOIDCAuthProvider authprovider = new AzureOIDCAuthProvider();
			authprovider.handleCallback(customMetadataValues, callbackState);

			System.assert(false, 'Expected exception');
		} catch(AzureOIDCAuthProvider.OAuthException ex) {
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

		Map<String, String> customMetadataValues = new Map<String, String>{
			'ClientId__c' => 'client-id-1234',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'openid profile email',
			'RedirectUrl__c' => 'https://my-redirect-url.com/authcallback'
		};

		String state = 'nothingmeanginful';
		String accessToken = mockAccessToken;
		Auth.AuthProviderTokenResponse tokenResponse = new Auth.AuthProviderTokenResponse('Azure', accessToken, '', state);

		// =====================================
		// Stubbing
		// =====================================
		SuccessfulUserInfoHttpMock httpMock = new SuccessfulUserInfoHttpMock();
		Test.setMock(HttpCalloutMock.class, httpMock);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AzureOIDCAuthProvider authprovider = new AzureOIDCAuthProvider();

		Auth.UserData userData = authprovider.getUserInfo(customMetadataValues, tokenResponse);
		
		Test.stopTest();

		String requestBody = EncodingUtil.urlDecode(httpMock.requestBody, 'UTF-8');

		System.assertEquals(userData.firstName, 'Nathan');
		System.assertEquals(userData.lastName, 'FRANKLIN');
		System.assertEquals(userData.fullName, 'FRANKLIN, Nathan');
		System.assertEquals(userData.username, 'franklinn1@test.npe.auspost.com.au');
		System.assertEquals(userData.email, 'franklinn1@test.npe.auspost.com.au');
		System.assertEquals(userData.attributeMap.get('upn'), 'franklinn1@test.npe.auspost.com.au');

	}

	/**
	 * Scenario: UserInfo api call fails due to an error from azure
	 */
	@IsTest
	private static void testEnsureUserInfoMethodFailsAsExpectedWhenInvalidResponseIsReceived() {

		// =====================================
		// Data Preparation
		// =====================================

		Map<String, String> customMetadataValues = new Map<String, String>{
			'ClientId__c' => 'client-id-1234',
			'AuthoriseEndpointUrl__c' => 'https://my-authorisation-end-point.com/authorise',
			'Scope__c' => 'openid profile email',
			'RedirectUrl__c' => 'https://my-redirect-url.com/authcallback'
		};

		String state = 'nothingmeanginful';
		String accessToken = 'my-access-token';
		Auth.AuthProviderTokenResponse tokenResponse = new Auth.AuthProviderTokenResponse('Azure', accessToken, '', state);

		// =====================================
		// Stubbing
		// =====================================
		FailedUserInfoHttpMock httpMock = new FailedUserInfoHttpMock();
		Test.setMock(HttpCalloutMock.class, httpMock);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AzureOIDCAuthProvider authprovider = new AzureOIDCAuthProvider();

		try {

			authprovider.getUserInfo(customMetadataValues, tokenResponse);

			System.assert(false, 'Expected exception');
		} catch(AzureOIDCAuthProvider.OAuthException ex) {
			// exception thrown since id_token was missing
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

		AzureOIDCAuthProvider authprovider = new AzureOIDCAuthProvider();
        String actual = authprovider.getCustomMetadataType();
        System.assertEquals('AzureOIDCAuthProvider__mdt', actual, 'Incorrect metadata returned');
		
		Test.stopTest();
	}

	private class PartialSuccessfulAccessTokenWithoutAccessTokenHttpMock implements HttpCalloutMock {
		public String requestBody = '';

		public HTTPResponse respond(HTTPRequest req) {		
			requestBody = req.getBody();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"token_type":"Bearer","scope":"email openid profile","expires_in":3739,"ext_expires_in":3739}');
			res.setStatusCode(200);
			return res;
		}
	}
	private class SuccessfulAccessTokenHttpMock implements HttpCalloutMock {
		public String requestBody = '';

		public HTTPResponse respond(HTTPRequest req) {		
			requestBody = req.getBody();

			String accessToken = mockAccessToken;

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"token_type":"Bearer","scope":"email openid profile","expires_in":3739,"ext_expires_in":3739,"access_token":"' + accessToken + '"}');
			res.setStatusCode(200);
			return res;
		}
	}
	private class FailedAccessTokenHttpMock implements HttpCalloutMock {
		public String requestBody = '';

		public HTTPResponse respond(HTTPRequest req) {		
			requestBody = req.getBody();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"error":"invalid_grant","error_description":"AADSTS700009: Reply address must be provided when presenting an autho-bf98-83ccd72c9600Correlation ID: d85ff88d-c192-4802-bbad-29Z","error_codes":[700009],"timestamp":"2022-11-08 21:49:39Z","trace_id":"f7c9120","correlation_id":"d85ff8858"}');
			res.setStatusCode(400);
			res.setStatus('Bad Request');
			return res;
		}
	}
	private class SuccessfulUserInfoHttpMock implements HttpCalloutMock {
		public String requestBody = '';

		public HTTPResponse respond(HTTPRequest req) {		
			requestBody = req.getBody();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"sub":"hwcO1diw2q0SVXwXCGNL0FPum1dyZJEhs8-jzPbvnM4","name":"FRANKLIN, Nathan","family_name":"FRANKLIN","given_name":"Nathan","picture":"https://graph.microsoft.com/v1.0/me/photo/$value","email":"franklinn1@test.npe.auspost.com.au"}');
			res.setStatusCode(200);
			return res;
		}
	}
	private class FailedUserInfoHttpMock implements HttpCalloutMock {
		public String requestBody = '';

		public HTTPResponse respond(HTTPRequest req) {		
			requestBody = req.getBody();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"error":{"code":"InvalidAuthenticationToken","message":"Access token is empty.","innerError":{"date":"2022-11-09T00:22:00","request-id":"3fa91061-aeb2-40a3-a51d-c95921fffcd5","client-request-id":"3fa91061-aeb2-40a3-a51d-c95921fffcd5"}}}');
			res.setStatusCode(401);
			res.setStatus('Unauthorized');
			return res;
		}
	}

	//

	// access_token includes:
	// {
	// 	"aud": "3f7d16ea-6672-4d60-bcd1-fa5d2672009a",
	// 	"iss": "https://login.microsoftonline.com/41afef0e-7a9e-4584-9dba-86c335624811/v2.0",
	// 	"email": "franklinn1@test.npe.auspost.com.au",
	// 	"name": "FRANKLIN, Nathan",
	// 	"upn": "franklinn1@test.npe.auspost.com.au",
	// 	"ver": "2.0"
	//   }
	public static String mockAccessToken {
		get {
			return 'ignored.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTAwMDAtYzAwMC0wMDAwMDAwMDAwMDAiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC80MWFmZWYwZS03YTllLTQ1ODQtOWRiYS04NmMzMzU2MjQ4MTEvIiwiaWF0IjoxNjY4MTE2MzQ1LCJuYmYiOjE2NjgxMTYzNDUsImV4cCI6MTY2ODEyMTM5NywiYWNjdCI6MCwiYWNyIjoiMSIsImFjcnMiOlsidXJuOnVzZXI6cmVnaXN0ZXJzZWN1cml0eWluZm8iXSwiYWlvIjoiQVhRQWkvOFRBQUFBWWZzMHBTbzFkdTEzd3hsM0ZGc2NGdjhUZnJteWdsVGV4T0tzYW9zWHJKTVFpMWFoMzArbldvZUROZFpZVnkwd0NTUjA1bFFLbEtXSC9NeGRkK2RvMjN4UmNDcGdFaGtFWEVDOGZnYnhoR3ZmUk9IanZYVFBIZTR4RTUxTGhQKzVkOE9HTzFCSjI1T0tGdmNxYy9sdjZnPT0iLCJhbXIiOlsicHdkIiwibWZhIl0sImFwcF9kaXNwbGF5bmFtZSI6Ik15TmV0d29yay1TYWxlc2ZvcmNlKFNUZXN0KSIsImFwcGlkIjoiM2Y3ZDE2ZWEtNjY3Mi00ZDYwLWJjZDEtZmE1ZDI2NzIwMDlhIiwiYXBwaWRhY3IiOiIxIiwiZmFtaWx5X25hbWUiOiJGUkFOS0xJTiIsImdpdmVuX25hbWUiOiJOYXRoYW4iLCJpZHR5cCI6InVzZXIiLCJpcGFkZHIiOiIxMjAuODguMTI0LjE0MiIsIm5hbWUiOiJGUkFOS0xJTiwgTmF0aGFuIiwib2lkIjoiZWQ3Njk5NmItODRlNC00ZWI3LWEwYTMtZjU4OWQwZDc0NDMzIiwib25wcmVtX3NpZCI6IlMtMS01LTIxLTI2NTQ5ODYwNjUtMjM1NTk1MTk4Ni01OTAxMzE0NTAtMTIxMjM1IiwicGxhdGYiOiI1IiwicHVpZCI6IjEwMDMyMDAxRjFDNEI4QTgiLCJyaCI6IjAuQVdjQUR1LXZRWjU2aEVXZHVvYkROV0pJRVFNQUFBQUFBQUFBd0FBQUFBQUFBQUJuQUI0LiIsInNjcCI6ImVtYWlsIG9wZW5pZCBwcm9maWxlIiwic3ViIjoiYThGdHo0bWYzMU1Bdkd3U2szVmlJbnI1OUhuNlVTa1R4dGRLZ2pOa2EyQSIsInRlbmFudF9yZWdpb25fc2NvcGUiOiJPQyIsInRpZCI6IjQxYWZlZjBlLTdhOWUtNDU4NC05ZGJhLTg2YzMzNTYyNDgxMSIsInVuaXF1ZV9uYW1lIjoiZnJhbmtsaW5uMUB0ZXN0Lm5wZS5hdXNwb3N0LmNvbS5hdSIsInVwbiI6ImZyYW5rbGlubjFAdGVzdC5ucGUuYXVzcG9zdC5jb20uYXUiLCJ1dGkiOiJqdS1zc2EydUJVaWJWelhJelFQSUFBIiwidmVyIjoiMS4wIiwid2lkcyI6WyJiNzlmYmY0ZC0zZWY5LTQ2ODktODE0My03NmIxOTRlODU1MDkiXSwieG1zX3N0Ijp7InN1YiI6Imh3Y08xZGl3MnEwU1ZYd1hDR05MMEZQdW0xZHlaSkVoczgtanpQYnZuTTQifSwieG1zX3RjZHQiOjE0MTg4NzYyODZ9.ignored';
		}
	}

}