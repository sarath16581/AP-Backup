@isTest
private class StarTrack_WebSvcCallouts_Test {
    @isTest
    public static void testPublishCD() {

        Test.startTest();
        
        Case c = new Case();
        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        StarTrack_WebSvcCallouts_Test cont = new StarTrack_WebSvcCallouts_Test(sc);

        // Invoke the continuation by calling the action method
        Continuation conti = cont.publishCD_test();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_publishCD());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);
        
        Test.stopTest();

        // result is the return value of the callback
        System.assertEquals(null, result);
    }
    
    @isTest
    public static void testCaseNotification() {

        Test.startTest();
        
        Case c = new Case();
        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        StarTrack_WebSvcCallouts_Test cont = new StarTrack_WebSvcCallouts_Test(sc);

        // Invoke the continuation by calling the action method
        Continuation conti = cont.caseNotification_test();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody('');

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);
        
        Test.stopTest();

        // result is the return value of the callback
        System.assertEquals(null, result);
    }
    
    @isTest
    public static void testDUPCON() {

        Test.startTest();
        
        Case c = new Case();
        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        StarTrack_WebSvcCallouts_Test cont = new StarTrack_WebSvcCallouts_Test(sc);

        // Invoke the continuation by calling the action method
        Continuation conti = cont.DUPCON_test();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_DUPCON());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);
        
        Test.stopTest();

        // result is the return value of the callback
        System.assertEquals(null, result);
    }
    
    @isTest
    public static void testBeginSubscribe() {

        Test.startTest();
        
        Case c = new Case();
        ApexPages.StandardController sc = new ApexPages.StandardController(c);
        StarTrack_WebSvcCallouts_Test cont = new StarTrack_WebSvcCallouts_Test(sc);

        // Invoke the continuation by calling the action method
        Continuation conti = cont.Subscribe_test();

        // Verify that the continuation has the proper requests
        Map<String, HttpRequest> requests = conti.getRequests();
        System.assertEquals(requests.size(), 1);

        // Perform mock callout 
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_subscribe());

        // Set the fake response for the continuation
        String requestLabel = requests.keyset().iterator().next();
        Test.setContinuationResponse(requestLabel, response);

        // Invoke callback method
        Object result = Test.invokeContinuationMethod(cont, conti);
        System.debug(cont);
        
        Test.stopTest();

        // result is the return value of the callback
        System.assertEquals(null, result);
    }    
    
    AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = new AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
    AsyncWwwAuspostComAuSchemaCustomercarema.PublishCDResponse_elementFuture pubCDEmsAsyncResponse;
    AsyncWwwAuspostComAuSchemaCustomercarema.CaseNotificationResponse_elementFuture caseNotifEmsAsyncResponse;
    AsyncWwwAuspostComAuSchemaCustomercarema.DUPCONResponse_elementFuture dupconEmsAsyncResponse;
    AsyncWwwAuspostComAuSchemaCustomercarema.SubscribeResponse_elementFuture subscribeEmsAsyncResponse;
    
    //Publish CD
    public Continuation publishCD_test() {
        
        Continuation cont = new Continuation(1000);
        cont.continuationMethod = 'processPublishCD_test';

        wwwAuspostComAuSchemaCustomercarema.ConsignmentData cdreq = new wwwAuspostComAuSchemaCustomercarema.ConsignmentData();
        pubCDEmsAsyncResponse = emsAsyncStub.beginPublishCD(cont, cdreq);

        return cont;
    }
    
    public Object processPublishCD_test() {
        System.assert(String.valueOf(pubCDEmsAsyncResponse.getValue()) != null);
        return null;
    }
    
    //Case Notifiacation
    public Continuation caseNotification_test() {
        
        Continuation cont = new Continuation(1000);
        cont.continuationMethod = 'processCaseNotification_test';

        wwwAuspostComAuSchemaCustomercarema.CaseNotification cnreq = new wwwAuspostComAuSchemaCustomercarema.CaseNotification();
        caseNotifEmsAsyncResponse = emsAsyncStub.beginCaseNotification(cont, cnreq);

        return cont;
    }
    
    public Object processCaseNotification_test() {
        //caseNotifEmsAsyncResponse.getValue();
        return null;
    }
    
    //DUPCON
    public Continuation DUPCON_test() {
        
        Continuation cont = new Continuation(1000);
        cont.continuationMethod = 'processDUPCON_test';

        dupconEmsAsyncResponse = emsAsyncStub.beginDUPCON(cont, 'System', 'Consignment', 1, 1);

        return cont;
    }
    
    public Object processDUPCON_test() {
        System.assert(String.valueOf(dupconEmsAsyncResponse.getValue()) != null);
        return null;
    }
    
    //Subscribe
    public Continuation Subscribe_test() {
        
        Continuation cont = new Continuation(1000);
        cont.continuationMethod = 'processSubscribe_test';

        wwwAuspostComAuSchemaCustomercarema.SubscribeRequest subsReq = new wwwAuspostComAuSchemaCustomercarema.SubscribeRequest();
        subscribeEmsAsyncResponse = emsAsyncStub.beginSubscribe(cont, subsReq);

        return cont;
    }
    
    public Object processSubscribe_test() {
        System.assert(String.valueOf(subscribeEmsAsyncResponse.getValue()) != null);
        return null;
    }
    
    public StarTrack_WebSvcCallouts_Test(ApexPages.StandardController stdController) {

    }
    
    @isTest
    public static void callUnusedCallouts_publishCD() {
        wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 emsStub = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();

        Test.startTest();
        Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutPubCDMock());
        Boolean success = emsStub.PublishCD(new wwwAuspostComAuSchemaCustomercarema.ConsignmentData());
        Test.stopTest();
    }
    
    @isTest
    public static void callUnusedCallouts_DUPCON() {
        wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 emsStub = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();

        Test.startTest();
        Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutDUPCONMock());
        wwwAuspostComAuSchemaCustomercarema.DUPCON_Data dupdata = emsStub.DUPCON('','',1,1);
        Test.stopTest();
    }
    
    @isTest
    public static void callUnusedCallouts_Subscribe() {
        wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 emsStub = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
        Test.startTest();
        Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutSubscribeMock ());
        wwwAuspostComAuSchemaCustomercarema.SubscribeResponse subsResp = emsStub.Subscribe(new wwwAuspostComAuSchemaCustomercarema.SubscribeRequest());
        Test.stopTest();
    }
}