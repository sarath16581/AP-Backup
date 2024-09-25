/***
 * @description Genesys Intergration contains the callout logic to Genesy
 *	NOTE: Genesys Intergration enables callouts to all Genesys Api's (see: https://developer.genesys.cloud/devapps/api-explorer)
 * @author 	Paul Perry
 * @date 	2024-08-27
 * @group 	SCV/Unified
 * @test 	GenesysIntegration_Test
 * @changelog
 */
public with sharing class GenesysIntegrationService {
	/**
	 * Instance for mocking
	 */
	public static GenesysIntegrationService newInstance() {
		return (GenesysIntegrationService)Application.Utilities.newInstance(GenesysIntegrationService.class);
	}

	/**
	 * Retrieves the conversation call payload from Genesys for provided conversationId
	 * @param conversationId the unique identifier for a call interaction
	 */
	public Map<String,Object> fetchConversationCallDetail(String conversationId) {
		String endpoint = 'conversations/calls/' + conversationId.escapeHtml4();

		// Send the update request and handle the response
		HttpResponse response = sendGenesysApiRequest('GET', endpoint, null);

		if (response.getStatusCode() == 200) {
			return (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
		}

		throw new GenesysResponseException(String.join(new String[] {
			'Failed to get call interaction. Status: ' + response.getStatusCode(),
			'Response Body: ' + response.getBody()
		}, '\n'), response);
	}

	/**
	 * Update custom participant attributes for provided conversation and participant Id
	 * @param conversationId the unique identifier for a call interaction
	 * @param participantId the unique identifier for a participant on a call interaction
	 *
	 * @return The response by Genesy
	 */
	public String patchConversationParticipantAttributes(String conversationId, String participantId, Map<String,Object> attributes) {
		// Set the endpoint URL for the update request
		String endpoint = String.format(
			'conversations/calls/{0}/participants/{1}/attributes',
			new String[] {
				conversationId.escapeHtml4(),
				participantId.escapeHtml4()
			}
		);

		// Convert attributes map to JSON string and set the body
		String body = JSON.serialize(new Map<String,Object>{
			'attributes' => attribute
		});

		// Send the update request and handle the response
		HttpResponse response = sendGenesysApiRequest('PATCH', endpoint, body);

		if (response.getStatusCode() == 202) {
			return response.getBody();
		} else {
			throw new GenesysResponseException(String.join(new String[] {
				'Failed to update participant attributes. Status: ' + response.getStatusCode(),
				'Response Body: ' + response.getBody()
			}, '\n'), response);
		}
	}

	/**
	 * Generate a HttpRequest for Genesys Cloud Api including base url endpoint and access token
	 * @param method 	GET / PUT / PATCH
	 * @param endpoint 	suffix for the endpoint specific to your operation
	 * @param body 		optional body to be sent with the request
	 *
	 * @return HttpResponse from Genesy
	 */
	public static HttpResponse sendGenesysApiRequest(String method, String endpoint, String body) {
		HttpRequest request = new HttpRequest();

		request.setMethod(method);
		// Set the endpoint URL for the update request
		request.setEndpoint('callout:Genesys/api/v2/' + endpoint);
		// Set headers for the update request, obtaining token from Genesys first
		request.setHeader('Content-Type', 'application/json');

		if (body != null) {
			request.setBody(body);
		}

		return (new Http()).send(request);
	}

	public class GenesysResponseException extends Exception {
		public HttpResponse response;

		public GenesysResponseException(String message, HttpResponse response) {
			this(message);
			this.response = response;
		}
	}
}