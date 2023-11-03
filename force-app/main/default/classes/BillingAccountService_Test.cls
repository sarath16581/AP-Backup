/**
 * @description Test class for BillingAccountService
 * @author Ranjeewa Silva
 * @group Tests
 * @changelog
 * 2023-10-31 - Ranjeewa Silva - Created
 */
@IsTest
private class BillingAccountService_Test {

	@TestSetup
	private static void setup() {
		AusPostSettings__c setting = new AusPostSettings__c(Name = 'CreateBillingAccountCredentials', URL2__c = 'http://callout:test', LockDuration__c = 30);
		insert setting;
	}

	/**
	 *	Ensure that an synchronous API call to external service returning a successful result is parsed.
	 */
	@IsTest
	private static void testSynchronousRequestWithSuccessResponse() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new BillingAccountServiceSuccessHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		BillingAccountService service = BillingAccountService.getInstance();
		HttpResponse resp = service.submitRequest('{\'test\':\'\'}', 'test1234', 'Salesforce');
		BillingAccountService.Response response = service.parseResponse(resp);

		Test.stopTest();

		Assert.isTrue(response.isSuccess, 'Expected success status to be returned in parsed response, but received error status instead.');
		Assert.areEqual(202, response.statusCode, 'Expected \'202\' status code to be returned in parsed response, but received \'' + response.statusCode + '\'.');
		Assert.isTrue(response.errors.isEmpty(), 'Expected no errors to be returned in parsed response, but received errors.');
		Assert.isTrue(String.isBlank(response.getErrorMessage()), 'Expected no errors to be returned in parsed response, but received errors.');
		Assert.isFalse(response.getIsRetryable(), 'Successfully acknowledged request is not retryable, but parsed response indicate otherwise.');
	}

	/**
	 *	Ensure that an synchronous API call to external service returning a error response including error details are parsed.
	 */
	@IsTest
	private static void testSynchronousRequestWithErrorResponseIncludingErrorDetails() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new BillingAccountService400HttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		BillingAccountService service = BillingAccountService.getInstance();
		HttpResponse resp = service.submitRequest('{\'test\':\'\'}', 'test1234', 'Salesforce');
		BillingAccountService.Response response = service.parseResponse(resp);

		Test.stopTest();

		Assert.isFalse(response.isSuccess, 'Expected error status to be returned in parsed response, but received success instead.');
		Assert.areEqual(400, response.statusCode, 'Expected \'400\' status code to be returned in parsed response, but received \'' + response.statusCode + '\'.');
		Assert.isFalse(response.errors.isEmpty(), 'Expected errors to be returned in parsed response, but received no errors.');
		Assert.isTrue(String.isNotBlank(response.getErrorMessage()), 'Expected errors to be returned in parsed response, but received no errors.');
	}

	/**
	 *	Ensure that an synchronous API call to external service returning a error response without error details are parsed.
	 */
	@IsTest
	private static void testSynchronousRequestWithErrorResponseWithoutErrorDetails() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new BillingAccountService503HttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		BillingAccountService service = BillingAccountService.getInstance();
		HttpResponse resp = service.submitRequest('{\'test\':\'\'}', 'test1234', 'Salesforce');
		BillingAccountService.Response response = service.parseResponse(resp);

		Test.stopTest();

		Assert.isFalse(response.isSuccess, 'Expected error status to be returned in parsed response, but received success instead.');
		Assert.areEqual(503, response.statusCode, 'Expected \'503\' status code to be returned in parsed response, but received \'' + response.statusCode + '\'.');
		Assert.isFalse(response.errors.isEmpty(), 'Expected errors to be returned in parsed response, but received no errors.');
		Assert.isTrue(String.isNotBlank(response.getErrorMessage()), 'Expected errors to be returned in parsed response, but received no errors.');
	}

	/**
	 *	Ensure that an synchronous API call to external service returning an unexpected response payload is handled.
	 */
	@IsTest
	private static void testSynchronousRequestWithErrorResponseInvalidBody() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new BillingAccountServiceInvalidHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Invoke the continuation
		BillingAccountService service = BillingAccountService.getInstance();
		HttpResponse resp = service.submitRequest('{\'test\':\'\'}', 'test1234', 'Salesforce');
		BillingAccountService.Response response = service.parseResponse(resp);

		Test.stopTest();

		Assert.isFalse(response.isSuccess, 'Expected error status to be returned in parsed response, but received success instead.');
		Assert.areEqual(500, response.statusCode, 'Expected \'500\' status code to be returned in parsed response, but received \'' + response.statusCode + '\'.');
		Assert.isFalse(response.errors.isEmpty(), 'Expected errors to be returned in parsed response, but received no errors.');
		Assert.isTrue(String.isNotBlank(response.getErrorMessage()), 'Expected errors to be returned in parsed response, but received no errors.');
	}

	/**
	 *	Ensure that an asynchronous (continuation) Billing Account Service API call returns httpRequest with endpoint details.
	 */
	@IsTest
	private static void testAsynchronousRequestConfiguration() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// invoke continuation
		Continuation cont = BillingAccountService.getInstance().getContinuation('test', '', 'Salesforce');

		Test.stopTest();

		// get the embedded http request to inspect
		HttpRequest httpRequest = cont.getRequests().values()[0];
		Assert.isNotNull(httpRequest, 'Returned continuation instance should have a valid request, but got null.');
		Assert.areEqual(BillingAccountService.setting.URL2__c, httpRequest.getEndpoint(), 'Request endpoint must point to configured URL in custom setting \'CreateBillingAccountCredentials\'.');
		Assert.areEqual('POST', httpRequest.getMethod(), 'Request must be sent using http POST, but was ' + httpRequest.getMethod());
	}

	class BillingAccountServiceSuccessHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'  "orgRecordId":"",\n' +
					'  "requestObjId":"",\n' +
					'  "transactionId":"",\n' +
					'  "status":"Success"\n' +
					'}');
			response.setStatusCode(202);
			return response;
		}
	}

	class BillingAccountService400HttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('{\n' +
					'	"errors": [\n' +
					'		{\n' +
					'			"id": "9ac30065-4291-41d5-8cb7-9da78b6f23ab",\n' +
					'			"code": "AS-9009",\n' +
					'			"title": "Invalid Request Format",\n' +
					'			"detail": "Failed while validating the request. Json payload is not valid for the requested target system."\n' +
					'		}\n' +
					'	]\n' +
					'}');
			response.setStatusCode(400);
			return response;
		}
	}

	class BillingAccountServiceInvalidHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setBody('invalidresponse');
			response.setStatusCode(500);
			return response;
		}
	}

	class BillingAccountService503HttpMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(503);
			return response;
		}
	}
}