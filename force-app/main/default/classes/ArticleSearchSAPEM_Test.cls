@isTest
public class ArticleSearchSAPEM_Test {
    
    @isTest static void testInvokeContinuation(){
        List<String> articleIds = new List<String>{'JDQ021778901000910903'};
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new webServiceMockResponse());
        Continuation conti =  (Continuation)AsynchApexContinuationController.invoke('ArticleSearchSAPEM','searchArticle',articleIds,true);
        Map<String, HttpRequest> requests = conti.getRequests();
        String requestLabel = requests.keyset().iterator().next();
        
        ArticleSearchSAPEM.infoState sInfo = new ArticleSearchSAPEM.infoState();
        sInfo.articleId = 'JDQ021778901000910903';
        sInfo.className = 'ArticleSearchSAPEM';
        AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture emsAsyncResponse = new AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture();

        sInfo.apiState = emsAsyncResponse;
        object rtnObj = AsynchApexContinuationController.soapCallback(sInfo);
        System.assert(rtnObj != null,'Error returning API payload' );
		Test.stopTest();
    }
    
    public class webServiceMockResponse implements HttpCalloutMock{
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"userTokenx":"userToken"}');
            return res;
        }
    }

}