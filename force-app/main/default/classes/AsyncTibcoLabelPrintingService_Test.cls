/***
 * @author George Nguyen
 * @date 2022-07-11
 * @domain Core
 * @description Test class for AsyncTibcoLabelPrintingService (auto-gemerated)
 * @changelog
 * 2022-07-11 - George Nguyen - Created
 */
@IsTest
class AsyncTibcoLabelPrintingService_Test {
    @IsTest
    static void webserviceInvoke() {
        
        TibcoLabelPrintingService.GetRequestType generate = new TibcoLabelPrintingService.GetRequestType();

        generate.InterfaceHeader = new TibcoLabelPrintingService.InterfaceHeader();
        generate.InterfaceHeader.InterfaceName = 'LabelPrintingService';
        generate.InterfaceHeader.InterfaceVersion = 0.1;
        generate.InterfaceHeader.MessageType = 'Request';
        generate.InterfaceHeader.BusinessReferenceID = 'test 1234';
        generate.InterfaceHeader.SourceSystemID = 'Salesforce';
        generate.InterfaceHeader.Timestamp = Datetime.now();

        generate.ServiceHeader = new TibcoLabelPrintingService.ServiceHeader();
        generate.ServiceHeader.RequestType = 'PDF';
        generate.ServiceHeader.RequesterId = 'test@test.com';
        generate.ServiceHeader.LabelMessage = 'ICPS Label';

        generate.LabelGroup = new List<TibcoLabelPrintingService.LabelGroupType>();
        TibcoLabelPrintingService.LabelGroupType groupType = new TibcoLabelPrintingService.LabelGroupType();
        groupType.Layout = 'A4-6PP LANDSCAPE';
        groupType.Branding = false;
        groupType.LeftOffset = 0;
        groupType.TopOffset = 0;
        groupType.Label = new List<TibcoLabelPrintingService.LabelType>();
        generate.LabelGroup.add(groupType);

        for(Integer i = 1; i <= 3; i++) {
            TibcoLabelPrintingService.LabelType labelType = new TibcoLabelPrintingService.LabelType();
            labelType.TemplateName = 'ICPS';
            labelType.Barcode = 'test 1234';
            labelType.Source = 'ICPS';
            labelType.IcpsContents = new TibcoLabelPrintingService.IcpsContentType();
            labelType.IcpsContents.RecordReferenceNumber = 'test 1234';
            labelType.IcpsContents.StoredLocation = 'somewhere';
            labelType.IcpsContents.IcpsLabelIndex = i;
            labelType.IcpsContents.IcpsLabelCount = 3;
            groupType.Label.add(labelType);
        }

        TibcoLabelPrintingServiceWebServiceMock mock = new TibcoLabelPrintingServiceWebServiceMock();
        Test.setMock(WebServiceMock.class, mock);

        Continuation cont = new Continuation(60);
        cont.continuationMethod = 'getResponse';

        AsyncTibcoLabelPrintingService.AsyncLabelPrintingServicePort port = new AsyncTibcoLabelPrintingService.AsyncLabelPrintingServicePort();
        AsyncTibcoLabelPrintingService.getResponseFuture response = port.beginGet(cont, generate);

        // This is only to test coverage on the auto-generated classes by WSDL2Apex
        System.assert(true);
    }
}