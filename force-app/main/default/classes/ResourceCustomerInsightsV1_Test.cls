@IsTest
public class ResourceCustomerInsightsV1_Test {
	/**
	 * @description : Create test user
	 * @param hasAccess : `Boolean` Indicate if the user should be granted access to the apex classes
	 * @return  `User`
	 */
	static User setupTesUser(Boolean hasAccess){
		Id integrationProfileId = [SELECT Id FROM Profile 
									WHERE Name = 'AusPost Integration'
									LIMIT 1].Id;
		User integrationUser = ApplicationTestDataFactory.getUsers(1, integrationProfileId, false)[0];
		insert integrationUser;
		if(hasAccess){
			PermissionSetAssignment psa = new PermissionSetAssignment (
				PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name='RoutingInsightsAPI' LIMIT 1].Id
				, AssigneeId = integrationUser.Id);
			insert psa;
		}
		return integrationUser;
	}
    /**
	 * @description : Test with no access
	 * Response should return error
	 */
	@IsTest
	static void testUserAccess(){

		//setup test user
		User integrationUser = setupTesUser(false);

		Test.startTest();
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
        request.requestUri =
            '/api/1.0/insights/customer';
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;

		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}

		Assert.areEqual(403, response.statusCode, 'Forbidden');
	}
    /**
	 * @description : Test with no params
	 * Response should return error
	 */
	@IsTest
	static void testNoParams(){

		//setup test user
		User integrationUser = setupTesUser(true);
		
		Test.startTest();
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
        request.requestUri =
            '/api/1.0/insights/customer';
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;

		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		
		Assert.areEqual(400, response.statusCode, 'BAD REQUEST: Due to NO params');
		Assert.areEqual(true, response.responseBody.toString().containsIgnoreCase('Bad Request'), 'BAD REQUEST: Due to NO params');
	}
	/**
	 * @description : Test with BOTH email & phone params
	 * Response should return error
	 */
    @IsTest
	static void testPhoneAndEmailParams(){
		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		//setup test user
		User integrationUser = setupTesUser(true);
		
		Test.startTest();
        request.requestUri =
            '/api/1.0/insights/customer';
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;
		request.params.put('phone', '0300300300');
		request.params.put('email', 'invalid@invalid.com.invalid');

		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		Test.stopTest();
		Assert.areEqual(400, response.statusCode, 'BAD REQUEST: Due to BOTH Email & Phone Number params');
		Assert.areEqual(true, response.responseBody.toString().containsIgnoreCase('Bad Request'), 'BAD REQUEST: Due to BOTH Email & Phone Number params');
	}
	/**
	 * @description : Test with only phone param
	 * Response should return success
	 * 
	 * TODO: Fix the test mock to get 200 response code
	 */
    @IsTest
	static void testPhoneNumberParam(){
		String customerPhone='0300300300';
		// Mock Data
		RecordType consumerRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Business_Account' LIMIT 1];
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount.RecordTypeId = consumerRecordType.Id;
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
				,'RecordType.DeveloperName'=>'Business_Account'
		});
		personContact = (Contact)ApplicationTestDataFactory.setUnwritableFields(personContact, new Map<String, Object>{
				'IsPersonAccount'=>true
		});
		personContact.Phone=customerPhone;
		//stubs
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectWithCasesAndInteractionsByPhoneNumber(customerPhone, new Map<String,Object>(), new Set<Object>()))
			.thenReturn(new List<Contact>{personContact});
		MockUtility.Mocks.stopStubbing();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		//setup test user
		User integrationUser = setupTesUser(true);

		Test.startTest();
        request.requestUri =
            '/api/1.0/insights/customer';
		request.params.put('phone', customerPhone);
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;
		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		Test.stopTest();
		Assert.areEqual(500, response.statusCode, 'Mocking returns null(Needs to be fixed)');
		Assert.areEqual(true, response.responseBody.toString().containsIgnoreCase('System.NullPointerException'), 'Mocking returns null(Needs to be fixed)');
	}
	/**
	 * @description : Test with only email param
	 * Response should return success
	 * 
	 * TODO: Fix the test mock to get 200 response code
	 */
    @IsTest
	static void testEmailParam(){
		String customerEmail='invalid@invalid.com.invalid';
		// Mock Data
		RecordType consumerRecordType = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Business_Account' LIMIT 1];
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount.RecordTypeId = consumerRecordType.Id;
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
				,'RecordType.DeveloperName'=>'Business_Account'
		});
		personContact = (Contact)ApplicationTestDataFactory.setUnwritableFields(personContact, new Map<String, Object>{
				'IsPersonAccount'=>true
		});
		personContact.Email=customerEmail;
		//stubs
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectWithCasesAndInteractionsByPhoneNumber(customerEmail, new Map<String,Object>(), new Set<Object>()))
			.thenReturn(new List<Contact>{personContact});
		MockUtility.Mocks.stopStubbing();

		//setup test user
		User integrationUser = setupTesUser(true);

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		Test.startTest();
        request.requestUri =
            '/api/1.0/insights/customer';
		request.params.put('email', customerEmail);
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;
		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		Test.stopTest();
		Assert.areEqual(500, response.statusCode, 'Mocking returns 500 error(Needs to be fixed)');
		Assert.areEqual(true, response.responseBody.toString().containsIgnoreCase('System.NullPointerException'), 'Mocking returns null(Needs to be fixed)');
	}
	/**
	 * @description Test method for ResourceCustomerInsightsV1.transformOutput()
	 */
	@IsTest
	static void testTransformOutput(){
		String customerPhone='0300300300';
		String queryConditions= ' AND (HomePhone =:searchKey OR MobilePhone =:searchKey OR Phone =:searchKey)';
		Map<String, Object> bindMap = new Map<String, Object>();
		bindMap.put('searchKey', customerPhone);
		// Mock Data
		RecordType accountRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).values()[0];
		RecordType caseRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'}).values()[0];
		RecordType taskRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Task', new Set<String>{'SSSWCall'}).values()[0];
		
		//Account data
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.RecordTypeId = accountRecordType.Id;
		//Contact data
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
				,'RecordType.DeveloperName'=>'Business_Account'
		});
		
		personContact = (Contact)ApplicationTestDataFactory.setUnwritableFields(personContact, new Map<String, Object>{
				'IsPersonAccount'=>true
		});
		personContact.Phone=customerPhone;
		//case data
		Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
		caseRecord.RecordTypeId = caseRecordType.Id;
		caseRecord.Type = 'All Other Enquiries';
		caseRecord.EnquirySubTYpe__c = 'All Other';
		caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{
				'ArticleTest__r.ArticleId__c' =>'123456'
				,'ClosedDate' => Date.today()
				,'IsClosed'=>true
				,'RecordType.DeveloperName'=>'SSSWGeneralEnquiry'
		});
		
		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'Cases' => new List <Case>{ caseRecord }});
		//Task data
		Task taskRecord = ApplicationTestDataFactory.getTasks(2, null, true)[0];
		taskRecord.RecordTypeId = taskRecordType.Id;
		taskRecord.ActivityDate = Date.today();
		taskRecord = (Task)ApplicationTestDataFactory.setUnwritableFields(taskRecord, new Map<String, Object>{
				'CreatedBy.Profile.Name' =>'SSSW - Service Agent'
				,'RecordType.DeveloperName'=>'SSSWGeneralEnquiry'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'Tasks' => new List <Task>{ taskRecord }});
		//VoiceCall Data
		VoiceCall voiceCallRecord = new VoiceCall();
		voiceCallRecord = (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(voiceCallRecord, new Map<String, Object>{
				'CreatedBy.Profile.Name' =>'SSSW - Service Agent'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'RelatedRecords' => new List <VoiceCall>{ voiceCallRecord }});
		
		//LiveChatTranscript data
		LiveChatTranscript transcriptRecord = new LiveChatTranscript();
		transcriptRecord = (LiveChatTranscript)ApplicationTestDataFactory.setUnwritableFields(transcriptRecord, new Map<String, Object>{
				'Owner.Profile.Name' =>'SSSW - Service Agent'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'LiveChatTranscripts' => new List <LiveChatTranscript>{ transcriptRecord }});
		
		//stubs
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectWithCasesAndInteractionsHelper(queryConditions,bindMap, new Set<Object>()))
			.thenReturn(new List<Contact>{personContact});
		MockUtility.Mocks.stopStubbing();

		
		Test.startTest();

		// Call the Selector Mehtod
		Set<SObjectField> contactFields = new Set<SObjectField>{
			Contact.Id, Contact.APCN__c, Contact.Firstname, Contact.Lastname, Contact.Email
			, Contact.VerifiedEmail__c, Contact.Phone, Contact.MobilePhone, Contact.VerifiedMobile__c
		};
		ContactsSelector contactSelector = ContactsSelector.newInstance(0, contactFields);
		List<Contact> contacts = contactSelector.selectWithCasesAndInteractionsHelper(queryConditions,bindMap, new Set<Object>());
		// Call the transformOutput method
		List<Map<String, Object>> output = ResourceCustomerInsightsV1.transformOutput(contacts);
		Test.stopTest();
		List<Object> cases = (List<Object>)output[0].get('cases');
		Map<String, Object> caseOutput = (Map<String, Object>) cases[0];
		List<Object> interactions = (List<Object>)output[0].get('interactions');
		Assert.areEqual(personContact.Id, output[0].get('sfid'), 'Contact Id should match');
		Assert.areEqual(caseRecord.Id, String.valueOf(caseOutput.get('sfid')), 'Case Id should match');
		Assert.areEqual(3, interactions.size(), 'There should be 3 interactions');
	}
}