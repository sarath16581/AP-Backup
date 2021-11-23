/**************************************************
Description:    Interface for SOAP web services;  Dynamically called in AsynchApexContinuationController

History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

public interface  IAsynchApexContinuationSOAP {
    void setHTTPRequest(HttpRequest req,string methodName, string[] params);
    Object parseResponse(HttpResponse httpResp );
    Void invokeContinuation(Continuation con, string methodname,String[] params);
    Object continuationMethod(Object state);
    Integer getTimeOut();
}