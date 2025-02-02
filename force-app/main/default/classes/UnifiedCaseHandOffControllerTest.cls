/**
 * @description Test class for UnifiedCaseHandOffController
 * @author Vasu Gorakati
 * @date 2024-06-18
 * @changelog
 * 2024-06-18 - Vasu Gorakati - Case Hand-off
 * 2024-07-18 - Raghav Ravipati - Added changes to test duplicate consigment scenarios.
 * 2024-09-20 - Vasu Gorakati - CSLU-799 - Schedule Contact Request Cancellation
 **/
@isTest
public class UnifiedCaseHandOffControllerTest {
	@isTest
	static void testSingleArticleConsignment() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Article__c> articles = ApplicationTestDataFactory.getConsignments(1, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(1, cases[0].Id, articles[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);

		MockUtility.Mocks.startStubbing();

		// set up our responses
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByArticleNames(new Set<String>{ articles[0].Name }, StarTrack_Constants.CON_REC_TYPE, new Set<Object>{ ArticlesSelector.Options.WITH_RECORDTYPE })
			)
			.thenReturn(new List<Article__c>{ articles[0] });
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{ cases[0].Id }, new Set<Object>{ CasesSelector.Options.WITH_CONTACT }))
			.thenReturn(new Map<Id, Case>{ cases[0].Id => cases[0] });
		MockUtility.Mocks.when(mockImpactedArticlesSelector.selectByCaseId(new Set<Id>{ cases[0].Id }, new Set<Object>())).thenReturn(impactedArticles);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		String businessUnit = UnifiedCaseHandOffController.getBusinessUnit(articles[0].ProductId__c);

		UnifiedCaseHandOffController.CaseHandOffWrapper request = new UnifiedCaseHandOffController.CaseHandOffWrapper();
		request.articleId = '';
		request.businessUnit = businessUnit;
		request.caseId = cases[0].Id;
		request.caseRecordType = 'UnifiedInvestigation';
		request.comment = 'Testing';
		request.contactCenter = 'UnifiedAusPostHandoffTriageQueue';
		request.handoffReason = 'Network contact required';

		UnifiedCaseHandOffController.handOffCase(request);

		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		Id caseSSSWDeliveryRecordType = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		Id caseSSSWentitlement = UnifiedCaseHandOffController.getSSSWEntitlementId();
		System.assertNotEquals(null, cases[0].CaseTransferDate__c, 'Case transfer date should be updated');
		System.assertEquals('Network contact required', cases[0].CaseTransferReason__c, 'Case transfer reason should be updated');
		System.assertEquals(caseSSSWentitlement, cases[0].EntitlementId, 'Case Entitlement should be set to Standard Entitlement - SSSW');
		System.assertEquals(caseSSSWDeliveryRecordType, cases[0].RecordTypeId, 'Record type should be set to SSSWDelivery');
	}

	@isTest
	static void testMultiArticleConsignment() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Article__c> articles = ApplicationTestDataFactory.getConsignments(2, true); // Example: 2 articles
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(2, cases[0].Id, articles[0].Id, true); // Example: 2 impacted articles

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		//set up responses
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByArticleNames(new Set<String>{ articles[0].Name }, StarTrack_Constants.CON_REC_TYPE, new Set<Object>{ ArticlesSelector.Options.WITH_RECORDTYPE })
			)
			.thenReturn(articles);
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{ cases[0].Id }, new Set<Object>{ CasesSelector.Options.WITH_CONTACT }))
			.thenReturn(new Map<Id, Case>{ cases[0].Id => cases[0] });
		MockUtility.Mocks.when(mockImpactedArticlesSelector.selectByCaseId(new Set<Id>{ cases[0].Id }, new Set<Object>())).thenReturn(impactedArticles);

		// Capture database updates and inserts
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		// Create wrapper for case handoff
		UnifiedCaseHandOffController.CaseHandOffWrapper request = new UnifiedCaseHandOffController.CaseHandOffWrapper();
		request.articleId = '';
		request.businessUnit = 'AustraliaPost';
		request.caseId = cases[0].Id;
		request.caseRecordType = 'UnifiedInvestigation';
		request.comment = 'Testing';
		request.contactCenter = 'UnifiedAusPostHandoffTriageQueue';
		request.handoffReason = 'Network contact required';

		// Call the method under test
		UnifiedCaseHandOffController.handOffCase(request);

		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		List<List<sObject>> insertRecs = MockUtility.verifyAndCaptureInsertedDmlRecords(mockDatabase, 2);

		List<Case> insertedChildCases = new List<Case>();
		List<CaseComment> insertedCaseComments = new List<CaseComment>();

		for (List<SObject> insertList : insertRecs) {
			for (SObject record : insertList) {
				if (record instanceof Case) {
					insertedChildCases.add((Case) record);
				} else if (record instanceof CaseComment) {
					insertedCaseComments.add((CaseComment) record);
				}
			}
		}

		System.assertEquals(2, insertedChildCases.size());
		System.assertEquals(1, insertedCaseComments.size(), 'Case comment not inserted');
	}

	@isTest
	static void testStarTrackConsignmentSearch() {
		// =====================================
		// Data Preparation
		// =====================================

		insert new StarTrack_Settings__c(
			SetupOwnerId = UserInfo.getOrganizationId(),
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

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		UnifiedCaseHandOffController controller = new UnifiedCaseHandOffController();

		Continuation conti = (Continuation) UnifiedCaseHandOffController.searchConsignmentStarTrack('2AT71923');

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

		System.assertNotEquals(null, result, 'Result should be set');
	
	}
	/**
	* To test Duplicate consigments that has duplicate records that are less than 6 months old
	*/
	@isTest
	static void testStarTrackSearchWithDuplicatesLessThanSixmonths() {
		// =====================================
		// Data Preparation
		// =====================================

		insert new StarTrack_Settings__c(
			SetupOwnerId = UserInfo.getOrganizationId(),
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

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		UnifiedCaseHandOffController controller = new UnifiedCaseHandOffController();

		Continuation conti = (Continuation) UnifiedCaseHandOffController.searchConsignmentStarTrack('2AT71923');

		// Perform mock callout
		HttpResponse response = new HttpResponse();
		response.setBody(StarTrackContinuationCalloutMock.getResponse_multiConsignWhereAllConsignmentsWithinLast6Months());

		// Set the fake response for the continuation
		Map<String, HttpRequest> requests = conti.getRequests();
		String requestLabel = requests.keyset().iterator().next();
		Test.setContinuationResponse(requestLabel, response);

		// Invoke callback method
		// note this will call the controller.processSearchRemoteConsignment() instance method
		// the actual continuation call from the remote action calls the static processSearchRemoteConsignment(state) method
		Object result = Test.invokeContinuationMethod(controller, conti);
		List<Article__c> articles = (List<Article__c>) result;
		Test.stopTest();
		System.assertNotEquals(null, result, 'Result should be set');
		System.assertEquals(2, articles.size(), 'Multiple articles found whoes date sent is less than 6 months');	
	}
	/**
	* To test Duplicate consigments that has only one record that are less than 6 months old
	*/
	@isTest
	static void testStarTrackSearchWithMultipleRecordsAndOneIsLessThanSixmonths() {
		// =====================================
		// Data Preparation
		// =====================================

		insert new StarTrack_Settings__c(
			SetupOwnerId = UserInfo.getOrganizationId(),
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

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		UnifiedCaseHandOffController controller = new UnifiedCaseHandOffController();

		Continuation conti = (Continuation) UnifiedCaseHandOffController.searchConsignmentStarTrack('2AT71923');

		// Perform mock callout
		HttpResponse response = new HttpResponse();
		response.setBody(StarTrackContinuationCalloutMock.getResponse_multiConsignWithOneConsignmentWithinLast6Months());

		// Set the fake response for the continuation
		Map<String, HttpRequest> requests = conti.getRequests();
		String requestLabel = requests.keyset().iterator().next();
		Test.setContinuationResponse(requestLabel, response);

		// Invoke callback method
		// note this will call the controller.processSearchRemoteConsignment() instance method
		// the actual continuation call from the remote action calls the static processSearchRemoteConsignment(state) method
		Object result = Test.invokeContinuationMethod(controller, conti);
		List<Article__c> articles = (List<Article__c>) result;
		Test.stopTest();

		System.assertNotEquals(null, result, 'Result should be set');		
		System.assertEquals(1, articles.size(), 'got the recent article and it is less than 6 months');
	
	}

	@isTest
	static void testStarTrackScenario() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Article__c> articles = ApplicationTestDataFactory.getConsignments(1, true);
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(1, cases[0].Id, articles[0].Id, true);
		Account consumer = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<ContactRequest> contactRequests = ApplicationTestDataFactoryCase.getContactRequests(1, new List<Id>{cases[0].Id}, consumer.PersonContactId, true);

		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);
		ContactRequestsSelector mockContactRequestsSelector = (ContactRequestsSelector) MockUtility.mockSelector(ContactRequestsSelector.class);
  
		MockUtility.Mocks.startStubbing();

		//Set up responses
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByArticleNames(new Set<String>{ articles[0].Name }, StarTrack_Constants.CON_REC_TYPE, new Set<Object>{ ArticlesSelector.Options.WITH_RECORDTYPE })
			)
			.thenReturn(new List<Article__c>{ articles[0] });
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{ cases[0].Id }, new Set<Object>{ CasesSelector.Options.WITH_CONTACT }))
			.thenReturn(new Map<Id, Case>{ cases[0].Id => cases[0] });
		MockUtility.Mocks.when(mockImpactedArticlesSelector.selectByCaseId(new Set<Id>{ cases[0].Id }, new Set<Object>())).thenReturn(impactedArticles);
		MockUtility.Mocks.when(mockContactRequestsSelector.search(new Map<String, Object>{'whatIds' => new Set<Id>{ cases[0].Id }}, true)).thenReturn(contactRequests);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		UnifiedCaseHandOffController.CaseHandOffWrapper request = new UnifiedCaseHandOffController.CaseHandOffWrapper();
		request.articleId = articles[0].Id;
		request.businessUnit = 'StarTrack';
		request.caseId = cases[0].Id;
		request.caseRecordType = 'UnifiedInvestigation';
		request.comment = 'Testing';
		request.contactCenter = 'UnifiedStarTrackHandoffTriageQueue';
		request.handoffReason = 'Network contact required';

		UnifiedCaseHandOffController.handOffCase(request);

		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		Id caseStarTrackDeliveryEnquiryRecordType = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
		System.assertNotEquals(null, cases[0].CaseTransferDate__c, 'Case transfer date should be updated');
		System.assertEquals('Network contact required', cases[0].CaseTransferReason__c, 'Case transfer reason should be updated');
		System.assertEquals(caseStarTrackDeliveryEnquiryRecordType, cases[0].RecordTypeId, 'Record type should be set to StarTrack_PUD_Enquiry');
		System.assertEquals('Abandoned', contactRequests[0].Status, 'Contact Request Status should be set to Abandoned');
	}
}