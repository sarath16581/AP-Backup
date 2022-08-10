/***
 * @author George Nguyen
 * @date 2022-07-11
 * @domain Core
 * @description A service class that provides functionalities related o ICPS (Label Printing)
 * @changelog
 * 2022-07-11 - George Nguyen - Created
 */
public inherited sharing class ICPSService {

	static ICPSService instance;
    public static ICPSService getInstance() {
		if (instance == null) {
			instance = (ICPSService) Application.Utilities.newInstance(ICPSService.class);
		}
		return instance;
	}

    public class ICPSException extends Exception{}

    /*
    * NOTE: 
    * Using HTTP instead of WebService.invoke(..) because the end point requires SOAP 1.2 (which currently is Not supported by WSDL2Apex)
    */
    public String retrieveBase64Labels(ICPS__c record, String username) {

        if(record.NumberofArticles__c == 0) {
            throw new ICPSException('The label cannot be printed because no articles have been added to this ICPS record');
        }

        AusPostSettings__c setting = AusPostSettings__c.getValues('ICPS');
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(setting.URL__c); // e.g. https://callout:LAYER7_CERT/lps/labelPrintingService
        req.setBody(generateRequest(record, username));
        req.setMethod('POST');
        Http http = new Http(); 	
        HTTPResponse res = http.send(req);

        String contentType = res.getHeader('Content-Type');
        String boundary = contentType.split('boundary="')[1].split('"')[0]; // Identifier of multipart sections
        String boundaryHex = EncodingUtil.convertToHex(Blob.valueOf('--' + boundary));
        String responseHex = EncodingUtil.convertToHex(res.getBodyAsBlob());
        Blob pdf = EncodingUtil.convertFromHex(responseHex.split(boundaryHex)[2]); // Split multipart

        return System.EncodingUtil.base64Encode(pdf);
    }

    private String generateRequest(ICPS__c record, String username) {
        ICPSSettings__mdt icpsSettings = ICPSSettings__mdt.getInstance('ICPS_Settings');

        TibcoLabelPrintingService.get request = new TibcoLabelPrintingService.get();
        TibcoLabelPrintingService.GetRequestType generate = new TibcoLabelPrintingService.GetRequestType();
        request.Generate = generate;

        generate.InterfaceHeader = new TibcoLabelPrintingService.InterfaceHeader();
        generate.InterfaceHeader.InterfaceName = 'LabelPrintingService';
        generate.InterfaceHeader.InterfaceVersion = 0.1;
        generate.InterfaceHeader.MessageType = 'Request';
        generate.InterfaceHeader.BusinessReferenceID = record.Name;
        generate.InterfaceHeader.SourceSystemID = 'Salesforce';
        generate.InterfaceHeader.Timestamp = Datetime.now();

        generate.ServiceHeader = new TibcoLabelPrintingService.ServiceHeader();
        generate.ServiceHeader.RequestType = icpsSettings.ServiceHeaderRequestType__c; // 'PDF';
        generate.ServiceHeader.RequesterId = username;
        generate.ServiceHeader.LabelMessage = icpsSettings.ServiceHeaderLabelMessage__c; // 'ICPS Label';

        generate.LabelGroup = new List<TibcoLabelPrintingService.LabelGroupType>();
        TibcoLabelPrintingService.LabelGroupType groupType = new TibcoLabelPrintingService.LabelGroupType();
        groupType.Layout = icpsSettings.GroupTypeLayout__c; // 'A4-6PP LANDSCAPE';
        groupType.Branding = false;
        groupType.LeftOffset = icpsSettings.GroupTypeLeftOffset__c; // 0;
        groupType.TopOffset = icpsSettings.GroupTypeTopOffset__c; // 0;
        groupType.Label = new List<TibcoLabelPrintingService.LabelType>();
        generate.LabelGroup.add(groupType);

        for(Integer i = 1; i <= record.NumberofArticles__c; i++) {
            TibcoLabelPrintingService.LabelType labelType = new TibcoLabelPrintingService.LabelType();
            labelType.TemplateName = icpsSettings.LabelTypeTemplateName__c; // 'ICPS';
            labelType.Barcode = record.Name;
            labelType.Source = 'ICPS';
            labelType.IcpsContents = new TibcoLabelPrintingService.IcpsContentType();
            labelType.IcpsContents.RecordReferenceNumber = record.Name;
            labelType.IcpsContents.StoredLocation = record.StoreLocationReporting__c;
            labelType.IcpsContents.IcpsLabelIndex = i;
            labelType.IcpsContents.IcpsLabelCount = record.NumberofArticles__c.intValue();
            groupType.Label.add(labelType);
        }

        String requestBody = '<?xml version="1.0"?>';
        requestBody += '<soap:Envelope xmlns:gen="http://www.auspost.com.au/Schema/ProductandServiceFulfilment/LodgementManagement/generateLabel:v1"';
        requestBody += '    xmlns:soap="http://www.w3.org/2003/05/soap-envelope">'; // SOAP 1.2
        requestBody += '<soap:Header/><soap:Body>' + XML.serialize('gen:get', request) + '</soap:Body></soap:Envelope>';
        return requestBody;
    }
}