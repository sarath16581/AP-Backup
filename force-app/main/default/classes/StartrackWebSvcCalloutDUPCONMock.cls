@isTest
global class StartrackWebSvcCalloutDUPCONMock implements WebServiceMock {
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

        wwwAuspostComAuSchemaCustomercarema.DUPCONResponse_element response_x = new wwwAuspostComAuSchemaCustomercarema.DUPCONResponse_element();
        response_x.DUPCONResult = new wwwAuspostComAuSchemaCustomercarema.DUPCON_Data();
        response.put('response_x', response_x);
   }
}