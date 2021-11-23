/**************************************************
Description:    Interface for REST web services;  Dynamically called in AsynchApexContinuationController

History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

public interface  IAsynchApexContinuationREST {
    void setHTTPRequest(HttpRequest req,string classNameStr, String methodName, String[] params);
    Integer getTimeOut();
    Object parseResponse(HttpResponse httpResp );
}