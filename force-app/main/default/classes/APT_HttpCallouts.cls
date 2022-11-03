/**
* @author nasir jawed
* @date 2022-09-20
* @group Class
* @tag ApexController
* @domain Apttus
* @description  A class for Compass API request/response.
* @changelog
*/
public with sharing class APT_HttpCallouts  {
  
  /*
   * Making a callout to the compass API by passing Compass id, quote Id from the object Deal support Request
   */
    public static HttpResponse makeCompassAPIRequest(APT_CompassPricingController.HttpRequestWrapper reqWrapper) { 
        try{
            Http vHTTP = new Http();
            HttpRequest vReq = new HttpRequest();
            vReq.setEndpoint('callout:CompassPricing');
            vReq.setMethod('POST');
            vReq.setHeader('Content-Type', 'application/json');           
            vReq.setBody('{"customerId": "' + reqWrapper.customerId + '","quoteId": "' + reqWrapper.quoteId + '","ratingModel": "' + reqWrapper.ratingModel  + '"}');
            HttpResponse vRes = vHTTP.send(vReq);            
            return vRes;
            
            
        }catch(Exception exc){
            String stackTrace = exc.getStackTraceString().substringBefore('\n');
            String className = stackTrace.substringAfter('.').substringBefore('.');  
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');

            UTIL_LoggingService.logHandledException(exc, UserInfo.getOrganizationId(), 'Sales', className, methodName, 'NONE', LoggingLevel.ERROR);          
            return null;
        }

    }    
}
