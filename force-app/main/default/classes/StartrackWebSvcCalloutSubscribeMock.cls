@isTest
global class StartrackWebSvcCalloutSubscribeMock implements WebServiceMock {
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

        wwwAuspostComAuSchemaCustomercarema.SubscribeResponse_element response_x = new wwwAuspostComAuSchemaCustomercarema.SubscribeResponse_element();
        response_x.SubscribeResult = new wwwAuspostComAuSchemaCustomercarema.SubscribeResponse();
        response.put('response_x', response_x);
   }
}