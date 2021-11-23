@isTest
public class wwwAuspostComAuSchemaCustomercaremaMock implements WebServiceMock {
		public void doInvoke(
			Object stub,
			Object request,
			Map<String, Object> response,
			String endpoint,
			String soapAction,
			String requestName,
			String responseNS,
			String responseName,
			String responseType) {
       
		System.debug(LoggingLevel.INFO, 'wwwAuspostComAuSchemaCustomercarMockImpl.doInvoke() - ' +
			'\n request: ' + request +
			'\n response: ' + response +
			'\n endpoint: ' + endpoint +
			'\n soapAction: ' + soapAction +
			'\n requestName: ' + requestName +
			'\n responseNS: ' + responseNS +
			'\n responseName: ' + responseName +
			'\n responseType: ' + responseType);

		if(request instanceOf wwwAuspostComAuSchemaCustomercarema.CaseNotification) {
			response.put( 'response_x', new wwwAuspostComAuSchemaCustomercarema.CaseNotificationResponse_element());
		}
		else if(request instanceOf wwwAuspostComAuSchemaCustomercarema.DUPCON_element) {
			response.put( 'response_x', new wwwAuspostComAuSchemaCustomercarema.DUPCONResponse_element());
		}
		else if(request instanceOf wwwAuspostComAuSchemaCustomercarema.PrivateSOAP_Publish_element) {
			response.put( 'response_x', new wwwAuspostComAuSchemaCustomercarema.PrivateSOAP_PublishResponse_element());
		}
		else if(request instanceOf wwwAuspostComAuSchemaCustomercarema.PublishCD_element) {
			response.put( 'response_x', new wwwAuspostComAuSchemaCustomercarema.PublishCDResponse_element());
		}
		else if(request instanceOf wwwAuspostComAuSchemaCustomercarema.Search_element) {
			response.put( 'response_x', new wwwAuspostComAuSchemaCustomercarema.SearchResponse_element());
		}
		else if(request instanceOf wwwAuspostComAuSchemaCustomercarema.SearchFull_element) {
			response.put( 'response_x', new wwwAuspostComAuSchemaCustomercarema.SearchFullResponse_element());
		}
		else if(request instanceOf wwwAuspostComAuSchemaCustomercarema.Subscribe_element) {
			response.put( 'response_x', new wwwAuspostComAuSchemaCustomercarema.SubscribeResponse_element());
		}
	}
}