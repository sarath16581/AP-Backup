@isTest
global class StartrackWebSvcCalloutMockEx_TimeOut implements WebServiceMock {
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
        CalloutException e = (CalloutException)CalloutException.class.newInstance();
        e.setMessage('Time out');
        throw e;        
   }
}