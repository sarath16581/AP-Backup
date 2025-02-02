/***
 * @author George Nguyen
 * @date 2022-07-11
 * @domain Core
 * @description Test class for ICPSService service
 * @changelog
 * 2022-07-11 - George Nguyen - Created
 */
@IsTest
 class ICPSService_Test {
    
    /*
    * This test method will test that the correct request body is generated by capturing request in the Mock class and then ensures the output is compared to the expected output. 
    */
    @IsTest
    static void retrieveBase64Labels() {
        insert new AusPostSettings__c(
            Name = 'ICPS',
            URL__c = 'https://callout:LAYER7_CERT/lps/labelPrintingService'
        );

		ICPS__c tempRecord = ICPSTestDataFactory.getICPS(1, false)[0];
        tempRecord = (ICPS__c)ApplicationTestDataFactory.setUnwritableFields(tempRecord, new Map<String, Object>{'Name' => 'test', 'NumberofArticles__c' => 2, 'StoreLocationReporting__c' => 'somewhere'});

        ICPSLabelPrintingHttpCalloutMock mock = new ICPSLabelPrintingHttpCalloutMock();
        mock.recordToCheckInRequest = tempRecord; // to check the Request body. 
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        String actual = ICPSService.getInstance().retrieveBase64Labels(tempRecord, 'test@test.com');
        Test.stopTest();

        String expected = EncodingUtil.base64Encode(Blob.valueOf('second part of multipart response'));
        System.assertEquals(expected, actual, 'the output of the method retrieveBase64Labels should be returned in the correct format');
    }

    class ICPSLabelPrintingHttpCalloutMock implements HttpCalloutMock {

        public ICPS__c recordToCheckInRequest {get;set;}

        public HTTPResponse respond(HTTPRequest req) {
            ICPSSettings__mdt icpsSettings = ICPSSettings__mdt.getInstance('ICPS_Settings');

            String body = req.getBody();
            System.assert(body.contains('<RequestType>' + icpsSettings.ServiceHeaderRequestType__c + '</RequestType>'), 'the request should contain this');
            System.assert(body.contains('<LabelMessage>' + icpsSettings.ServiceHeaderLabelMessage__c + '</LabelMessage>'), 'the request should contain this');
            System.assert(body.contains('<TemplateName>' + icpsSettings.LabelTypeTemplateName__c + '</TemplateName>'), 'the request should contain this');
            System.assert(body.contains('<IcpsLabelIndex>1</IcpsLabelIndex>'), 'the request should contain this');
            System.assert(body.contains('<IcpsLabelIndex>2</IcpsLabelIndex>'), 'the request should contain this');
            System.assert(body.contains('<IcpsLabelCount>' + recordToCheckInRequest.NumberofArticles__c.intValue() + '</IcpsLabelCount>'), 'the request should contain this');
            System.assert(body.contains('<RecordReferenceNumber>' + recordToCheckInRequest.Name + '</RecordReferenceNumber>'), 'the request should contain this');
            System.assert(body.contains('<Barcode>' + recordToCheckInRequest.Name + '</Barcode>'), 'the request should contain this');
            System.assert(body.contains('<Layout>' + icpsSettings.GroupTypeLayout__c + '</Layout>'), 'the request should contain this');
            System.assert(body.contains('<LeftOffset>' + icpsSettings.GroupTypeLeftOffset__c.setScale(1) + '</LeftOffset>'), 'the request should contain this');
            System.assert(body.contains('<TopOffset>' + icpsSettings.GroupTypeTopOffset__c.setScale(1) + '</TopOffset>'), 'the request should contain this');
            System.assert(body.contains('<StoredLocation>' + recordToCheckInRequest.StoreLocationReporting__c + '</StoredLocation>'), 'the request should contain this');
            System.assert(body.contains('<BusinessReferenceID>' + recordToCheckInRequest.Name + '</BusinessReferenceID>'), 'the request should contain this');

            String mockResponse = '--uuid:1xxxxxxxxxxx2first part of multipart response--uuid:1xxxxxxxxxxx2second part of multipart response';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'multipart/related; type="application/xop+xml"; boundary="uuid:1xxxxxxxxxxx2";');
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }
}