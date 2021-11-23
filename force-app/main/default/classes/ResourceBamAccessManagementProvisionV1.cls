/**************************************************
Description :               Webservice to 'provision' the requested contact to the BAM Access Management App
							No provisioning actually occurs, but we still have the provisioning endpoint to revalidate that a user can actually still be onboarded between the time validation API is run and provisioning API is run
Custom Metadatatype :       ResourceAPI__mdt
/api/1.0/bam/accessmanagement/provision (contact id in Request Body)

History:
--------------------------------------------------
2019-07-02  nathan.franklin@auspost.com.au  Created
**************************************************/
public with sharing class ResourceBamAccessManagementProvisionV1 extends ResourceAPIService.IApi {

	// Salesforce ID from request.Body
	public static String requestContactId;

	// request ID from request.Body
	public static String requestId;

	// Sales EOR request ID
	public static String eorRequestId;

	/**
	 * Handle the provisioning request for BAM Access Management
	 * Camunda is expecting a 204 response here which equates to an acknowledgement that the request has been received
	 * After that Camunda will then expect an asynchronous response to notify that the provisioning process has been completed successfully.
	 *
	 * There is 1 exception to this scenario, and that is if we can't extract the Camunda requestId from the payload received, then we return a 500 response with the message Malformed Request
	 *
	 * NOTE: There is no action to be completed within this API, this is just to revalidate that the user can actually be onboarded to Access Management
	 */
	public override ResourceAPIService.IResourceResponse post() {

		System.debug('>> ResourceBamAccessManagementProvisionV1:start');

		AccessManagementProvisioningApiAsyncResourceResponse response;

		try {
			// check to make sure the logged in user has access to be able to make these calls
			if(!BAMUserUtility.currentUserHasBAMApiAccess()){
				return new AccessManagementProvisioningApiAcknowledgementResponse(true);
			} else {

				List<String> errors = new List<String>();
				Map<String, Object> results = null;
				Map<String, Object> contactAttributes = null;
				Map<String, Object> requestAttributes = null;
				User requestedUser = null;

				// catch any errors with parsing the body
				try {
					System.debug(RestContext.request.requestBody.toString());
					results = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
					contactAttributes = (Map<String, Object>)results.get('contact');
					requestAttributes = (Map<String, Object>)results.get('request');

					if(contactAttributes == null) contactAttributes = new Map<String, Object>();
					if(requestAttributes == null) requestAttributes = new Map<String, Object>();

					requestId = String.valueOf(results.get('id'));
					eorRequestId = String.valueOf(requestAttributes.get('id'));
					requestContactId  = String.valueOf(contactAttributes.get('id'));
				} catch(Exception ex) { System.debug('ERROR Parsing: ' + ex); } // do nothing

				if (String.isEmpty(requestId)) {
					// since we can't reconcile this request back to an originating requestId, we end the flow now with a synchronous feedback
					return new AccessManagementProvisioningApiAcknowledgementResponse(true);
				}

				// catch any 'provisioning' system errors.
				// these will be fed back via the asycnhronous feedback loop
				try {
					if (!String.isEmpty(requestContactId)) {
						// retrieve the user details
						requestedUser = BAMUserUtility.retrieveContactUserDetail(requestContactId);

						//validate the contact that was passed in to ensure a BSP account can be provisioned against it.
						errors.addAll(ResourceBamAccessManagementValidationV1.validateUser(requestedUser));
					} else {
						errors.add(Label.BAMBSP_User_Record_Not_Found);
					}

					// if there are errors then we need to feed these back via an asynchronous response (the synchronous response will still return a 204 acknowledgement)
					if (errors.isEmpty()) {
						response = new AccessManagementProvisioningApiAsyncResourceResponse(200, 'Fulfilled', requestId);
					} else {
						response = new AccessManagementProvisioningApiAsyncResourceResponse(500, 'Error', requestId, '500', String.join(errors, '\n'));
					}
				} catch(Exception ex) {
					response = new AccessManagementProvisioningApiAsyncResourceResponse(500, 'Error', requestId, '500', ex.getMessage());
				}
			}

		} catch(Exception e) {
			System.debug(e);
			return new AccessManagementProvisioningApiAcknowledgementResponse(true);
		}

		// based on the Asynchronous response we have built above (AccessManagementProvisioningApiAsyncResourceResponse),
		// we queue the actual callout to be completed in a future to allow this acknowledgement to complete first
		sendProvisioningResponseToCamunda(eorRequestId, response.serialize());

		// if we got to this point then we need to send a 204 acknowledgement back to camunda to acknowledge that the request has been received
		return new AccessManagementProvisioningApiAcknowledgementResponse();
	}

	@future(callout=true)
	public static void sendProvisioningResponseToCamunda(String requestId, String request) {
		try {

			System.debug('Sending Provisioning Response - Request:: ' + request);

			// Send Asynchronous response to Camunda after provisioning
			HttpResponse response = BAMIntegrationUtility.postRequest('BAM_PROVISION_RESPONSE', request);

			if(response.getStatusCode() != 204) {
				System.debug(response.getBody());

				String body = response.getBody();
				if(String.isEmpty(body)) body = 'no body';

				// Capture the errors and attach it to the External Onboarding request
				Attachment attach=new Attachment();
				attach.name = 'provision response error';
				attach.body = Blob.valueOf(body);
				attach.parentId = requestId;
				insert attach;
			}

		} catch (exception exp){
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'BAM Access Management Provisioning API',
					ResourceBamBspProvisionV1.class.getName(), 'send Async Response To Camunda',
					null, LoggingLevel.ERROR);
		}
	}

	public class AccessManagementProvisioningApiAsyncResourceResponse extends ResourceAPIService.IResourceResponse {

		public AccessManagementProvisioningApiAsyncResourceResponse(Integer responseCode, String status, String id) {
			this(responseCode, status, id, '', '');
		}

		public AccessManagementProvisioningApiAsyncResourceResponse(Integer responseCode, String status, String id, String errorCode, String errorMessage) {
			output.put('status', status);

			if(!String.isEmpty(id)) {
				output.put('id', id);
			}

			if(!String.isEmpty(errorCode)) {
				output.put('errorCode', errorCode);
			}

			if(!String.isEmpty(errorMessage)) {
				output.put('errorMessage', errorMessage);
			}

			this.responseCode = responseCode;
		}
	}

	public class AccessManagementProvisioningApiAcknowledgementResponse extends ResourceAPIService.IResourceResponse {

		public AccessManagementProvisioningApiAcknowledgementResponse() {
			this(false);
		}

		public AccessManagementProvisioningApiAcknowledgementResponse(Boolean isMalformed) {
			if(isMalformed) {
				this.responseCode = 500;
				output.put('message', Label.BAMBSP_Malformed_Request);
			} else {
				this.responseCode = 204;
			}
		}

		//Returns serialize result in JSON format
		public override String serialize() {
			if(output.keySet().isEmpty()) {
				return '';
			} else {
				return JSON.serializePretty(output);
			}
		}
	}


}