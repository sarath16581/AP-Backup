/*------------------------------------------------------------
Author:        Dion Gunn (dion.gunn@auspost.com.au)
Description:   Coverage for the Auspost Cusomer Care schema wwwAuspostComAuSchemaCustomercarema,
				microsoftComWsdlTypes,schemasDatacontractOrg200407Emsequi,schemasXmlsoapOrgSoapEnvelope,
				AsyncWwwAuspostComAuSchemaCustomercarema and schemasMicrosoftCom200310Serializat
History
31-02-2017 - Dion Gunn - Created
------------------------------------------------------------*/

/*	DG 28/08/17 - This test class is designed just to create coverage for the stubs, NOT to test any business logic.
	This was done as the schema includes objects not yet being used in Salesforce. Hopefully this makes it easier
	to manage schema updates in the future without having to butcher the generated stubs file.
*/

@isTest
private class wwwAuspostComAuSchemaCustomercaremaTest {
	
    //Synchronous
	@isTest static void coverGeneratedCodeTypes() {
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		wwwAuspostComAuSchemaCustomercarema parentObject = new wwwAuspostComAuSchemaCustomercarema();
		new schemasDatacontractOrg200407Emsequi.fault();
		new schemasXmlsoapOrgSoapEnvelope.Body();
		new schemasXmlsoapOrgSoapEnvelope.Envelope();
		new schemasXmlsoapOrgSoapEnvelope.Header();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfArticleType();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfAttachmentType();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfBBGEN7Jobs_DataDetail();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfBBGEN7Packages_DataDetail();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfBookinNoteType();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfDUPCON_DataDetail();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfEventType();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfProcessFunctions();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfProofOfDeliveryType();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfString();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfSubDocketType();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfThreadFunctions();
		new wwwAuspostComAuSchemaCustomercarema.ArrayOfThreadProcessData();
		new wwwAuspostComAuSchemaCustomercarema.ArticleType();
		new wwwAuspostComAuSchemaCustomercarema.AttachmentType();
		new wwwAuspostComAuSchemaCustomercarema.BBGEN7Jobs_Data();
		new wwwAuspostComAuSchemaCustomercarema.BBGEN7Jobs_DataDetail();
		new wwwAuspostComAuSchemaCustomercarema.BBGEN7Packages_Data();
		new wwwAuspostComAuSchemaCustomercarema.BBGEN7Packages_DataDetail();
		new wwwAuspostComAuSchemaCustomercarema.BookinNoteType();
		new wwwAuspostComAuSchemaCustomercarema.CaseNotification();
		new wwwAuspostComAuSchemaCustomercarema.CaseNotificationResponse_element();
		new wwwAuspostComAuSchemaCustomercarema.ConsignmentData();
		new wwwAuspostComAuSchemaCustomercarema.ConsignmentType();
		new wwwAuspostComAuSchemaCustomercarema.DUPCON_Data();
		new wwwAuspostComAuSchemaCustomercarema.DUPCON_DataDetail();
		new wwwAuspostComAuSchemaCustomercarema.DUPCON_element();
		new wwwAuspostComAuSchemaCustomercarema.DUPCONResponse_element();
		new wwwAuspostComAuSchemaCustomercarema.EventType();
		new wwwAuspostComAuSchemaCustomercarema.Header();
		new wwwAuspostComAuSchemaCustomercarema.PerformanceMetrics();
		new wwwAuspostComAuSchemaCustomercarema.PrivateSOAP_Publish_element();
		new wwwAuspostComAuSchemaCustomercarema.PrivateSOAP_PublishResponse_element();
		new wwwAuspostComAuSchemaCustomercarema.ProcessFunctions();
		new wwwAuspostComAuSchemaCustomercarema.ProofOfDeliveryType();
		new wwwAuspostComAuSchemaCustomercarema.PublishCD_element();
		new wwwAuspostComAuSchemaCustomercarema.PublishCDResponse_element();
		new wwwAuspostComAuSchemaCustomercarema.ResponseMetrics();
		new wwwAuspostComAuSchemaCustomercarema.Search_element();
		new wwwAuspostComAuSchemaCustomercarema.SearchFull_element();
		new wwwAuspostComAuSchemaCustomercarema.SearchFullResponse_element();
		new wwwAuspostComAuSchemaCustomercarema.SearchRequest();
		new wwwAuspostComAuSchemaCustomercarema.SearchResponse();
		new wwwAuspostComAuSchemaCustomercarema.SubDocketType();
		new wwwAuspostComAuSchemaCustomercarema.Subscribe_element();
		new wwwAuspostComAuSchemaCustomercarema.SubscribeRequest();
		new wwwAuspostComAuSchemaCustomercarema.SubscribeResponse();
		new wwwAuspostComAuSchemaCustomercarema.ThreadFunctions();
		new wwwAuspostComAuSchemaCustomercarema.ThreadProcessData();
        new AsyncwwwAuspostComAuSchemaCustomercarema.SearchFullResponse_elementFuture();
        new AsyncwwwAuspostComAuSchemaCustomercarema.SearchResponse_elementFuture();
        new AsyncwwwAuspostComAuSchemaCustomercarema.PublishCDResponse_elementFuture();
        new AsyncwwwAuspostComAuSchemaCustomercarema.CaseNotificationResponse_elementFuture();
        new AsyncwwwAuspostComAuSchemaCustomercarema.DUPCONResponse_elementFuture();
        new AsyncwwwAuspostComAuSchemaCustomercarema.PrivateSOAP_PublishResponse_elementFuture();
        new AsyncwwwAuspostComAuSchemaCustomercarema.SubscribeResponse_elementFuture();
		new schemasMicrosoftCom200310Serializat();
		new microsoftComWsdlTypes();
	}
    
    //Synchronous
	@isTest static void coverCodeForCaseNotification(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 testObject = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
		testObject.CaseNotification(null);
	}
	@isTest static void coverCodeForDUPCON(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 testObject = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
		System.assertEquals(null, testObject.DUPCON(null, null, null, null));
	}
	@isTest static void coverCodeForPrivateSOAP_Publish(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 testObject = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
		System.assertEquals(null, testObject.PrivateSOAP_Publish(null, null));
	}
	@isTest static void coverCodeForPublishCD(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 testObject = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
		System.assertEquals(null, testObject.PublishCD(null));
	}
	@isTest static void coverCodeForSearch_x(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 testObject = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
		System.assertEquals(null, testObject.Search_x(null));
	} 
	@isTest static void coverCodeForSearchFull(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 testObject = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
		System.assertEquals(null, testObject.SearchFull(null, null));
	}
	@isTest static void coverCodeForSubscribe(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2 testObject = new wwwAuspostComAuSchemaCustomercarema.BasicHttpBinding_IEMS2();
		System.assertEquals(null, testObject.Subscribe(null));
	}
    
    //Asynchronous
    @isTest static void coverCodeForCaseNotificationAsync(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 testObject = new AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
		testObject.beginCaseNotification(new Continuation(30),null);
	}
    @isTest static void coverCodeForDUPCONAsync(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 testObject = new AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
    	testObject.beginDUPCON(new Continuation(30),null, null, null, null);
	}
    @isTest static void coverCodeForPrivateSOAP_PublishAsync(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 testObject = new AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
    	testObject.beginPrivateSOAP_Publish(new Continuation(30),null, null);
	}
    	@isTest static void coverCodeForPublishCDAsync(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 testObject = new AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
        testObject.beginPublishCD(new Continuation(30),null);
	}
	@isTest static void coverCodeForSearch_xAsync(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 testObject = new AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
    	testObject.beginSearch_x(new Continuation(30),null);
	} 
	@isTest static void coverCodeForSearchFullAsync(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 testObject = new AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
        testObject.beginSearchFull(new Continuation(30),null, null);
	}
	@isTest static void coverCodeForSubscribeAsync(){
		Test.setMock(WebServiceMock.class, new wwwAuspostComAuSchemaCustomercaremaMock());
		AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2 testObject = new AsyncwwwAuspostComAuSchemaCustomercarema.AsyncBasicHttpBinding_IEMS2();
        testObject.beginSubscribe(new Continuation(30),null);
	}
}