@isTest
global class StartrackWebSvcCalloutMockEx implements WebServiceMock {
    global String errorMessage {get; set;}
    global Boolean isDml {get; set;}
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
        if (isDml) {
          DmlException e = (DmlException)DmlException.class.newInstance();
          throw e;        
        }
        CalloutException e = (CalloutException)CalloutException.class.newInstance();
        e.setMessage(errorMessage);
        throw e;        
    }
}