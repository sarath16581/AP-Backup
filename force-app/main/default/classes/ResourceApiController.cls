/**************************************************
Description:    Handles all API requests that are prefixed with /api. This pushes it through the lightning api router based on configuration in Custom Metadata type (Lightning_API__mdt)
Test Class: ResourceAliveV1_Test
History: 
--------------------------------------------------
2018-11-28  nathan.franklin@auspost.com.au  Created
**************************************************/
@RestResource(urlMapping='/api/*')
global with sharing class ResourceApiController {

    /**
     * This is the router that handles all POST requests that start with /api/.
     * This method will route the request to the appropriate apex class to handle the request.
     */
    @HttpPost
    global static void post() {
        // default output
        List<String> failedOutput = new List<String>{'404', 'Malformed Request'};
        ResourceAPIService.ResourceAPIConfigWrapper config;

        try {

            // parse the url and extract the dynamic params (inside the request uri) and the post params (json key value pair)
            ResourceAPIService.RequestParams params = new ResourceAPIService.RequestParams(RestContext.request.requestURI, (RestContext.request.requestBody != null ? RestContext.request.requestBody.toString() : '{}'));

            // get the appropriate config
            // this will search through all the custom metadata records to find the correct configuration to use for this request (example: which Apexclass to call)
            // this also updates params var with the dynamic url parts
            // this will only return a config with the appropriate HTTP method
            config = ResourceAPIService.getResourceAPIConfig(params, RestContext.request.httpMethod);
            System.debug('>> ResourceApiController.query ResourceAPIService.ResourceAPIConfigWrapper: ' + config);
            System.debug('>> ResourceApiController.query endpoint: ' + RestContext.request.requestURI);
            System.debug('>> ResourceApiController.query params: ' + RestContext.request.params);

            // initial validation of the routing
            if(config != null && !String.isEmpty(config.config.ApexClassHandler__c)) {
                Type apexClassType = Type.forName(config.config.ApexClassHandler__c);
                ResourceAPIService.IApi resource = (ResourceAPIService.IApi) apexClassType.newInstance();

                // config.params is instance of ResourceAPIService.RequestParams
                // pass this instance to class so it can access the request body and special URL params
                resource.requestParams = config.params;

                try {
                    // invoke the API class to process the request
                    ResourceAPIService.IResourceResponse response = resource.post();

                    // log request if required
                    maybeLogRequest(config.config, RestContext.request, response.getResponseCode(), false);

                    // finally serialize response and push back to the restcontext
                    ResourceAPIService.serializeResponse(response);
                    return;
                } catch (Exception ex) {
                    System.debug(ex);
                    failedOutput = new List<String>{'500', ex.getMessage()};
                }
            }
        } catch (Exception ex) {
            System.debug(ex);
            failedOutput = new List<String>{'500', ex.getMessage()};
        }

        // log request if required
        if(config != null && config.config != null) {
            maybeLogRequest(config.config, RestContext.request, Integer.valueOf(failedOutput[0]), false);
        }

        ResourceAPIService.serializeResponse(new ResourceAPIService.ResourceResponse(Integer.valueOf(failedOutput[0]), failedOutput[1]));
    }

    /**
     * This is the router that handles all GET requests that start with /api/.
     * This method will route the request to the appropriate apex class to handle the request.
     * If the configuration for the endpoint hit uses caching then this method will also cache the output for the specified TTL.
     */
    @HttpGet
    global static void query() {
        // default output
        ResourceAPIService.ResourceAPIConfigWrapper config;
        List<String> failedOutput = new List<String>{'404', 'Malformed Request'};

        try {

            // parse the url and extract the dynamic params (inside the request uri) and the querystring params
            ResourceAPIService.RequestParams params = new ResourceAPIService.RequestParams(RestContext.request.requestURI, RestContext.request.params);

            // get the appropriate config
            // this will search through all the custom metadata records to find the correct configuration to use for this request (example: which Apexclass to call)
            // this also updates params var with the dynamic url parts
            // this will only return a config with the appropriate HTTP method
            config = ResourceAPIService.getResourceApiConfig(params, RestContext.request.httpMethod);

            System.debug('>> ResourceApiController.query ResourceAPIService.ResourceAPIConfigWrapper: ' + config);
            System.debug('>> ResourceApiController.query endpoint: ' + RestContext.request.requestURI);
            System.debug('>> ResourceApiController.query params: ' + RestContext.request.params);

            // initial validation of the routing
            if(config != null && !String.isEmpty(config.config.ApexClassHandler__c)) {
                Type apexClassType = Type.forName(config.config.ApexClassHandler__c);
                ResourceAPIService.IApi resource = (ResourceAPIService.IApi) apexClassType.newInstance();

                // set a default resultsPerPage and pageNumber (for apex classes that implement pagination)
                if(!String.isEmpty(RestContext.request.params.get('resultsPerPage')) && String.valueOf(RestContext.request.params.get('resultsPerPage')).isNumeric())
                    resource.resultsPerPage = Integer.valueOf(RestContext.request.params.get('resultsPerPage'));

                if(!String.isEmpty(RestContext.request.params.get('pageNumber')) && String.valueOf(RestContext.request.params.get('pageNumber')).isNumeric())
                    resource.pageNumber = Integer.valueOf(RestContext.request.params.get('pageNumber'));

                if(!String.isEmpty(RestContext.request.params.get('countOnly')) && String.valueOf(RestContext.request.params.get('countOnly')).isNumeric())
                    resource.countOnly = (RestContext.request.params.get('countOnly') == '1' ? true : false);

                resource.requestParams = config.params;

                try {

                    // check if request is cacheable and has been cached
                    if (config.config.CacheQueryResponse__c) {
                        System.debug('Checking for Cached Response: ' + resource.getQueryCacheKeySuffix());
                        Object cachedResponse = CacheManager.get('RESOURCE_API', resource.getQueryCacheKeySuffix());
                        System.debug('Cached Response: ' + cachedResponse);
                        if (cachedResponse != null && cachedResponse instanceof ResourceAPIService.IResourceResponse) {
                            System.debug('Feeding Cached API Response');

                            // log request if required and mark it as cached
                            maybeLogRequest(config.config, RestContext.request, ((ResourceAPIService.IResourceResponse)cachedResponse).getResponseCode(), true);

                            // serialize the response and include the X-Platform-Cache header to indicate whether the result is fed from platform cache or not.
                            ResourceAPIService.serializeResponse((ResourceAPIService.IResourceResponse) cachedResponse, true);
                            return;
                        }
                    }

                    // no cache was found so query using the apex adapter
                    ResourceAPIService.IResourceResponse response = resource.query();

                    // check if response should be cached
                    if (config.config.CacheQueryResponse__c && response.cacheOutputtedResultIfEnabled()) {
                        System.debug('Caching API Response');
                        CacheManager.put('RESOURCE_API', resource.getQueryCacheKeySuffix(), response, (config.config.CacheTTLOverride__c != null ? Integer.valueOf(config.config.CacheTTLOverride__c) : null));
                    }

                    // log request if required
                    maybeLogRequest(config.config, RestContext.request, response.getResponseCode(), false);

                    // finally serialize response and push back to the restcontext
                    ResourceAPIService.serializeResponse((ResourceAPIService.IResourceResponse)response);
                    return;
                } catch (Exception ex) {
                    System.debug(ex);
                    failedOutput = new List<String>{'500', ex.getMessage()};
                }
            }
        } catch (Exception ex) {
            System.debug(ex);
            failedOutput = new List<String>{'500', ex.getMessage()};
        }

        // log request if required
        // we only log it if we have found an API to consume
        if(config != null && config.config != null) {
            maybeLogRequest(config.config, RestContext.request, Integer.valueOf(failedOutput[0]), false);
        }

        ResourceAPIService.serializeResponse(new ResourceAPIService.ResourceResponse(Integer.valueOf(failedOutput[0]), failedOutput[1]));
    }

    public static void maybeLogRequest(ResourceAPI__mdt config, RestRequest request, Integer responseCode, Boolean isCachedResponse) {
        if(config.LogRequests__c) {
            String queryString = '';
            if(request.params != null) {
                for (String paramName : request.params.keySet()) {
                    queryString += (!String.isEmpty(queryString) ? '&' : '') + paramName + '=' + request.params.get(paramName);
                }
            }

            try {
                logRequest(config.HTTPMethod__c, request.requestURI, queryString, (config.LogBody__c ? request.requestBody.toString() : ''), responseCode, isCachedResponse);
            } catch(Exception ex) { System.Debug('Could not create Log: ' + ex); }
        }
    }

    /**
     * If logging is enabled for an endpoint, then it is completed in a future to prevent interference with that the API is doing (possibility of mixed_dml and uncommited changes etc...)
     */
    @future
    public static void logRequest(String requestMethod, String endPoint, String queryString, String requestBody, Integer responseCode, Boolean isCachedResponse) {
        APILog log = new APILog();
        log.logRequest(requestMethod, endPoint, queryString, requestBody, responseCode, isCachedResponse);
    }

    //TODO Refactor later to remove APILog__c
    public without sharing class APILog {
        public void logRequest(String requestMethod, String endPoint, String queryString, String requestBody, Integer responseCode, Boolean isCachedResponse) {
//            Application_Log__c log = new Application_Log__c(Debug_Level__c = 'Info', Integration_Payload__c	= requestBody, Log_Code__c = requestMethod, Message__c = queryString, Reference_Information__c = String.valueOf(responseCode) + (isCachedResponse ? ', isCached' : ''), Source__c = 'API Framework', Source_Function__c = endPoint);
//            insert log;
            APILog__c log = new APILog__c(RequestType__c = requestMethod, Endpoint__c = endPoint, QueryString__c = queryString, Body__c = requestBody, ResponseCode__c = responseCode, ResultCached__c = isCachedResponse);
            insert log;
        }
    }

}