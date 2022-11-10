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

		System.assertEquals('my-access-token', tokenResponse.oauthToken);
		System.assertEquals(true, Pattern.compile('(?is)code=0AWcADu-vQZ56hEWduo').matcher(requestBody).find(), 'Auth Code was not present: ' + requestBody);
		System.assertEquals(true, Pattern.compile('(?is)scope=openid profile email').matcher(requestBody).find(), 'Scope was not present: ' + requestBody);
		System.assertEquals(true, Pattern.compile('(?is)grant_type=authorization_code').matcher(requestBody).find(), 'Authorisation Type was not present: ' + requestBody);
		System.assertEquals(true, Pattern.compile('(?is)client_id=client-id-1234').matcher(requestBody).find(), 'Client Id was not present: ' + requestBody);
		System.assertEquals(true, Pattern.compile('(?is)client_secret=').matcher(requestBody).find(), 'Client Secret was not present: ' + requestBody);

		System.assertEquals(mockIdToken, authprovider.idTokenJwt);

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
	 * Scenario: Id_token was not return in payload so we throw an exception
	 */
	@IsTest
	private static void testEnsureCallbackMethodFailsSinceIdTokenIsMissing() {

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
		PartialSuccessfulAccessTokenWithoutIdTokenHttpMock httpMock = new PartialSuccessfulAccessTokenWithoutIdTokenHttpMock();
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
			// exception thrown since id_token was missing
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
		String accessToken = 'my-access-token';
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

		//special for setting the Id Token which would normally 
		authprovider.idTokenJwt = mockIdToken;

		Auth.UserData userData = authprovider.getUserInfo(customMetadataValues, tokenResponse);
		
		Test.stopTest();

		String requestBody = EncodingUtil.urlDecode(httpMock.requestBody, 'UTF-8');

		System.assertEquals(userData.firstName, 'Nathan');
		System.assertEquals(userData.lastName, 'FRANKLIN');
		System.assertEquals(userData.fullName, 'FRANKLIN, Nathan');
		System.assertEquals(userData.username, 'franklinn1@test.npe.auspost.com.au');
		System.assertEquals(userData.email, 'franklinn1@test.npe.auspost.com.au');
		System.assertEquals(userData.attributeMap.get('preferred_username'), 'franklinn1@test.npe.auspost.com.au');

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

		//special for setting the Id Token which would normally 
		authprovider.idTokenJwt = mockIdToken;

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

	private class PartialSuccessfulAccessTokenWithoutIdTokenHttpMock implements HttpCalloutMock {
		public String requestBody = '';

		public HTTPResponse respond(HTTPRequest req) {		
			requestBody = req.getBody();

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"token_type":"Bearer","scope":"email openid profile","expires_in":3739,"ext_expires_in":3739,"access_token":"my-access-token"}');
			res.setStatusCode(200);
			return res;
		}
	}
	private class SuccessfulAccessTokenHttpMock implements HttpCalloutMock {
		public String requestBody = '';

		public HTTPResponse respond(HTTPRequest req) {		
			requestBody = req.getBody();

			String idToken = mockIdToken;

			// id_token includes:
			// {
			// 	"aud": "3f7d16ea-6672-4d60-bcd1-fa5d2672009a",
			// 	"iss": "https://login.microsoftonline.com/41afef0e-7a9e-4584-9dba-86c335624811/v2.0",
			// 	"email": "franklinn1@test.npe.auspost.com.au",
			// 	"name": "FRANKLIN, Nathan",
			// 	"preferred_username": "franklinn1@test.npe.auspost.com.au",
			// 	"upn": "franklinn1@test.npe.auspost.com.au",
			// 	"ver": "2.0"
			//   }
			// ^^ subset of above id token

			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"token_type":"Bearer","scope":"email openid profile","expires_in":3739,"ext_expires_in":3739,"access_token":"my-access-token","id_token":"' + idToken + '"}');
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

	// id_token includes:
	// {
	// 	"aud": "3f7d16ea-6672-4d60-bcd1-fa5d2672009a",
	// 	"iss": "https://login.microsoftonline.com/41afef0e-7a9e-4584-9dba-86c335624811/v2.0",
	// 	"email": "franklinn1@test.npe.auspost.com.au",
	// 	"name": "FRANKLIN, Nathan",
	// 	"preferred_username": "franklinn1@test.npe.auspost.com.au",
	// 	"upn": "franklinn1@test.npe.auspost.com.au",
	// 	"ver": "2.0"
	//   }
	public static String mockIdToken {
		get {
			return 'ignored.eyJhdWQiOiIzZjdkMTZlYS02NjcyLTRkNjAtYmNkMS1mYTVkMjY3MjAwOWEiLCJpc3MiOiJodHRwczovL2xvZ2luLm1pY3Jvc29mdG9ubGluZS5jb20vNDFhZmVmMGUtN2E5ZS00NTg0LTlkYmEtODZjMzM1NjI0ODExL3YyLjAiLCJpYXQiOjE2Njc5NDQ2MzIsIm5iZiI6MTY2Nzk0NDYzMiwiZXhwIjoxNjY3OTQ4NTMyLCJlbWFpbCI6ImZyYW5rbGlubjFAdGVzdC5ucGUuYXVzcG9zdC5jb20uYXUiLCJuYW1lIjoiRlJBTktMSU4sIE5hdGhhbiIsIm9pZCI6ImVkNzY5OTZiLTg0ZTQtNGViNy1hMGEzLWY1ODlkMGQ3NDQzMyIsInByZWZlcnJlZF91c2VybmFtZSI6ImZyYW5rbGlubjFAdGVzdC5ucGUuYXVzcG9zdC5jb20uYXUiLCJyaCI6IjAuQVdjQUR1LXZRWjU2aEVXZHVvYkROV0pJRWVvV2ZUOXlabUJOdk5INlhTWnlBSnBuQUI0LiIsInN1YiI6Imh3Y08xZGl3MnEwU1ZYd1hDR05MMEZQdW0xZHlaSkVoczgtanpQYnZuTTQiLCJ0aWQiOiI0MWFmZWYwZS03YTllLTQ1ODQtOWRiYS04NmMzMzU2MjQ4MTEiLCJ1cG4iOiJmcmFua2xpbm4xQHRlc3QubnBlLmF1c3Bvc3QuY29tLmF1IiwidXRpIjoieEdfaVpydlVORWlMRkRvbmFHT0xBQSIsInZlciI6IjIuMCJ9.ignored';
		}
	}

}