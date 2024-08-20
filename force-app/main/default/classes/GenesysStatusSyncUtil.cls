/**
 * Single purpose util that fetches the Status IDs from Genesys
 * capturing these in Custom Object records.
 * 
 * Status Sync will be used by SCV to align CTI Status with Omni presence status
 * 
 * 
 * Directions for anonynous execute (copy/paste):
 * 
 *	GenesysStatusSyncUtil.syncGenesysStatuses();
 * 
 */
public with sharing class GenesysStatusSyncUtil {
	/**
	 * Perform callout to Genesys and fetch the available statuses
	 */
    public static void syncGenesysStatuses() {
		HttpResponse response = sendGenesysApiRequest(
			'GET',				// method
			'systempresences', 	// endpoint
			null				// body
		);

		if (response.getStatusCode() != 200) {
			throw new HandledException(String.join(new String[] {
				'Failed to fetch statuses. Status: ' + response.getStatusCode(),
				'Response Body: ' + response.getBody()
			}, '\n'));
		}

		GenesysPresenceStatus[] statuses = (GenesysPresenceStatus[])JSON.deserialize(
			response.getBody(),
			GenesysPresenceStatus[].class
		);

		// Clear existing Genesys statuses
		List<GenesysAgentStatusIdMapping__c> existingMappings = GenesysAgentStatusIdMappingsSelector.newInstance().selectBySource('Genesys');
		if (!existingMappings.isEmpty()) {
			ApplicationDatabase.getInstance().dmlDelete(existingMappings);
		}

		GenesysAgentStatusIdMapping__c[] target = new List<GenesysAgentStatusIdMapping__c>();

		for (GenesysPresenceStatus status :statuses) {
			target.add(status.toGenesysStatusMapping());
		}

		if (!target.isEmpty()) {
			ApplicationDatabase.getInstance().dmlInsert(target);
		}
	}

	private class GenesysPresenceStatus {
		String id;
		String name;
		String selfUri;

		GenesysAgentStatusIdMapping__c toGenesysStatusMapping() {
			return new GenesysAgentStatusIdMapping__c(
				StatusId__c = this.id,
				Name = this.name,
				Source__c = 'Genesys'
			);
		}
	}

	/**
	 * Generate a HttpRequest for Genesys Cloud Api including base url endpoint and access token
	 * @return HttpResponse from Genesys
	 */
	private static HttpResponse sendGenesysApiRequest(String method, String endpoint, String body) {
		// TODO: Obtain endpoint and credentials from NamedCredential / Custom Setting
		String endpointPrefix = genesysApiDetails.baseUrl;
		HttpRequest request = new HttpRequest();

		request.setMethod(method);
		// Set the endpoint URL for the update request
		request.setEndpoint(endpointPrefix + endpoint);
		// Set headers for the update request, obtaining token from Genesys first
		request.setHeader('Content-Type', 'application/json');
		request.setHeader('Authorization', 'Bearer ' + obtainGenesysAccessToken());

		if (body != null) {
			request.setBody(body);
		}

		return (new Http()).send(request);
	}

	private static String obtainGenesysAccessToken() {
		// Specify the required client ID and client secret
		// Encode the client ID and client secret for the Authorization header
		String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(
			Blob.valueOf(genesysApiDetails.clientId + ':' + genesysApiDetails.clientSecret)
		);

		HttpRequest request = new HttpRequest();
		request.setEndpoint(genesysApiDetails.authUrl);
		request.setMethod('POST');
		request.setHeader('Authorization', authorizationHeader);
		request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

		// Create a new Http object to send the OAuth token request
		HTTPResponse response = (new Http()).send(request);
		System.debug(response.getBody());

		// Deserialize the JSON response to extract the access token
		Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
		return (String)responseMap.get('access_token');
	}

	private class GenesysApiDetails {
		private String baseUrl;
		private String clientId;
		private String clientSecret;
		private String authUrl;

		private GenesysApiDetails(String baseUrl, String clientId, String clientSecret) {
			this.baseUrl = baseUrl;
			this.clientId = clientId;
			this.clientSecret = clientSecret;
		}
	}

	private static GenesysApiDetails genesysApiDetails {
		get {
			if (genesysApiDetails == null) {
				// TODO: Obtain this from custom setting / Named Credential
				genesysApiDetails = new GenesysApiDetails(
					'https://api.mypurecloud.com.au/api/v2/',
					'1f040ad2-8bc2-40e3-a06a-558346c86f9c',
					'H-HW7V-qThT8leZg3OcviJL_7LNZrpefAxgKYIGBDvc'
				);

				genesysApiDetails.authUrl = 'https://login.mypurecloud.com.au/oauth/token?grant_type=client_credentials';
			}

			return genesysApiDetails;
		}
		set;
	}
}