/***
 * @description Custom auth provider for Azure
 *
 * This was built since both OOTB Open ID Connect and Microsoft providers did not provide the preferred_username/upn attribute from Azure
 * Email and subject were the only 2 fields, however email field seemed to be manually maintained and in some scenarios the value would be blank
 * By implementing our own provider we have access to any additional attributes that are needed.
 *
 * @author Nathan Franklin
 * @date 2022-11-08
 * @changelog
*/
global class AzureOIDCAuthProvider extends Auth.AuthProviderPluginClass {
	
	@TestVisible
	String idTokenJwt = '';

	global String getCustomMetadataType() {
		return 'AzureOIDCAuthProvider__mdt';
	}

	global PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {
		String clientId = authProviderConfiguration.get('ClientId__c');
		String authoriseEndpointUrl = authProviderConfiguration.get('AuthoriseEndpointUrl__c');
		String scope = authProviderConfiguration.get('Scope__c');
		String redirectUrl = authProviderConfiguration.get('RedirectUrl__c');

		String url = authoriseEndpointUrl + '?response_type=code&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') + '&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8') + '&redirect_uri='+ EncodingUtil.urlEncode(redirectUrl, 'UTF-8') + '&state=' + stateToPropagate;
		return new PageReference(url);
	}

	global Auth.AuthProviderTokenResponse handleCallback(Map<String, String> authProviderConfiguration, Auth.AuthProviderCallbackState state) {

		String errorMessage = '';
		String clientId = authProviderConfiguration.get('ClientId__c');
		String authoriseEndpointUrl = authProviderConfiguration.get('AuthoriseEndpointUrl__c');
		String scope = authProviderConfiguration.get('Scope__c');
		String redirectUrl = authProviderConfiguration.get('RedirectUrl__c');
		String tokenNamedCredentialName = authProviderConfiguration.get('NamedCredentialTokenUrlName__c');
		String externalCredentialName = authProviderConfiguration.get('ExternalCredentialName__c');

		Map<String,String> queryParams = state.queryParameters;
		String code = queryParams.get('code');
		String sfdcState = queryParams.get('state');

		// convert the authorisation code to an access_token (with an id_token)
		HttpRequest req = new HttpRequest();
		String url = 'callout:' + tokenNamedCredentialName;
		req.setMethod('POST');
		req.setEndpoint(url);
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

		String clientSecretExternalCredentialName = 'Credential.' + externalCredentialName + '.client_secret';

		String tokenBody = 'client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
							'&code=' + EncodingUtil.urlEncode(code, 'UTF-8') +
							'&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8') +
							'&grant_type=authorization_code' +
							'&redirect_uri=' + EncodingUtil.urlEncode(redirectUrl, 'UTF-8') +
							'&client_secret={!$' + clientSecretExternalCredentialName + '}';
		req.setBody(tokenBody);

		Http http = new Http();
		HttpResponse res = http.send(req);
		
		String body = res.getBody();
		Token tokenResponse = (Token)JSON.deserialize(body, Token.Class);

		if(tokenResponse == null) {
			throw new OAuthException('A token error occurred');
		}

		if(!String.isEmpty(tokenResponse.error_description) || !String.isEmpty(tokenResponse.error)) {
			errorMessage = 'Token API: ' + (!String.isEmpty(tokenResponse.error) ? tokenResponse.error + ': ' : '') + (!String.isEmpty(tokenResponse.error_description) ? tokenResponse.error_description : 'A token error occurred');
		}

		if (res.getStatusCode() != 200 || !String.isEmpty(errorMessage)) {
			if(String.isEmpty(errorMessage)) {
				errorMessage = 'A token error occurred';
			}
			throw new OAuthException(errorMessage);
		}

		if(String.isEmpty(tokenResponse.id_token) || String.isEmpty(tokenResponse.access_token)) {
			throw new OAuthException('The returned response was invalid');
		}

		// store the jwt token from the /token endpoint call
		// this is used in the getUserInfo method where the details are extracted out form it
		idTokenJwt = tokenResponse.id_token;

		// note there is no refresh token for this flow
		return new Auth.AuthProviderTokenResponse('Azure', String.valueOf(tokenResponse.access_token), '', sfdcState);
	}

	/**
	 * NOTE: This allows us to call the userinfo endpoint in Azure
	 * Although this is not necessary, we do this anyway to validate the access token is current and functional (since we don't actually use the access token for anything else)
	 */
	global Auth.UserData getUserInfo(Map<String, String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {

		String errorMessage = '';
		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		
		// this can be hard coded since it will never change
		// that being said, at some point we should probably store it in the custom metadta config
		req.setEndpoint('https://graph.microsoft.com/oidc/userinfo');

		req.setHeader('Authorization', 'Bearer ' + response.oauthToken);
		HttpResponse res = http.send(req);

		String body = res.getBody();
		UserInfoToken tokenResponse = (UserInfoToken)JSON.deserialize(body, UserInfoToken.Class);

		if(tokenResponse == null) {
			throw new OAuthException('A UserInfo token error occurred');
		}

		if(tokenResponse.error != null && (!String.isEmpty(tokenResponse.error.code) || !String.isEmpty(tokenResponse.error.message))) {
			errorMessage = 'UserInfo API: ' + (!String.isEmpty(tokenResponse.error.code) ? tokenResponse.error.code + ': ' : '') + (!String.isEmpty(tokenResponse.error.message) ? tokenResponse.error.message : 'A token error occurred');
		}

		if (res.getStatusCode() != 200 || !String.isEmpty(errorMessage)) {
			if(String.isEmpty(errorMessage)) {
				errorMessage = 'A UserInfo token error occurred';
			}
			throw new OAuthException(errorMessage);
		}

		Auth.UserData userData = parseIdToken();
		userData.firstName = tokenResponse.given_name;
		userData.lastName = tokenResponse.family_name;
		return userData;
	}

	private Auth.UserData parseIdToken() {

		// a JWT token is split up into 3 parts. We only want to extract the claims out 
		List<String> idTokenParts = String.valueOf(idTokenJwt).split('\\.');
		if(idTokenParts.size() != 3) {
			throw new OAuthException('id_token is invalid');
		}

		// TODO... If this is set here, it may cause failures if getUserInfo() is called outside the current instance of the class where the id_token value is held....
		//			hmmmmmm
		// parse the claims into a class so we can access it later on
		// we store it in an instance variable for easy access
		IdToken idTokenClaims = (IdToken)JSON.deserialize(EncodingUtil.base64Decode(idTokenParts[1]).toString(), IdToken.Class);

		String identifier = idTokenClaims.sub;
		String fullName = idTokenClaims.name;
		String username = idTokenClaims.preferred_username;
		String email = idTokenClaims.email;
		String provider = 'Azure';
		
		Map<String, String> attributeMap = new Map<String, String>();
		
		attributeMap.put('sub', idTokenClaims.sub);
		attributeMap.put('iss', idTokenClaims.iss);
		attributeMap.put('iat', String.valueOf(idTokenClaims.iat));
		attributeMap.put('nbf', String.valueOf(idTokenClaims.nbf));
		attributeMap.put('exp', String.valueOf(idTokenClaims.exp));
		attributeMap.put('email', idTokenClaims.email);
		attributeMap.put('name', idTokenClaims.name);
		attributeMap.put('oid', idTokenClaims.oid);
		attributeMap.put('preferred_username', idTokenClaims.preferred_username);
		attributeMap.put('upn', idTokenClaims.upn);
		attributeMap.put('aud', idTokenClaims.aud);

		Auth.UserData userData = new Auth.UserData(identifier, '', '', fullName, email, '', username, '', provider, '', attributeMap);
		return userData;
	}

	global class OAuthException extends Exception {}

	/**
	 * Response received from the /token endpoint
	 */
	global class Token {
		public String access_token;
		public String id_token;
		public String token_type;
		public Integer expires_in;
		
		public String error;
		public String error_description;

	}

	global class IdToken {
		public String aud;
		public String iss;
		public Integer iat;
		public Integer nbf;
		public Integer exp;
		public String email;
		public String name;
		public String oid;
		public String preferred_username;
		public String sub;
		public String upn;
	}

	global class UserInfoToken {
		public String sub;
		public String name;
		public String family_name;
		public String given_name;
		public String picture;
		public String email;
		public UserInfoErrorMessage error;
	}

	global class UserInfoErrorMessage {
		public String code;
		public String message;
	}

}