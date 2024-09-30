/**
 * @description Service layer for interacting with Happy Parcel Integration layer
 *
 * API Spec:
 * https://australiapost.jira.com/wiki/spaces/ISS/pages/1003586982/API+Specification+-+parcel+v1+events+id
 *
 * @author Nathan Franklin
 * @date 2020-06-18
 * @group Happy
 * @domain Core
 * @changelog
 * 2024-05-17 - Seth Heang - Added continuation methods for async callout to .NET API for retrieving StarTrack consignment/article details
 * 2024-06-26 - Seth Heang - Added additional mapping for .NET Callout including EDD and SourceSystem to response payload
 * 2024-07-15 - Seth Heang - Updated .NET callout response handling to handle duplicate consignment scenario
 **/
public with sharing class HappyParcelService {
	/**
	 * Creates a new instance of the service. This allows use to use dependency injection for mocking
	 */
	public static HappyParcelService getInstance() {
		return (HappyParcelService) Application.Utilities.getInstance(HappyParcelService.class);
	}

	public Result querySynchronousResponse(String trackingId) {
		HttpRequest request = getRequest(trackingId);

		Http http = new Http();
		HttpResponse httpResp = http.send(request);

		Result result = parseResponse(httpResp);
		return result;
	}

	/**
	 * Returns a HttpRequest to be used with either a synchronous or Continuation query
	 */
	public HttpRequest getRequest(String trackingId) {
		AusPostSettings__c setting = AusPostSettings__c.getValues('HAPPYPARCEL_GCP');

		String endPoint = setting.URL__c.removeEnd('/') + '/' + EncodingUtil.urlEncode(trackingId, 'UTF-8');
		HttpRequest request = new HttpRequest();
		request.setHeader('source_system_id', setting.AppKey__c);
		request.setHeader('business_reference_id', trackingId);
		request.setMethod('GET');
		request.setTimeout(getApiTimeout() * 1000);
		request.setEndpoint(endPoint);

		return request;
	}

	public Continuation getContinuation(String trackingId) {
		Continuation con = new Continuation(getApiTimeout());
		con.addHttpRequest(getRequest(trackingId));
		return con;
	}

	public Integer getApiTimeout() {
		AusPostSettings__c setting = AusPostSettings__c.getValues('HAPPYPARCEL_GCP');
		System.debug(setting);
		return Integer.valueOf(setting.LockDuration__c);
	}

	public Result parseResponse(HttpResponse response) {
		Integer statusCode = response.getStatusCode();
		String statusText = response.getStatus();
		String responseBody = response.getBody();
		System.debug('statusCode: ' + statusCode);
		System.debug('statusText: ' + statusText);
		System.debug('Response: ' + responseBody);

		Result result = new Result();
		result.articles = new List<Article>();
		result.errors = new List<String>();
		result.responseCode = statusCode;
		result.doRetry = false;

		if (statusCode == 200) {
			// a successful response was received and parsed
			try {
				result.articles = parseSuccessfulResponse(responseBody);
				result.isSuccess = true;
			} catch (Exception ex) {
				// JSON parse error most likely meaning the data can not be surfaced
				System.debug(ex);
				result.isSuccess = false;
				result.errors.add(ex.getMessage());
			}
		} else if (statusCode >= 2000) {
			// && String.isEmpty(error)) {
			// continuation error
			Error continuationError = new Error();
			continuationError.detail = statusText;
			continuationError.code = String.valueOf(statusCode);

			result.isSuccess = false;
			result.errors = new List<String>{ continuationError.toString() };
		} else if (statusCode == 503) {
			// service unavailable
			// the structure of HP in GCP requires reclustering and rebuilding of the tables
			// during this process (which normally take a couple of seconds), the service is unavailable
			// this is a dodgy solution but have been asked to build a 'Try again' option into the solution
			result.isSuccess = false;
			result.doRetry = true;
		} else if (statusCode != 404) {
			// a 404 will occur if HP does not have any data available for a particular tracking id
			// this feedback does not need to be displayed to the user so we only add errors for unexpected responses
			try {
				result.isSuccess = false;
				for (Error err : parseErrorResponse(responseBody)) {
					result.errors.add(err.toString());
				}
			} catch (Exception ex) {
				// JSON parse error most likely meaning the data can not be surfaced
				System.debug(ex);
			}

			// show the entire response if the JSON parser couldn't pass the response
			if (result.errors.isEmpty()) {
				result.errors.add(responseBody);
			}
		} else {
			// is 404, we don't attach any errors to the response since to prevent feedback at the UI layer
			result.isSuccess = false;
		}

		return result;
	}

	private List<Article> parseSuccessfulResponse(String jsonResponse) {
		List<Article> articles = new List<Article>();

		JSONParser parser = JSON.createParser(jsonResponse);
		while (parser.nextToken() != null) {
			if (parser.getCurrentName() == 'parcels' && parser.getCurrentToken() == JSONToken.START_ARRAY) {
				while (parser.nextToken() != null) {
					// Advance to the start object marker to
					// find next article object.
					if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
						// Read entire invoice object, including its array of line items.
						articles.add((Article) parser.readValueAs(Article.class));

						// Skip the child start array and start object markers.
						parser.skipChildren();
					}
				}
			}
		}

		System.debug('parsed articles: ' + articles);
		return articles;
	}

	private List<Error> parseErrorResponse(String jsonResponse) {
		List<Error> errors = new List<Error>();

		JSONParser parser = JSON.createParser(jsonResponse);
		while (parser.nextToken() != null) {
			if (parser.getCurrentName() == 'errors' && parser.getCurrentToken() == JSONToken.START_ARRAY) {
				while (parser.nextToken() != null) {
					// Advance to the start object marker to
					// find next article object.
					if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
						// Read entire invoice object, including its array of line items.
						errors.add((Error) parser.readValueAs(Error.class));

						// Skip the child start array and start object markers.
						parser.skipChildren();
					}
				}
			}
		}

		System.debug('parsed errors: ' + errors);
		return errors;
	}

	public class Article {
		@AuraEnabled
		public String article_id;
		@AuraEnabled
		public String consignment_id;

		// concatenated address string from manifest
		@AuraEnabled
		public String manifest_address;

		// dpid of the manifested address
		@AuraEnabled
		public String dpid;

		// latitude of the delivery/attempt delivery scans
		@AuraEnabled
		public Decimal latitude_scan;

		// longitude of the delivery/attempt delivery scans
		@AuraEnabled
		public Decimal longitude_scan;

		// latitude of the manifested address dpid
		@AuraEnabled
		public Decimal latitude_dpid;

		// longitude of the manifested address dpid
		@AuraEnabled
		public Decimal longitude_dpid;

		// the threshold limit which determines which emoticon to show if the flag_distance attribute is above or below
		@AuraEnabled
		public String distance_threshold;

		//km for example
		@AuraEnabled
		public String distance_threshold_unit;

		//	the indicator of distance assessment
		@AuraEnabled
		public String flag_distance;

		//the euclidean distance between scan and manifested address (unit: km)
		@AuraEnabled
		public String distance_calculated;

		//the scan events of the geo-coordinate
		@AuraEnabled
		public String gps_event;

		//	sap edd lower range	YYYY-MM-DD
		@AuraEnabled
		public String dedd_low;

		// sap edd higher range YYYY-MM-DD
		@AuraEnabled
		public String dedd_high;

		// hp edd lower range YYYY-MM-DD
		@AuraEnabled
		public String hp_dedd_low;

		// hp edd higher range YYYY-MM-DD
		@AuraEnabled
		public String hp_dedd_high;

		// the indicator of smiling face (1: smile, 0:mad, null:n.a)
		// stopped, overdue, on-track, unknown
		@AuraEnabled
		public String flag_smiling {
			get {
				return (String.isEmpty(flag_smiling) ? '' : flag_smiling.toLowerCase());
			}
			set {
				flag_smiling = value;
			}
		}

		// actual time difference between manifest scan and first physical scans
		@AuraEnabled
		public Decimal manifest_gap;

		// historical average time difference between manifest scan and first physical scans
		@AuraEnabled
		public Decimal average_handling_time;

		// assessment on manifesting quality
		@AuraEnabled
		public String flag_manifest_quality {
			get {
				return (String.isEmpty(flag_manifest_quality) ? '' : flag_manifest_quality.toLowerCase());
			}
			set {
				flag_manifest_quality = value;
			}
		}

		// sample_size in manifest gap assessment
		@AuraEnabled
		public Decimal sample_volume;

		// previous concatenated address string
		@AuraEnabled
		public String previous_address;

		// previous address line 1
		@AuraEnabled
		public String previous_address_1;

		// previous address line 2
		@AuraEnabled
		public String previous_address_2;

		// previous suburb string
		@AuraEnabled
		public String previous_suburb;

		// previous destination postcode string
		@AuraEnabled
		public String previous_to_postcode;

		// current concatenated address string
		@AuraEnabled
		public String current_address;

		// current address line 1
		@AuraEnabled
		public String current_address_1;

		//current address line 2
		@AuraEnabled
		public String current_address_2;

		// current suburb string
		@AuraEnabled
		public String current_suburb;

		//current destination postcode string
		@AuraEnabled
		public String current_to_postcode;

		@AuraEnabled
		public List<Issue> issues;
	}

	public class Issue {
		// the work centre where the issue occurred
		@AuraEnabled
		public String wcc;

		// the work centre name where the issue occurred
		@AuraEnabled
		public String wcc_name;

		// type of issues: missort, looping, unusual location
		@AuraEnabled
		public String type;

		// time spend in looping (will be null for other issues)
		@AuraEnabled
		public Decimal looping_time;

		//hour, day/days
		@AuraEnabled
		public String looping_time_unit;
	}

	public class Error {
		//{business_reference_id} sent in request - returned only if its a valid request
		@AuraEnabled
		public String id;

		//The code associated to the error Eg. AS-9005
		@AuraEnabled
		public String code;

		//The name category for the error - End system error
		@AuraEnabled
		public String title;

		//The human readable error message
		@AuraEnabled
		public String detail;

		public override String toString() {
			return (!String.isEmpty(code) ? code : '') + (!String.isEmpty(code) ? ': ' : '') + detail;
		}
	}

	public class Result {
		@AuraEnabled
		public Boolean isSuccess { get; protected set; }
		@AuraEnabled
		public Boolean doRetry { get; protected set; }
		@AuraEnabled
		public Integer responseCode { get; protected set; }
		@AuraEnabled
		public List<Article> articles { get; protected set; }
		@AuraEnabled
		public List<String> errors { get; protected set; }
	}

	/**
	 * @description		Perform Async callout to dotNet API for retrieving StarTrack Article/Consignment and then call callback method for attribute mapping
	 * @param		String searchType
	 * @param		String searchSubject
	 * @param		HappyParcelController.TrackingArticle trackingResult
	 * @return		Continuation
	 */
	public Continuation searchStarTrackAsync(String searchType, String searchSubject, HappyParcelController.TrackingArticle trackingResult) {
		wwwAuspostComAuSchemaCustomercarema.SearchRequest request = StarTrackConsignmentSearchUtil.generateSearchRequest(
			searchSubject,
			searchType,
			StarTrack_Constants.REQUEST_ACTION_FULL,
			StarTrack_Constants.SOURCEID_SALESFORCE,
			UserInfo.getUserName()
		);
		AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = StarTrackConsignmentSearchUtil.generateAsyncStub();

		try {
			Continuation cont = new Continuation(Integer.valueOf(StarTrack_Constants.starTrackConfigSetting.Web_Service_Callout_Timeout__c));
			cont.continuationMethod = 'processStarTrackSearchResult';
			StateInfoStarTrack stateInfo = new StateInfoStarTrack(emsAsyncStub.beginSearch_x(cont, request), trackingResult);
			HappyParcelController.starTrackContState = stateInfo;
			cont.state = stateInfo;
			return cont;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @description		Callback method to handle response, of an async callout to dotNet API for retrieving StarTrack article/consignment details
	 * @param		Object state
	 * @return		Object
	 */
	public Object processStarTrackSearchResult(Object state) {
		StateInfoStarTrack stInfo = (StateInfoStarTrack) state;
		HappyParcelController.TrackingArticle trackingResult = stInfo.trackingResult;
		// Process callout response
		StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrapper = processResponse(stInfo.stResponse.getValue(), stInfo.trackingResult.article.Id);
		// Make additional callout for Duplicate Consignment Scenario
		if (conWrapper?.requiredAdditionalCallout != null) {
			return HappyParcelService.getInstance().searchStarTrackAsync(
					conWrapper.requiredAdditionalCallout.searchType,
					conWrapper.requiredAdditionalCallout.value,
					trackingResult
			);
		}
		// Map .NET response and display updates on happy parcel component
		if (conWrapper?.articleList != null && conWrapper.articleList.size() > 0){
			Article__c consignmentST = conWrapper.articleList?.get(0);
			trackingResult.article.FurtherReferences__c = consignmentST?.FurtherReferences__c;
			trackingResult.article.DeliveryInstructions__c = consignmentST?.DeliveryInstructions__c;
			trackingResult.article.ConsignmentParcelCount__c = consignmentST?.ConsignmentParcelCount__c;
			trackingResult.article.ExpectedDeliveryDate__c = consignmentST?.ExpectedDeliveryDate__c;
			trackingResult.article.Source_System__c = consignmentST?.Source_System__c;
		}
		// Map warning message and display on happy parcel component
		if(conWrapper?.warningMessages != null){
			trackingResult.warningMessages = conWrapper?.warningMessages;
		}
		return trackingResult;
	}

	/**
	 * @description	Called by the callback method to process attribute mapping for article/consignment details returned from dotNet API for StarTrack
	 * 				Perform DML update after the attribute mappings
	 * @param		wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse
	 * @param		Id consignmentSFId
	 * @return		StarTrackConsignmentSearchUtil.ConsignmentWrapper
	 */
	public StarTrackConsignmentSearchUtil.ConsignmentWrapper processResponse(wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse, Id consignmentSFId) {
		List<Database.SaveResult> results;
		try {
			// Single Consignment Scenario
			if (emsResponse.Header.NbrOfRows == 1 || emsResponse.Consignment != null) {
				Article__c thisConsignment;
				thisConsignment = new Article__c();
				Set<String> references = new Set<String>{ emsResponse.Consignment.FurtherReference1, emsResponse.Consignment.FurtherReference2 };
				references.remove(null);
				thisConsignment.FurtherReferences__c = references.isEmpty() ? null : String.join(references, ', ');
				thisConsignment.DeliveryInstructions__c = thisConsignment.DeliveryInstructions__c == null ? emsResponse.Consignment.DeliveryInstructions : thisConsignment.DeliveryInstructions__c;
				thisConsignment.ConsignmentParcelCount__c = thisConsignment.ConsignmentParcelCount__c == null ? emsResponse.Consignment.ConsignmentParcelCount : thisConsignment.ConsignmentParcelCount__c;
				thisConsignment.ExpectedDeliveryDate__c = emsResponse?.Consignment?.ExpectedDeliveryDate != null ? emsResponse.Consignment.ExpectedDeliveryDate : thisConsignment.ExpectedDeliveryDate__c;
				//thisConsignment.Source_System__c = emsResponse?.Consignment?.SourceSystem != null ? emsResponse.Consignment.SourceSystem : thisConsignment.Source_System__c;
				thisConsignment.Id = consignmentSFId;
				results = ApplicationDatabase.getInstance().dmlUpdate(new List<SObject>{ thisConsignment });

				thisConsignment.Source_System__c = emsResponse?.Consignment?.SourceSystem != null ? emsResponse.Consignment.SourceSystem : thisConsignment.Source_System__c;


				return new StarTrackConsignmentSearchUtil.ConsignmentWrapper(true, null, new List<Article__c>{ thisConsignment });
			}
			// Duplicate Consignment Scenario
			else if (emsResponse.Header.NbrOfRows > 1 && emsResponse.SearchResults != null) {
				List<wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail> validDupConData = filterValidConsignments(emsResponse.SearchResults.Results.DUPCON_DataDetail);
				// Single valid consignment returns after the filtering
				if(validDupConData.size() == 1){
					// make another .NET callout with the UniqueExternalId value and 'UNIQUEEXTERNALID' search type
					String consignmentExternalId = validDupConData[0].UniqueExternalId;
					return new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false, null, null,
							new StarTrackConsignmentSearchUtil.AdditionalStarTrackCallout(
									StarTrack_Constants.TYPE_UNIQUEEXTERNALID,
									consignmentExternalId
							)
					);
				}
				// Multiple valid consignments after the filtering
				else if (validDupConData.size() > 1) {
					// Display duplicate consignment warning and do not update any new mappings from .NET API
					return new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false, null, null, new List<String>{ System.Label.HappyParcelNETDuplicateConsignmentWarningText });
				}
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logFailedDatabaseResults(results, 'HappyParcel' , String.valueOf(HappyParcelService.class), 'processResponse', null, ApplicationLogger.LoggingLevel.ERROR);
			throw new AuraHandledException(e.getMessage());
		}
		return null;
	}

	/**
	 * @description logic to filter a list of incoming duplicate consignment and only return valid consignment that meet below criteria:
	 * 				- DateSent is within the last 6 months
	 * @param dupconDataDetails duplicate consignments
	 * @return List<wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail>
	 */
	public List<wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail> filterValidConsignments(List<wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail> dupconDataDetails){
		List<wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail> validDupConDataDetails = new List<wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail>();
		for (wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail consignmentData : dupconDataDetails) {
			// DateSent is within the last 6 months
			if(consignmentData.DateSent.date() >= System.today().addMonths(-6)){
				validDupConDataDetails.add(consignmentData);
			}
		}
		return validDupConDataDetails;
	}

	/**
	 * @description		Wrapper class to be used by in the Async callout to dotNet API for retrieving StarTrack details.
	 * 			Its purpose is to retain State information while making the async request callout and pass the state back for callback method
	 */
	public class StateInfoStarTrack {
		HappyParcelController.TrackingArticle trackingResult { get; set; }
		AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture stResponse { get; set; }

		public StateInfoStarTrack(AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture response, HappyParcelController.TrackingArticle trackingResult) {
			this.stResponse = response;
			this.trackingResult = trackingResult;
		}
	}
}