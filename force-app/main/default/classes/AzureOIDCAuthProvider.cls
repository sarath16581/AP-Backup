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

		// convert the authorisation code to an access_token
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

		if(String.isEmpty(tokenResponse.access_token)) {
			throw new OAuthException('The returned response was invalid');
		}

		// note there is no refresh token for this flow
		return new Auth.AuthProviderTokenResponse('Azure', String.valueOf(tokenResponse.access_token), '', sfdcState);
	}

	/**
	 * NOTE: This allows us to call the userinfo endpoint in Azure
	 * Although this is not necessary, we do this anyway to validate the access token is current and functional
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
		UserInfoToken parsedUserInfoToken = (UserInfoToken)JSON.deserialize(body, UserInfoToken.Class);

		if(parsedUserInfoToken == null) {
			throw new OAuthException('A UserInfo token error occurred');
		}

		if(parsedUserInfoToken.error != null && (!String.isEmpty(parsedUserInfoToken.error.code) || !String.isEmpty(parsedUserInfoToken.error.message))) {
			errorMessage = 'UserInfo API: ' + (!String.isEmpty(parsedUserInfoToken.error.code) ? parsedUserInfoToken.error.code + ': ' : '') + (!String.isEmpty(parsedUserInfoToken.error.message) ? parsedUserInfoToken.error.message : 'A token error occurred');
		}

		if (res.getStatusCode() != 200 || !String.isEmpty(errorMessage)) {
			if(String.isEmpty(errorMessage)) {
				errorMessage = 'A UserInfo token error occurred';
			}
			throw new OAuthException(errorMessage);
		}

		Auth.UserData userData = parseAccessToken(response.oauthToken);
		userData.email = parsedUserInfoToken.email;
		return userData;
	}

	private Auth.UserData parseAccessToken(String token) {

		// a JWT token is split up into 3 parts. We only want to extract the claims out 
		List<String> tokenParts = String.valueOf(token).split('\\.');
		if(tokenParts.size() != 3) {
			throw new OAuthException('access_token is invalid');
		}

		AccessToken tokenClaims = (AccessToken)JSON.deserialize(EncodingUtil.base64Decode(tokenParts[1]).toString(), AccessToken.Class);

		String identifier = tokenClaims.sub;
		String fullName = tokenClaims.name;
		String username = tokenClaims.upn;
		String provider = 'Azure';
		
		Map<String, String> attributeMap = new Map<String, String>();
		attributeMap.put('sub', tokenClaims.sub);
		attributeMap.put('iss', tokenClaims.iss);
		attributeMap.put('iat', String.valueOf(tokenClaims.iat));
		attributeMap.put('nbf', String.valueOf(tokenClaims.nbf));
		attributeMap.put('exp', String.valueOf(tokenClaims.exp));
		attributeMap.put('name', tokenClaims.name);
		attributeMap.put('first_name', tokenClaims.given_name);
		attributeMap.put('last_name', tokenClaims.family_name);
		attributeMap.put('oid', tokenClaims.oid);
		attributeMap.put('upn', tokenClaims.upn);
		attributeMap.put('aud', tokenClaims.aud);

		// System.debug('attributeMap: ' + attributeMap);
		// for(String key : attributeMap.keySet()) {
		// 	System.debug(key + ' = ' + attributeMap.get(key));
		// }

		Auth.UserData userData = new Auth.UserData(identifier, tokenClaims.given_name, tokenClaims.family_name, fullName, '', '', username, '', provider, '', attributeMap);
		return userData;
	}

	global class OAuthException extends Exception {}

	/**
	 * Response received from the /token endpoint
	 */
	global class Token {
		public String access_token;
		public String token_type;
		public Integer expires_in;
		
		public String error;
		public String error_description;

	}

	global class AccessToken {
		public String aud;
		public String iss;
		public Integer iat;
		public Integer nbf;
		public Integer exp;
		public String email;
		public String oid;
		public String preferred_username;
		public String sub;
		public String upn;
		public String name;
		public String family_name;
		public String given_name;
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