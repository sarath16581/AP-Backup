@isTest
global class StartrackWebSvcCalloutPubCDMock implements WebServiceMock {
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

        wwwAuspostComAuSchemaCustomercarema.PublishCDResponse_element response_x = new wwwAuspostComAuSchemaCustomercarema.PublishCDResponse_element();
        response_x.PublishCDResult = true;        
        response.put('response_x', response_x);
   }
}