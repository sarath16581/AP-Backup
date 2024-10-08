/**
 * @description Test Class used for ResourceCustomerInsightsV1
 * @author Rejeesh Raghavan
 * @date 2024/09/05
 * @changelog
 * 2024/09/05 - Rejeesh Raghavan - Initial version
 */
@IsTest
public class ResourceCustomerInsightsV1_Test {
	/**
	 * @description : Create test user
	 * @param hasAccess : `Boolean` Indicate if the user should be granted access to the apex classes
	 * @return  `User`
	 */
	static User setupTestUser(Boolean hasAccess){
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
	 * @description : Create bindMap variable to be passed as bindMap for SOQL
	 * @param hasCaseType 
	 * @param hasInteractionType 
	 * @return  `Map<String, Object>` bindMap
	 */
	static Map<String, Object> getBindMap(Boolean hasCaseType, Boolean hasInteractionType){
		Map<String, Object> bindMap = new Map<String, Object>();
		if(hasCaseType){
			Set<String> caseRecordTypes = new Set<String>();
			caseRecordTypes.addAll(ResourceCustomerInsightsV1.AP_CASE_RECORDTYPES);
			caseRecordTypes.addAll(ResourceCustomerInsightsV1.ST_CASE_RECORDTYPES);
			caseRecordTypes.addAll(ResourceCustomerInsightsV1.UNIFIED_CASE_RECORDTYPES);
			bindMap.put('caseRecordTypes',caseRecordTypes);
			bindMap.put('closedCaseCutoffDate',Date.today().addDays(-30));
			
			//add Case sub-query conditions 
			bindMap.put('caseConditions', '((IsClosed = true AND ClosedDate >=:closedCaseCutoffDate) OR IsClosed = false) AND  RecordType.DeveloperName  IN :caseRecordTypes');
		}
		if(hasInteractionType){
			Set<String> interactionProfiles = new Set<String>();
			interactionProfiles.addAll(ResourceCustomerInsightsV1.AP_CC_PROFILES);
			interactionProfiles.addAll(ResourceCustomerInsightsV1.ST_CC_PROFILES);
			interactionProfiles.addAll(ResourceCustomerInsightsV1.U_CC_PROFILES);
			bindMap.put('interactionProfiles', interactionProfiles);
			bindMap.put('interactionCutoffDate', Date.today().addDays(-30));

			//add Tasks sub-query conditions
			bindMap.put('taskType', 'Phone Call');
			bindMap.put('apVoiceCallRecordType', 'SSSWCall');
			bindMap.put('taskConditions', '(Type =:taskType  OR  RecordType.DeveloperName =:apVoiceCallRecordType) AND CreatedDate >=:interactionCutoffDate AND CreatedBy.Profile.Name IN :interactionProfiles');
			
			//add VoiceCalls sub-query conditions
			bindMap.put('voiceCallsConditions', 'CreatedDate >=:interactionCutoffDate AND LastModifiedBy.Profile.Name IN :interactionProfiles');
			
			//add LiveChatTranscripts sub-query conditions
			bindMap.put('liveChatTranscriptConditions', 'CreatedDate >=:interactionCutoffDate AND Owner.Profile.Name IN :interactionProfiles');
		}
		return bindMap;
	}

    /**
	 * @description : Test with no access
	 * Response should return error
	 */
	@IsTest
	static void testUserAccess(){

		//setup test user
		User integrationUser = setupTestUser(false);

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
		User integrationUser = setupTestUser(true);
		
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
		User integrationUser = setupTestUser(true);
		
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
	 * @description : Test with only phone param (case_type & interaction_type will be defaulted to allcontactcentre)
	 * Response should return success
	 */
    @IsTest
	static void testPhoneNumberParam(){
		String customerPhone='0300300300';
		
		//reverse the phone number
		String reversedPhone = Util.reversePhoneString(customerPhone);
		
		// Mock Data
		RecordType accountRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).values()[0];
		RecordType caseRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'}).values()[0];
		RecordType taskRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Task', new Set<String>{'SSSWCall'}).values()[0];
		//Account data
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.RecordTypeId = accountRecordType.Id;
		//Contact data
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personContact.Phone=customerPhone;
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
				,'RecordType.DeveloperName'=>'Business_Account'
		});
		personContact = (Contact)ApplicationTestDataFactory.setUnwritableFields(personContact, new Map<String, Object>{
				'IsPersonAccount'=>true
				,'ReversePhone__c'=> reversedPhone
		});

		//Case data
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
				'LastModifiedBy.Profile.Name' =>'SSSW - Service Agent'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'Voice_Calls__r' => new List <VoiceCall>{ voiceCallRecord }});
		
		//LiveChatTranscript data
		LiveChatTranscript transcriptRecord = new LiveChatTranscript();
		transcriptRecord = (LiveChatTranscript)ApplicationTestDataFactory.setUnwritableFields(transcriptRecord, new Map<String, Object>{
				'Owner.Profile.Name' =>'SSSW - Service Agent'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'LiveChatTranscripts' => new List <LiveChatTranscript>{ transcriptRecord }});
		
		//class bindMap variables
		Map<String, Object> bindMap = getBindMap(true, true);
		
		//stubs
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectWithCasesAndInteractionsByReversePhoneNumber(
			reversedPhone
			, bindMap
			, new Set<Object>{
				ContactsSelector.ComplexSubQueryOptions.WITH_RECENT_CASES
				, ContactsSelector.ComplexSubQueryOptions.WITH_ALL_RECENT_INTERACTIONS
			}))
			.thenReturn(new List<Contact>{personContact});
		MockUtility.Mocks.stopStubbing();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		//setup test user
		User integrationUser = setupTestUser(true);

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
		Map<String, Object> jsonResponseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		List<Object> responseBody = (List<Object>)(jsonResponseBody.get('response'));
		Map<String, Object> jsonCustomerRecord = (Map<String, Object>)responseBody[0];
		List<Object> jsonCases = (List<Object>)(jsonCustomerRecord.get('cases'));
		Map<String, Object> jsonCaseRecord = (Map<String, Object>)jsonCases[0];
		List<Object> jsonInteractions = (List<Object>)(jsonCustomerRecord.get('interactions'));
		Assert.areEqual(200, response.statusCode, 'Respose code should be success');
		Assert.areEqual(true, jsonResponseBody.get('success'),'Response code should be success');
		Assert.areEqual(personContact.Id, jsonCustomerRecord.get('sfid'),'Contact Id should match');
		Assert.areEqual(caseRecord.Id, (String)jsonCaseRecord.get('sfid'),'Case Id should match');
		Assert.areEqual(3, jsonInteractions.size(),'There should be 3 interactions');
	}
	/**
	 * @description : Test with phone param & case_type params & interaction_type as allcontactcentre
	 * Response should return success
	 */
    @IsTest
	static void testValidPhoneNumberAndCaseTypeAndInteractionTypeParams(){
		String customerPhone='0300300300';

		//reverse the phone number
		String reversedPhone = Util.reversePhoneString(customerPhone);

		// Mock Data
		RecordType accountRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).values()[0];
		RecordType caseRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'}).values()[0];
		RecordType taskRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Task', new Set<String>{'SSSWCall'}).values()[0];

		//Account data
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.RecordTypeId = accountRecordType.Id;

		//Contact data
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personContact.Phone=customerPhone;
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
				,'RecordType.DeveloperName'=>'Business_Account'
		});
		personContact = (Contact)ApplicationTestDataFactory.setUnwritableFields(personContact, new Map<String, Object>{
				'IsPersonAccount'=>true
				,'ReversePhone__c'=> reversedPhone
		});

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
				'LastModifiedBy.Profile.Name' =>'SSSW - Service Agent'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'Voice_Calls__r' => new List <VoiceCall>{ voiceCallRecord }});
		
		//LiveChatTranscript data
		LiveChatTranscript transcriptRecord = new LiveChatTranscript();
		transcriptRecord = (LiveChatTranscript)ApplicationTestDataFactory.setUnwritableFields(transcriptRecord, new Map<String, Object>{
				'Owner.Profile.Name' =>'SSSW - Service Agent'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'LiveChatTranscripts' => new List <LiveChatTranscript>{ transcriptRecord }});

		//class bindMap variables
		Map<String, Object> bindMap = getBindMap(true, true);
		
		//stubs
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectWithCasesAndInteractionsByReversePhoneNumber(
			reversedPhone
			, bindMap
			, new Set<Object>{
				ContactsSelector.ComplexSubQueryOptions.WITH_RECENT_CASES
				, ContactsSelector.ComplexSubQueryOptions.WITH_ALL_RECENT_INTERACTIONS
			}))
			.thenReturn(new List<Contact>{personContact});
		MockUtility.Mocks.stopStubbing();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		//setup test user
		User integrationUser = setupTestUser(true);

		Test.startTest();
        request.requestUri =
            '/api/1.0/insights/customer';
		request.params.put('phone', customerPhone);
		request.params.put('case_type', 'allcontactcentre');
		request.params.put('interaction_type', 'allcontactcentre');
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;
		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		Test.stopTest();
		Map<String, Object> jsonResponseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		List<Object> responseBody = (List<Object>)(jsonResponseBody.get('response'));
		Map<String, Object> jsonCustomerRecord = (Map<String, Object>)responseBody[0];
		List<Object> jsonCases = (List<Object>)(jsonCustomerRecord.get('cases'));
		Map<String, Object> jsonCaseRecord = (Map<String, Object>)jsonCases[0];
		List<Object> jsonInteractions = (List<Object>)(jsonCustomerRecord.get('interactions'));
		Assert.areEqual(200, response.statusCode, 'Respose code should be success');
		Assert.areEqual(true, jsonResponseBody.get('success'),'Response code should be success');
		Assert.areEqual(personContact.Id, jsonCustomerRecord.get('sfid'),'Contact Id should match');
		Assert.areEqual(caseRecord.Id, (String)jsonCaseRecord.get('sfid'),'Case Id should match');
		Assert.areEqual(3, jsonInteractions.size(),'There should be 3 interactions');
	}
	/**
	 * @description : Test with phone param & INVALID case_type params & interaction_type params
	 * Response should return success, but there should not be any case or interaction records
	 */
    @IsTest
	static void testValidPhoneNumberAndInvalidCaseTypeAndInteractionTypeParams(){
		String customerPhone='0300300300';

		//reverse the phone number
		String reversedPhone = Util.reversePhoneString(customerPhone);

		// Mock Data
		RecordType accountRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Account', new Set<String>{'Business_Account'}).values()[0];

		//Account data
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.RecordTypeId = accountRecordType.Id;
		//Contact data
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personContact.Phone=customerPhone;
		personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{
				'PersonContactId' => personContact.Id
				,'RecordType.DeveloperName'=>'Business_Account'
		});
		personContact = (Contact)ApplicationTestDataFactory.setUnwritableFields(personContact, new Map<String, Object>{
				'IsPersonAccount'=>true
				,'ReversePhone__c'=> reversedPhone
		});
		
		//class bindMap variables
		Map<String, Object> bindMap = getBindMap(false, false);
		
		//stubs
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectWithCasesAndInteractionsByReversePhoneNumber(reversedPhone, bindMap, new Set<Object>()))
			.thenReturn(new List<Contact>{personContact});
		MockUtility.Mocks.stopStubbing();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		//setup test user
		User integrationUser = setupTestUser(true);

		Test.startTest();
        request.requestUri =
            '/api/1.0/insights/customer';
		request.params.put('phone', customerPhone);
		request.params.put('case_type', 'invalid');
		request.params.put('interaction_type', 'invalid');
        request.httpMethod = 'GET';
        RestContext.request = request;
		RestContext.response = response;
		System.runAs(integrationUser){
			// Call the method to test
			ResourceApiController.query();
		}
		Test.stopTest();
		Map<String, Object> jsonResponseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		List<Object> responseBody = (List<Object>)(jsonResponseBody.get('response'));
		Map<String, Object> jsonCustomerRecord = (Map<String, Object>)responseBody[0];
		List<Object> jsonCases = (List<Object>)(jsonCustomerRecord.get('cases'));
		List<Object> jsonInteractions = (List<Object>)(jsonCustomerRecord.get('interactions'));
		Assert.areEqual(200, response.statusCode, 'Respose code should be success');
		Assert.areEqual(true, jsonResponseBody.get('success'),'Response code should be success');
		Assert.areEqual(personContact.Id, jsonCustomerRecord.get('sfid'),'Contact Id should match');
		Assert.areEqual(0, jsonCases.size(),'There should be 0 cases');
		Assert.areEqual(0, jsonInteractions.size(),'There should be 0 interactions');
	}
	/**
	 * @description : Test with only email param (case_type & interaction_type will be defaulted to allcontactcentre)
	 * Response should return success
	 */
    @IsTest
	static void testEmailParam(){
		String customerEmail='invalid@invalid.com.invalid';

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
		personContact.Email=customerEmail;

		//Case data
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
				'LastModifiedBy.Profile.Name' =>'SSSW - Service Agent'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'Voice_Calls__r' => new List <VoiceCall>{ voiceCallRecord }});
		
		//LiveChatTranscript data
		LiveChatTranscript transcriptRecord = new LiveChatTranscript();
		transcriptRecord = (LiveChatTranscript)ApplicationTestDataFactory.setUnwritableFields(transcriptRecord, new Map<String, Object>{
				'Owner.Profile.Name' =>'SSSW - Service Agent'
		});

		personContact = (Contact)ApplicationTestDataFactory.setChildRelationships(personContact,new Map <String, List <SObject>> {'LiveChatTranscripts' => new List <LiveChatTranscript>{ transcriptRecord }});

		//class bindMap variables
		Map<String, Object> bindMap = getBindMap(true, true);
		
		//stubs
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectWithCasesAndInteractionsByEmailAddress(
			customerEmail
			, bindMap
			, new Set<Object>{
				ContactsSelector.ComplexSubQueryOptions.WITH_RECENT_CASES
				, ContactsSelector.ComplexSubQueryOptions.WITH_ALL_RECENT_INTERACTIONS
			}))
			.thenReturn(new List<Contact>{personContact});
		MockUtility.Mocks.stopStubbing();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		//setup test user
		User integrationUser = setupTestUser(true);

		Test.startTest();
		System.debug('customerEmail T:'+ customerEmail);
		System.debug('bindMap T:'+ JSON.serialize(bindMap));
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
		Map<String, Object> jsonResponseBody = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		List<Object> responseBody = (List<Object>)(jsonResponseBody.get('response'));
		Map<String, Object> jsonCustomerRecord = (Map<String, Object>)responseBody[0];
		List<Object> jsonCases = (List<Object>)(jsonCustomerRecord.get('cases'));
		Map<String, Object> jsonCaseRecord = (Map<String, Object>)jsonCases[0];
		List<Object> jsonInteractions = (List<Object>)(jsonCustomerRecord.get('interactions'));
		Assert.areEqual(200, response.statusCode, 'Respose code should be success');
		Assert.areEqual(true, jsonResponseBody.get('success'),'Response code should be success');
		Assert.areEqual(personContact.Id, jsonCustomerRecord.get('sfid'),'Contact Id should match');
		Assert.areEqual(caseRecord.Id, (String)jsonCaseRecord.get('sfid'),'Case Id should match');
		Assert.areEqual(3, jsonInteractions.size(),'There should be 3 interactions');
	}
}