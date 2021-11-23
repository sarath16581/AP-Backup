/**************************************************
Description:    Make API collouts. Called by AsynchApexContinuationController
                Objects for this class are dynamically created, use test class to test :  AsynchApexContinuationController_Test
History:
--------------------------------------------------
2008-07-01  clint.dsilva@auspost.com.au Created

**************************************************/

public with sharing class ImageUnsortable extends ImageAPIDetails {

    public class errorException extends Exception{}
    /**
    * Format the result returned form the image API so that it can be used by Lightning component ConsignmentAttachment
    *
    * @param HttpRequest set values in request object
    * @param classNameStr name of class to create object from. Class must implement either IAsynchApexContinuationREST or IAsynchApexContinuationSOAP
    * @param methodName name of method to execute or this can be  a placeholed used within if statement to execute code
    * @param params array of params used by function methodName
    *
    */
    public override void  setHTTPRequest(HttpRequest req,string classNameStr, String methodName, String[] params){
        String url = '';
        string guidId;
        if(params != null && params.size() > 0) {
            guidId = params[0];
        }
        Map<String, String> login = getAPIDetails();
        if(login == null) {
            throw new errorException('Cannot connect to Unsortable API now setting found');
        } else  {
            req.setTimeout(25000);
            url = login.get('url');
            url =  url +   EncodingUtil.urlEncode(guidId, 'UTF-8'); // + '.jpg';
            req.setEndpoint(url);
            req.setHeader('Authorization', login.get('authorization'));
            req.setHeader('Accept-Encoding', 'gzip');
            req.setMethod('GET');
        }
    }
    /**
    * Get config setting for API from custom settings
    */
    public static Map<String, String> getAPIDetails(){
        List<AusPostSettings__c> logins = [Select URL__c, URL2__c, URL3__c, Username__c, Password__c From AusPostSettings__c Where Name = 'UnsortableAPI' And IsActive__c = true];
        if(logins.size() == 0){
            return null;
        }
        String username = logins[0].Username__c;
        String password = logins[0].Password__c;
        string url2 = String.isEmpty(logins[0].URL2__c)?'': logins[0].URL2__c;
        string url3 = String.isEmpty(logins[0].URL3__c)?'': logins[0].URL3__c;
        String url =  logins[0].URL__c;
        if(String.isEmpty(logins[0].URL__c)){
            return null;
        }
        string urlComplete = url + url2 + url3;
        Map<String, String> output = new Map<String, String>();
        output.put('username', logins[0].Username__c);
        output.put('password', logins[0].Password__c);
        output.put('url', urlComplete);
        // set http basic auth headers
        Blob headerValue = Blob.valueOf(logins[0].Username__c + ':' + logins[0].Password__c);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        System.Debug(authorizationHeader);
        output.put('authorization', authorizationHeader);
        return output;
    }
}