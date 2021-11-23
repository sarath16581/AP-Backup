/**
 * Created by hasantha on 15/4/19.
 */


public without sharing class pso_IAsynchApexContinuationImpl implements IAsynchApexContinuationREST{

    /**
     * implementations of setHTTPRequest() to handle the request, this will format and prepare the request
     *
     * @param request
     * @param classNameStr
     * @param methodName
     * @param params
     */
    public void setHTTPRequest(HttpRequest request, String classNameStr, String methodName, List<String> params) {
        try {
            String requestBody = '';
            // Consignment info related request parameter preparation
            if (methodName == 'sendOnboardingRequest') {
                // prepare the json body
                requestBody = pso_ParcelSendOnboarding.prepareAndCalloutRequest(params);
            }

            System.debug('pso_IAsynchApexContinuationImpl jsonRequest>>>' + requestBody);

            // prepare the request
            request.setHeader('Content-Type', 'application/json');
            // system wide callout time out setting
            request.setTimeout(5000);
            // Set request parameters
            request.setMethod('POST');
            request.setEndpoint('callout:Parcel_Send_Onboarding_Camunda/accessone/v2/registration/salesforce/onboard');
            // If the callout includes a body (POST and PUT requests)
            if (String.isNotBlank(requestBody)) {
                // Set the body to the callout
                request.setBody(requestBody);
            }

        } catch (Exception e){
            // Error Logged to Exception object for analysis
            //TODO UTIL_LoggingService need to b e modified to handle for transactions with callouts (otherwise uncommited work exception will be fired)
            /**UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'pso_IAsynchApexContinuationImpl', pso_IAsynchApexContinuationImpl.class.getName(), 'setHTTPRequest',
                    null, LoggingLevel.ERROR
            );**/
            system.debug('ERROR EXCEPTION : setHTTPRequest() '+e);
        }
    }

    /**
     * parse the response received
     *
     * @param response
     *
     * @return
     */
    public Object parseResponse(HttpResponse response) {
        try {
                // access the response
                String jsonResponse = response.getBody();
                Integer statusCode = response.getStatusCode();

                // status code check
                if (statusCode >= 2000) {
                    System.debug('Data Async Callout Error : ' + statusCode);
                    return null;
                }

                // parse the full response and get the payload
                jsonResponse = response.getBody();
                HttpResponseInfo responseInfo = (HttpResponseInfo) System.JSON.deserialize(jsonResponse, HttpResponseInfo.class);

                System.debug('responseInfo : ' + responseInfo);

                // TODO: error handeling based on parameters passed through response
                if(responseInfo.methodName == 'sendOnboardingRequest') {
                    return responseInfo;
                }
            } catch (exception e){
                // Error Logged to Exception object for analysis
                //TODO UTIL_LoggingService need to b e modified to handle for transactions with callouts (otherwise uncommited work exception will be fired)
                /*UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'pso_IAsynchApexContinuationImpl', pso_IAsynchApexContinuationImpl.class.getName(), 'parseResponse',
                null, LoggingLevel.ERROR
                );*/
                system.debug('ERROR EXCEPTION parseResponse(): '+e);
            }

        return null;
    }

    public Integer getTimeOut(){
        return 120;
    }

    public with sharing class HttpResponseInfo{
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public string payload { get; set; }
        @AuraEnabled public string [] params { get; set; }
        @AuraEnabled public string []errorList { get; set; }
        @AuraEnabled public string className { get; set; }
        @AuraEnabled public string methodName { get; set; }
    }
}