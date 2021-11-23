/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  : Controller class for qasAddressValidation LWC component
--------------------------------------- History --------------------------------------------------
01.04.2019    Sameed Khan(Mav3rik)    Created
**/
public with sharing class QASAddressValidationController {
    static AusPostSettings__c addressValidationSetting = AusPostSettings__c.getValues('AddressValidation');

    @AuraEnabled(cacheable = true)
    public static string searchAddress(String searchTerm){
       String url = addressValidationSetting.URL2__c + '?term=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8');
        return sendRequest(url, addressValidationSetting.Token__c);        
    }

    @AuraEnabled(cacheable = true)
    public static string getAddressDetails(String address){
        String url = addressValidationSetting.URL3__c + '?address=' + EncodingUtil.urlEncode(address, 'UTF-8');
        return sendRequest(url, addressValidationSetting.Token__c);
    }

    public static String sendRequest(String url, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('auspost-access-token', token);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res);
        return res.getBody();
    }
}