/**************************************************
Description:    Restful API Service Utility class
Usage:          Used by Restuful API methods for various interactions with the RestContext
History:
--------------------------------------------------
2018-04-11  nathan.franklin@auspost.com.au Updated
2018-12-11  nathan.franklin@auspost.com.au Added API interfaces for faster API onboarding
**************************************************/
public with sharing class ResourceAPIService {

	/**
	 * interface for the Apex Handler Classes defined in the ResourceAPI__mdt records
	 */
	public abstract class IApi {
		public RequestParams requestParams;

		// a list of fields that can be created with this case type
		// any cases created will be created with SSSWGeneralEnquiry and workflow rules will change the record type accordingly
		protected final Map<String, String> API_FIELD_MAPPINGS;
		protected final Set<String> API_CREATABLE_FIELDS;

		// used for classes that implement pagination, these are convieniant variables to help with correct calculation
		public Integer resultsPerPage = 50;
		public Integer pageNumber = 1;
		public Boolean countOnly = false;

		// used to pass validation error messages back after a validation method has fired
		public List<String> validationErrors = new List<String>();

		// used for POST method
		public virtual IResourceResponse post() {
			return new ResourceAPIService.ResourceResponse(501, '', 'Not Implemented');
		}
		//		public virtual IResourceResponse validatePostParams() {
		//			return null;
		//		}

		// used for GET method
		public virtual IResourceResponse query() {
			return new ResourceAPIService.ResourceResponse(501, '', 'Not Implemented');
		}
		//		public virtual IResourceResponse validateQueryParams() {
		//			return null;
		//		}
		public virtual String getQueryCacheKeySuffix() {
			return requestParams.version + '/' + requestParams.uri + '/' + resultsPerPage + '/' + pageNumber + '/' + (countOnly ? 'count' : '');
		}

		//		/**
		//		 * This will convert the records queried into their mapped values defined within each class
		//		 */
		//		public List<Map<String, Object>> normaliseSObjectOutput(List<SObject> records, Map<String, String> fieldMappings) {
		//			List<Map<String, Object>> output = new List<Map<String, Object>>();
		//			for(SObject record : records) {
		//				Map<String, Object> mapRecord = new Map<String, Object>();
		//				for(String key : fieldMappings.keySet()) {
		//					if(record.isSet(fieldMappings.get(key))) {
		//						mapRecord.put(key.toLowerCase(), record.get(fieldMappings.get(key)));
		//					}
		//				}
		//				output.add(mapRecord);
		//			}
		//			return output;
		//		}

		/**
		 * For classes that implement pagination, this is a helper method to correctly calculate the offset of where the records should start
		 */
		public Integer getPaginationOffset() {
			// Example: pageNumber = 1, resultsPerPage = 10
			// 	For page 1, the offset should be 0 because it's the starting point, hence the minus resultsPerPage
			return (pageNumber * resultsPerPage) - resultsPerPage;
		}
	}

	/**
	 * Provides a way to feedback the API response in the framework in a flexible way per API.
	 */
	public virtual class IResourceResponse {
		protected Map<String, Object> output = new Map<String, Object>();
		protected Integer responseCode = null;

		public virtual String serialize() {
			return JSON.serializePretty(output);
		}
		public virtual Integer getResponseCode() {
			return responseCode;
		}

		/**
		 * Determines whether the specific request should be cached. This is only applicable in a GET and when the overall endpoint is cacheable (defined in custom metadata)
		 */
		public virtual Boolean cacheOutputtedResultIfEnabled() {
			return (responseCode == 200 ? true : false);
		}
	}

	/**
	 * Provides the serialised response sent back to the consumer.
	 * This is the default response that all API's should respond with.
	 */
	public class ResourceResponse extends IResourceResponse {
		/**
		 * Returns whether a request was successful or not
		 * Property exists for backwards compatibility only.
		 */
		public Boolean success {
			get {
				return (Boolean)output.get('success');
			}
		}

		/**
		 * Property exists for backwards compatibility only.
		 */
		public String error {
			get {
				return String.valueOf(output.get('error'));
			}
		}

		/**
		 * In most cases this will be Map<String, String>
		 * Property exists for backwards compatibility only.
		 */
		public Object response {
			get {
				return output.get('response');
			}
		}

		/**
		 * Response for response code only without any body. Automatically sets the success parameter.
		 */
		public ResourceResponse(Integer responseCode) {
			this(responseCode == 200, null, null, responseCode);
		}

		/**
		 * Response for response code only without any body but with an error. Automatically sets the success parameter.
		 */
		public ResourceResponse(Integer responseCode, String error) {
			this(responseCode == 200, error, null, responseCode);
		}

		/**
		 * Response for success (true/false) only without any body but with an error.
		 * Backward compatibility
		 */
		public ResourceResponse(Boolean success, String error) {
			this(success, error, null);
		}

		/**
		 * Response for success (true/false) with an optional error and response body.
		 * Backward compatibility
		 */
		public ResourceResponse(Boolean success, String error, Object response) {
			this(success, error, response, (success ? 200 : 500));
		}

		/**
		 * Response for response code with a body and an error message will automatically be set if the response code is not 200.
		 */
		public ResourceResponse(Integer responseCode, Object response) {
			this(responseCode == 200, (responseCode != 200 ? 'Error' : null), response, responseCode);
		}

		/**
		 * Response for response code with a body, an error message and response body
		 */
		public ResourceResponse(Integer responseCode, String error, Object response) {
			this(responseCode == 200, error, response, responseCode);
		}

		/**
		 * Core constructor for defining the output response.
		 */
		public ResourceResponse(Boolean success, String error, Object response, Integer responseCode) {
			output.put('success', success);
			if(!String.isEmpty(error)) {
				output.put('error', error);
			}
			if(response != null) {
				output.put('response', response);
			}

			this.responseCode = responseCode;
		}
	}

	/**
	 * Parses the Request URI and query string parameters and returns them in an easy to use format.
	 */
	public class RequestParams {
		// defaults
		public Decimal version = 1.0;

		// initialisation
		public String uri = '';
		public List<String> uriParts = new List<String>();
		public Map<String, String> queryStringParams = new Map<String, String>();
		public List<String> dynamicUriParams = new List<String>();
		public Map<String, Object> bodyParams = new Map<String, Object>();

		// used for POST method (where a JSON body is passed in)
		// @throwable
		public RequestParams(String uri, String jsonBody) {
			this(uri, new Map<String, String>());

			// parse json body and store the output
			// a json request is also expecting { key1: value1, key2: value2 }
			// all values should be strings or else
			if(!String.isEmpty(jsonBody)) {
				bodyParams = (Map<String, Object>)JSON.deserializeUntyped(jsonBody);
			}
		}

		// used for GET method
		public RequestParams(String uri, Map<String, String> queryStringParams) {
			this.uri = uri;
			this.queryStringParams = queryStringParams;

			// parse the url
			parseUri();

			System.Debug('>> RequestParams: ' + this);
		}

		/**
		 * Dynamic URL parameters are used to catch wildcarded URL patterns to retrieve the actual value from the url called
		 * Example:
		 * 	A url pattern exists in custom metadata record: consumer/(.*?)/cases
		 * 	This is a regex that creates a group (with (.*?)).
		 *
		 * 	When calling /consumer/C12234/cases, this will allow the C12234 to be extracted out and added as a dynamic param which can be used in the query class
		 */
		public void addDynamicUriParam(String value) {
			dynamicUriParams.add(value);
		}

		private void parseUri() {
			String uri = uri.split('\\?')[0];
			String[] parts = uri.split('\\/');
			System.Debug('>> parts: ' + parts);

			// this is the basic format of the URL called
			// example: /api/1.0/consumer/C12345/cases
			//	0		1	 2
			// [empty string]/api/[version]/etc...

			// get version number
			if(parts.size() >= 3) {
				// make sure the version number is a decimal value
				try {
					version = Decimal.valueOf(parts[2]);
				} catch(Exception ex) {
					System.debug('VERSION mismatch');
					version = 0.0;
				}
			}

			// get everything after version
			// this will be the actual url parts we use to map back to the custom metadata entry record.
			if(parts.size() >= 4) {
				for(Integer i=3;i<parts.size();i++) {
					uriParts.add(parts[i]);
				}

				// this is used to map back to the URL pattern in the custom metadata object ResourceAPI__mdt (URI__c)
				this.uri = String.join(uriParts, '/');
			}

		}

		public String getParam(String param) {
			return (String.isEmpty(queryStringParams.get(param)) ? '' : queryStringParams.get(param));
		}
	}

	/**
	 * A wrapper class to retrieve the Request params and the metadata configuration for the API in question
	 * The metadata configm contains the details about which class to execute, the version, and caching duration etc...
	 */
	public class ResourceAPIConfigWrapper {
		public ResourceAPI__mdt config;
		public RequestParams params;

		public ResourceAPIConfigWrapper(ResourceAPI__mdt config, RequestParams params) {
			this.config = config;
			this.params = params;
		}
	}

	/**
	 * Maps an API request received to a lightning API configuration which points to a custom Apex controller
	 * This uses regex to 'match' the incoming url to a particular record.
	 * This will extract the dynamic params out the request url and add them to the RequestParams for easy use.
	 */
	public static ResourceAPIConfigWrapper getResourceApiConfig(RequestParams params, String httpMethod) {
		String uri = params.uri;
		List<ResourceAPI__mdt> configs = [
				Select OrderPriority__c, URI__c, APIVersion__c, ApexClassHandler__c, HTTPMethod__c, CacheQueryResponse__c, CacheTTLOverride__c, LogRequests__c, LogBody__c
				From ResourceAPI__mdt
				Where APIVersion__c = :params.version
				Order By OrderPriority__c ASC
		];
		for(ResourceAPI__mdt config : configs) {

			// match the http method
			if(!String.isEmpty(config.HTTPMethod__c) && config.HTTPMethod__c.toLowerCase() != httpMethod.toLowerCase())
				continue;

			try {
				String parsedUri = config.URI__c.replace('%param%', '([^\\/]*)') + '$';
				Pattern regEx = Pattern.compile(parsedUri);
				Matcher match = regEx.matcher(uri);

				if (match.matches()) {
					// found a uri match
					for (Integer i = 1; i <= match.groupCount(); i++) {
						params.addDynamicUriParam(match.group(i));
					}

					return new ResourceAPIConfigWrapper(config, params);
				}
			} catch(Exception ex) {
				System.debug('API Config Incorrect: ' + ex);
			}
		}

		return null;
	}

	/**
	 * Allows for a very fluid custom delivery of JSON content without worrying about APEX encoding and issues when it encodes the response.
	 */
	public static void serializeResponse(IResourceResponse output) {
		serializeResponse(output, output.getResponseCode(), false);
	}

	/**
	 * Allows for a very fluid custom delivery of JSON content without worrying about APEX encoding and issues when it encodes the response.
	 */
	public static void serializeResponse(IResourceResponse output, Boolean isCached) {
		serializeResponse(output, output.getResponseCode(), isCached);
	}

	/**
	 * Allows for a very fluid custom delivery of JSON content without worrying about APEX encoding and issues when it encodes the response.
	 */
	public static void serializeResponse(IResourceResponse output, Integer responseCode) {
		serializeResponse(output, output.getResponseCode(), false);
	}

	/**
	 * Allows for a very fluid custom delivery of JSON content without worrying about APEX encoding and issues when it encodes the response.
	 */
	public static void serializeResponse(IResourceResponse output, Integer responseCode, Boolean isCached) {
		RestResponse res = RestContext.response;
		if (res == null) {
			res = new RestResponse();
			RestContext.response = res;
		}

		res.addHeader('Content-Type', 'application/json');
		if(isCached) {
			res.addHeader('X-Platform-Cache', '1');
		}
		res.responseBody = blob.valueOf(output.serialize());
		res.statusCode = responseCode;
	}
}