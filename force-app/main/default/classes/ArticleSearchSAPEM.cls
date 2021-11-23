/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  :  Make API collouts to SAPEM. Called by AsynchApexContinuationController.
                     Objects for this class are dynamically created, use test class to test :  AsynchApexContinuationController_Test

--------------------------------------- History --------------------------------------------------
05.04.2019    Sameed Khan(Mav3rik)    Created
**/
public with sharing class ArticleSearchSAPEM implements IAsynchApexContinuationSOAP {
    
    /**
    * Set API configuration
    *
    * @param HttpRequest set values in request object
    * @param methodName name of method to execute or this can be  a placeholed used within if statement to execute code
    * @param params array of params used by function methodName
    *
    */
    public void setHTTPRequest(HttpRequest req,string methodName, string[] params){}

    /**
    * Format the API response
    *
    * @param httpResp Value sent by API
    *
    */
    public Object parseResponse(HttpResponse httpResp ){return null;}

    /**
    * Call the continuation object
    *
    * @param cont Set continuation object
    * @param methodName Used in IF statements of function to call method by that name
    * @param params Parameters for method
    */
    public Void invokeContinuation(Continuation cont, string methodName, string[] params ){
        if(  methodName == 'searchArticle' ){
            if(params != null && params.size() > 0){
                this.searchArticle(cont,params[0]);
            } else {
                // return error nothing to search
            }
        }
    }

    /**
    * Callback of Continuation
    *
    * @param State Continuation State object
    */
    public Object continuationMethod(Object state){
        infoState infSt = (infoState )state;
        ReturnObj rtnObj = new ReturnObj();
        rtnObj.articleId = infSt.articleId;
        rtnObj.payload = '';
        //process callout response
        List<Article__c> articleList = new List<Article__c>();
        AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture trackResults;
        TIBCOSearchResult result = new TIBCOSearchResult();
        trackResults = (AsyncAuspostQueryTrackEventsSchema.QueryTrackEventsResponse_elementFuture) infSt.apiState;

        try {
            if(BspConstants.SUCCESS.equals(trackResults.getValue().TrackingResult[0].ResultDescription)){ //Validate if the response result description is a SUCCESS.
                for(AuspostQueryTrackEventsSchema.TrackingResults tr : trackResults.getValue().TrackingResult){
                    result.trackResults.add(new TIBCOTrackingResultWrapper(tr));
                }
            }
            rtnObj.payload = result;
        } catch(exception  ex){
            result.success = false;
            result.errors.add(ex.getMessage());
            rtnObj.payload = result;
        }
        return rtnObj;
    }

    /**
    * Set continuation timeout
    *
    */
    public Integer getTimeOut(){
        return 120;
    }

    /**
    * Call Article Search API
    *
    * @param cont Continuation object
    * @param articleId Article no to search for
    */
    public void searchArticle(Continuation cont, String articleId){
        AsyncAuspostTrackEventService.AsyncEventManagement_v1Endpoint1 service = new AsyncAuspostTrackEventService.AsyncEventManagement_v1Endpoint1();
        service.endpoint_x = TIBCOArticleService.TIBCO_ENDPOINT;
        service.Header = new AuspostCommonSchema.InterfaceHeader();
        service.Header.InterfaceName = 'queryArticle';
        service.Header.InterfaceVersion = '1.0';
        service.Header.MessageType = 'Request';
        service.Header.SourceSystemID = 'SFDC';
        service.Header.SourceInformation = '';
        service.Header.Timestamp = System.now();
        service.Header.BusinessReferenceID = articleId;
        Map<String, String> httpHeaders = new Map<String, String>();
        httpHeaders.put('Content-Type', 'application/soap+xml');
        httpHeaders.put('SOAPAction', '/Services/EventManagement_TrackEvent/EventManagement/querySalesforce_TrackEvents_v1');
        service.inputHttpHeaders_x = httpHeaders;

        infoState infSt = new infoState();
        infSt.articleId = articleId;
        infSt.apiState = service.beginQueryTrackEvents_v1(cont, new List<String>{articleId}, 'NAMED_USER'); //Execute the callout request.
        infSt.className = 'ArticleSearchSAPEM';
        infSt.methodName = 'continuationMethod';
        cont.state = infSt;
    }

    /**
    * Wrapper class for continuation state object
    *
    * @param cont Continuation object
    * @param articleId article no to search for
    */
    public class infoState {
        public string articleId {get; set;}
        public string className {get; set;}
        public string methodName {get; set;}
        public object apiState {get; set;}
    }

    /**
    * Wrapper class for return of continuation
    *
    */
    public class ReturnObj {
        public string articleId {get; set;}
        public object payload {get; set;}
    }
}