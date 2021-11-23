/**************************************************
Description:
History:
--------------------------------------------------
2019-08-29  Hasantha.Liyanage@auspost.com.au  Created
2019-11-03  nathan.franklin@auspost.com.au  Changed getOrgDefaults() call to getInstance for custom setting
2020-08-17  hara.sahoo@auspost.com.au  Added requestGuidString() for MRS service
2020-09-14 haraprasad.sahoo@auspost.com.au Modified : Change made for roll out of Safe Drop feature on Missing Items form - Updated the tracking url
2020-10-06  hara.sahoo@auspost.com.au  Modified getChasCalloutHttpRequest to cater for consignment search API
2021-06-24  hara.sahoo@auspost.com.au  Added requestEDDEstimates() for shipment EDD service
**************************************************/
public with sharing class ChasCallout {
    
    public static string endpointURL = null;
    public static String apikey = null;
    public static Integer connectionTimeOut = null;
    public static String apChannelName = 'HelpSupport';
    public static String serviceParams = null;
    
    public static HttpResponse requestStatus(String trackingNumber)
    {
        if (trackingNumber != null && trackingNumber.trim().length() > 0) {
        //-- Getting OneTrack Service API Endpoint URL, API Key and timeout from Custom Settings
        getOneTrackAPIDetails();
        HttpRequest request = getChasCalloutHttpRequest(trackingNumber,'&expand=events');
        HttpResponse response = getChasCalloutHttpResponse(request);
        return response;
        }
        else
        {
            return null;
        }
        
    }
    
    public static HttpResponse requestGuidString(String trackingNumber)
    {
        if (trackingNumber != null && trackingNumber.trim().length() > 0) {
        //-- Getting MRS Service API Endpoint URL, API Key and timeout from Custom Settings
        getSafedropAPIDetails();
        HttpRequest request = getChasCalloutHttpRequest(trackingNumber,'/safedropimage');
        HttpResponse response = getChasCalloutHttpResponse(request);
        return response;
        }
        else 
        {
            return null;
        }
        
    }
    
    public static HttpResponse requestEDDEstimates(String trackingNumber, String postcode)
    {
        if (trackingNumber != null && trackingNumber.trim().length() > 0) {
        //-- Getting MRS Service API Endpoint URL, API Key and timeout from Custom Settings
        getEDDServiceAPIDetails();
        HttpRequest request = getChasCalloutHttpRequest(trackingNumber,postcode);
        HttpResponse response = getChasCalloutHttpResponse(request);
        return response;
        }
        else 
        {
            return null;
        }
        
    }
    public static void getOneTrackAPIDetails() {
        
        try {
            Consumer_Help_and_Support__c consumerHelpNSupport = Consumer_Help_and_Support__c.getInstance();
                System.debug('consumerHelpNSupport=' + consumerHelpNSupport);
                if (consumerHelpNSupport != null) {
                    endpointURL = consumerHelpNSupport.End_Point_1Track_Service_URL_v2__c;
                    apikey = consumerHelpNSupport.API_Key_v2__c;
                    connectionTimeOut = Integer.valueOf(consumerHelpNSupport.Connection_Time_Out__c);
                    apChannelName = consumerHelpNSupport.AP_Channel_Name__c;
            } else {
                System.debug(LoggingLevel.ERROR, 'No Custom Setting is present for CHAS to get OneTrack endpoint URL and its API Keys') ;
            }
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error while getting Custom Setting of CHAS to get 1Track endpoint URL and its API Keys' + ex.getMessage()) ;
        }
    }
    
    public static void getSafedropAPIDetails() {
        
        //-- Getting Redirect Service API Endpoint URL, API Key and timeout from Custom Settings
            try {
                Consumer_Help_and_Support__c consumerHelpNSupport = Consumer_Help_and_Support__c.getInstance();
                
                if (consumerHelpNSupport != null) {
                    endpointURL = consumerHelpNSupport.End_Point_Safedrop_Service_URL__c;
                    apikey = consumerHelpNSupport.Safedrop_API_Key__c;
                    connectionTimeOut = Integer.valueOf(consumerHelpNSupport.Safedrop_Connection_Time_Out__c);
                    apChannelName = consumerHelpNSupport.AP_Channel_Name__c;
                    System.debug('consumerHelpNSupport=' + endpointURL);
                } else {
                    System.debug(LoggingLevel.ERROR, 'No Custom Setting is present for CHAS to get 1Track endpoint URL and its API Keys') ;
                }
                
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Error while getting Custom Setting of CHAS to get 1Track endpoint URL and its API Keys' + ex.getMessage()) ;
            }
    }
    
    public static void getEDDServiceAPIDetails() {
        
        //-- Getting EDD Service API Endpoint URL, API Key and timeout from Custom Settings
            try {
                Consumer_Help_and_Support__c consumerHelpNSupport = Consumer_Help_and_Support__c.getInstance();
                
                if (consumerHelpNSupport != null) {
                    endpointURL = consumerHelpNSupport.End_Point_URL_EDD_Service__c;
                    apikey = consumerHelpNSupport.EDD_Service_API_Key__c;
                    connectionTimeOut = Integer.valueOf(consumerHelpNSupport.EDD_Service_Connection_Time_Out__c);
                    apChannelName = consumerHelpNSupport.AP_Channel_Name__c;
                    serviceParams = consumerHelpNSupport.EDDQueryParams__c;
                    System.debug('consumerHelpNSupport=' + endpointURL);
                } else {
                    System.debug(LoggingLevel.ERROR, 'No Custom Setting is present for EDD service API') ;
                }
                
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Error while getting Custom Setting for EDD service API' + ex.getMessage()) ;
            }
    }
    
    
    public static HttpRequest getChasCalloutHttpRequest(String trackingNumber, String queryParams) {
        String endpointURLWithTrackingNum = '';
        //-- 1. Building Http Request
        //Added the query parameters like ?expand=events and AUTH-KEY settings
        if(queryParams.contains('safedropimage'))
        {
            endpointURLWithTrackingNum = endpointURL + trackingNumber.trim() + queryParams;
        } else
        {
            endpointURLWithTrackingNum = endpointURL + '?q=' + trackingNumber.trim() + queryParams;
        }
        //Added for shipment edd service, here query parameter is the postcode 
        if (endpointURL.contains('shipment-edd') && !String.isEmpty(queryParams))
        {
            endpointURLWithTrackingNum = endpointURL + trackingNumber.trim() + serviceParams +'='+ queryParams;
        }
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endpointURLWithTrackingNum);
        httpReq.setMethod('GET');
        httpReq.setHeader('AUTH-KEY', apikey);
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('AP_CHANNEL_NAME', apChannelName); 
        httpReq.setTimeout(connectionTimeOut);
        System.debug('Http Request=' + httpReq);
        return httpReq;
    }
    
    public static HttpResponse getChasCalloutHttpResponse(HttpRequest httpReq) {
        
        Http http = new Http();
        HttpResponse httpRes;
        
        try {
            httpRes = http.send(httpReq);
        } catch (System.CalloutException e) {
            //-- Retrying the http request in case of timeout
            httpRes = http.send(httpReq);
        }
        
        //System.debug('Http Response=' + JSON.serialize(httpRes));
        return httpRes;
    }
    
}