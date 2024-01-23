/**
*
* Help and support : Controller for safedrop image for chas Help and support community
                     Controller for MRS service callout
* History :
* --------------------------------------------------
* 2020-07-12 haraprasad.sahoo@auspost.com.au Created - Change made for roll out of Safe Drop feature on Missing Items form
* 2020-07-12 haraprasad.sahoo@auspost.com.au Added - getAMEAddressString()
*/
public with sharing class ChasSafeDropController {
    public class ContinuationState {
        public String httpRequestLabel;
        public String safeDropGuid;
        public String caseId;
    }
    /**
* This method will take the 'safedropGuid' as input and will call the safedrop service and fetch the image from the AWS server
* */
    @AuraEnabled(continuation=true cacheable=true)
    public static Object getSafeDropImage( String safedropGuid ) {
        if(!String.isEmpty(safedropGuid))
        {
            // proceed to invoke a continuation to load the safe drop image from AWS through the digital repository API
            try {
                
                HttpRequest req = SafeDropUtility.getSafeDropHttpRequest(safedropGuid);
                // Create a Continuation for the HTTPRequest
                // This is used for async requests
                Continuation con = new Continuation(60);
                con.continuationMethod = 'callback';
                
                // add the object state to transfer to the continuation
                ContinuationState state = new ContinuationState();
                state.httpRequestLabel = con.addHttpRequest(req);
                state.safeDropGuid = safedropGuid;
                
                con.state =  state;
                // Return it to the system for processing
                return con;
            } catch (Exception e) {
                // there was an error either receiving a response from the server or processing it on our end.
                // display this error to the user
                String error = 'EXCEPTION\nType: ' + e.getTypeName() + '\nMessage: ' + e.getMessage() + '\nLine Number: ' + String.valueOf(e.getLineNumber()) + '\n\nStack:\n' + e.getStackTraceString();
                return error;
            }
        }
        else {
            // continue on to next step because there is no safe drop guid
            return 'OK';
        }
    }
    //Callback method
    @AuraEnabled(cacheable=true)
    public static String callback(Object state)
    {
        ContinuationState continuationState = (ContinuationState)state;
        System.debug(continuationState);
        
        HttpResponse resp = Continuation.getResponse(continuationState.httpRequestLabel);
        //HttpResponse resp = Continuation.getResponse(labels[0]);
        
        String responseBody = resp.getBody();
        System.Debug(responseBody);
        
        // parse the json
        System.debug('SAFE-DROP API RAW REPONSE: ' + responseBody);
        SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);
        System.debug('SAFE-DROP API PARSED REPONSE: ' + response);
        
        if(response.isError) {
            // display this error message to the user
            return response.errorMessage;
        } else {
            // add the safe drop image as an attachment to the event message and report back to the page that it's ok to redirect to the PDF
            Id caseId = continuationState.caseId;
            String guid = continuationState.safeDropGuid;
            
            System.debug('Continuation Details: ' + caseId + ', ' + guid);
            
            
            // return an OK response so the redirect proxy page will continue onto the PDF generation page
            return response.imageBody;
        }
    }
    
    public class ResponseWrapper {
        @AuraEnabled public String safeDropGuid;
        @AuraEnabled public Integer statusCode;
    } 
    
    /**
* This method will take the 'Tracking Number' as input and will call the MRS-redirect service and fetch the guid
* */
    @AuraEnabled
    public static ResponseWrapper getSafeDropGuid(String trackingNumber){
        ResponseWrapper result = new ResponseWrapper();
        HttpResponse response  = null;
        if(trackingNumber != null && trackingNumber.trim().length() > 0){
            response = ChasCallout.requestGuidString(trackingNumber);
            if(response!=null){
                if(response.getStatusCode() != null ){
                    result.statusCode = response.getStatusCode();
                }
            }
            if(result.statusCode == 200)
            {
                // Deserialize the JSON string into collections of primitive data types.
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                result.safeDropGuid = String.valueOf(results.get('safeDropImageGuid'));
            }
        }
        return result;
    }
    @AuraEnabled(cacheable=true)
    public static String getAMEAddressString(String dpid)
    {
        String response = AMEAddressValidationController1.getAddressDetailsFromDPID(dpid);
        return response;
    }
    
}