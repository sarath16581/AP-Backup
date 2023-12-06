/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description Helper for createBillingAccount component and used for billing account creation
 *				API Specification of external service:
 *				https://australiapost.jira.com/wiki/spaces/ISS/pages/1472954644/API+Specification+-+customer+v1+billingaccounts
 * @changelog
 * 2020-11-18 - arjun.singh@auspost.com.au - Created
 * 2021-05-12 - avula.jansirani@auspost.com.au - added submitRequest() method
 * 2022-08-04 - Seth Heang - Updated parseResponse method to handle rating plan activation changes
 * 2023-10-30 - Ranjeewa Silva - Refactored 'parseResponse' method to only do the parsing. Calling classes are now
 *							   responsible for any subsequent actions based on the response.
 */
public with sharing class BillingAccountService {

	// status codes considered transient errors.
	private static final Set<Integer> TRANSIENT_ERROR_STATUS_CODES = new Set<Integer>{2000, 2001, 2003};

	// grab settings configured in custom setting
	@TestVisible private static AusPostSettings__c setting {
		get {
			if(setting == null) {
				setting = AusPostSettings__c.getValues('CreateBillingAccountCredentials');
			}
			return setting;
		}
		private set;
	}

	public static BillingAccountService getInstance() {
		return (BillingAccountService) Application.Utilities.getInstance(BillingAccountService.class);
	}

	/**
	 * Generate HTTP request that can be submitted to external billing account service.
	 *
	 * @param requestBody JSON payload to be set as the request body.
	 * @param businessReferenceId Business Reference ID of the request being sent. This should be a unique identifier for differentiating the request.
	 * @param sourceSystem Source system identifier to be sent to external service.
	 *
	 * @return HTTPRequest instance
	 */
	public HttpRequest getRequest(String requestBody , String businessReferenceId, String sourceSystem) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint(setting?.URL2__c);
		request.setTimeout(getApiTimeout()*1000);
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json;charset=UTF-8');
		request.setHeader('businessReferenceId', businessReferenceId);
		request.setHeader('sourceSystemId', sourceSystem);
		request.setBody(requestBody);
		return request;
	}

	/**
	 * Returns a continuation instance that can be used to make long running callouts to external billing accounts
	 * end point.
	 *
	 * @param requestBody JSON payload to be set as the request body.
	 * @param businessReferenceId Business Reference ID of the request being sent. This should be a unique identifier for differentiating the request.
	 * @param sourceSystem Source system identifier to be sent to external service.
	 *
	 * @return Continuation instance
	 */
	public Continuation getContinuation(String requestBody , String businessReferenceId, String sourceSystem) {
		Continuation con = new Continuation(getApiTimeout());
		con.addHttpRequest(getRequest(requestBody, businessReferenceId, sourceSystem));
		return con;
	}

	/**
	 * Parse the response received from external billing account service end point (Camunda).
	 * @param httpResponse Response received from external service.
	 *
	 * @return parsed response.
	 */
	public Response parseResponse(HttpResponse httpResponse) {
		Integer statusCode = httpResponse.getStatusCode();
		String responseBody = httpResponse.getBody();
		Response result = new Response(statusCode, responseBody);
		if (statusCode == 202) {
			//  external service has accepted the request. return isSuccess=true.
			result.isSuccess = true;
		} else {
			// request has failed. attempt to extract error details from response body if available.
			result.isSuccess = false;
			// for HTTP status code 400 and 500 we receive error details in response body from external system
			if (statusCode == 400 || statusCode == 500) {
				// attempt to parse response body
				try {
					BillingAccountAPIErrorResponse errorResponse = (BillingAccountAPIErrorResponse) JSON.deserialize(responseBody, BillingAccountAPIErrorResponse.class);
					for (Error error: errorResponse.errors) {
						result.errors.add(error.toString());
					}
				} catch (Exception e) {
					// error parsing the response from external service. log the exception.
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', BillingAccountService.class.getName(), 'parseResponse', null, ApplicationLogger.LoggingLevel.ERROR);
					result.errors.add('Cannot parse error response received (http status code : ' + httpResponse.getStatusCode() + ')');
				}
			}

			// check if error message has been populated. if not return a generic error message.
			if (result.errors.isEmpty()) {
				// return a generic HTTP status error because error JSON object doesn't exist or error parsing the error response
				result.errors.add((httpResponse.getStatus() == null ? 'An Error Occurred' : httpResponse.getStatus()) + ' (' + String.valueOf(httpResponse.getStatusCode()) + ')');
			}
		}
		return result;
	}

	/**
	 * Synchronously call external billing account service (Camunda) to submit request.
	 *
	 * @param requestBody JSON payload to be set as the request body.
	 * @param businessReferenceId Business Reference ID of the request being sent. This should be a unique identifier for differentiating the request.
	 * @param sourceSystem Source system identifier to be sent to external service.
	 *
	 * @return
	 */
	public HttpResponse submitRequest(String requestBody , String businessReferenceId, String sourceSystem) {
		 return new Http().send(getRequest(requestBody, businessReferenceId, sourceSystem));
	}

	/**
	 * Return API Timeout to be configured on the request.
	 * @return Configured timeout, defaults to 120s if not configured.
	 */
	private Integer getApiTimeout() {
		if (setting?.LockDuration__c != null){
			return Integer.valueOf(setting.LockDuration__c);
		}
		return 120;
	}

	/**
	 * Represents an 'Error' response from external service. Please refer API specification above for more details.
	 */
	private class BillingAccountAPIErrorResponse {
		private List<Error> errors {get; private set;}
	}

	/**
	 * Represents an individual error in the response from external service.
	 * Please refer API specification above for more details.
	 */
	private class Error {
		private String id {get; private set;}
		private String code {get; private set;}
		private String title {get; private set;}
		private String details {get; private set;}

		/**
		 * Returns a formatted error message that can be displayed to users if necessary.
		 * @return error message
		 */
		public override String toString() {
			return 'ERROR: ' + (String.isNotBlank(code) ? code : '')
					+ (String.isNotBlank(title) ? (', ' + title) : '')
					+ (String.isNotBlank(details) ? (', ' + details) : '');
		}
	}

	/**
	 * Represents the parsed response returned by this class after parsing the response from external service.
	 */
	public class Response {

		@TestVisible @AuraEnabled public Boolean isSuccess {get; private set;}
		@AuraEnabled public Integer statusCode {get; private set;}
		@AuraEnabled public String responseBody {get; private set;}
		@AuraEnabled public List<String> errors {get; private set;}

		/**
		 * For error status codes, return if the operation can be retried.
		 * @return true if status code is considered transient, false otherwise.
		 */
		@AuraEnabled public Boolean getIsRetryable() {
			return !isSuccess && TRANSIENT_ERROR_STATUS_CODES.contains(statusCode);
		}

		/**
		 * Returns a combined error message that could be displayed to the user
		 * @return error message
		 */
		@AuraEnabled public String getErrorMessage() {
			String errorMessage = '';
			for (String error: errors) {
				if (String.isNotBlank(error)) {
					errorMessage += (String.isNotBlank(errorMessage) ? (', ' + error) : error);
				}
			}
			return errorMessage;
		}

		public Response(Integer statusCode, String responseBody) {
			this.statusCode = statusCode;
			this.responseBody = responseBody;
			this.errors = new List<String>();
		}
	}
}