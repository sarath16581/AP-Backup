/**************************************************
Description:    Test class Endpoint for Alive ping (/alive)
History:
--------------------------------------------------
2018-11-28  nathan.franklin@auspost.com.au  Created
**************************************************/
@isTest
public with sharing class ResourceAliveV1_Test {

    @TestSetup
    public static void setup() {
        //inserting custom settings for enable cache
        CacheSettings__c setting = new CacheSettings__c (CacheEnabled__c = true);
        insert setting;
    }

    /**
     * Scenario:
     *      This will test the Alive api endpoint.
     *      This uses the SF_ALIVE metadata record in the LightningAPI__mdt type.
     */
    public static testMethod void testAlivePing() {

        Test.startTest();

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = '/api/1.0/alive';
        request.params.put('resultsPerPage', '20');
        request.params.put('pageNumber', '1');
        request.params.put('countOnly', '0');
        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        ResourceApiController.query();

        Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.debug(response.responseBody.toString());

        //verify response status
        System.assertEquals(200, response.statusCode);
        System.assertEquals(true, jsonResponse.get('success'));
        System.assertEquals('OK', String.valueOf(jsonResponse.get('response')));

        request = new RestRequest();
        response = new RestResponse();
        request.requestUri = '/api/1.0/alive';
        request.params.put('resultsPerPage', '20');
        request.params.put('pageNumber', '1');
        request.params.put('countOnly', '0');
        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;

        // Call the method to trigger a cached response
        // this will only work if the 'cache response' option on the SF_ALIVE metadata record of ResourceAPI__mdt is enabled
        ResourceApiController.query();

        jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.debug(response.responseBody.toString());

        //verify response status
        System.assertEquals(200, response.statusCode);
        System.assertEquals(true, jsonResponse.get('success'));
        System.assertEquals('OK', String.valueOf(jsonResponse.get('response')));

        Test.stopTest();
    }

    /**
     * Scenario:
     *      This will test the Alive api endpoint.
     *      This uses the SF_ALIVE metadata record in the LightningAPI__mdt type.
     */
    public static testMethod void testAlivePingPost() {

        Test.startTest();

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri = '/api/1.0/alive';
        request.httpMethod = 'POST';

        RestContext.request = request;
        RestContext.response = response;

        // Call the method to test
        ResourceApiController.post();

        Test.stopTest();

        Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.debug(response.responseBody.toString());

        //verify response status
        System.assertEquals(200, response.statusCode);
        System.assertEquals(true, jsonResponse.get('success'));
        System.assertEquals('OK', String.valueOf(jsonResponse.get('response')));
    }

}