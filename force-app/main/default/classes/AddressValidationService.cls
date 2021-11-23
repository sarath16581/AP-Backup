/**************************************************
Type:       Global AddressValidationService class containing webservice methods
Purpose:    Used by AddressComponent, AddressValidation components to get a token using which the page requests for addresses from QAC
History:
--------------------------------------------------
Dec-2013:  shruthi.kunchinadka@bluewolf.com  Created                                            
**************************************************/
Global Class AddressValidationService {
    
    final static String APPLICATION_NAME = 'applicationName';
    final static String APPLICATION_KEY = 'appKey';
    final static String SERVICE_NAME = 'serviceName';
    final static String TOKEN_DURATION = 'tokenDuration';
    final static String TOKEN_REQUEST = 'tokenRequest';
    
    webservice static String getToken() {
        String token = '';
        
        AusPostSettings__c addValidation = AusPostSettings__c.getValues('AddressValidation');
        token = addValidation.Token__c;
        return token;
    }
    
    webservice static String getAddressURL() {
        String addressURL = '';
        
        AusPostSettings__c addValidation = AusPostSettings__c.getValues('AddressValidation');
        addressURL = addValidation.URL2__c;
        return addressURL;
    }
    
    webservice static String getDetailsURL() {
        String detailsURL = '';
        
        AusPostSettings__c addValidation = AusPostSettings__c.getValues('AddressValidation');
        detailsURL = addValidation.URL3__c;
        return detailsURL;
    }
    
    @future(callout=true)
    public static void updateToken() {
        String token = '';
        
        AusPostSettings__c addValidation = AusPostSettings__c.getValues('AddressValidation');
        HttpRequest req = new HttpRequest();
        String username = addValidation.Username__c;
        String password= addValidation.Password__c;
        Http http = new Http();
        req.setEndpoint(addValidation.URL__c);
        req.setMethod('POST');
        Blob headerValue = Blob.valueOf(username +':' +password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        System.debug('Encoder Value' + EncodingUtil.base64Encode(headerValue));
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type','application/json');
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeFieldName(TOKEN_REQUEST);
        gen.writeStartObject();
        gen.writeStringField(APPLICATION_NAME, addValidation.ApplicationName__c);
        gen.writeStringField(APPLICATION_KEY, addValidation.AppKey__c);
        gen.writeStringField(SERVICE_NAME, addValidation.ServiceName__c);
        gen.writeStringField(TOKEN_DURATION, addValidation.TokenDuration__c);
        gen.writeEndObject();
        gen.writeEndObject();
        System.debug(gen.getAsString());
        req.setBody(gen.getAsString());
        HttpResponse res = http.send(req);
        System.debug(res.getBody());
        JSONParser parser = JSON.createParser(res.getBody());
        while(parser.nextToken()!=null) 
        {
            if(parser.getCurrentName() == 'userToken' && parser.getText() != 'userToken') 
            {
                System.debug(parser.getText());
                token = parser.getText();
            }
        }
        addValidation.Token__c = token;
        update addValidation;
    }
    
}