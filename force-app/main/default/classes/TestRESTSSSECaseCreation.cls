/* Version	 		Author					Description
*	1.0				Bharat P		Test Class for the Custom REST API created for 
*									Startrack Special Services and Security Express.
*/
@isTest
public class TestRESTSSSECaseCreation{
	/* Test Method for successful creation of case and related object record */
    public static testMethod void testSSSECaseCreateSuccess(){
        String JSONMsg = '{"case":{"Billing_Number__c":"1234"},"job":{"Job_Type__c":"Security Express","Pickup_Date__c":"18/05/2018"},"freightitems":[{"Quantity__c":3}]}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/v1.0/request/SSSECaseJob';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSONMsg);
        RestContext.request = req;
        RestContext.response = res;
   		Test.startTest();
        RESTSSSECaseCreation.createNewSSSECase();
        Test.stopTest();
    }
    
    /* Test Method for failure i ncreation of case due to a bad request */
    public static testMethod void testSSSECaseCreateFail(){
    	String JSONMsg = '{"case":{"Billing_Number__c":"222"} "job":{"Job_Type__c":"Security Express"},"freightitems":[{}]}';
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/v1.0/request/SSSECaseJob';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSONMsg);
        RestContext.request = req;
        RestContext.response = res;
   		Test.startTest();
        RESTSSSECaseCreation.createNewSSSECase();
        Test.stopTest();        
    }
}