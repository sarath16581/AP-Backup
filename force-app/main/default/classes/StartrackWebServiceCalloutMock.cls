/**
 * Created by hasan on 11/12/2022.
 */
@isTest
global class StartrackWebServiceCalloutMock implements WebServiceMock {
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

        wwwAuspostComAuSchemaCustomercarema.SearchResponse_element response_x = new wwwAuspostComAuSchemaCustomercarema.SearchResponse_element();
        wwwAuspostComAuSchemaCustomercarema.ConsignmentData consignmentData = new wwwAuspostComAuSchemaCustomercarema.ConsignmentData();
        wwwAuspostComAuSchemaCustomercarema.ConsignmentType consignment = new wwwAuspostComAuSchemaCustomercarema.ConsignmentType();
        consignment.ConsignmentID = 'TM2_OSTZ00000275_0000';
        consignment.BillingAccount = 'T90001510';
        consignment.Network = 'MEL';
        consignment.ExpectedDeliveryDate = Datetime.newInstance(2022, 11, 04).date();
        consignment.ActualWeight = 12;
        consignment.BarcodeNumber = 'barcode324';
        consignment.ControlledReturn = false;
        consignment.Cubing = 'cubing';
        consignment.DangerousGoods = false;
        consignment.DeliveryInstructions = 'DeliveryInstructions';
        consignment.DispatchDate = Datetime.newInstance(2022, 11, 03);
        consignment.DispatchID = 'OST';
        consignment.InsuranceAmount = 12.1;
        //consignment.InsuranceRequired = true;
        consignment.LastScanEvent = Datetime.newInstance(2016, 5, 17);
        consignment.ConsignmentNumber = 'OSTZ00000275';
        consignment.NumberofItems = 2;
        consignment.DoesithavePOD = false;
        consignment.ReceiverPhone = '1231';
        //consignment.ReceiverCity = 'city';
        consignment.ReceiverAddress = 'address';
        consignment.ReceiverAddressLine1 = 'test message';
        consignment.ReceiverAddressLine2 = 'test message';
        consignment.ReceiverAddressLine3 = 'test message';
        consignment.ReceiverAddressLine4 = 'test message';
        consignment.ReceiverCompany = 'test message';
        consignment.ReceiverCountry = 'test message';
        consignment.ReceiverEmail = 'test message';
        consignment.ReceiverName = 'test message';
        consignment.ReceiverPostcode = 'test message';
        consignment.ReceiverState = 'test message';
        //consignment.SenderCity = 'test message';
        consignment.SenderAddress = 'test message';
        consignment.SenderAddressLine1 = 'test message';
        consignment.SenderAddressLine2 = 'test message';
        consignment.SenderAddressLine3 = 'test message';
        consignment.SenderAddressLine4 = 'test message';
        consignment.SenderCompany = 'test message';
        consignment.SenderCountry = 'test message';
        consignment.SenderEmail = 'test message';
        consignment.SenderName = 'test message';
        consignment.SenderPostcode = 'test message';
        consignment.SenderState = 'test message';
        //consignment.ServiceType = 'test message';
        consignment.ServiceCode = 'test message';
        consignment.SubdocketNumber = 'test message';
        consignment.UnitType = 'test message';
        consignment.CID = '20160101';
        //consignment.LogicalName = new schemasDatacontractOrg200407System.Type_x();

        List<wwwAuspostComAuSchemaCustomercarema.EventType> eventList = new List<wwwAuspostComAuSchemaCustomercarema.EventType>();
        wwwAuspostComAuSchemaCustomercarema.ArrayOfEventType arrOfEvent = new wwwAuspostComAuSchemaCustomercarema.ArrayOfEventType();
        wwwAuspostComAuSchemaCustomercarema.EventType ev = new wwwAuspostComAuSchemaCustomercarema.EventType();
        ev.EventCompletionTime = DateTime.newInstance(2016, 6, 6);
        ev.EventID = 'TM1_EVENT_OSTZ00000275_0000_OSTZ00000275EXP00001_20221103115407';
        ev.EventSource = 'S';
        ev.EventDescription = 'Advanced shipping notice received from Sender';
        ev.EventTypeCode = 'A';
        ev.SourceSystem = 'SAPEM';
        ev.ActualDateTime =  DateTime.newInstance(2022, 11, 03);
        ev.DisplayExt = true;
        ev.ExtDesc = 'Advanced shipping notice received from Sender';
        eventList.add(ev);
        arrOfEvent.Event = eventList;

        List<wwwAuspostComAuSchemaCustomercarema.ArticleType> articleList = new List<wwwAuspostComAuSchemaCustomercarema.ArticleType>();
        wwwAuspostComAuSchemaCustomercarema.ArrayOfArticleType arrOfArticle = new wwwAuspostComAuSchemaCustomercarema.ArrayOfArticleType();
        wwwAuspostComAuSchemaCustomercarema.ArticleType article = new wwwAuspostComAuSchemaCustomercarema.ArticleType();
        article.Events = arrOfEvent;
        article.SourceSystem = 'TEAM';
        article.ArticleID = 'TM1_OSTZ00000275_0000_OSTZ00000275EXP00001';
        article.ArticleNumber = 'OSTZ00000275EXP00001';
        articleList.add(article);
        arrOfArticle.Article = articleList;
        //consignment.Articles = arrOfArticle;

        //consignment.Events = arrOfEvent;

        consignmentData.Consignment = consignment;
        wwwAuspostComAuSchemaCustomercarema.ResponseMetrics respMetrics = new wwwAuspostComAuSchemaCustomercarema.ResponseMetrics();
        respMetrics.Performance =  new wwwAuspostComAuSchemaCustomercarema.PerformanceMetrics();
        consignmentData.ResponseMetrics = respMetrics;
        ConsignmentData.Header = new wwwAuspostComAuSchemaCustomercarema.Header();
        consignmentData.Header.NbrOfRows = 1;
        response_x.SearchResult = consignmentData;

        response.put('response_x', response_x);
    }

}