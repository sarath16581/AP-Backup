public with sharing class Cognition_CalloutUtility {
    /**
    Type: Class for invoking Cognition API Callouts
    History:
	17-05-2018: Created - Subbu C, Gaurav A and Omair A (Salesforce)
    --------------------------------------------------
    **/
    public static CustomerCognitionSettings__c customerCognitionSettings {

        get {
            if (customerCognitionSettings == null) {
                customerCognitionSettings = CustomerCognitionSettings__c.getOrgDefaults();
            }
            return customerCognitionSettings;
        }
        set;
    }
    
    
    /**
    *   @description Execute the physical callout and return the response
    *   @return Returns the HttpResponse from the Customer Cognition API
    **/
    
    public static String executeCallout (String method, String resourceName, String requestBody) {
        
        // Instantiate a new request
        HttpRequest request = new HttpRequest();
        String authorizationHeader = 'Basic ' + customerCognitionSettings.BasicAuthnHeader__c; 
        System.debug('authorizationHeader>>>'+authorizationHeader);
        request.setHeader('Authorization', authorizationHeader);
        request.setHeader('Content-Type', 'application/json');
 
        CognitionAPIs__c timeoutRecord = CognitionAPIs__c.getInstance('Timeout');
        request.setTimeout(Integer.valueof(timeoutRecord.Timeout__c));

        // Set request parameters
        request.setMethod(method);
        request.setEndpoint(customerCognitionSettings.EndPoint__c + resourceName);
        
        // If the callout includes a body (POST and PUT requests)
        if (String.isNotBlank(requestBody)) {
            System.debug('requestBody>>>'+requestBody);
            // Set the body to the callout
            request.setBody(requestBody);
        }
        /**
        * Create a new http object to send the request object
        * A response object is generated as a result of the request  
        **/
        System.debug('request>>>'+request);
        
            try {
                Http http = new Http();
                HTTPResponse res = http.send(request);
                System.debug(res.getBody());

                return res.getBody();
            } catch(Exception e) {          
                //throw new AuraHandledException('Error! Something went wrong: '+ e.getMessage()); 
                return e.getMessage();
            }
        

    }
    
}