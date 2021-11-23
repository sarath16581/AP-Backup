/**************************************************
Description:       Test class to specifically cover ResourceV1IVRStarTrackSuccessful API calls
History:
--------------------------------------------------
2018-05-28  nathan.franklin@auspost.com.au Updated
2018-06-08  dilshan.egodawela@auspost.com.au Updated
**************************************************/
@isTest
public class ResourceV1IVRStarTrackSuccessful_Test {

	/********************************************
	Scenario:
	Successful Case Creation based on Passed Consignment Identifier
	*********************************************/
	@isTest
	public static void testCaseCreation() {

		//Create StarTrack Setting value.
		//This is used by the Consignment Search method
		INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(),
			Get_All_Consignment_Details__c = true,
			EMS_Endpoint__c = 'testendpt',
			Web_Service_Callout_Timeout__c = 10,
			Use_Continuation_for_Consignment_Search__c = true,
			XML_Logging__c = true,
			Logging__c = true,
			Log_For__c = 'ALL USER',
			StarTrack_ConSearch_Authentication_Level__c = 2,
			StarTrack_ConSearch_Client_Cert__c = 'cert',
			Sync_Web_Service_Callout_Timeout__c = 5
		);

		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse restresponse = new RestResponse();
		request.requestUri = '/services/apexrest/v1.0/IVR/StarTrack/Successful';

		request.httpMethod = 'PUT';

		//Pass in the Consignment Identifier used in the WebServiceMock
		request.requestBody = Blob.valueof('{"consignmentIdentifier":"TR2_66a94898-0927-450e-abfa-defa36972669","callerType":"Sender","callerId":"unavailable"}');

		//Set Mock class
		Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());

		RestContext.request = request;
		RestContext.response = restresponse;

		// Call the method to test
		ResourceV1IVRStarTrackSuccessful.put();

		// Verify results

		Test.stopTest();

		System.debug(JSON.deserializeUntyped(restresponse.responseBody.toString()));
		System.debug(restresponse);
		//verify response status
		System.assertEquals(restresponse.statusCode, 200);

		//Query Cases to get the CaseNumber of the newly craeted Case
		String newCaseNo = [select Id,CaseNumber from Case limit 1].CaseNumber;

		//Process the response
		Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(restresponse.responseBody.toString());
		Map<String, Object> temp = (Map<String, Object>) results.get('response');

		System.debug(temp.get('caseNumber'));

		//Verify Case Number with the response
		System.assertEquals(temp.get('caseNumber'), newCaseNo);

	}

	/********************************************
	Scenario:
	Return error response when the consignment search is throwing errors
	*********************************************/
	@isTest
	public static void testErrorResponse() {
		//Create StarTrack Setting value.
		//This is used by the Consignment Search method
		INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(),
			Get_All_Consignment_Details__c = true,
			EMS_Endpoint__c = 'testendpt',
			Web_Service_Callout_Timeout__c = 10,
			Use_Continuation_for_Consignment_Search__c = true,
			XML_Logging__c = true,
			Logging__c = true,
			Log_For__c = 'ALL USER',
			StarTrack_ConSearch_Authentication_Level__c = 2,
			StarTrack_ConSearch_Client_Cert__c = 'cert',
			Sync_Web_Service_Callout_Timeout__c = 5
		);

		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse restresponse = new RestResponse();
		request.requestUri = '/services/apexrest/v1.0/IVR/StarTrack/Successful';

		request.httpMethod = 'PUT';

		//Pass in the Consignment Identifier used in the WebServiceMock or any in this instance
		request.requestBody = Blob.valueof('{"consignmentIdentifier":"TR2_66a94898-0927-450e-abfa-defa36972669","callerType":"Sender","callerId":"unavailable"}');

		//Set Mock class
		StartrackWebSvcCalloutMockEx mockException = new StartrackWebSvcCalloutMockEx();
		mockException.errorMessage = 'Failed to get next element';
		mockException.isDml = true;
		Test.setMock(WebServiceMock.class, mockException);

		RestContext.request = request;
		RestContext.response = restresponse;

		// Call the method to test
		ResourceV1IVRStarTrackSuccessful.put();

		Test.stopTest();

		System.debug(JSON.deserializeUntyped(restresponse.responseBody.toString()));
		System.debug(restresponse);
		// Verify results
		//verify response status
		System.assertEquals(restresponse.statusCode, 500);

	}

}