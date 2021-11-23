/**************************************************
Description:    Make API collouts. Called by AsynchApexContinuationController
                Objects for this class are dynamically created, use test class to test :  AsynchApexContinuationController_Test
History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

public with sharing class ImageConsignmentSearch implements IAsynchApexContinuationSOAP {
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
        //V6900063
        if(  methodName == 'searchConsignment' ){
            if(params != null && params.size() > 0){
                this.searchConsignment(cont,params[0]);
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
        rtnObj.consignmentNumber = infSt.consignmentNumber;
        rtnObj.payload = '';
        //process callout response
        List<Article__c> articleList = new List<Article__c>();
        try {
            AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture emsAsyncResponse = (AsyncWwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture)infSt.apiState;
            wwwAuspostComAuSchemaCustomercarema.ConsignmentData emsResponse =  emsAsyncResponse.getValue();
            StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrapper = StarTrackConsignmentSearchUtil.processResponse(emsResponse, false);
            if(!conWrapper.articleList.isEmpty()) {
                rtnObj.payload = conWrapper;
            } else {
                string sError = 'Did not find a consignment result from processSearchConsignment';
                sError = conWrapper.errorCode;
                conWrapper.errorCode =  sError;
                rtnObj.payload = conWrapper;
            }
        } catch(exception  ex){

            StarTrackConsignmentSearchUtil.ConsignmentWrapper conWrapper = new StarTrackConsignmentSearchUtil.ConsignmentWrapper(false,ex.getMessage(),articleList);
            rtnObj.payload = conWrapper;
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
    * Call Search consignment API
    *
    * @param cont Continuation object
    * @param consignmentNumber Consignment no to search for
    */
    public void searchConsignment(Continuation cont,String consignmentNumber){
        wwwAuspostComAuSchemaCustomercarema.SearchRequest request = StarTrackConsignmentSearchUtil.generateSearchRequest(consignmentNumber, StarTrack_Constants.TYPE_CONSIGNMENT, StarTrack_Constants.REQUEST_ACTION_FULL);
        AsyncWwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 emsAsyncStub = StarTrackConsignmentSearchUtil.generateAsyncStub();
        infoState infSt = new infoState();
        infSt.consignmentNumber = consignmentNumber;
        infSt.apiState = emsAsyncStub.beginSearch_x(cont, request);
        infSt.className = 'ImageConsignmentSearch';
        infSt.methodName = 'continuationMethod';
        cont.state = infSt;
    }

    /**
    * Wrapper class for continuation state object
    *
    * @param cont Continuation object
    * @param consignmentNumber Consignment no to search for
    */
    public class infoState {
        public string consignmentNumber {get; set;}
        public string className {get; set;}
        public string methodName {get; set;}
        public object apiState {get; set;}
    }

    /**
    * Wrapper class for return of continuation
    *
    */
    public class ReturnObj {
        public string consignmentNumber {get; set;}
        public object payload {get; set;}
    }
}