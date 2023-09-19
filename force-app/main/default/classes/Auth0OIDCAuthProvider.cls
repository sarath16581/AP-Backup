/***
 * @description This is a custom auth provider built specifically for Auth0 for a community user setup
 * Auth0 is supported OOTB using standard Open Id Connect provider, however, using the standard provider would cause a simple opaque access token to be returned given the standard provider does not allow us to send an 'audience' paramter
 * By including the 'audience' parameter, this instructs Auth0 to generate a JWT access token and passes that back to use rather than just the simple opaque token
 * The JWT access token can subsequently be pulled into our application by calling Auth.AuthToken.getAccessToken
 * The reason we might need the JWT access token in the future is that this will allow us to send the user context into any of the downstream API's our applications may choose to invoke
 * A good use case (although not in prod right now), is the ability to pass the user context into a Track API which could allow us to automatically retrieve parcels specific to the current logged in user
 *
 * The custom auth provider implementation is quite lacking. Simple things like passing the OOTB URL Suffix field, or passing the auth provider id to our class here is currently not possible,
 * 		so we need to add additional attributes (some duplicated) to our custom metadata type to collect all the necessary attribute values
 *
 * NOTE: This class makes use of ConnectApi.Communities.getCommunity(Network.getNetworkId()) which means this class is for a community only. It could be easily uplifted to support core login if needed
 *
 * @author Nathan Franklin
 * @date 2023-02-21
 * @changelog
 * 2023-09-12 - Mahesh Parvathaneni - reverted the cookie handler changes
 * 2023-09-19 - Maahesh Parvathaneni - added variable ATTRIBUTE_CNUMBER_MAPPING, ATTRIBUTE_APCN_MAPPING
*/
global class Auth0OIDCAuthProvider extends Auth.AuthProviderPluginClass {

	/**
	 * In order to assure consistency of the outputted encrypted value used for PKCE, we need to specify the IV manually.
	 * Although best practices of encryption state this should be random/unpredictable, in our case this is ok since we
	 * 	are not using it specifically for encryption, just to derive a hash
	 */
	public static final Blob CRYPTO_IV = Blob.valueOf('ghqNA8aoTUF8WIsx');

	public static final String AUTH_PROVIDER_NAME = 'Auth0';

	@TestVisible
	public static final String ATTRIBUTE_CNUMBER_MAPPING = 'https://auspost/cnumber';

	@TestVisible
	public static final String ATTRIBUTE_APCN_MAPPING = 'https://auspost/apcn';

	@TestVisible
	private Id NETWORK_ID { // can't be declared as final since we assign this value in our test class
		get {
			if(NETWORK_ID == null) {
				Id networkId = Network.getNetworkId();
				NETWORK_ID = networkId;
			}
			return NETWORK_ID;
		}
		private set;
	}

	@TestVisible
	private String COMMUNITY_URL { // can't be declared as final since we assign this value in our test class
		get {
			if(COMMUNITY_URL == null) {
				COMMUNITY_URL = ConnectApi.Communities.getCommunity(NETWORK_ID).siteUrl;
			}
			return COMMUNITY_URL;
		}
		private set;
	}

	@TestVisible
	private String COMMUNITY_LOGIN_URL { // can't be declared as final since we assign this value in our test class
		get {
			if(COMMUNITY_URL == null) {
				COMMUNITY_URL = ConnectApi.Communities.getCommunity(NETWORK_ID).loginUrl;
			}
			return COMMUNITY_URL;
		}
		private set;
	}

	global String getCustomMetadataType() {
		return 'Auth0OIDCAuthProvider__mdt';
	}

	/**
	 * Grab the authoise url params and redirect the user to auth0 for authenitcation
	 * NOTE: the existence of the audience parameter which will allow us to return a JWT access token
	 */
	global PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {	
		String clientId = authProviderConfiguration.get('ClientId__c');
		String authoriseEndpointUrl = authProviderConfiguration.get('AuthoriseEndpointUrl__c');
		String audience = authProviderConfiguration.get('Audience__c');
		String scope = authProviderConfiguration.get('Scope__c');
		String urlSuffix = authProviderConfiguration.get('URLSuffix__c');
		Blob pkceEncryptionKey = EncodingUtil.base64Decode(String.valueOf(authProviderConfiguration.get('PKCEEncryptionKey__c')));
		String redirectUri = COMMUNITY_URL + '/services/authcallback/' + urlSuffix;
		String pkceChallenge = getPKCECode(stateToPropagate, pkceEncryptionKey)[0];
		System.debug('PKCE Challenge: ' + pkceChallenge);

		String qs = 'response_type=code' +
						'&code_challenge_method=S256' +
						'&code_challenge=' + pkceChallenge + // <-- does not need to be url encoded
						'&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
						'&scope=' + EncodingUtil.urlEncode(scope, 'UTF-8') +
						'&audience=' + EncodingUtil.urlEncode(audience, 'UTF-8') +
						'&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8') +
						'&state=' + EncodingUtil.urlEncode(stateToPropagate, 'UTF-8');

		String url = authoriseEndpointUrl + '?' + qs;
		return new PageReference(url);
	}

	/**
	 * Handle the response from Auth0 which would contain the authorisation 'code' param which we will exhcnage for an access token.
	 * NOTE: This requires the client secret, which is stored within an external credential via a named credential
	 * The new named/external credential architecture is poor at best and it requires us to track the name of external credential linked to the named credential so it can be linked below
	 * As of 2023-02, there is currently no other way to do this.
	 */
	global Auth.AuthProviderTokenResponse handleCallback(Map<String, String> authProviderConfiguration, Auth.AuthProviderCallbackState state) {
		Map<String,String> queryParams = state.queryParameters;
		String code = queryParams.get('code');
		String sfdcState = queryParams.get('state');

		Blob pkceEncryptionKey = EncodingUtil.base64Decode(String.valueOf(authProviderConfiguration.get('PKCEEncryptionKey__c')));
		String pkceCodeVerifier = getPKCECode(sfdcState, pkceEncryptionKey)[1];
		System.debug('PKCE Verifier: ' + pkceCodeVerifier);

		String externalCredentialName = authProviderConfiguration.get('ExternalCredentialName__c');
		externalCredentialName = (!String.isEmpty(externalCredentialName) ? externalCredentialName.replace('.', '\\.') : ''); // poor mans escape

		String clientId = authProviderConfiguration.get('ClientId__c');
		String clientSecret = '{!$Credential.' + authProviderConfiguration.get('ExternalCredentialName__c') + '.secret}';
		String tokenEndpointUrl = authProviderConfiguration.get('TokenEndpointUrl__c');
		String userinfoEndpointUrl = authProviderConfiguration.get('UserInfoEndpointUrl__c');
		String audience = authProviderConfiguration.get('Audience__c');
		String scope = authProviderConfiguration.get('Scope__c');
		String urlSuffix = authProviderConfiguration.get('URLSuffix__c');
		String redirectUri = COMMUNITY_URL + '/services/authcallback/' + urlSuffix;

		HttpRequest req = new HttpRequest();
		String url = tokenEndpointUrl;
		req.setMethod('POST');
		req.setEndpoint(tokenEndpointUrl);
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

		String tokenBody = 'client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8') +
							'&client_secret=' + clientSecret + // {!$...} format
							'&code_verifier=' + EncodingUtil.urlEncode(pkceCodeVerifier, 'UTF-8') +
							'&code=' + EncodingUtil.urlEncode(code, 'UTF-8') +
							'&grant_type=authorization_code' +
							'&redirect_uri=' + EncodingUtil.urlEncode(redirectUri, 'UTF-8');
		req.setBody(tokenBody);

		Http http = new Http();
		HttpResponse res = http.send(req);

		Integer statusCode = res.getStatusCode();
		String body = res.getBody();
		System.debug(body);

		Token tokenResponse = (Token)JSON.deserialize(body, Token.Class);

		if(tokenResponse == null) {
			throw new OAuthException('A token error occurred');
		}

		if(statusCode < 200 || statusCode > 299) {
			String errorMessage = '';
			if(!String.isEmpty(tokenResponse.error_description) || !String.isEmpty(tokenResponse.error)) {
				errorMessage = 'Token API: ' + (!String.isEmpty(tokenResponse.error) ? tokenResponse.error + ': ' : '') + (!String.isEmpty(tokenResponse.error_description) ? tokenResponse.error_description : 'A token error occurred');
			}

			if(String.isEmpty(errorMessage)) {
				errorMessage = 'A token error occurred';
			}
			throw new OAuthException(errorMessage);
		}

		if(String.isEmpty(tokenResponse.access_token)) {
			throw new OAuthException('The returned response was invalid');
		}

		// note there is no refresh token for this flow
		return new Auth.AuthProviderTokenResponse(AUTH_PROVIDER_NAME, String.valueOf(tokenResponse.access_token), '', sfdcState);
	}

	/**
	 * NOTE: This allows us to call the userinfo endpoint in Azure
	 * Although this is not necessary, we do this anyway to validate the access token is current and functional
	 */
	global Auth.UserData getUserInfo(Map<String, String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
		String communityLoginUrl = COMMUNITY_LOGIN_URL;
		String userinfoEndpointUrl = authProviderConfiguration.get('UserInfoEndpointUrl__c');

		Http http = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');

		// This would most likely be using the callout:[named cred] format
		// note, the external credential is not needed for the userinfo call (since we pass in the exchanged access token). however,
		// 		it allows us the bypass the need to add a remote site setting :)
		req.setEndpoint(userinfoEndpointUrl);
		req.setHeader('Authorization', 'Bearer ' + response.oauthToken);

		HttpResponse res = http.send(req);
		String body = res.getBody();
		System.debug(body);
		Integer statusCode = res.getStatusCode();

		// deserialising untyped allows easy access to post specific attributes of which include the following names:
		// https://auspost/cnumber
		// https://auspost/apcn
		// etc....
		Map<String, Object> parsedUserInfoToken = (Map<String, Object>)JSON.deserializeUntyped(body);
		if(parsedUserInfoToken == null) {
			throw new OAuthException('A UserInfo token error occurred');
		}

		if(statusCode < 200 || statusCode > 299) {

			String errorMessage = '';

			if(!String.isEmpty(String.valueOf(parsedUserInfoToken.get('status')))) {
				errorMessage += (!String.isEmpty(errorMessage) ? ', ' : '') + 'Status: ' + parsedUserInfoToken.get('status');
			}
			if(!String.isEmpty(String.valueOf(parsedUserInfoToken.get('code')))) {
				errorMessage += (!String.isEmpty(errorMessage) ? ', ' : '') + 'Code: ' + parsedUserInfoToken.get('code');
			}
			if(!String.isEmpty(String.valueOf(parsedUserInfoToken.get('detail')))) {
				errorMessage += (!String.isEmpty(errorMessage) ? ', ' : '') + 'Detail: ' + parsedUserInfoToken.get('detail');
			}

			errorMessage = (!String.isEmpty(errorMessage) ? errorMessage : 'An unknown error occurred: ' + statusCode);
			errorMessage = 'UserInfo API: ' + errorMessage;

			System.debug(statusCode + ', ' + errorMessage);

			throw new OAuthException(errorMessage);
		}

		Map<String, String> attributeMap = new Map<String, String>();
		for(String key : parsedUserInfoToken.keySet()) {
			attributeMap.put(key, String.valueOf(parsedUserInfoToken.get(key)));
		}

		String fullName = attributeMap.get('given_name') + ' ' + attributeMap.get('family_name');
		Auth.UserData userData = new Auth.UserData(attributeMap.get('sub'), attributeMap.get('given_name'), attributeMap.get('family_name'), fullName, attributeMap.get('email'), '', attributeMap.get('email'), '', AUTH_PROVIDER_NAME, communityLoginUrl, attributeMap);
		return userData;
	}

	/**
	 * Generates a new challenge/verifier code
	 * Given the persistentStateValue should be the same in the initialise and handleCallback methods
	 * we should be able to rely on a consistent value being generated
	 *
	 * In theory, I didn't have to encrypt the state... I could have just hashed the state using sha256, however, the verifier would be too predictable and possibly expose an attack vector
	 * By encrypting using a key, the verifier is completely unpredictable
	 * Short of just using a salt (which possibly could have been enough), encryption with a key is a pretty secure way of getting an unpredictable challenge/verifier
	 *
	 * @param encryptionKey Blob Use output of Crypto.generateAesKey(256). This is base64 encoded in the custom metadata.
	 */
	@TestVisible
	private List<String> getPKCECode(String persistentStateValue, Blob encryptionKey) {
		Blob hashedEncryption = Crypto.generateDigest('SHA-256', Crypto.encrypt('AES256', encryptionKey, CRYPTO_IV, Blob.valueOf(persistentStateValue)));
		String codeVerifier = EncodingUtil.base64Encode(hashedEncryption);
		String codeChallenge = pkceBase64URLencode(Crypto.generateDigest('SHA-256', Blob.valueOf(codeVerifier)));
		return new List<String>{codeChallenge, codeVerifier};
	}

	/**
	 * The PKCE way to base64 encode
	 */
	private String pkceBase64URLencode(Blob input){
		String output = encodingUtil.base64Encode(input);
		output = output.replace('+', '-');
		output = output.replace('/', '_');
		while ( output.endsWith('=')){
			output = output.subString(0,output.length()-1);
		}
		return output;
	}

	/**
	 * Response received from the /token endpoint
	 */
	private class Token {
		// this should be a JWT token if an audience was passed in
		// note: auth0 doco's say we should treat this as an opaque token even if it's a jwt and only use it to pass down to various api calls we make within our applications rather than parsing it to extra anything out of it
		public String access_token;

		public String token_type;
		public Integer expires_in;

		public String error;
		public String error_description;
	}

	global class OAuthException extends Exception {}

}