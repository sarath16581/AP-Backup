/**
 * @description Test Class used for the CTI Integration for Australia Post and StarTrack 
 * @author Vasu Gorakati
 * @date 2025-05-03
 * @changelog
 * 2025-05-03 - Vasu Gorakati - Initial version
 */
@isTest
public class GenesysConnectorController_Test {
	
	/*****************************************************************
	 * Scenario:
	 * Star Track - Triggers a search for cases based on the consignment passed in for
	 * mutiple cases
	 *****************************************************************/
	@IsTest
	private static void multipleCaseFindConsignmentStarTrack() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getConsignments(2, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		cases[1].ArticleTest__c = articles[1].Id;
		cases[1].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticlesSelector.selectByArticleNames(new Set<String>{ articles[0].Name}, StarTrack_Constants.CON_REC_TYPE, new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE}))
			.thenReturn(articles);
		MockUtility.Mocks.when(mockCasesSelector.selectByArticleId(New Set<Id>{articles[0].Id}, StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT,new Set<Object>()))
			.thenReturn(cases);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Object result = GenesysConnectorController.findConsignmentStarTrack(articles[0].Name);

		Test.stopTest();   

		System.assertEquals(true, String.valueOf(result).contains('MultipleCase'));
		
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, MockUtility.Mocks.times(1))).selectByArticleNames((Set<String>)fflib_Match.eq(new Set<String>{ articles[0].Name}),(String)fflib_Match.eq(StarTrack_Constants.CON_REC_TYPE), (Set<Object>)fflib_Match.anyObject());
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectByArticleId((Set<Id>)fflib_Match.eq(new Set<Id>{ articles[0].Id}),(String)fflib_Match.eq(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT), (Set<Object>)fflib_Match.anyObject());

		fflib_ArgumentCaptor articleNamesCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, MockUtility.Mocks.times(1))).selectByArticleNames((Set<String>)articleNamesCaptor.capture(), (String)fflib_Match.eq(StarTrack_Constants.CON_REC_TYPE), (Set<Object>)fflib_Match.anyObject());
		Set<String> articleNamesCaptured = (Set<String>) articleNamesCaptor.getValue();

		System.assertEquals(1,articleNamesCaptured.size());
 		
		fflib_ArgumentCaptor articleIdsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectByArticleId((Set<Id>)articleIdsCaptor.capture(), (String)fflib_Match.eq(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT), (Set<Object>)fflib_Match.anyObject());
		Set<Id> articleIdsCaptured = (Set<Id>) articleIdsCaptor.getValue();

		System.assertEquals(1,articleIdsCaptured.size());
		
	}	
	/*****************************************************************
	 * Scenario:
	 * Star Track - Triggers a search for cases based on the consignment passed in for
	 * single cases
	 *****************************************************************/
	@IsTest
	private static void singleCaseFindConsignmentStarTrack() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getConsignments(1, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockArticlesSelector.selectByArticleNames(new Set<String>{ articles[0].Name}, StarTrack_Constants.CON_REC_TYPE, new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE}))
			.thenReturn(articles);
		MockUtility.Mocks.when(mockCasesSelector.selectByArticleId(New Set<Id>{articles[0].Id}, StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT,new Set<Object>()))
			.thenReturn(cases);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Object result = GenesysConnectorController.findConsignmentStarTrack(articles[0].Name);

		Test.stopTest();   

		System.assertEquals(String.valueOf(result), cases[0].Id + '_' + cases[0].CaseNumber + '_' + cases[0].Status);
		
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, MockUtility.Mocks.times(1))).selectByArticleNames((Set<String>)fflib_Match.eq(new Set<String>{ articles[0].Name}),(String)fflib_Match.eq(StarTrack_Constants.CON_REC_TYPE), (Set<Object>)fflib_Match.anyObject());
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectByArticleId((Set<Id>)fflib_Match.eq(new Set<Id>{ articles[0].Id}),(String)fflib_Match.eq(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT), (Set<Object>)fflib_Match.anyObject());

		fflib_ArgumentCaptor articleNamesCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, MockUtility.Mocks.times(1))).selectByArticleNames((Set<String>)articleNamesCaptor.capture(), (String)fflib_Match.eq(StarTrack_Constants.CON_REC_TYPE), (Set<Object>)fflib_Match.anyObject());
		Set<String> articleNamesCaptured = (Set<String>) articleNamesCaptor.getValue();

		System.assertEquals(1,articleNamesCaptured.size());
 		
		fflib_ArgumentCaptor articleIdsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectByArticleId((Set<Id>)articleIdsCaptor.capture(), (String)fflib_Match.eq(StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT), (Set<Object>)fflib_Match.anyObject());
		Set<Id> articleIdsCaptured = (Set<Id>) articleIdsCaptor.getValue();

		System.assertEquals(1,articleIdsCaptured.size());
	}

  /*****************************************************************
	 * Scenario:
	 * Attempts to do find consignment on an article that doesn't exist in salesforce yet.
	 * A continuation will be invoked to queries .net webservice
	 *****************************************************************/
	@isTest
	static void findConsignmentContinuation() {

		INSERT new StarTrack_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), Get_All_Consignment_Details__c = true,
											EMS_Endpoint__c = 'testendpt', Web_Service_Callout_Timeout__c = 10,
											Use_Continuation_for_Consignment_Search__c = true, XML_Logging__c = true,
											Logging__c = true, Log_For__c = 'ALL USER', StarTrack_ConSearch_Authentication_Level__c = 2,
											StarTrack_ConSearch_Client_Cert__c = 'cert', Sync_Web_Service_Callout_Timeout__c = 5);

		Test.startTest();

		GenesysConnectorController controller = new GenesysConnectorController();

		Continuation conti = (Continuation) GenesysConnectorController.findConsignmentStarTrack('2AT71923');

		// Perform mock callout
		HttpResponse response = new HttpResponse();
		response.setBody(StarTrackContinuationCalloutMock.getResponse_singleConsign());

		// Set the fake response for the continuation
		Map<String, HttpRequest> requests = conti.getRequests();
		String requestLabel = requests.keyset().iterator().next();
		Test.setContinuationResponse(requestLabel, response);

		// Invoke callback method
		// note this will call the controller.processSearchRemoteConsignment() instance method
		// the actual continuation call from the remote action calls the static processSearchRemoteConsignment(state) method
		Object result = Test.invokeContinuationMethod(controller, conti);

		Test.stopTest();

		// check to make sure that the article was created and the right NoCase_ response is returned.
		Article__c article = [Select Id From Article__c Where RecordType.DeveloperName = 'Consignment'];
		System.assertEquals(String.valueOf(result), 'NoCase_' + article.Id);

	}
	
	/*****************************************************************
	 * Scenario: Star Track - Get related contact of case for star track
	 *
	 *****************************************************************/  
	@IsTest
	private static void checkRelatedContactOfCaseStarTrack() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1,true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		List<AuthorisedContacts__c> relatedCons =  ApplicationTestDataFactory.getAuthorisedContacts(1,cases[0].Id, true);
		relatedCons[0] = (AuthorisedContacts__c)ApplicationTestDataFactory.setUnwritableFields(relatedCons[0], new Map<String, Object> { 'Calc_Contact_Phone_Number__c' => '0478738121'});
		
		// =====================================
		// Stubbing
		// =====================================
		AuthorisedContactsSelector mockAuthorisedContactsSelector = (AuthorisedContactsSelector) MockUtility.mockSelector(AuthorisedContactsSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAuthorisedContactsSelector.selectByCaseIdOrderByName(new Set<Id>{cases[0].Id}, new Set<Object>()))
			.thenReturn(relatedCons);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AuthorisedContacts__c relatedCon = GenesysConnectorController.checkRelatedContactOfCaseStarTrack(cases[0].Id, '0478738121');
		
		Test.stopTest();	 
		
		System.assertEquals(relatedCons[0].Id, relatedCon.Id);
		
		((AuthorisedContactsSelector)MockUtility.Mocks.verify(mockAuthorisedContactsSelector, MockUtility.Mocks.times(1))).selectByCaseIdOrderByName((Set<Id>)fflib_Match.eq(new Set<Id>{ cases[0].Id}),(Set<Object>)fflib_Match.anyObject());
  
		fflib_ArgumentCaptor caseIdsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((AuthorisedContactsSelector)MockUtility.Mocks.verify(mockAuthorisedContactsSelector, MockUtility.Mocks.times(1))).selectByCaseIdOrderByName((Set<Id>)caseIdsCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
		Set<Id> caseIdsCaptured = (Set<Id>) caseIdsCaptor.getValue();

		System.assertEquals(1,caseIdsCaptured.size());
	}	

	/*****************************************************************
	 * Scenario: Star Track - Get related case with recent caller phone details
	 *
	 *****************************************************************/ 	
	@isTest
	private static void updateCaseWithRecentCallerStarTrack(){
		
		List<Case> cases = ApplicationTestDataFactory.getCases(1,false);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		INSERT cases;
		
		List<AuthorisedContacts__c> relatedCons =  ApplicationTestDataFactory.getAuthorisedContacts(1,cases[0].Id, true);
		relatedCons[0] = (AuthorisedContacts__c)ApplicationTestDataFactory.setUnwritableFields(relatedCons[0], new Map<String, Object> { 'Calc_Contact_Phone_Number__c' => '0478738121'});

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		Case c = GenesysConnectorController.updateCaseWithRecentCallerStarTrack(relatedCons[0], cases[0].Id);
		
		Test.stopTest();
		
		System.assertEquals('0478738121', c.Recent_Caller_Phone_Number__c);
	}
	
	/*****************************************************************
	 * Scenario: Star Track - Create case with consignment number
	 *
	 *****************************************************************/ 	
	@isTest
	private static void createCasewithConsignmentNumberStarTrack(){
		
		List<Article__c> articles = ApplicationTestDataFactory.getConsignments(1, false);
		INSERT articles;
		
		Test.startTest();
		
		Case c = GenesysConnectorController.createCasewithConsignmentNumberStarTrack(articles[0].Id, '0432077466', false, null, null, null);
		
		Test.stopTest();  
		
		System.Assert(c != null, 'case should not be null');
	}   

	/*****************************************************************
	 * Scenario: Star Track - Create call log for Star Track
	 *
	 *****************************************************************/ 	
	@isTest
	private static void createCallLog(){
		
		List<Case> cases = ApplicationTestDataFactory.getCases(1,false);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		INSERT cases;
		
		Test.startTest();
		
		String result = GenesysConnectorController.createCallLogStarTrack(cases[0].Id);
		
		Test.stopTest();
		
		System.assertEquals('Success', result);
	}
	/*****************************************************************
	 * Scenario: Australia Post - search by Case id
	 *
	 *****************************************************************/ 
	@isTest
	static void searchAPCaseId() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;

		// =====================================
		// Stubbing
		// =====================================
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById(New Set<Id>{cases[0].Id}, new Set<Object>{CasesSelector.Options.WITH_CONTACT}))
			.thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		Map<String, String> jsonMap = new Map<String, String>();
		jsonMap.put('caseId', cases[0].Id);
		String eventJson = JSON.serialize(jsonMap);
		Map<String, Object> result = GenesysConnectorController.searchAP(eventJson);
		
		Test.stopTest();

		System.assertEquals('caseId', result.get('match'));
	}
	
	/*****************************************************************
	 * Scenario: Australia Post - search by Case Number
	 *
	 *****************************************************************/ 
	@isTest
	static void searchAPCaseNumber() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;
		
		// =====================================
		// Stubbing
		// =====================================
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectByCaseNumber(new Set<String>{cases[0].CaseNumber},new Set<Object>{CasesSelector.Options.WITH_CONTACT}))
			.thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
	
		Map<String, String> jsonMap = new Map<String, String>();
		jsonMap.put('caseNumber', cases[0].CaseNumber);
		String eventJson = JSON.serialize(jsonMap);
		Map<String, Object> result = GenesysConnectorController.searchAP(eventJson);
		
		Test.stopTest();

		System.assertEquals('caseNumber', result.get('match'));
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectByCaseNumber((Set<String>)fflib_Match.eq(new Set<String>{ cases[0].CaseNumber}),(Set<Object>)fflib_Match.anyObject());

		fflib_ArgumentCaptor caseNumbersCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectByCaseNumber((Set<String>)caseNumbersCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
		Set<String> caseNumbersCaptured = (Set<String>) caseNumbersCaptor.getValue();

		System.assertEquals(1,caseNumbersCaptured.size());
	}
	
 	/*****************************************************************
	 * Scenario: Australia Post - search by Tracking Number
	 *
	 *****************************************************************/ 
	@isTest
	static void searchAPTrackingNumber() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;
		cases[0].ReferenceID__c = 'I2DZ07794311';
		
		// =====================================
		// Stubbing
		// =====================================
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectCasesByReferenceId(new Set<String>{cases[0].ReferenceID__c},new Set<Object>{CasesSelector.Options.WITH_CONTACT}))
			.thenReturn(cases);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		Map<String, String> jsonMap = new Map<String, String>();
		jsonMap.put('trackingNumber', cases[0].ReferenceID__c);
		String eventJson = JSON.serialize(jsonMap);
		Map<String, Object> result = GenesysConnectorController.searchAP(eventJson);
		
		Test.stopTest();

		System.assertEquals('trackingNumber', result.get('match'));

		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectCasesByReferenceId((Set<String>)fflib_Match.eq(new Set<String>{cases[0].ReferenceID__c}),(Set<Object>)fflib_Match.anyObject());

		fflib_ArgumentCaptor caseReferenceIdsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectCasesByReferenceId((Set<String>)caseReferenceIdsCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
		Set<String> caseReferenceIdsCaptured = (Set<String>) caseReferenceIdsCaptor.getValue();

		System.assertEquals(1,caseReferenceIdsCaptured.size());
	}	
	
 	/*****************************************************************
	 * Scenario: Australia Post - search by Contact Id
	 *
	 *****************************************************************/ 
	@isTest
	static void searchAPContactId() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> acc = ApplicationTestDataFactory.getPersonAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc[0].Id, true);
		
		// =====================================
		// Stubbing
		// =====================================
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectById(new Set<Id>{contacts[0].Id}, new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE}))
			.thenReturn(new Map<Id, Contact>(contacts));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		Map<String, String> jsonMap = new Map<String, String>();
		jsonMap.put('contactId', contacts[0].Id);
		String eventJson = JSON.serialize(jsonMap);
		Map<String, Object> result = GenesysConnectorController.searchAP(eventJson);
		
		Test.stopTest();

		System.assertEquals('contactId', result.get('match'));
	
		((ContactsSelector)MockUtility.Mocks.verify(mockContactsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contacts[0].Id}),(Set<Object>)fflib_Match.anyObject());

		fflib_ArgumentCaptor contactIdsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((ContactsSelector)MockUtility.Mocks.verify(mockContactsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)contactIdsCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
		Set<Id> contactIdsCaptured = (Set<Id>) contactIdsCaptor.getValue();

		System.assertEquals(1,contactIdsCaptured.size());
	}
	
 	/*****************************************************************
	 * Scenario: Australia Post - search by Contact Phone 
	 *
	 *****************************************************************/ 
	@isTest
	static void searchAPContactPhoneNumber() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> acc = ApplicationTestDataFactory.getPersonAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc[0].Id, true);
		contacts[0].Phone = '0432077466';
		
		// =====================================
		// Stubbing
		// =====================================
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectByLikedAnyPhoneOrderByName(contacts[0].Phone, new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE}))
			.thenReturn(new Map<Id, Contact>(contacts));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		Map<String, String> jsonMap = new Map<String, String>();
		jsonMap.put('phoneNumber', contacts[0].Phone);
		String eventJson = JSON.serialize(jsonMap);
		Map<String, Object> result = GenesysConnectorController.searchAP(eventJson);
		
		Test.stopTest();

		System.assertEquals('phoneNumber', result.get('match'));

		((ContactsSelector)MockUtility.Mocks.verify(mockContactsSelector, MockUtility.Mocks.times(1))).selectByLikedAnyPhoneOrderByName((String)fflib_Match.eq(contacts[0].Phone),(Set<Object>)fflib_Match.anyObject());

		fflib_ArgumentCaptor contactphoneCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((ContactsSelector)MockUtility.Mocks.verify(mockContactsSelector, MockUtility.Mocks.times(1))).selectByLikedAnyPhoneOrderByName((String)contactPhoneCaptor.capture(), (Set<Object>)fflib_Match.anyObject());
	
		System.assertEquals(true,contactPhoneCaptor != null);
	}

 	/*****************************************************************
	 * Scenario: Australia Post - check task creation for AP
	 *
	 *****************************************************************/ 
	@isTest
	static void maintainTaskAP() {

		Map<String, Object> mapCallLog = new Map<String, Object>{
			'callType' => 'Inbound',
			'enquiryType' => 'BusinessSolutions',
			'enquirySubType' => 'Priority 1',
			'phoneNumber' => 'Invalid or No Selection'
		};
		
		String callLog = JSON.serialize(mapCallLog);

		Map<String, Object> mapTaskDetails = new Map<String, Object>{
			'interactionId' => 'test12'
		};
		
		String taskDetails = JSON.serialize(mapTaskDetails);

		// =====================================
		// Testing
		// =====================================		
		Test.startTest();
		
		object result = GenesysConnectorController.maintainTaskAP(callLog, taskDetails, callLog);
		
		Test.stopTest();
		
		System.Assert(result != null, 'task should be inserted');
	}
}