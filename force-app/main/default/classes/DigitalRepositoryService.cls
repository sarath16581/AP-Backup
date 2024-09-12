/**
 * @description Service layer for interacting with Digital Repository integration layer (v2) for retrieving documents stored in
 * digital repository (AWS S3)
 * API Spec:
 * https://australiapost.jira.com/wiki/spaces/ISS/pages/503120147/API+Specification+-+digitalrepository+v2+documents
 *
 * @author Ranjeewa Silva
 * @date 2022-04-07
 * @group Service
 * @domain Core
 * @changelog
 * 2022-04-07 - Ranjeewa Silva - Created
 **/

public with sharing class DigitalRepositoryService {

	// grab settings configured in custom setting
	private static AusPostSettings__c setting {
		get {
			if(setting == null) {
				setting = AusPostSettings__c.getValues('DigitalRepositoryDocumentsAPIv2');
			}
			return setting;
		}
		private set;
	}

	/**
	 * Returns a new instance of the service
	 * @return new instance
	 */
	public static DigitalRepositoryService getInstance() {
		return (DigitalRepositoryService) Application.Utilities.getInstance(DigitalRepositoryService.class);
	}

	/**
	 * Returns a continuation instance that can be used to make long running callouts to digital repository documents
	 * end point.
	 *
	 * Please refer API Spec in TIBCO for the details.
	 *
	 * @param objectId Object id to be retrieved from digital repository. Note that file extension (e.g. .JPG) may have to be specified (e.g. '6de3141d-634a-4cbd-9570-f78af58f6d30.JPG').
	 * @param bucketName Name of the digital repository bucket holding the object.
	 *
	 * @return Continuation instance
	 */
	public Continuation getContinuation(String objectId, String bucketName) {
		return getContinuation(objectId, bucketName, null, null, null);
	}

	/**
	 * Returns a continuation instance that can be used to make long running callouts to digital repository documents
	 * end point.
	 *
	 * Please refer API Spec in TIBCO for the details.
	 *
	 * @param objectId Object id to be retrieved from digital repository. Note that file extension (e.g. .JPG) may have to be specified (e.g. '6de3141d-634a-4cbd-9570-f78af58f6d30.JPG').
	 * @param bucketName Name of the digital repository bucket holding the object.
	 * @param blurImage Flag to indicate whether to obscure faces and any text detected for privacy reasons. Optional.
	 * @param resizePercentage Percentage original image should be resized to. Optional.
	 * @param resizeThreshold Resize image only if the image size is more than the threshold value in Kilobytes.
	 *
	 * @return Continuation instance
	 */
	public Continuation getContinuation(String objectId, String bucketName, Boolean blurImage, Integer resizePercentage, Integer resizeThreshold) {
		Continuation con = new Continuation(getApiTimeout());
		con.addHttpRequest(getRequest(objectId, bucketName, blurImage, resizePercentage, resizeThreshold));
		return con;
	}

	/**
	 * Synchronously call Digital Repository API to retrieve the supplied object id.
	 *
	 * Please refer API Spec in TIBCO for the details.
	 *
	 * @param objectId Object id to be retrieved from digital repository. Note that file extension (e.g. .JPG) may have to be specified (e.g. '6de3141d-634a-4cbd-9570-f78af58f6d30.JPG').
	 * @param bucketName Name of the digital repository bucket holding the object.
	 *
	 * @return response containing document contents / error details
	 */
	public DocumentApiResponse querySynchronousResponse(String objectId, String bucketName) {
		return querySynchronousResponse(objectId, bucketName, null, null, null);
	}

	/**
	 * Synchronously call Digital Repository API to retrieve the supplied object id.
	 *
	 * Please refer API Spec in TIBCO for the details.
	 *
	 * @param objectId Object id to be retrieved from digital repository. Note that file extension (e.g. .JPG) may have to be specified (e.g. '6de3141d-634a-4cbd-9570-f78af58f6d30.JPG').
	 * @param bucketName Name of the digital repository bucket holding the object.
	 * @param blurImage Flag to indicate whether to obscure faces and any text detected for privacy reasons. Optional.
	 * @param resizePercentage Percentage original image should be resized to. Optional.
	 * @param resizeThreshold Resize image only if the image size is more than the threshold value in Kilobytes.
	 *
	 * @return response containing document contents / error details
	 */
	public DocumentApiResponse querySynchronousResponse(String objectId, String bucketName, Boolean blurImage, Integer resizePercentage, Integer resizeThreshold) {
		HttpRequest request = getRequest(objectId, bucketName, blurImage, resizePercentage, resizeThreshold);

		Http http = new Http();
		HttpResponse httpResp = http.send(request);
		return parseResponse(httpResp);
	}

	/**
	 * Parse the response received from Digital Repository V2 end point.
	 * @param httpResponse response
	 *
	 * @return parsed response with document contents / errors
	 */
	public DocumentApiResponse parseResponse(HttpResponse httpResponse) {
		Integer statusCode = httpResponse.getStatusCode();
		String responseBody = httpResponse.getBody();

		DocumentApiResponse response = new DocumentApiResponse();

		if (statusCode == 200) {
			// a successful response was received - attempt to parse the response.
			try {
				response = parseResponseBody(responseBody);
				if (String.isEmpty(response.getDocumentContent())) {
					// the object content doesn't exist in the response
					response.isError = true;
					response.errors.add('Image content not found.');
				} else {
					// the object content exist in the response. mark as a successful response.
					response.isError = false;
				}
			} catch (Exception ex) {
				// error parsing the response. populate error details.
				response.isError = true;
				response.errors.add(ex.getMessage());
			}
		} else if (statusCode >= 2000) {
			// continuation error - populate error details
			response.errors.add(getContinuationError(statusCode));
			response.isError = true;
		} else {
			// attempt to parse the response as we may get error details returned.
			try {
				response = parseResponseBody(responseBody);
			} catch (Exception ex) {
				// received a http error status and the error response cannot be parsed.
				// return a generic error in this case
				System.debug(ex.getMessage());
			}

			if (response.errors.isEmpty()) {
				// status code returned is not 200 - the request failed.
				response.isError = true;
				// return a generic HTTP status error because the error JSON object doesn't exist
				response.errors.add((httpResponse.getStatus() == null ? 'An Error Occurred' : httpResponse.getStatus()) + ' (' + String.valueOf(httpResponse.getStatusCode()) + ')');
			}
		}

		return response;
	}

	/**
	 * Returns a HttpRequest to be used with either a synchronous or Continuation query
	 *
	 * @param objectId Object id to be retrieved from digital repository. Note that file extension (e.g. .JPG) may have to be specified (e.g. '6de3141d-634a-4cbd-9570-f78af58f6d30.JPG').
	 * @param bucketName Name of the digital repository bucket holding the object.
	 * @param blurImage Flag to indicate whether to obscure faces and any text detected for privacy reasons. Optional.
	 * @param resizePercentage Percentage original image should be resized to. Optional.
	 * @param resizeThreshold Resize image only if the image size is more than the threshold value in Kilobytes.
	 *
	 * @return
	 */
	private HttpRequest getRequest(String objectId, String bucketName, Boolean blurImage, Integer resizePercentage, Integer resizeThreshold) {

		String endpoint = setting.URL__c.removeEnd('/')
				+ '?bucket_name='+ EncodingUtil.urlEncode(bucketName, 'UTF-8')
				+ '&object_id=' + EncodingUtil.urlEncode(objectId, 'UTF-8')
				+ (blurImage != null ? '&blur_image=' + (blurImage ? 'Y' : 'N') : '')
				+ (resizePercentage != null ? '&resize_percentage=' + resizePercentage : '')
				+ (resizeThreshold != null ? '&resize_threshold_value=' + resizeThreshold : '');

		HttpRequest request = new HttpRequest();
		request.setTimeout(getApiTimeout()*1000);
		request.setEndpoint(endpoint);
		request.setMethod('GET');
		return request;
	}

	private DocumentApiResponse parseResponseBody(String responseBody) {
		DigitalRepositoryDocumentResponse digitalRepositoryResponse = (DigitalRepositoryDocumentResponse) JSON.deserialize(responseBody, DigitalRepositoryDocumentResponse.class);
		return new DocumentApiResponse(digitalRepositoryResponse?.document);
	}

	private Integer getApiTimeout() {
		if (setting != null && setting.LockDuration__c != null){
			return Integer.valueOf(setting.LockDuration__c);
		}
		return 60;
	}

	private static String getContinuationError(Integer statusCode) {
		Map<Integer, String> errors = new Map<Integer, String>();
		errors.put(2000,'The timeout was reached, and the server didn’t get a chance to respond.');
		errors.put(2001,'There was a connection failure.');
		errors.put(2002,'Exceptions occurred.');
		errors.put(2003,'The response hasn’t arrived (which also means that the Apex asynchronous callout framework hasn’t resumed).');
		errors.put(2004,'The response size is too large (greater than 1 MB).');

		if(errors.get(statusCode) == null) {
			return String.valueOf(statusCode) + ': An error occurred.';
		} else {
			return errors.get(statusCode);
		}
	}

	public class DocumentApiResponse {

		// flag indicating success / error
		@AuraEnabled public Boolean isError;

		// parsed document returned by the end point.
		@AuraEnabled public Document document;

		// errors to be returned. in addition to the errors returned by the endpoint, this could include any errors
		// encountered while attempting to parse the response.
		@AuraEnabled public List<String> errors;

		public DocumentApiResponse() {
			this.errors = new List<String>();
		}

		public DocumentApiResponse(Document document) {
			this.document = document;
			this.errors = new List<String>();
			if (document?.error != null && !document.error.isEmpty()) {
				for (Error e: document.error) {
					this.errors.add(e.toString());
				}
			}
			this.isError = !this.errors.isEmpty();
		}

		/**
		 * Returns a combined error message that could be displayed to the user
		 * @return error message
		 */
		@AuraEnabled public String getErrorMessage() {
			String errorMessage = '';
			for (String error: errors) {
				errorMessage += (!String.isEmpty(errorMessage) && !String.isEmpty(error) ? ', ' : '');
				errorMessage += (!String.isEmpty(error) ? error : '');
			}
			return errorMessage;
		}

		/**
		 * Returns the document contents
		 * @return base 64 encoded contents returned by the end point.
		 */
		@AuraEnabled public String getDocumentContent() {
			return this.document?.object_details?.object_content;
		}
	}

	public class DigitalRepositoryDocumentResponse {
		public Document document;
	}

	public class Document {

		// object id of the document retrieved.
		@AuraEnabled public String object_id;

		// bucket name that identify the storage location in digital repository (S3)
		@AuraEnabled public String bucket_name;

		// document details retrieved
		@AuraEnabled public DocumentDetails object_details;

		// errors returned by the API.
		@AuraEnabled public List<Error> error;
	}

	public class DocumentDetails {
		@AuraEnabled public String object_content;
	}

	public class Error {

		//The code associated to the error Eg. AS-9007
		@AuraEnabled public String code;

		//The name category for the error - End system error
		@AuraEnabled public String name;

		//The human readable error message
		@AuraEnabled public String message;

		public override String toString() {
			if(!String.isEmpty(code) && code == 'AS-9007') {
				// special handling to return a more user friendly error.
				return 'Error: Document Not Found';
			}
			return 'ERROR: ' + (!String.isEmpty(code) ? code : '')
					+ (!String.isEmpty(name) ? (', ' + name) : '')
					+ (!String.isEmpty(message) ? (', ' + message) : '');
		}
	}

}