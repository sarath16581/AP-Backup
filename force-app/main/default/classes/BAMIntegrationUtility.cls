/**************************************************
Description:	Utility class to handle calls to Camunda
History:
--------------------------------------------------
2019-06-04  Lija.Jawahar@auspost.com.au  	Created
2019-06-07  Lija.Jawahar@auspost.com.au  	Added addition request/post methods for more flexibility
2019-06-27  ajudd@salesforce.com 			Changes to use named credential for auth
2019-08-12  ajudd@salesforce.com			Added BAM Record Type Id conditions
2023-12-12  mahesh.parvathaneni@auspost.com.au Changed the authentication mechanism to Auth0
2023-12-19  boris.bachovski2@austpost.com.au Changes to use AP Secrets manage package for Auth0. Also removed getRequest() methods as they are not used.
2024-02-02	mahesh.parvathaneni@auspost.com.au Updated getter to use the OAuth base class from the "AP Secrets" package
**************************************************/
public class BAMIntegrationUtility {
	@TestVisible
	private static Boolean testingDoNotSend = false;

	public static String RESULT_OK = 'ok';
	public static String RESULT_ERROR = 'error';
	public static String FIELD_RESULT = 'result';
	public static String FIELD_MESSAGE = 'message';

	//constants
	private static final String BAM_LODGEMENT = 'BAMLodgement';

	private static apsecrets.OAuth.TokenResponse AUTH0_TOKEN {
		get {
			if (AUTH0_TOKEN == null) {
				apsecrets.Auth0AccessManager auth0mgr = new apsecrets.Auth0AccessManager(BAM_LODGEMENT);
				AUTH0_TOKEN = auth0mgr.getAccessToken();
			}
			return AUTH0_TOKEN;
		}
		private set;
	}

	/* making HTTP POST call
	 * BAMIntegrationUtility.postRequest(String apiName, String request)
	 */
	public static HttpResponse postRequest(String apiName, Object request) {
		return postRequest(apiName, JSON.serialize(request));
	}

	/* making HTTP POST call
	 * BAMIntegrationUtility.postRequest(String apiName, String request)
	 * Uses named credential, prefixed in url value in custom setting.
	 */
	public static HttpResponse postRequest(String apiName, String request)
	{
		
		AusPostSettings__c setting = AusPostSettings__c.getValues(apiName);
		
		System.debug('BAMIntegrationUtility::postRequest:setting url = ' + setting.URL2__c);
		System.debug('BAMIntegrationUtility::postRequest:request = ' + request);
		
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json;charset=UTF-8');
		req.setEndpoint(setting.URL2__c);
		req.setHeader('Authorization', 'Bearer ' + AUTH0_TOKEN.access_token);
		req.setBody(request);
		
		Http httpHandler = new Http();
		HttpResponse response = new HttpResponse();
		
		if(!Test.isRunningTest() || (Test.isRunningTest() && !testingDoNotSend)) {
			response = httpHandler.send(req);
			
			// If the response is 401, then the token has expired. Get a new token and retry the request.
			if (response.getStatusCode() == 401) {
				apsecrets.Auth0AccessManager auth0mgr = new apsecrets.Auth0AccessManager(BAM_LODGEMENT, apsecrets.CacheSettings.RunMode.FORCE_GENERATE);
				AUTH0_TOKEN = auth0mgr.getAccessToken();	
				req.setHeader('Authorization', 'Bearer ' + AUTH0_TOKEN.access_token);
				response = httpHandler.send(req);
			}

		} else {
			response.setBody('dummy-test-response-body');
		}
		
		return response;
		
	}

	/**
	 * Cancel any inflight pending requests for the selected contact
	 */
	public static Boolean cancelExternalRequest(Id contactId) {
		Map<String, Object> mapResults = new Map<String, Object>();

		//Get external onboarding request BAM record type id
		Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

		// check to see if there is anything that requires cancelling first
		List<ExternalOnboardingEvent__e> onboardingEvents = new List<ExternalOnboardingEvent__e>();
		for (BAMContactApplication__c contactApplication : [
				SELECT Id, Application__r.AppKey__c, (Select Id, Status__c, Type__c From BAM_External_Onboarding_Requests__r WHERE RecordTypeId = :bamExtObRTId Order By CreatedDate Desc LIMIT 1)
				FROM BAMContactApplication__c
				WHERE Contact__c = :contactId
		]) {
			// only process the cancellation for this application if the last EOR is pending
			// this is assumed for both Provision and Deprovision
			if (contactApplication.BAM_External_Onboarding_Requests__r != null && 'Pending'.equalsIgnoreCase(contactApplication.BAM_External_Onboarding_Requests__r[0].Status__c)) {
				ExternalOnboardingEvent__e eoeRec = new ExternalOnboardingEvent__e();
				eoeRec.RequestNumber__c = contactApplication.BAM_External_Onboarding_Requests__r[0].Id;
				eoeRec.Status__c = 'error';
				eoeRec.ResponseText__c = 'Request Cancelled';
				eoeRec.IsBam__c = true;
				eoeRec.Type__c = contactApplication.BAM_External_Onboarding_Requests__r[0].Type__c;
				eoeRec.Application__c = contactApplication.Application__r.AppKey__c;
				onboardingEvents.add(eoeRec);
			}
		}

		if (!onboardingEvents.isEmpty()) {
			System.debug('>> Pending Requests to be Cancelled: ' + onboardingEvents);
			// there are pending provisioning requests which need to be cancelled
			// send a cancellation request and trigger
			Map<String, String> payload = new Map<String, String>{
					'contactId' => contactId
			};
			HttpResponse response = BAMIntegrationUtility.postRequest('BAM_CANCEL_REQUEST', JSON.serialize(payload));
			
			// check if the request was successful or the server returned a response where no data exists for a contact id (404)
			if (response.getStatusCode() != 204 && response.getStatusCode() != 404) {
				String errorMessage = '';
				Map<String, Object> error = new Map<String, Object>();
				try {
					error = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
					errorMessage = String.valueOf(error.get('message'));
				} catch (Exception ex) {
					System.debug('>> Request Cancellation Error Response: ' + response.getBody());
				}
				if (String.isEmpty(errorMessage)) {
					errorMessage = 'The cancellation request failed to process successfully.';
				}

				throw new BamException(errorMessage);
			} else {
				// publish the external event messages to mark the pending external events as errored (request cancelled)
				BAMExternalOnboardingEventHandler.processBAMResponses(onboardingEvents);
			}
		} else {
			throw new BamException('There are no pending requests to be cancelled.');
		}

		return true;
	}

	public class BamException extends Exception {}
	public class applicationException extends Exception {}
	
}