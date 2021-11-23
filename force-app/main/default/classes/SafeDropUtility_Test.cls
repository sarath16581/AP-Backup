/**
 * Utility Test Class helper in addition to covering SafeDropUtility
 *
 * @author Nathan Franklin
 * @date
 * @description
 * @changelog
 * 22/05/2017  disha.kariya@auspost.com.au     Added Token for bucket name in AusPost Setting
 * 26/05/2020 haraprasad.sahoo@auspost.com.au  Added mock methods for MyNetworkPODSafedrop continuation callouts
 * 2021-09-09  seth.heang@auspost.com.au   Uplift SF API version to 52
 * 2021-10-15 - Nathan Franklin - Added test methods to cover class
 */
@isTest
public class SafeDropUtility_Test {

    public class InvalidReturnTypeException extends Exception { }

    /**
     * Scenario: ensure safe drop events are returned
     */
    @IsTest
    private static void testEnsureSafedropEventTypesAreFound() {
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

        Set<String> eventTypes = SafeDropUtility.getSafeDropEvents();
        Set<String> attachmentTypes = SafeDropUtility.getSafeDropAttachmentTypes();

        Test.stopTest();

        System.assert(eventTypes.isEmpty() == false, 'Safe drop event types were not found');
        System.assert(attachmentTypes.isEmpty() == false, 'Safe drop event attachment types were not found');

    }

    /************************************************************************************************
	 *	SCENARIO:
	 *		Api call to Safe Drop is made and returns a successful response.
	 *************************************************************************************************/
    @IsTest
    private static void testSuccessResponse() {
        SafeDropUtility_Test.insertAuthSettings();

        Test.startTest();

        // Invoke the continuation
        HttpRequest request = SafeDropUtility.getInstance().getHttpRequest('TEST');

        Continuation con = new Continuation(1);
        con.addHttpRequest(request);

        String requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel(con);
        SafeDropUtility_Test.setSuccessContinuationResponse(requestLabel);

        HttpResponse resp = Continuation.getResponse(requestLabel);

        String responseBody = resp.getBody();

        // parse the json
        SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);

        Test.stopTest();

        System.assertEquals(false, response.isError);
        System.assertNotEquals('', response.imageBody);
    }

    /************************************************************************************************
	 *	SCENARIO:
	 *		Api call to Safe Drop is made and returns a error response.
	 *************************************************************************************************/
    @IsTest
    private static void testErrorResponse() {
        SafeDropUtility_Test.insertAuthSettings();

        Test.startTest();

        // Invoke the continuation
        HttpRequest request = SafeDropUtility.getInstance().getHttpRequest('TEST');

        Continuation con = new Continuation(1);
        con.addHttpRequest(request);

        String requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel(con);
        SafeDropUtility_Test.setErrorContinuationResponse(requestLabel);

        HttpResponse resp = Continuation.getResponse(requestLabel);

        String responseBody = resp.getBody();

        // parse the json
        SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);

        Test.stopTest();

        System.assertEquals(true, response.isError);
        System.assertNotEquals('', response.errorMessage);

    }

    /************************************************************************************************
	 *	SCENARIO:
	 *		Api call to Safe Drop is made and returns a error response.
	 *************************************************************************************************/
    @IsTest
    private static void testContinuationErrorResponse() {
        SafeDropUtility_Test.insertAuthSettings();

        Test.startTest();

        // Invoke the continuation
        HttpRequest request = SafeDropUtility.getInstance().getHttpRequest('TEST');

        Continuation con = new Continuation(1);
        con.addHttpRequest(request);

        String requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel(con);
        SafeDropUtility_Test.setErrorContinuationResponse(requestLabel, 2001, '');

        HttpResponse resp = Continuation.getResponse(requestLabel);

        String responseBody = resp.getBody();

        // parse the json
        SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);

        Test.stopTest();

        System.assertEquals(true, response.isError);
        System.assertNotEquals('', response.errorMessage);

    }

    /************************************************************************************************
	 *	SCENARIO:
	 *		Api call to Safe Drop is made and errors but does not return a correct response body
	 *		EXAMPLE: User authorisation errors
	 *************************************************************************************************/
    @IsTest
    private static void testFailResponse() {
        SafeDropUtility_Test.insertAuthSettings();

        Test.startTest();

        // Invoke the continuation
        HttpRequest request = SafeDropUtility.getInstance().getHttpRequest('TEST');

        Continuation con = new Continuation(1);
        con.addHttpRequest(request);

        String requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel(con);
        SafeDropUtility_Test.setFailContinuationResponse(requestLabel);

        HttpResponse resp = Continuation.getResponse(requestLabel);

        String responseBody = resp.getBody();

        // parse the json
        SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);

        Test.stopTest();

        System.assertEquals(true, response.isError);
        System.assertNotEquals('', response.errorMessage);
    }

    /************************************************************************************************
	 *	SCENARIO:
	 *		A nothing test for code coverage
	 *************************************************************************************************/
    @IsTest
    private static void testGetSafedropAPIResponse() {

        Test.startTest();

        SafeDropUtility.SafeDropApiResponse response = new SafeDropUtility.SafeDropApiResponse(false, '', '');

        Test.stopTest();

        System.assertEquals(false, response.isError);
    }


    public static String getInvokedContinuationLabel(Object continuation) {
        Map<String, HttpRequest> requests = ((Continuation)continuation).getRequests();
        String requestLabel = requests.keyset().iterator().next();
        if(!(continuation instanceOf Continuation)) {
            throw new InvalidReturnTypeException('Invalid Return Type');
        }
        return requestLabel;
    }

    /**
     * Used to returb a successful response to the continuation request
     */
    public static void setSuccessContinuationResponse(String requestLabel) {
        // Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"document":{"object_id":"07847bc7-f699-4078-8df5-56fc92aac930.JPG","bucket_name":"ap-test-st-parcel-atl-imagecapture-ptest","object_details":{"object_content":"base64code"}}}');

        Test.setContinuationResponse(requestLabel, res);
    }

    public static void setErrorContinuationResponse(String requestLabel) {
        setErrorContinuationResponse(requestLabel, 500, '{"document":{"error":[{"code":"AS-9007","name":"A document not found with this criteria.","message":"{\\n  \\"Error\\":{\\n    \\"Code\\":\\"NoSuchKey\\",\\n    \\"Message\\":\\"The specified key does not exist.\\",\\n    \\"Key\\":\\"07847bc7-f699-4078-8df5-56fc92aac930\\",\\n    \\"RequestId\\":\\"3F3AD9BA4A558789\\",\\n    \\"HostId\\":\\"7BWS2xkg+GMe098cehCKIAyP5jakymmsTRnjWo44ympAlg4AWk9mUMT2U2U3uhfplzcbyZnYv3U=\\"\\n  }\\n}"}]}}');
    }

    public static void setErrorContinuationResponse(String requestLabel, Integer statusCode) {
        setErrorContinuationResponse(requestLabel, statusCode, '{"document":{"error":[{"code":"AS-9007","name":"A document not found with this criteria.","message":"{\\n  \\"Error\\":{\\n    \\"Code\\":\\"NoSuchKey\\",\\n    \\"Message\\":\\"The specified key does not exist.\\",\\n    \\"Key\\":\\"07847bc7-f699-4078-8df5-56fc92aac930\\",\\n    \\"RequestId\\":\\"3F3AD9BA4A558789\\",\\n    \\"HostId\\":\\"7BWS2xkg+GMe098cehCKIAyP5jakymmsTRnjWo44ympAlg4AWk9mUMT2U2U3uhfplzcbyZnYv3U=\\"\\n  }\\n}"}]}}');
    }

    public static void setErrorContinuationResponse(String requestLabel, Integer statusCode, String body) {
        // Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        res.setBody(body);

        Test.setContinuationResponse(requestLabel, res);
    }

    public static void setFailContinuationResponse(String requestLabel) {
        // Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(401);
        res.setStatus('Unauthorized');
        res.setBody('<html><head><title>Apache Tomcat/5.5.27 - Error report</title></head><body><h1>HTTP Status 401 - Unauthorized</h1><u>This request requires HTTP authentication (Unauthorized).</u></p><HR size="1" noshade="noshade"><h3>Apache Tomcat/5.5.27</h3></body></html>');

        Test.setContinuationResponse(requestLabel, res);
    }

    public static void insertAuthSettings() {
        AusPostSettings__c setting = new AusPostSettings__c(
                URL__c = 'http://digitalrepository/v1/documents',
                Username__c = '',
                Password__c = '',
                IsActive__c = true,
                Token__c = 'ATLImage',
                Name = 'SafeDropAPI'
        );
        insert setting;
    }
    
    /**
     * Used to create a continuation state request 
     */
    public static POD_SafeDropController.ContinuationState  getInvokedContinuationLabel_ConState(Object continuation) {
        POD_SafeDropController.ContinuationState  state =  new POD_SafeDropController.ContinuationState ();
        Map<String, HttpRequest> requests = ((Continuation)continuation).getRequests();
        state.httprequestLabel = requests.keyset().iterator().next();
        if(!(continuation instanceOf Continuation)) {
            throw new InvalidReturnTypeException('Invalid Return Type');
        }
        return state;
    }
   
    
    /**
     * Used to create a continuation state request for myNetworkPODSafedrop controller
     */
    public static MyNetworkPODSafedrop.ContinuationState  getmyNetworkInvokedContinuationLabel_ConState(Object continuation) {
        MyNetworkPODSafedrop.ContinuationState  state =  new MyNetworkPODSafedrop.ContinuationState ();
        Map<String, HttpRequest> requests = ((Continuation)continuation).getRequests();
        state.httprequestLabel = requests.keyset().iterator().next();
        if(!(continuation instanceOf Continuation)) {
            throw new InvalidReturnTypeException('Invalid Return Type');
        }
        return state;
    }
    
    /**
     * Used to returb a successful response to the continuation request 
     */
    public static void setSuccessContinuationResponse_ConState(POD_SafeDropController.ContinuationState requestLabel) {
        // Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"document":{"object_id":"07847bc7-f699-4078-8df5-56fc92aac930.JPG","bucket_name":"ap-test-st-parcel-atl-imagecapture-ptest","object_details":{"object_content":"base64code"}}}');

        Test.setContinuationResponse(requestLabel.httpRequestLabel, res);
    }
    
    /**
     * Used to return a successful response to the continuation request for myNetworkPODSafedrop controller
     */
    public static void setmyNetworkSuccessContinuationResponse_ConState(MyNetworkPODSafedrop.ContinuationState requestLabel) {
        // Perform mock callout
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"document":{"object_id":"07847bc7-f699-4078-8df5-56fc92aac930.JPG","bucket_name":"ap-test-st-parcel-atl-imagecapture-ptest","object_details":{"object_content":"base64code"}}}');

        Test.setContinuationResponse(requestLabel.httpRequestLabel, res);
    }

}