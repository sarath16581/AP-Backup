/*
 * Created: Andrew Judd 27 May 2019.
 */
@isTest
public class BAMProvisionCallout_Test {
	
	class EchoHttpMock implements HttpCalloutMock
	{
		public HttpResponse res;
		EchoHttpMock(HttpResponse response)
		{
			res = response;
		}
		public HttpResponse respond(HttpRequest req)
		{
			return res;
		}
	}
	
	testmethod static void validateProvisionSuccess(){
		 
		Map<String, Id> recordIdMap = new  Map<String,Id>();
		Map<String,String> payloadMap = new  Map<String,String>();
		
		//Create test data 
		recordIdMap = BAMTestUtility.createBamBasicRecords();
		
		//Get contact Id
		Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp');
		
		//Call provision to generate payload
		payloadMap = BAMProvision.provision(contactId);
		
		// Create Custom Settings 
		Database.insert(new AusPostSettings__c(Name = 'BAM_PROVISION_REQUEST', URL2__c = 'dummy_URL'));
		
		//MOCK
		HttpResponse res = new HttpResponse();
		res.setStatusCode(204);

		Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));

		Test.startTest();
		
		BAMProvisionCallout.processRequest(contactId, payloadMap);

		//Get System Error record  
		ExceptionLog__c[] excepLog = [Select Id FROM ExceptionLog__c WHERE ClassName__c = 'BAMProvisionCallout' LIMIT 1];
		
		System.debug('excepLog size='+excepLog.size());
		
		//Confirm system error was not created
		System.assertEquals(0, excepLog.size(), 'An exception log was generated and should not have been');

		Test.stopTest();
	 }
	
	testmethod static void validateProvisionError(){
		 
		Map<String, Id> recordIdMap = new  Map<String,Id>();
		Map<String,String> payloadMap = new  Map<String,String>();
		
		//Create test data 
		recordIdMap = BAMTestUtility.createBamBasicRecords();
		
		//Get contact Id
		Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp');
		
		//Call provision to generate payload
		payloadMap = BAMProvision.provision(contactId);
		
		// Create Custom Settings 
		Database.insert(new AusPostSettings__c(Name = 'BAM_PROVISION_REQUEST', URL2__c = 'dummy_URL'));
		
		//MOCK
		HttpResponse res = new HttpResponse();
		res.setStatusCode(500);

		Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));

		Test.startTest();
		
		BAMProvisionCallout.processRequest(contactId, payloadMap);

		//Get System Error record  
		ExceptionLog__c[] excepLog = [Select Id FROM ExceptionLog__c WHERE ClassName__c = 'BAMProvisionCallout' LIMIT 1];
		
		System.debug('excepLog size='+excepLog.size());
		
		//Confirm system error was not created
		System.assertEquals(0, excepLog.size(), 'An exception log was generated and should not have been');

		Test.stopTest();
	 }
	
	testmethod static void validateDeprovisionError(){
		 
		Map<String, Id> recordIdMap = new  Map<String,Id>();
		Map<String,String> payloadMap = new  Map<String,String>();
		
		//Create test data 
		recordIdMap = BAMTestUtility.createBamBasicRecords();
		
		//Get Ids
		Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp');
		
  
		//Set Contact Application to Pending Delete - i.e. deprovision
		BAMContactApplication__c[] objConApp = [Select Id, Pending_Delete__c FROM BAMContactApplication__c WHERE Contact__c = :contactId LIMIT 1];
		objConApp[0].Pending_Delete__c = true;
		update objConApp[0];
		
		//Call provision to generate payload
		payloadMap = BAMProvision.provision(contactId);
		
		// Create Custom Settings 
		Database.insert(new AusPostSettings__c(Name = 'BAM_DEPROVISION_REQUEST', URL2__c = 'dummy_URL'));
		
		//MOCK
		HttpResponse res = new HttpResponse();
		res.setStatusCode(500);

		Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));
		
		Test.startTest();
		
		BAMProvisionCallout.processRequest(contactId, payloadMap);

		//Get System Error record 
		ExceptionLog__c[] excepLog = [Select Id FROM ExceptionLog__c WHERE ClassName__c = 'BAMProvisionCallout' LIMIT 1];
		
		//Confirm system error was not created
		System.assertEquals(0, excepLog.size(), 'An exception log was generated and should not have been');

		Test.stopTest();
	 }
	
	 testmethod static void validateProvisionSystemError(){
		 
		Map<String, Id> recordIdMap = new  Map<String,Id>();
		Map<String,String> payloadMap = new  Map<String,String>();
		
		//Create test data 
		recordIdMap = BAMTestUtility.createBamBasicRecords();
		
		//Get contact Id
		Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp');
		
		//Call provision to generate payload
		payloadMap = BAMProvision.provision(contactId);
		
		//Dont Create Custom Settings to cause an error
		//Database.insert(new AusPostSettings__c(Name = 'xxxxx', URL2__c = 'dummy_URL'));
		
		//MOCK
		HttpResponse res = new HttpResponse();
		res.setStatusCode(500);

		Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));

		Test.startTest();
		
		BAMProvisionCallout.processRequest(contactId, payloadMap);

		//Get System Error record 
		ExceptionLog__c[] excepLog = [Select Id FROM ExceptionLog__c WHERE ClassName__c = 'BAMProvisionCallout' LIMIT 1];
		
		//Confirm system error was created
		System.assertNotEquals(1, excepLog.size(), 'An exception log was not generated and should have been');

		Test.stopTest();
	 }

	 testmethod static void validateCancelExternalRequest1NoPendingReqs(){
		 
		Map<String, Id> recordIdMap = new  Map<String,Id>();
		Map<String,String> payloadMap = new  Map<String,String>();

		//Get external onboarding request BAM record type id
		Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;
		
		//Create test data 
		recordIdMap = BAMTestUtility.createBamBasicRecords();
		
		//Get contact Id
		Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp');
		
		//Call provision to generate payload
		payloadMap = BAMProvision.provision(contactId);
		 
		//Set all pending requests to Success
		List<BAMExternalOnboardingRequest__c> eorList = new List<BAMExternalOnboardingRequest__c>(
						[SELECT Id, Status__c FROM BAMExternalOnboardingRequest__c 
						WHERE Contact__c = :contactId 
						AND RecordTypeId = :bamExtObRTId]);
		for(BAMExternalOnboardingRequest__c eor : eorList){
			eor.Status__c = 'Success';
		}
		if(eorList.size() > 0)
		{
			update eorList;
		}
		
		// Create Custom Settings 
		Database.insert(new AusPostSettings__c(Name = 'BAM_CANCEL_REQUEST', URL2__c = 'dummy_URL'));
		
		//Set MOCK with 204 error
		HttpResponse res = new HttpResponse();
		res.setStatusCode(204);

		Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));

		Test.startTest();
		
		 //Call cancel and expect error to be thrown with message 'There are no pending requests to be cancelled.'
		 try{
		 	BAMIntegrationUtility.cancelExternalRequest(contactId);
		 }
		 catch (Exception ex) {
			//Assert the error is the one expected
			System.assertEquals(ex.getMessage(), 'There are no pending requests to be cancelled.', 'When no Pending requests the class should return message: There are no pending requests to be cancelled.');
		}

		Test.stopTest();
	 }
	
	testmethod static void validateCancelExternalRequest2PendingReqsError(){
		 
		Map<String, Id> recordIdMap = new  Map<String,Id>();
		Map<String,String> payloadMap = new  Map<String,String>();

		//Get external onboarding request BAM record type id
		Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;
		
		//Create test data 
		recordIdMap = BAMTestUtility.createBamBasicRecords();
		
		//Get contact Id
		Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp');
		
		//Call provision to generate payload
		payloadMap = BAMProvision.provision(contactId);
		
		// Create Custom Settings 
		Database.insert(new AusPostSettings__c(Name = 'BAM_CANCEL_REQUEST', URL2__c = 'dummy_URL'));
		
		//Set MOCK with 204 error
		HttpResponse res = new HttpResponse();
		res.setStatusCode(204);

		Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));

		Test.startTest();
		//Call cancel and expect request to be cancelled
		BAMIntegrationUtility.cancelExternalRequest(contactId);
		
		//Assert that an eor record has been processed correctly
		//EOR will have Status__c = Error and Error__c = 'Request Cancelled' 
		BAMExternalOnboardingRequest__c[] eorRec = [SELECT Id, Status__c, Error__c FROM BAMExternalOnboardingRequest__c
													WHERE Contact__c = :contactId AND Status__c = 'Error' AND RecordTypeId = :bamExtObRTId  
													LIMIT 1];
		
		System.assertEquals(eorRec[0].Status__c,'Error','The status of the eor record should be Error');
		System.assertEquals(eorRec[0].Error__c,'Request Cancelled','The status of the eor record should be Error');

		Test.stopTest();
	 }
	
	testmethod static void validateCancelExternalRequest3PendingReqsMsgEmpty(){
		 
		Map<String, Id> recordIdMap = new  Map<String,Id>();
		Map<String,String> payloadMap = new  Map<String,String>();
		
		//Create test data 
		recordIdMap = BAMTestUtility.createBamBasicRecords();
		
		//Get contact Id
		Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp');
		
		//Call provision to generate payload
		payloadMap = BAMProvision.provision(contactId);
		
		// Create Custom Settings 
		Database.insert(new AusPostSettings__c(Name = 'BAM_CANCEL_REQUEST', URL2__c = 'dummy_URL'));
		
		//Set MOCK with 200 error and error message (empty)
		HttpResponse res = new HttpResponse();
		res.setStatusCode(200);
		res.setBody('{"message":""}');

		Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));

		Test.startTest();
		
		//Call cancel and expect thrown error to be returned
		try{
			BAMIntegrationUtility.cancelExternalRequest(contactId);
		}
		catch (Exception ex) {
			//Assert the error is the one expected
			System.assertEquals(ex.getMessage(), 'The cancellation request failed to process successfully.', 'When an empty message is returned the class should return message: The cancellation request failed to process successfully.');
		}

		Test.stopTest();
	 }
	testmethod static void validateCancelExternalRequest4PendingReqsMsgNotEmpty(){
		 
		Map<String, Id> recordIdMap = new  Map<String,Id>();
		Map<String,String> payloadMap = new  Map<String,String>();
		
		//Create test data 
		recordIdMap = BAMTestUtility.createBamBasicRecords();
		
		//Get contact Id
		Id contactId = recordIdMap.get('con'); 
		Id conAppId = recordIdMap.get('conapp');
		
		//Call provision to generate payload
		payloadMap = BAMProvision.provision(contactId);
		
		// Create Custom Settings 
		Database.insert(new AusPostSettings__c(Name = 'BAM_CANCEL_REQUEST', URL2__c = 'dummy_URL'));
		
		//Set MOCK with 200 success and message (popluated with 'Dummy test message')
		HttpResponse res = new HttpResponse();
		res.setStatusCode(200);
		res.setBody('{"message":"Dummy test message"}');

		Test.setMock(HttpCalloutMock.class, new EchoHttpMock(res));
		// Mock response for Managed Package Callout
		apsecrets.Auth0HTTPCalloutSimulator.setMock(new apsecrets.Auth0AccessManager_Test.Auth0HttpCalloutMock(null, null, true, null));
		
		Test.startTest();
		
		//Call cancel and expect thrown error to be returned
		try{
			BAMIntegrationUtility.cancelExternalRequest(contactId);
		}
		catch (Exception ex) {
			//Assert the error is the one expected
			System.assertEquals(ex.getMessage(), 'Dummy test message', 'When a message is returned the class should throw the same error: Dummy test message');
		}

		Test.stopTest();
	 }
}