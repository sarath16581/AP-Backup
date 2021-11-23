/***
 * @description
 *      Wraps the Async SOQL API
 *
 * @author Nathan Franklin
 * @date 2021-03-01
 * @group Integration
 * @changelog
 */
public inherited sharing class AsyncSOQLService {

	/**
	 * Grabs a new instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
	public static AsyncSOQLService getInstance() {
		return (AsyncSOQLService)Application.Utilities.getInstance(AsyncSOQLService.class);
	}

	public Id runUpsertAsyncSoql(String soql, SObjectType targetObject, Map<SObjectField, SObjectField> fieldMappings, SObjectField targetExternalIdField) {
		return runAsyncSoql(soql, 'upsert', targetObject, fieldMappings, targetExternalIdField);
	}

	public Id runInsertAsyncSoql(String soql, SObjectType targetObject, Map<SObjectField, SObjectField> fieldMappings) {
		return runAsyncSoql(soql, 'insert', targetObject, fieldMappings, null);
	}

	/**
	 * Kick off a new async soql query. Returns the job Id for the query.
	 *
	 * @param soql
	 * @param operation
	 * @param targetObject
	 * @param fieldMappings Field mappings of Source -> Target
	 *
	 * @return
	 */
	private Id runAsyncSoql(String soql, String operation, SObjectType targetObject, Map<SObjectField, SObjectField> fieldMappings, SObjectField targetExternalIdField) {

		Map<String, Object> apiParams = new Map<String, Object>();

		apiParams.put('query', soql);
		apiParams.put('targetObject', String.valueOf(targetObject));
		apiParams.put('operation', operation);

		Map<String, String> stringFieldMappings = new Map<String, String>();
		for(SObjectField sourceField : fieldMappings.keySet()) {
			stringFieldMappings.put(String.valueOf(sourceField), String.valueOf(fieldMappings.get(sourceField)));
		}
		apiParams.put('targetFieldMap', stringFieldMappings);

		if(targetExternalIdField != null) {
			apiParams.put('targetExternalIdField', String.valueOf(targetExternalIdField));
		}

		String jsonBody = JSON.serialize(apiParams);
		System.debug(jsonBody);
		Response apiResponse = getResponse(getBaseEndPoint(), 'POST', jsonBody);
		if(!apiResponse.isError && !String.isEmpty(apiResponse.jobId)) {
			return apiResponse.jobId;
		} else {
			throw new AsyncSoqlException(apiResponse);
		}
	}

	/**
	 * Grab the status of a job
	 */
	public Response getJobStatus(Id jobId) {
		if(jobId == null) {
			Response apiResponseError = new Response();
			apiResponseError.status = 'Error';
			apiResponseError.message = 'Job Id is invalid';
			return apiResponseError;
		}

		return getResponse(getBaseEndPoint() + '/' + jobId, 'GET');
	}

	// Instance method to cancel job
	public Response cancelJob(Id jobId) {
		if(jobId == null) {
			Response apiResponseError = new Response();
			apiResponseError.status = 'Error';
			apiResponseError.message = 'Job Id is invalid';
			return apiResponseError;
		}

		return getResponse(getBaseEndPoint() + '/' + jobId, 'DELETE');
	}

	public Response getResponse(String endpoint, String method) {
		return getResponse(endpoint, method, '');
	}

	/**
	 * Grab the Async SOQL url endpoint...
	 * NOTE: This will throw an exception if the setting isn't found which is expected behaviour
	 */
	public String getBaseEndPoint() {
		return AusPostSettings__c.getInstance('ASYNC_SOQL').URL__c;
	}

	private Response getResponse(String endpoint, String method, String body) {
		Http http = new Http();
		HttpRequest request = new HttpRequest();
		request.setMethod(method);
		request.setEndpoint(endpoint);
        request.setTimeout(40000);

		// only set the body if one was padded in
		if(!String.isEmpty(body)) {
			request.setBody(body);
			request.setHeader('Content-Length', String.valueOf(body.length()));
		}

		request.setHeader('Content-Type', 'application/json;charset=UTF-8');

		HttpResponse response = http.send(request);
		String responseBody = response.getBody();
		System.debug('responseBody: ' + responseBody);

		Integer responseCode = response.getStatusCode();
		String responseStatus = response.getStatus();
		Response apiResponse;
		if(response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
			apiResponse = (Response)JSON.deserialize(responseBody, Response.class);
			if(apiResponse == null) {
				apiResponse = new Response();
			}
			apiResponse.responseCode = responseCode;
			apiResponse.responseStatus = responseStatus;
		} else {
			apiResponse = new Response();
			apiResponse.responseCode = responseCode;
			apiResponse.responseStatus = responseStatus;
			apiResponse.message = responseCode + ': ' + responseStatus;

			// attempt to deserialise the error and overwrite the generic error
			try {
				List<ErrorResponse> error = (List<ErrorResponse>)JSON.deserialize(responseBody, List<ErrorResponse>.class);
				if(error != null && error.size() > 0) {
					apiResponse.message = error[0].errorCode + ': ' + error[0].message;
				}
			} catch(Exception ex) { }

		}
		return apiResponse;
	}

	public class Response {
		public String jobId;
		public String message;
		public String status;

		// HTTP Response
		public Integer responseCode;
		public String responseStatus;

		public Boolean isError {
			get {
				return 'Failed'.equalsIgnoreCase(status) || 'Error'.equalsIgnoreCase(status) || responseCode >= 300 || responseCode < 200;
			}
		}
		public Boolean isCanceled {
			get {
				return 'Canceled'.equalsIgnoreCase(status);
			}
		}
		public Boolean isComplete {
			get {
				return 'Complete'.equalsIgnoreCase(status);
			}
		}
		public Boolean isActive {
			get {
				return 'Running'.equalsIgnoreCase(status) || 'Scheduled'.equalsIgnoreCase(status) || 'New'.equalsIgnoreCase(status);
			}
		}
	}

	public class ErrorResponse {
		public String errorCode;
		public String message;
	}

	public class AsyncSoqlException extends Exception {
		public AsyncSoqlException(Response apiResponse) {
			this.setMessage(apiResponse.message + '\nResponse: ' + apiResponse.responseCode + ' - ' + apiResponse.responseStatus);
		}
	}

}