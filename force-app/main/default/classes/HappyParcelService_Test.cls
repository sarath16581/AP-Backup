/***
 * @author Nathan Franklin
 * @date 2020-07-01
 * @group Tests
 * @description Test Scenarios for Happy Parcel Service
 * @changelog
 * 2024-05-17 - Seth Heang - added methods to provide mock wrapper class response from SAP-EM callout
 */
@IsTest
public class HappyParcelService_Test {

	@TestSetup
	private static void setup() {
		AusPostSettings__c setting = new AusPostSettings__c(Name = 'HAPPYPARCEL_GCP', AppKey__c = 'SFDC', URL__c = 'https://mine/', LockDuration__c = 15);
		insert setting;
	}

	/**
	 * Scenario: Makes sure that a call to HP API returns a successful result
	 */
	@IsTest
	public static void testQuerySynchronousResponseWithSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new AnalyticsSuccessHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		HappyParcelService service = HappyParcelService.getInstance();
		HappyParcelService.Result result = service.querySynchronousResponse('33T64345964501000935000');

		System.assertEquals(true, result.isSuccess, 'Expected isSuccess to be true');
		System.assertEquals(false, result.doRetry, 'Expected doRetry to be false');
		System.assertEquals(0, result.errors.size(), 'Expected no errors in the response');
		System.assertEquals(1, result.articles.size(), 'Expected 1 article in the response');
		System.assertEquals('33T64345964501000935000', result.articles[0].article_id, 'Expected 33T64345964501000935000 article but got: ' + result.articles[0].article_id);

		Test.stopTest();

	}

	/**
	 * Scenario: Makes sure that a call to HP API returns a 404 response without any error messages
	 *              This is to suppress any error messages since this data is complimentary in the ui and there is no need to notify the user if the data is not available
	 */
	@IsTest
	public static void testQuerySynchronousResponseWith404ResponseWithoutErrorMessages() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new Analytics404HttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		HappyParcelService service = HappyParcelService.getInstance();
		HappyParcelService.Result result = service.querySynchronousResponse('33T64345964501000935000');

		System.assertEquals(false, result.isSuccess, 'Expected isSuccess to be false');
		System.assertEquals(false, result.doRetry, 'Expected doRetry to be false');
		System.assertEquals(0, result.errors.size(), 'Expected no errors in the response');
		System.assertEquals(0, result.articles.size(), 'Expected no articles in the response');
		System.assertEquals(404, result.responseCode, 'Expected a 404 response');

		Test.stopTest();

	}

	/**
	 * Scenario: Makes sure that a call to HP API returns a 503 response without any error messages
	 */
	@IsTest
	public static void testQuerySynchronousResponseWith503ResponseToEnsureUIRetryPrompt() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new Analytics503HttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		HappyParcelService service = HappyParcelService.getInstance();
		HappyParcelService.Result result = service.querySynchronousResponse('33T64345964501000935000');

		System.assertEquals(false, result.isSuccess, 'Expected isSuccess to be false');
		System.assertEquals(true, result.doRetry, 'Expected doRetry to be true');
		System.assertEquals(0, result.errors.size(), 'Expected no errors in the response');
		System.assertEquals(0, result.articles.size(), 'Expected no articles in the response');
		System.assertEquals(503, result.responseCode, 'Expected a 503 response');

		Test.stopTest();

	}

	/**
	 * Scenario: Makes sure that a call to HP API returns a 500 response and we can catch the error and display it
	 */
	@IsTest
	public static void testQuerySynchronousResponseWith500InvalidResponseBody() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new AnalyticsInvalidHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		HappyParcelService service = HappyParcelService.getInstance();
		HappyParcelService.Result result = service.querySynchronousResponse('33T64345964501000935000');

		System.assertEquals(false, result.isSuccess, 'Expected isSuccess to be false');
		System.assertEquals(false, result.doRetry, 'Expected doRetry to be false');
		System.assertEquals(1, result.errors.size(), 'Expected an error in the response');
		System.assertEquals('{ERROR,wefuiwhefiuwhe', result.errors[0], 'Expected the error to match the response body in the mock');
		System.assertEquals(0, result.articles.size(), 'Expected no articles in the response');
		System.assertEquals(500, result.responseCode, 'Expected a 500 response');

		Test.stopTest();

	}

	/**
	 * Scenario: Makes sure that a call to HP API returns a 500 response and we can catch the error and display it
	 */
	@IsTest
	public static void testQuerySynchronousResponseWith500ValidResponseBody() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new Analytics500HttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		HappyParcelService service = HappyParcelService.getInstance();
		HappyParcelService.Result result = service.querySynchronousResponse('33T64345964501000935000');

		System.assertEquals(false, result.isSuccess, 'Expected isSuccess to be false');
		System.assertEquals(false, result.doRetry, 'Expected doRetry to be false');
		System.assertEquals(1, result.errors.size(), 'Expected an error in the response');
		System.assertEquals(0, result.articles.size(), 'Expected no articles in the response');
		System.assertEquals(500, result.responseCode, 'Expected a 500 response');

		Test.stopTest();

	}

	class AnalyticsSuccessHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'  "parcels":[\n' +
					'    {\n' +
					'      "article_id":"33T64345964501000935000",\n' +
					'      "consignment_id":"33T643459645",\n' +
					'      "manifest_address":"Parcel Locker 10178 41579 19 Jardine Street KINGSTON 2604",\n' +
					'      "dpid":"87009973",\n' +
					'      "latitude_scan":-35.54654,\n' +
					'      "longitude_scan":149.15487,\n' +
					'      "latitude_dpid":-35.364578,\n' +
					'      "longitude_dpid":149.145414,\n' +
					'      "distance_threshold":1.0,\n' +
					'      "distance_threshold_unit":"km",\n' +
					'      "flag_distance":"1",\n' +
					'      "distance_calculated":0.031,\n' +
					'      "gps_event":"DD-ER13",\n' +
					'      "dedd_low":"2020-06-19",\n' +
					'      "dedd_high":"2020-06-24",\n' +
					'      "hp_dedd_low":"2020-06-19",\n' +
					'      "hp_dedd_high":"2020-06-22",\n' +
					'      "flag_smiling":"stopped",\n' +
					'      "manifest_gap":1.0,\n' +
					'      "average_handling_time":1.0,\n' +
					'      "sample_volume":7005.0,\n' +
					'      "flag_manifest_quality":"excellent",\n' +
					'      "previous_address":"UNIT 4, 59 NO AVENUE SYDNEY 2000",\n' +
					'      "previous_address_1":"UNIT 4, 59 NO AVENUE",\n' +
					'      "previous_address_2":"",\n' +
					'      "previous_suburb":"SYDNEY",\n' +
					'      "previous_to_postcode":"2000",\n' +
					'      "current_address":"PARCEL LOCKER 10178 41579 19 JARDINE STREET KINGSTON 2604",\n' +
					'      "current_address_1":"Parcel Locker 10178 41579",\n' +
					'      "current_address_2":"19 Jardine Street",\n' +
					'      "current_suburb":"KINGSTON",\n' +
					'      "current_to_postcode":"2604",\n' +
					'      "issues":[\n' +
					'        {\n' +
					'          "wcc":"278483",\n' +
					'          "wcc_name":"SYDNEY PARCEL FACILITY",\n' +
					'          "type":"looping",\n' +
					'          "looping_time":2,\n' +
					'          "looping_time_unit":"days"\n' +
					'        },\n' +
					'        {\n' +
					'          "wcc":"220142",\n' +
					'          "wcc_name":"NORTH WOLLONGONG PDC",\n' +
					'          "type":"missort"\n' +
					'        }\n' +
					'      ]\n' +
					'    }\n' +
					'  ]\n' +
					'}');
			response.setStatusCode(200);
			return response;
		}
	}

	// still is considered a success to prevent the an error feedback to the user
	// if the article is 404 then the correct error not found should be surfaced via
	class Analytics404HttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'  "errors":[\n' +
					'    {\n' +
					'      "id":"werfwerfwefrwerfwer",\n' +
					'      "code":"AS-9005",\n' +
					'      "title":"Data not found",\n' +
					'      "detail":"No data found for the provided reference ID"\n' +
					'    }\n' +
					'  ]\n' +
					'}');
			response.setStatusCode(404);
			return response;
		}
	}

	// triggers the doRetry flow
	class Analytics503HttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'  "errors":[\n' +
					'    {\n' +
					'      "id":"werfwerfwefrwerfwer",\n' +
					'      "code":"AS-9003",\n' +
					'      "title":"Unable to call End System",\n' +
					'      "detail":"The process was unable to reach or successfully call the End System. Please try again after few minutes."\n' +
					'    }\n' +
					'  ]\n' +
					'}');
			response.setStatusCode(503);
			return response;
		}
	}

	// triggers the doRetry flow
	class Analytics500HttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'  "errors":[\n' +
					'    {\n' +
					'      "id":"werfwerfwefrwerfwer",\n' +
					'      "code":"AS-9003",\n' +
					'      "title":"Unable to call End System",\n' +
					'      "detail":"The process was unable to reach or successfully call the End System. Please try again after few minutes."\n' +
					'    }\n' +
					'  ]\n' +
					'}');
			response.setStatusCode(500);
			return response;
		}
	}

	class AnalyticsInvalidHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{ERROR,wefuiwhefiuwhe');
			response.setStatusCode(500);
			return response;
		}
	}

	/**
	 * @description		Mock TrackingArticle wrapper response with a single article from .NET StarTrack callout
	 * @return		JSON String
	 */
	public static String getTrackingArticleOnlyMock() {
		return '{' +
				'"article":{' +
					'"Id":"a1hBm000000YfLhIAK",' +
					'"Name":"2AT71923",' +
					'"ArticleID__c":"2AT71923",' +
					'"SignatureRequiredFlag__c":true,' +
					'"InsuranceRequired__c":false,' +
					'"Notification__c":false,' +
					'"RecordTypeId":"012900000015ftlAAA",' +
					'"Delivered__c":0,' +
					'"TrackingID__c":"2AT71923",' +
					'"CaptureID_receiveronly__c":false,' +
					'"CaptureID_anyoneataddress__c":false,' +
					'"VODV_Redirect__c":false,' +
					'"RecordType":{' +
						'"Name":"Consignment",' +
						'"Id":"012900000015ftlAAA"' +
					'}' +
				'},' +
				'"events":[' +
				'],' +
				'"trackingId":"2AT71923"' +
				'}';
	}

	/**
	 * @description		Mock TrackingResult wrapper response with a single article from .NET StarTrack callout
	 * @return		JSON String
	 */
	public static String getTrackingResultMock(){
		return '{' +
				'"trackResults": [' +
					'{' +
						'"trackingID": "I1FZ50049085",' +
						'"Success": true,' +
						'"returnCode": "ESB-BUS-DATA-100",' +
						'"resultDescription": null,' +
						'"consignmentDetails": {' +
							'"sender": null,' +
							'"receiver": null,' +
							'"proxyConsignment": {' +
							'"attributes": {' +
							'"type": "Article__c",' +
							'"url": "/services/data/v61.0/sobjects/Article__c/a1hBm000000YfLhIAK"' +
						'},' +
						'"Id": "a1hBm000000YfLhIAK",' +
						'"Name": "I1FZ50049085",' +
						'"ArticleID__c": "I1FZ50049085",' +
						'"SignatureRequiredFlag__c": true,' +
						'"InsuranceRequired__c": false,' +
						'"Notification__c": false,' +
						'"RecordTypeId": "012900000015ftlAAA",' +
						'"Delivered__c": 0,' +
						'"TrackingID__c": "I1FZ50049085",' +
						'"CaptureID_receiveronly__c": false,' +
						'"CaptureID_anyoneataddress__c": false,' +
						'"VODV_Redirect__c": false,' +
						'"RecordType": {' +
							'"attributes": {' +
							'"type": "RecordType",' +
							'"url": "/services/data/v61.0/sobjects/RecordType/012900000015ftlAAA"' +
						'},' +
						'"Name": "Consignment",' +
						'"Id": "012900000015ftlAAA"' +
						'}' +
						'},' +
						'"eventMessages": [],' +
						'"articles": [' +
						'{' +
							'"transientAttributes": {' +
							'"predictedWindowStart": null,' +
							'"predictedWindowEnd": null,' +
							'"initialPredictedWindowStart": null,' +
							'"initialPredictedWindowEnd": null,' +
							'"contentItems": null' +
							'},' +
							'"sender": null,' +
							'"selected": false,' +
							'"receiver": null,' +
							'"proxyArticle": {' +
								'"attributes": {' +
								'"type": "Article__c",' +
								'"url": "/services/data/v61.0/sobjects/Article__c/a1hBm000000YfLjIAK"' +
							'},' +
							'"Id": "a1hBm000000YfLjIAK",' +
							'"Name": "I1FZ50049085EXP00001",' +
							'"ArticleID__c": "I1FZ50049085EXP00001",' +
							'"ProductCategory__c": "StarTrack",' +
							'"ServiceCode__c": "72",' +
							'"SignatureRequiredFlag__c": true,' +
							'"SubProduct__c": "Express",' +
							'"InsuranceRequired__c": false,' +
							'"Notification__c": false,' +
							'"Consignment__c": "a1hBm000000YfLhIAK",' +
							'"RecordTypeId": "012900000015ftkAAA",' +
							'"Delivered__c": 0,' +
							'"ProductID__c": "002",' +
							'"SubProductID__c": "725",' +
							'"ConsignmentTrackingNumber__c": "I1FZ50049085",' +
							'"CaptureID_receiveronly__c": false,' +
							'"CaptureID_anyoneataddress__c": false,' +
							'"VODV_Redirect__c": false,' +
							'"Consignment__r": {' +
								'"attributes": {' +
								'"type": "Article__c",' +
								'"url": "/services/data/v61.0/sobjects/Article__c/a1hBm000000YfLhIAK"' +
							'},' +
							'"ArticleID__c": "I1FZ50049085",' +
							'"Id": "a1hBm000000YfLhIAK"' +
							'},' +
							'"RecordType": {' +
								'"attributes": {' +
								'"type": "RecordType",' +
								'"url": "/services/data/v61.0/sobjects/RecordType/012900000015ftkAAA"' +
							'},' +
							'"Name": "Article",' +
							'"Id": "012900000015ftkAAA"' +
						'}' +
					'},' +
					'"eventMessages": [],' +
					'"eddImageIconName": "error16.png"' +
					'}' +
					']' +
					'},' +
					'"articleDetails": null' +
					'}' +
				'],' +
				'"success": true,' +
				'"errors": []' +
				'}';
	}

}