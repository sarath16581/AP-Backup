/***
 * @description Test cases for DigitalRepositoryService
 * @author Ranjeewa Silva
 * @date 2022-04-11
 * @group Tests
 * @domain Core
 * @changelog
 * 2022-04-11 - Ranjeewa Silva - Created.
 */

@IsTest
public class DigitalRepositoryService_Test {

	@TestSetup
	private static void setup() {
		AusPostSettings__c setting = new AusPostSettings__c(Name = 'DigitalRepositoryDocumentsAPIv2', URL__c = 'http://callout:test', LockDuration__c = 15);
		insert setting;
	}

	/**
	 * Scenario: Makes sure that a Digital Repository Service API call returning a successful response is parsed and returned
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
		Test.setMock(HttpCalloutMock.class, new DigitalRepositorySuccessHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		DigitalRepositoryService service = DigitalRepositoryService.getInstance();
		DigitalRepositoryService.DocumentApiResponse response = service.querySynchronousResponse('f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG', 'test-bucket');

		Test.stopTest();

		System.assertEquals(false, response.isError, 'Expected isError to be false');
		System.assertEquals(0, response.errors.size(), 'Expected no errors in the response');
		System.assertNotEquals(null, response.document, 'Expected a valid document in the response');
		System.assertEquals('f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG', response.document.object_id, 'Expected f845ceb7-cb5b-4bbc-aba1-cad55d07e75c article but got: ' + response.document.object_id);
		System.assert(String.isNotBlank(response.getDocumentContent()), 'Expected valid document contents, but got : ' + response.getDocumentContent());
		System.assert(String.isBlank(response.getErrorMessage()), 'Expected no errors, but got : ' + response.getErrorMessage());

	}

	/**
	 * Scenario: Makes sure that a Digital Repository API call returning a 404 response is parsed and error details are returned.
	 */
	@IsTest
	public static void testQuerySynchronousResponseWith404Response() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new DigitalRepository404HttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		DigitalRepositoryService service = DigitalRepositoryService.getInstance();
		DigitalRepositoryService.DocumentApiResponse response = service.querySynchronousResponse('f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG', 'invalidbucket999');

		Test.stopTest();

		System.assertEquals(true, response.isError, 'Expected isError to be true');
		System.assertEquals(1, response.errors.size(), 'Expected errors in the response');
		System.assertEquals(null, response.getDocumentContent(), 'Expected document contents to be null, but got : ' + response.getDocumentContent());
		System.assert(String.isNotBlank(response.getErrorMessage()), 'Expected a valid error message, but got : ' + response.getErrorMessage());

	}

	/**
	 * Scenario: Makes sure that a Digital Repository API call returning a 500 response with no error details is parsed.
	 *		   We still return an error to the caller.
	 */
	@IsTest
	public static void testQuerySynchronousResponseWith500InvalidResponseWithMoErrorDetails() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new DigitalRepositoryInvalidHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		DigitalRepositoryService service = DigitalRepositoryService.getInstance();
		DigitalRepositoryService.DocumentApiResponse response = service.querySynchronousResponse('f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG', 'test-bucket');

		System.assertEquals(true, response.isError, 'Expected isError to be true');
		System.assertEquals(1, response.errors.size(), 'Expected an error in the response');
		System.assertEquals(null, response.getDocumentContent(), 'Expected no document contents in the response');
		System.assertEquals('An Error Occurred (500)', response.getErrorMessage(), 'Expected a 500 response');

		Test.stopTest();

	}

	/**
	 * Scenario: Makes sure that a Digital Repository API call returning a 400 response is parsed and error details returned.
	 */
	@IsTest
	public static void testQuerySynchronousResponseWith400InvalidResponseWithMoErrorDetails() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new DigitalRepository400HttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		DigitalRepositoryService service = DigitalRepositoryService.getInstance();
		DigitalRepositoryService.DocumentApiResponse response = service.querySynchronousResponse('f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG', 'test-bucket', false, -1, -1);

		System.assertEquals(true, response.isError, 'Expected isError to be true');
		System.assertEquals(1, response.errors.size(), 'Expected an error in the response');
		System.assertEquals(null, response.getDocumentContent(), 'Expected no document contents in the response');
		System.assertEquals('ERROR: AS-9005, Invalid Parameter value, The field \'resize_percentage\' value is not valid. Please check the data type and the valid range.', response.getErrorMessage(), 'Expected a valid error message');

		Test.stopTest();

	}

	/**
	 *	Scenario: Makes sure that an asynchronous (continuation) Digital Repository Service API call returning a successful result is parsed.
	 */
	@IsTest
	private static void testQueryAsynchronousResponseWithSuccessResponse() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new DigitalRepositorySuccessHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		DigitalRepositoryService service = DigitalRepositoryService.getInstance();
		Continuation cont = (Continuation)service.getContinuation('f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG', 'test-bucket');

		// setup the continuation mock provider
		String requestLabel = new List<String>(cont.getRequests().keySet())[0];
		DigitalRepositoryService_Test.setSuccessContinuationResponse(requestLabel);

		// extract the continuation response and parse
		HttpResponse resp = Continuation.getResponse(requestLabel);
		DigitalRepositoryService.DocumentApiResponse response = service.parseResponse(resp);

		Test.stopTest();

		System.assertEquals(false, response.isError, 'Expected no errors but instead got: ' + JSON.serialize(response));
		System.assertEquals(0, response.errors.size(), 'Expected no errors in the response');
		System.assertNotEquals(null, response.document, 'Expected a valid document in the response');
		System.assertEquals('f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG', response.document.object_id, 'Expected f845ceb7-cb5b-4bbc-aba1-cad55d07e75c photo but got: ' + response.document.object_id);
		System.assertNotEquals(null, response.getDocumentContent(), 'Expected valid document contents, but got null.');
		System.assert(String.isBlank(response.getErrorMessage()), 'Expected no errors.');
	}

	/**
	 *	Scenario: Makes sure that an asynchronous (continuation) Digital Repository Service API call returning a continuation error
	 *			is parsed and returned.
	 */
	@IsTest
	private static void testQueryAsynchronousResponseWithContinuationError() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new DigitalRepositorySuccessHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		DigitalRepositoryService service = DigitalRepositoryService.getInstance();
		Continuation cont = (Continuation)service.getContinuation('f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG', 'test-bucket');

		// setup the continuation mock provider
		String requestLabel = new List<String>(cont.getRequests().keySet())[0];
		DigitalRepositoryService_Test.setErrorContinuationResponse(requestLabel);

		// extract the continuation response and parse
		HttpResponse resp = Continuation.getResponse(requestLabel);
		DigitalRepositoryService.DocumentApiResponse response = service.parseResponse(resp);

		Test.stopTest();

		System.assertEquals(true, response.isError, 'Expected continuation error but instead got: ' + JSON.serialize(response));
		System.assertEquals(1, response.errors.size(), 'Expected an error in the response');
		System.assertEquals(null, response.getDocumentContent(), 'Expected no document contents in the response');
		System.assert(String.isNotBlank(response.getErrorMessage()), 'Expected valid error message , but got : ' + response.getErrorMessage());
	}

	/**
	* Used to return a successful response to the continuation request
	*/
	public static void setSuccessContinuationResponse(String requestLabel) {
		// Perform mock callout
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
		res.setBody('{\n' +
				'  "document": {\n' +
				'	"object_id": "f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG",\n' +
				'	"bucket_name": "test-bucket",\n' +
				'	"object_details": {\n' +
				'	  "object_content": "/9j/4AAQSkZJRgABAgAAZABkAAD///9k"\n' +
				'	}\n' +
				'  }\n' +
				'}');
		res.setStatusCode(200);
		Test.setContinuationResponse(requestLabel, res);
	}

	/**
	* Used to return a continuation error response to the continuation request
	*/
	public static void setErrorContinuationResponse(String requestLabel) {
		// Perform mock callout
		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
		res.setStatusCode(2004);
		Test.setContinuationResponse(requestLabel, res);
	}

	class DigitalRepositorySuccessHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'  "document": {\n' +
					'	"object_id": "f845ceb7-cb5b-4bbc-aba1-cad55d07e75c.JPG",\n' +
					'	"bucket_name": "test-bucket",\n' +
					'	"object_details": {\n' +
					'	  "object_content": "/9j/4AAQSkZJRgABAgAAZABkAAD///9k"\n' +
					'	}\n' +
					'  }\n' +
					'}');
			response.setStatusCode(200);
			return response;
		}
	}

	class  DigitalRepository404HttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'  "document":{\n' +
					'	"error":[\n' +
					'	  {\n' +
					'		"code":"AS-9007",\n' +
					'		"name":"Object Not Found",\n' +
					'		"message":"A document not found with this criteria. Bucket name not found"\n' +
					'	  }\n' +
					'	]\n' +
					'  }\n' +
					'}');
			response.setStatusCode(404);
			return response;
		}
	}

	class  DigitalRepository400HttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'  "document":{\n' +
					'	"error":[\n' +
					'	  {\n' +
					'		"code":"AS-9005",\n' +
					'		"name":"Invalid Parameter value",\n' +
					'		"message":"The field \'resize_percentage\' value is not valid. Please check the data type and the valid range."\n' +
					'	  }\n' +
					'	]\n' +
					'  }\n' +
					'}');
			response.setStatusCode(404);
			return response;
		}
	}

	class DigitalRepositoryInvalidHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{ERROR,wefuiwhefiuwhe');
			response.setStatusCode(500);
			return response;
		}
	}

}