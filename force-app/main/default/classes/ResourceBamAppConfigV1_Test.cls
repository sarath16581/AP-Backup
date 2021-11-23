/**************************************************
Description: This class contains unit tests for validating the behavior of Apex class ResourceBamAppConfigV1

History:
21/05/2019  	lija.jawahar@auspost.com.au		Created.
**********************************************************/
@isTest
public  class ResourceBamAppConfigV1_Test {
    @testSetup static void setData() {
       
        Account testAccount = BAMTestUtility.createTestAccount('9999');
        insert testAccount;

        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id,'c123456' );
        insert testContact;
    }

    testMethod static void getAllApplications_SUCCESS(){
        
        // Create test applications
        List<BAMApplication__c> appList = new List<BAMApplication__c>();
        BAMApplication__c appBSP = BAMTestUtility.createBamApplication('BSP');
        appList.add(appBSP);
        BAMApplication__c app2 = BAMTestUtility.createBamApplication('BCD');
        appList.add(app2);
        BAMApplication__c app3 = BAMTestUtility.createBamApplication('CDE');
        appList.add(app3);
        insert appList;

        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/api/1.0/bam/applications';

        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;

		// Call the method to test
        ResourceApiController.query();

        Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.debug(jsonResponse);

        System.assertEquals(200, response.statusCode);
        System.assertEquals(true, jsonResponse.get('success'));

    }

    
    testMethod static void getAllApplication_NOTFOUND_ERR(){
        
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/api/1.0/bam/applications';

        request.httpMethod = 'GET';

        RestContext.request = request;
        RestContext.response = response;

		// Call the method to test
        ResourceApiController.query();

        Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
        System.debug(jsonResponse);

        System.assertEquals(404, response.statusCode);
        System.assertEquals(false, jsonResponse.get('success'));

    }
}