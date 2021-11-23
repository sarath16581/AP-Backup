/**************************************************
Description:    Test class to test AsynchApexContinuationController class

History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

@IsTest
private class AsynchApexContinuationController_Test {
    @testSetup static void  setData(){
        list<AusPostSettings__c> settingLst = new list<AusPostSettings__c>();
        AusPostSettings__c setting = new AusPostSettings__c(
                URL__c = 'http://',
                Username__c = '',
                Password__c = '',
                IsActive__c = true,
                Name = 'UnsortableAPI'
        );
        settingLst.add(setting);

        insert settingLst;
    }

    @isTest static void testGetVFBaseURL() {
        AsynchApexContinuationController.URLConfig url = AsynchApexContinuationController.getVFBaseURL();
        system.assert(!String.isBlank(url.baseURL), 'No Base url returned ');
    }

    @isTest static void testGetContinuationError(){
        string sErr = AsynchApexContinuationController.getContinuationError(1);
        system.assert(sErr.contains(': An error occurred.'), 'Invalid Error returned');

        string sErr1 = AsynchApexContinuationController.getContinuationError(2002);
        system.assert(sErr1 == 'Exceptions occurred.' , 'Invalid Error returned');

        AsynchApexContinuationController.statInfo sInfObj = new AsynchApexContinuationController.statInfo();
        sInfObj.continuationId = '1';
        sInfObj.className = 'cls';
        sInfObj.obj = 'test';
        sInfObj.params = new list<String>{'1','2','3'};

        AsynchApexContinuationController.ReturnObj rtn = new AsynchApexContinuationController.ReturnObj();
        rtn.errorList =  new list<String>{'1'} ;
        rtn.className = 'cls';
        rtn.payload = 'new';
        rtn.params = new list<String>{'1','2','3'};

    }

    @isTest static void testInvokeRestContinuation(){
        list<string> sLst  = new list<String>{'Img'};

        Test.startTest();
        Continuation conti =  (Continuation)AsynchApexContinuationController.invoke('ImageUnsortable','getImage',sLst,true);
        Map<String, HttpRequest> requests = conti.getRequests();
        String requestLabel = requests.keyset().iterator().next();
        HttpResponse response = new HttpResponse();
        response.setBody('{ "document":{ "object_id":"Image.jpg", "bucket_name":"ap-test-usf-cwc-imagecapture", "object_details":{ "object_content":"image content" } } }');
        Test.setContinuationResponse(requestLabel, response);
        AsynchApexContinuationController.statInfo sInfo = new AsynchApexContinuationController.statInfo();
        sInfo.continuationId = requestLabel;
        sInfo.classname = 'ImageUnsortable';
        sInfo.params = sLst;
        object rtnObj = AsynchApexContinuationController.restCallback(sInfo);
        System.assert(rtnObj != null,'Error returning API payload' );
        test.stopTest();

    }

    @isTest static void testInvokeRestContinuationError(){
        list<string> sLst  = new list<String>{'Img'};

        Test.startTest();
        Continuation conti =  (Continuation)AsynchApexContinuationController.invoke('ImageUnsortable','getImage',sLst,true);
        Map<String, HttpRequest> requests = conti.getRequests();
        String requestLabel = requests.keyset().iterator().next();
        HttpResponse response = new HttpResponse();
        response.setBody('{ "document":{ "error":[ { "code":"AS-9007", "name":"A document not found with this criteria.", "message":"{\n \"Error\":{\n \"Code\":\"NoSuchKey\",\n \"Message\":\"The specified key does not exist.\",\n \"Key\":\"keyfile.JPG\",\n \"RequestId\":\"1234\",\n \"HostId\":\"gTpYM=1\"\n }\n}" } ] } }');
        Test.setContinuationResponse(requestLabel, response);
        AsynchApexContinuationController.statInfo sInfo = new AsynchApexContinuationController.statInfo();
        sInfo.continuationId = requestLabel;
        sInfo.classname = 'ImageUnsortable';
        sInfo.params = sLst;
        object rtnObj = AsynchApexContinuationController.restCallback(sInfo);
        System.assert(rtnObj != null,'Error returning API payload' );
        test.stopTest();

    }

    @isTest static void testInvokeSoapContinuation(){
        list<string> sLst  = new list<String>{'connote1'};

        Test.startTest();
        AsynchApexContinuationController controller = new AsynchApexContinuationController();
        Continuation conti =  (Continuation)AsynchApexContinuationController.invoke('ImageConsignmentSearch','searchConsignment',sLst,true);
        Map<String, HttpRequest> requests = conti.getRequests();
        String requestLabel = requests.keyset().iterator().next();
        HttpResponse response = new HttpResponse();
        response.setBody(StarTrackContinuationCalloutMock.getResponse_singleConsign());
        Test.setContinuationResponse(requestLabel, response);

        ImageConsignmentSearch.infoState sInfo = new ImageConsignmentSearch.infoState();
        sInfo.consignmentNumber = 'connote1';
        sInfo.className = 'ImageConsignmentSearch';
        AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse = new AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture();

        sInfo.apiState = emsAsyncResponse;
        object rtnObj = AsynchApexContinuationController.soapCallback(sInfo);

        System.assert(rtnObj != null,'Error returning API payload' );
        test.stopTest();

        ImageConsignmentSearch imgSrch = new ImageConsignmentSearch();
        HttpRequest req = new HttpRequest();
        list<String> strLst = new list<String>{'1'};
        imgSrch.setHTTPRequest(req, 'test',strLst);
        HttpResponse httpResp = new HttpResponse();
        Object objTmp = imgSrch.parseResponse(httpResp);
    }

    @isTest static void testInvokeSoap(){
        list<string> sLst  = new list<String>{'connote1'};
        AsynchApexContinuationController cont = new AsynchApexContinuationController();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new restMock());
        object rtnObj = AsynchApexContinuationController.invoke('ImageUnsortable','getImage',sLst,false);
        System.assert(rtnObj != null,'Error returning API payload' );
        test.stopTest();

    }

    public class restMock implements  HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setBody('{ "document":{ "object_id":"Image.jpg", "bucket_name":"ap-test-usf-cwc-imagecapture", "object_details":{ "object_content":"image content" } } }');
            return response;
        }

    }

}