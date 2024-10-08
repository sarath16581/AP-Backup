/**
 * @description Test Class covering EventMessageUnifiedCaseAutomationModule
 * @author Ranjeewa Silva
 * @date 2024-08-30
 * @changelog
 * 2024-10-03 - Ranjeewa Silva - Updated to verify population of case closure email alert name on parameters passed into CaseUnifiedAutomationService.
 */

@IsTest
private class EventMessageUnifiedCaseAutoModule_Test {

	/**
	 * Test to ensure event messages not enabled for case automation through custom metadata do not trigger case automation.
	 */
	@IsTest
	static void testEventMessagesNotEligibleForAutomationDoNotTriggerCaseAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		EventMessage__c eventMessage = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		eventMessage.EventType__c = 'TEST-123';

		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-001'});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector)MockUtility.mockSelector(ImpactedArticlesSelector.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageUnifiedCaseAutomationModule().onAfterInsert(new List<EventMessage__c>{eventMessage}, mockUow);

		Test.stopTest();

		// verify impacted articles are not queried
		((ImpactedArticlesSelector)MockUtility.Mocks.verify(mockImpactedArticlesSelector, 0)).search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyBoolean());

		// verify async work is not registered with unit of work.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure event messages enabled for case automation through custom metadata do not trigger case automation if
	 * there are no eligible unified cases linked to the article.
	 */
	@IsTest
	static void testEligibleEventMessagesWithNoEligibleUnifiedCasesDoNotTriggerCaseAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		EventMessage__c eventMessage = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		eventMessage.EventType__c = 'TEST-001';

		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-001'});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector)MockUtility.mockSelector(ImpactedArticlesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockImpactedArticlesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<ImpactedArticle__c>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageUnifiedCaseAutomationModule().onAfterInsert(new List<EventMessage__c>{eventMessage}, mockUow);

		Test.stopTest();

		// verify search method was called to select impacted articles for the parent article linked to event message
		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((ImpactedArticlesSelector)MockUtility.Mocks.verify(mockImpactedArticlesSelector, 1)).search((Map<String, Object>)searchParamsCaptor.capture(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		Assert.areEqual(new Set<Id>{article.Id}, searchParams.get('articleIds'));
		Assert.isInstanceOfType(searchParams.get('caseRecordTypeIds'), Set<Id>.class);
		Assert.isFalse(((Set<Id>)searchParams.get('caseRecordTypeIds')).isEmpty(), 'Expected unified case record type ids parameter to be non empty, but is empty.');
		Assert.isTrue(((Set<Id>)searchParams.get('caseRecordTypeIds')).contains(ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType));
		Assert.areEqual(EventMessageUnifiedCaseAutomationModule.AUTOMATION_ENABLED_ENQUIRY_SUB_TYPES, searchParams.get('caseEnquirySubTypes'), 'Expected unified case enquiry sub types that support event message automation to be passed as a search parameter.');
		Assert.isTrue(Boolean.valueOf(searchParams.get('isCaseOpen')), 'Expected to query impacted articles on open cases only.');

		// verify async work is not registered with unit of work.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure closure eligible event messages for StarTrack register async work to close StarTrack cases.
	 */
	@IsTest
	static void testStarTrackClosureEventMessagesRegisterAsyncWorkForStarTrackCases() {
		// =====================================
		// Data Preparation
		// =====================================
		// setup event message type metadata for closure eligibility.
		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-000', 'TEST-001', 'TEST-002'});
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').IsCaseClosureEligible__c = 'Yes - AP Only';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-001').IsCaseClosureEligible__c = 'Yes - ST Only';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-002').IsCaseClosureEligible__c = 'Yes';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0]);

		eventMessages[0].EventType__c = 'TEST-000'; // closure eligible for AP
		eventMessages[1].EventType__c = 'TEST-001'; // closure eligible for ST
		eventMessages[2].EventType__c = 'TEST-002'; // closure eligible for both AP and ST

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		for (Case caseRecord: cases) {
			caseRecord.EnquirySubType__c = 'Late Item';
			caseRecord.ProductSubCategory__c = 'StarTrack Premium';
		}

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(3, new Map<Id, Case>(cases).keySet(), new Map<Id, Article__c>(articles).keySet(), true);
		impactedArticles[0].Case__r = cases[0];
		impactedArticles[1].Case__r = cases[1];
		impactedArticles[2].Case__r = cases[2];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector)MockUtility.mockSelector(ImpactedArticlesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockImpactedArticlesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(impactedArticles);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageUnifiedCaseAutomationModule().onAfterInsert(eventMessages, mockUow);

		Test.stopTest();

		// verify search method was called to select impacted articles.
		((ImpactedArticlesSelector)MockUtility.Mocks.verify(mockImpactedArticlesSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify async work is registered with unit of work.
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncWorker = (ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.getValue();
		Assert.areEqual(EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker.class, asyncWorker.classType,
				'Expected AsyncWorker type that handle unified case automation, but got something else');
		Assert.isNotNull(asyncWorker.params, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isInstanceOfType(asyncWorker.params, Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>.class,
				'AsyncWorker parameters are not of the expected type');

		Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam> params =
				(Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>)asyncWorker.params;
		Assert.areEqual(2, params.size(), 'Expected parameters not passed into async process');
		Assert.isTrue(params.containsKey(cases[1].Id), 'StarTrack case must be closed when receiving event message enabled for closure automation for StarTrack.');
		Assert.isTrue(params.containsKey(cases[2].Id), 'StarTrack case must be closed when receiving event message enabled for closure automation for any product.');
	}

	/**
	 * Test to ensure closure eligible event messages for Australia Post register async work to close Australia Post cases only.
	 */
	@IsTest
	static void testAusPostClosureEventMessagesRegisterAsyncWorkForAusPostCases() {
		// =====================================
		// Data Preparation
		// =====================================
		// setup event message type metadata for closure eligibility.
		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-000', 'TEST-001', 'TEST-002'});
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').IsCaseClosureEligible__c = 'Yes - AP Only';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-001').IsCaseClosureEligible__c = 'Yes - ST Only';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-002').IsCaseClosureEligible__c = 'Yes';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0]);

		eventMessages[0].EventType__c = 'TEST-000'; // closure eligible for AP
		eventMessages[1].EventType__c = 'TEST-001'; // closure eligible for ST
		eventMessages[2].EventType__c = 'TEST-002'; // closure eligible for both AP and ST

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		for (Case caseRecord: cases) {
			caseRecord.EnquirySubType__c = 'Late Item';
			caseRecord.ProductSubCategory__c = 'eParcel Parcel Post';
		}

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(3, new Map<Id, Case>(cases).keySet(), new Map<Id, Article__c>(articles).keySet(), true);
		impactedArticles[0].Case__r = cases[0];
		impactedArticles[1].Case__r = cases[1];
		impactedArticles[2].Case__r = cases[2];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector)MockUtility.mockSelector(ImpactedArticlesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockImpactedArticlesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(impactedArticles);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageUnifiedCaseAutomationModule().onAfterInsert(eventMessages, mockUow);

		Test.stopTest();

		// verify search method was called to select impacted articles.
		((ImpactedArticlesSelector)MockUtility.Mocks.verify(mockImpactedArticlesSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify async work is registered with unit of work.
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncWorker = (ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.getValue();
		Assert.areEqual(EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker.class, asyncWorker.classType,
				'Expected AsyncWorker type that handle unified case automation, but got something else');
		Assert.isNotNull(asyncWorker.params, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isInstanceOfType(asyncWorker.params, Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>.class,
				'AsyncWorker parameters are not of the expected type');

		Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam> params =
				(Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>)asyncWorker.params;
		Assert.areEqual(2, params.size(), 'Expected parameters not passed into async process');
		Assert.isTrue(params.containsKey(cases[0].Id), 'AP case must be closed when receiving event message enabled for closure automation for AP.');
		Assert.isTrue(params.containsKey(cases[2].Id), 'AP case must be closed when receiving event message enabled for closure automation for any product.');
	}

	/**
	 * Test to ensure reassignment eligible event messages for StarTrack register async work to reassign StarTrack cases.
	 */
	@IsTest
	static void testStarTrackReassignmentEventMessagesRegisterAsyncWorkForStarTrackCases() {
		// =====================================
		// Data Preparation
		// =====================================
		// setup event message type metadata for reassignment eligibility.
		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-000', 'TEST-001', 'TEST-002'});
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').IsCaseReassignmentEligible__c = 'Yes - AP Only';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-001').IsCaseReassignmentEligible__c = 'Yes - ST Only';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-002').IsCaseReassignmentEligible__c = 'Yes';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0]);

		eventMessages[0].EventType__c = 'TEST-000'; // reassignment eligible for AP
		eventMessages[1].EventType__c = 'TEST-001'; // reassignment eligible for ST
		eventMessages[2].EventType__c = 'TEST-002'; // reassignment eligible for both AP and ST

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		for (Case caseRecord: cases) {
			caseRecord.EnquirySubType__c = 'Late Item';
			caseRecord.ProductSubCategory__c = 'StarTrack Premium';
		}

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(3, new Map<Id, Case>(cases).keySet(), new Map<Id, Article__c>(articles).keySet(), true);
		impactedArticles[0].Case__r = cases[0];
		impactedArticles[1].Case__r = cases[1];
		impactedArticles[2].Case__r = cases[2];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector)MockUtility.mockSelector(ImpactedArticlesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockImpactedArticlesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(impactedArticles);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageUnifiedCaseAutomationModule().onAfterInsert(eventMessages, mockUow);

		Test.stopTest();

		// verify search method was called to select impacted articles.
		((ImpactedArticlesSelector)MockUtility.Mocks.verify(mockImpactedArticlesSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify async work is registered with unit of work.
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncWorker = (ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.getValue();
		Assert.areEqual(EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker.class, asyncWorker.classType,
				'Expected AsyncWorker type that handle unified case automation, but got something else');
		Assert.isNotNull(asyncWorker.params, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isInstanceOfType(asyncWorker.params, Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>.class,
				'AsyncWorker parameters are not of the expected type');

		Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam> params =
				(Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>)asyncWorker.params;
		Assert.areEqual(2, params.size(), 'Expected parameters not passed into async process');
		Assert.isTrue(params.containsKey(cases[1].Id), 'StarTrack case must be reassigned when receiving event message enabled for reassignment automation for StarTrack.');
		Assert.isTrue(params.containsKey(cases[2].Id), 'StarTrack case must be reassigned when receiving event message enabled for reassignment automation for any product.');
	}

	/**
	 * Test to ensure reassignment eligible event messages for Australia Post register async work to reassign Australia Post cases only.
	 */
	@IsTest
	static void testAusPostReassignmentEventMessagesRegisterAsyncWorkForAusPostCases() {
		// =====================================
		// Data Preparation
		// =====================================
		// setup event message type metadata for reassignment eligibility.
		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-000', 'TEST-001', 'TEST-002'});
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').IsCaseReassignmentEligible__c = 'Yes - AP Only';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-001').IsCaseReassignmentEligible__c = 'Yes - ST Only';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-002').IsCaseReassignmentEligible__c = 'Yes';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0]);

		eventMessages[0].EventType__c = 'TEST-000'; // reassignment eligible for AP
		eventMessages[1].EventType__c = 'TEST-001'; // reassignment eligible for ST
		eventMessages[2].EventType__c = 'TEST-002'; // reassignment eligible for both AP and ST

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		for (Case caseRecord: cases) {
			caseRecord.EnquirySubType__c = 'Late Item';
			caseRecord.ProductSubCategory__c = 'eParcel Parcel Post';
		}

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(3, new Map<Id, Case>(cases).keySet(), new Map<Id, Article__c>(articles).keySet(), true);
		impactedArticles[0].Case__r = cases[0];
		impactedArticles[1].Case__r = cases[1];
		impactedArticles[2].Case__r = cases[2];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector)MockUtility.mockSelector(ImpactedArticlesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockImpactedArticlesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(impactedArticles);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageUnifiedCaseAutomationModule().onAfterInsert(eventMessages, mockUow);

		Test.stopTest();

		// verify search method was called to select impacted articles.
		((ImpactedArticlesSelector)MockUtility.Mocks.verify(mockImpactedArticlesSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify async work is registered with unit of work.
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncWorker = (ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.getValue();
		Assert.areEqual(EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker.class, asyncWorker.classType,
				'Expected AsyncWorker type that handle unified case automation, but got something else');
		Assert.isNotNull(asyncWorker.params, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isInstanceOfType(asyncWorker.params, Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>.class,
				'AsyncWorker parameters are not of the expected type');

		Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam> params =
				(Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>)asyncWorker.params;
		Assert.areEqual(2, params.size(), 'Expected parameters not passed into async process');
		Assert.isTrue(params.containsKey(cases[0].Id), 'AP case must be reassigned when receiving event message enabled for reassignment automation for AP.');
		Assert.isTrue(params.containsKey(cases[2].Id), 'AP case must be reassigned when receiving event message enabled for reassignment automation for any product.');
	}

	/**
	 * Test to ensure async worker checks the case is closed before reassigning the case. This is to cater for edge-case
	 * scenarios where the case has got closed after the async worker is registered.
	 */
	@IsTest
	static void testAsyncWorkerExcludeAlreadyClosedCasesFromReassignmentAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = 'TEST-000';

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, true);
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => true
		});

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(1, new Map<Id, Case>(cases).keySet(), new Map<Id, Article__c>(articles).keySet(), true);
		impactedArticles[0].Case__r = cases[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		CaseUnifiedAutomationService mockCaseAutomationService = (CaseUnifiedAutomationService)MockUtility.mockUtility(CaseUnifiedAutomationService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam param = new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam();
		param.caseId = cases[0].Id;
		param.reassignmentEventTypes = new Set<String>{'TEST-000'};
		EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker worker = new EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(new Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>{cases[0].Id => param}));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify articles selector was not called as the case was already closed.
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, 0)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify case automation service is not called
		((CaseUnifiedAutomationService)MockUtility.Mocks.verify(mockCaseAutomationService, 0)).processForCaseReassignment((List<CaseUnifiedAutomationService.RecordWrapper>)fflib_Match.anyObject(), (CaseUnifiedAutomationService.InvocationPoint)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure async worker checks the case is closed before attempting closure automation. This is to cater for edge-case
	 * scenarios where the case has got closed after the async worker is registered.
	 */
	@IsTest
	static void testAsyncWorkerExcludeAlreadyClosedCasesFromClosureAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = 'TEST-000';

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, true);
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => true
		});

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(1, new Map<Id, Case>(cases).keySet(), new Map<Id, Article__c>(articles).keySet(), true);
		impactedArticles[0].Case__r = cases[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		CaseUnifiedAutomationService mockCaseAutomationService = (CaseUnifiedAutomationService)MockUtility.mockUtility(CaseUnifiedAutomationService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam param = new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam();
		param.caseId = cases[0].Id;
		param.closureEventTypes = new Set<String>{'TEST-000'};
		EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker worker = new EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(new Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>{cases[0].Id => param}));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify articles selector was not called as the case was already closed.
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, 0)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify case automation service is not called
		((CaseUnifiedAutomationService)MockUtility.Mocks.verify(mockCaseAutomationService, 0)).processForCaseReassignment((List<CaseUnifiedAutomationService.RecordWrapper>)fflib_Match.anyObject(), (CaseUnifiedAutomationService.InvocationPoint)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure async worker delegates to service class to process case reassignment when receiving one eligible
	 * reassignment scan event type for a case.
	 */
	@IsTest
	static void testAsyncWorkerReceivingSingleEventCodeForReassignment() {
		// =====================================
		// Data Preparation
		// =====================================
		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-000'});
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').IsCaseReassignmentEligible__c = 'Yes';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').CaseAutomationReassignmentReason__c = 'TEST-000 Reassignment Reason';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = 'TEST-000';

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, true);
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => false
		});

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(1, new Map<Id, Case>(cases).keySet(), new Map<Id, Article__c>(articles).keySet(), true);
		impactedArticles[0].Case__r = cases[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		CaseUnifiedAutomationService mockCaseAutomationService = (CaseUnifiedAutomationService)MockUtility.mockUtility(CaseUnifiedAutomationService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam param = new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam();
		param.caseId = cases[0].Id;
		param.reassignmentEventTypes = new Set<String>{'TEST-000'};
		EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker worker = new EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(new Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>{cases[0].Id => param}));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify articles selector was not called as the case is for reassignment and not for closure. existing event messages on all impacted
		// articles on Case is to be checked only for closure automation.
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, 0)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify case automation service is called with expected parameters
		fflib_ArgumentCaptor serviceParamCaptor = fflib_ArgumentCaptor.forClass(List<CaseUnifiedAutomationService.RecordWrapper>.class);
		((CaseUnifiedAutomationService)MockUtility.Mocks.verify(mockCaseAutomationService, 1)).processForCaseReassignment((List<CaseUnifiedAutomationService.RecordWrapper>)serviceParamCaptor.capture(), (CaseUnifiedAutomationService.InvocationPoint)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		List<CaseUnifiedAutomationService.RecordWrapper> serviceParams = (List<CaseUnifiedAutomationService.RecordWrapper>)serviceParamCaptor.getValue();

		Assert.areEqual(1, serviceParams.size(), 'Expected the case record to be passed in to service for reassignment');
		Assert.areEqual(cases[0].Id, serviceParams[0].caseRecord.Id, 'Expected to pass Case record to service class for reassignment.');
		Assert.areEqual('TEST-000 Reassignment Reason', serviceParams[0].newReassignmentReason, 'Reassignment reason must be set based on event message type mapping metadata.');
	}

	/**
	 * Test to ensure async worker delegates to service class to process case closure when receiving one eligible
	 * closure scan event type for a case.
	 */
	@IsTest
	static void testAsyncWorkerReceivingSingleEventCodeForClosure() {
		// =====================================
		// Data Preparation
		// =====================================
		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-000'});
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').IsCaseClosureEligible__c = 'Yes';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').CaseAutomationResolutionCode__c = 'TEST-000 Resolution';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').CaseAutomationRootCause__c = 'TEST-000 Root Cause';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').CaseClosureEmailAlertNameAusPost__c = 'TEST-000 AP Alert';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').CaseClosureEmailAlertNameStarTrack__c = 'TEST-000 ST Alert';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0]);
		eventMessages[0].EventType__c = 'TEST-000';
		eventMessages[1].EventType__c = 'TEST-000';

		articles[0] = (Article__c)ApplicationTestDataFactory.setChildRelationships(articles[0], new Map<String, List<SObject>>{
				'Event_Messages__r' => eventMessages
		});

		articles[1] = (Article__c)ApplicationTestDataFactory.setChildRelationships(articles[1], new Map<String, List<SObject>>{
				'Event_Messages__r' => eventMessages
		});

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(2, true);
		//cases[0] is related to AusPost product
		cases[0].ProductSubCategory__c = 'eParcel Parcel Post';
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => false
		});

		//cases[1] is related to StarTrack product
		cases[1].ProductSubCategory__c = 'StarTrack Premium';
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{
				'IsClosed' => false
		});

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(2, new Map<Id, Case>(cases).keySet(), new Map<Id, Article__c>(articles).keySet(), true);
		impactedArticles[0].Case__r = cases[0];
		impactedArticles[1].Case__r = cases[1];

		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{
				'ImpactedArticles__r' => new List<ImpactedArticle__c>{impactedArticles[0]}
		});

		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1], new Map<String, List<SObject>>{
				'ImpactedArticles__r' => new List<ImpactedArticle__c>{impactedArticles[1]}
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		CaseUnifiedAutomationService mockCaseAutomationService = (CaseUnifiedAutomationService)MockUtility.mockUtility(CaseUnifiedAutomationService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.when(mockArticlesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam> params = new List<EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>();
		params.add(new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam());
		params.add(new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam());
		params[0].caseId = cases[0].Id;
		params[0].closureEventTypes = new Set<String>{'TEST-000'};
		params[1].caseId = cases[1].Id;
		params[1].closureEventTypes = new Set<String>{'TEST-000'};
		EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker worker = new EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(new Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>{cases[0].Id => params[0], cases[1].Id => params[1]}));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify articles selector was called once to query articles with existing event messages.
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify case automation service is called with expected parameters
		fflib_ArgumentCaptor serviceParamCaptor = fflib_ArgumentCaptor.forClass(List<CaseUnifiedAutomationService.RecordWrapper>.class);
		((CaseUnifiedAutomationService)MockUtility.Mocks.verify(mockCaseAutomationService, 1)).processForCaseClosure((List<CaseUnifiedAutomationService.RecordWrapper>)serviceParamCaptor.capture(), (CaseUnifiedAutomationService.InvocationPoint)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		List<CaseUnifiedAutomationService.RecordWrapper> serviceParams = (List<CaseUnifiedAutomationService.RecordWrapper>)serviceParamCaptor.getValue();

		Assert.areEqual(2, serviceParams.size(), 'Expected both case records to be passed in to service for closure');
		for (CaseUnifiedAutomationService.RecordWrapper serviceParam: serviceParams) {
			Assert.isTrue(new Set<Id>{cases[0].Id, cases[1].Id}.contains(serviceParam.caseRecord.Id), 'Expected to pass Case record to service class for closure.');
			Assert.areEqual('TEST-000 Resolution', serviceParam.newResolutionCode, 'Resolution code must be set based on event message type mapping metadata.');
			Assert.areEqual('TEST-000 Root Cause', serviceParam.newRootCause, 'Root Cause must be set based on event message type mapping metadata.');
			if (cases[0].Id == serviceParam.caseRecord.Id) {
				Assert.areEqual('TEST-000 AP Alert', serviceParam.caseClosureEmailAlert, 'Case closure email alert name must be set based on event message type mapping metadata.');
			} else {
				Assert.areEqual('TEST-000 ST Alert', serviceParam.caseClosureEmailAlert, 'Case closure email alert name must be set based on event message type mapping metadata.');
			}
		}
	}

	/**
	 * Test to ensure async worker delegates to service class to process case reassignment when receiving multiple eligible
	 * reassignment scan event types in the same transaction.
	 */
	@IsTest
	static void testAsyncWorkerReceivingMultipleEventCodesForReassignment() {
		// =====================================
		// Data Preparation
		// =====================================
		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-000', 'TEST-001'});
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').IsCaseReassignmentEligible__c = 'Yes';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').CaseAutomationReassignmentReason__c = 'TEST-000 Reassignment Reason';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-001').IsCaseReassignmentEligible__c = 'Yes';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-001').CaseAutomationReassignmentReason__c = 'TEST-001 Reassignment Reason';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, true);

		// setup event messages for each article. articles[0] is receiving both event messages in one transaction.
		// articles[1] is receiving event message 'TEST-000' and articles[2] is receiving 'TEST-001'
		// articles[1] and articles[2] are impacted articles on the same case record.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = 'TEST-000';
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[1].EventType__c = 'TEST-001';
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0]);
		eventMessages[2].EventType__c = 'TEST-000';
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0]);
		eventMessages[3].EventType__c = 'TEST-001';


		// setup case records. cases[0] has one impacted article - articles[0]. cases[1] has two impacted articles - articles[1] and articles[2].
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(2, true);
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => false
		});
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{
				'IsClosed' => false
		});

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(3, new List<Id>{cases[0].Id, cases[1].Id, cases[1].Id}, new List<Id>{articles[0].Id, articles[1].Id, articles[2].Id}, true);
		impactedArticles[0].Case__r = cases[0];
		impactedArticles[1].Case__r = cases[1];
		impactedArticles[2].Case__r = cases[1];

		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{
				'ImpactedArticles__r' => new List<ImpactedArticle__c>{impactedArticles[0]}
		});

		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1], new Map<String, List<SObject>>{
				'ImpactedArticles__r' => new List<ImpactedArticle__c>{impactedArticles[1], impactedArticles[2]}
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		CaseUnifiedAutomationService mockCaseAutomationService = (CaseUnifiedAutomationService)MockUtility.mockUtility(CaseUnifiedAutomationService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam> params = new List<EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>();
		params.add(new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam());
		params.add(new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam());
		params[0].caseId = cases[0].Id;
		params[0].reassignmentEventTypes = new Set<String>{'TEST-000', 'TEST-001'};
		params[1].caseId = cases[1].Id;
		params[1].reassignmentEventTypes = new Set<String>{'TEST-000', 'TEST-001'};
		EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker worker = new EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(new Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>{cases[0].Id => params[0], cases[1].Id => params[1]}));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify articles selector was not called as the case is for reassignment and not for closure. existing event messages on all impacted
		// articles on Case is to be checked only for closure automation.
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, 0)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify case automation service is called with expected parameters
		fflib_ArgumentCaptor serviceParamCaptor = fflib_ArgumentCaptor.forClass(List<CaseUnifiedAutomationService.RecordWrapper>.class);
		((CaseUnifiedAutomationService)MockUtility.Mocks.verify(mockCaseAutomationService, 1)).processForCaseReassignment((List<CaseUnifiedAutomationService.RecordWrapper>)serviceParamCaptor.capture(), (CaseUnifiedAutomationService.InvocationPoint)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		List<CaseUnifiedAutomationService.RecordWrapper> serviceParams = (List<CaseUnifiedAutomationService.RecordWrapper>)serviceParamCaptor.getValue();

		Assert.areEqual(2, serviceParams.size(), 'Expected two case records to be passed in to service for reassignment');
		for (CaseUnifiedAutomationService.RecordWrapper serviceParam: serviceParams) {
			if (serviceParam.caseRecord.Id == cases[0].Id) {
				Assert.areEqual(EventMessageUnifiedCaseAutomationModule.CASE_REASSIGNMENT_REASON_SINGLE_ARTICLE_DIFFERENT_EVENT_TRIGGERS, serviceParam.newReassignmentReason, 'Expected reassignment reason on receiving multiple eligible events on single article.');
			} else if (serviceParam.caseRecord.Id == cases[1].Id) {
				Assert.areEqual(EventMessageUnifiedCaseAutomationModule.CASE_REASSIGNMENT_REASON_DIFFERENT_EVENT_TRIGGERS, serviceParam.newReassignmentReason, 'Expected reassignment reason on receiving eligible events on multiple impacted articles.');
			}
		}
	}

	/**
	 * Test to ensure async worker delegates to service class to process case reassignment when receiving multiple eligible
	 * closure scan event types in the same transaction.
	 */
	@IsTest
	static void testAsyncWorkerReceivingMultipleEventCodesForClosure() {
		// =====================================
		// Data Preparation
		// =====================================
		injectMockEventMessageTypeMetadataInModule(new Set<String>{'TEST-000', 'TEST-001'});
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').IsCaseClosureEligible__c = 'Yes';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-000').CaseAutomationReassignmentReason__c = 'TEST-000 Reassignment Reason';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-001').IsCaseClosureEligible__c = 'Yes';
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.get('TEST-001').CaseAutomationReassignmentReason__c = 'TEST-001 Reassignment Reason';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, true);

		// setup event messages for each article. articles[0] is receiving both event messages in one transaction.
		// articles[1] is receiving event message 'TEST-000' and articles[2] is receiving 'TEST-001'
		// articles[1] and articles[2] are impacted articles on the same case record.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = 'TEST-000';
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[1].EventType__c = 'TEST-001';
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0]);
		eventMessages[2].EventType__c = 'TEST-000';
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0]);
		eventMessages[3].EventType__c = 'TEST-001';


		// setup case records. cases[0] has one impacted article - articles[0]. cases[1] has two impacted articles - articles[1] and articles[2].
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(2, true);
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => false
		});
		cases[1] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{
				'IsClosed' => false
		});

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(3, new List<Id>{cases[0].Id, cases[1].Id, cases[1].Id}, new List<Id>{articles[0].Id, articles[1].Id, articles[2].Id}, true);
		impactedArticles[0].Case__r = cases[0];
		impactedArticles[1].Case__r = cases[1];
		impactedArticles[2].Case__r = cases[1];

		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{
				'ImpactedArticles__r' => new List<ImpactedArticle__c>{impactedArticles[0]}
		});

		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1], new Map<String, List<SObject>>{
				'ImpactedArticles__r' => new List<ImpactedArticle__c>{impactedArticles[1], impactedArticles[2]}
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector)MockUtility.mockSelector(ArticlesSelector.class);
		CaseUnifiedAutomationService mockCaseAutomationService = (CaseUnifiedAutomationService)MockUtility.mockUtility(CaseUnifiedAutomationService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.when(mockArticlesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Article__c>(articles));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam> params = new List<EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>();
		params.add(new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam());
		params.add(new EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam());
		params[0].caseId = cases[0].Id;
		params[0].closureEventTypes = new Set<String>{'TEST-000', 'TEST-001'};
		params[1].caseId = cases[1].Id;
		params[1].closureEventTypes = new Set<String>{'TEST-000', 'TEST-001'};
		EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker worker = new EventMessageUnifiedCaseAutomationModule.AsyncEventMessageUnifiedCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(new Map<Id, EventMessageUnifiedCaseAutomationModule.UnifiedCaseAutomationAsyncWorkerParam>{cases[0].Id => params[0], cases[1].Id => params[1]}));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify articles selector was not called as the case is for reassignment and not for closure. existing event messages on all impacted
		// articles on Case is to be checked only for closure automation.
		((ArticlesSelector)MockUtility.Mocks.verify(mockArticlesSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// verify case automation service is called with expected parameters
		fflib_ArgumentCaptor serviceParamCaptor = fflib_ArgumentCaptor.forClass(List<CaseUnifiedAutomationService.RecordWrapper>.class);
		((CaseUnifiedAutomationService)MockUtility.Mocks.verify(mockCaseAutomationService, 1)).processForCaseReassignment((List<CaseUnifiedAutomationService.RecordWrapper>)serviceParamCaptor.capture(), (CaseUnifiedAutomationService.InvocationPoint)fflib_Match.anyObject(), (ApplicationUnitOfWork)fflib_Match.anyObject());
		List<CaseUnifiedAutomationService.RecordWrapper> serviceParams = (List<CaseUnifiedAutomationService.RecordWrapper>)serviceParamCaptor.getValue();

		Assert.areEqual(2, serviceParams.size(), 'Expected two case records to be passed in to service for reassignment');
		for (CaseUnifiedAutomationService.RecordWrapper serviceParam: serviceParams) {
			if (serviceParam.caseRecord.Id == cases[0].Id) {
				Assert.areEqual(EventMessageUnifiedCaseAutomationModule.CASE_REASSIGNMENT_REASON_SINGLE_ARTICLE_DIFFERENT_EVENT_TRIGGERS, serviceParam.newReassignmentReason, 'Expected reassignment reason on receiving multiple eligible events on single article.');
			} else if (serviceParam.caseRecord.Id == cases[1].Id) {
				Assert.areEqual(EventMessageUnifiedCaseAutomationModule.CASE_REASSIGNMENT_REASON_DIFFERENT_EVENT_TRIGGERS, serviceParam.newReassignmentReason, 'Expected reassignment reason on receiving eligible events on multiple impacted articles.');
			}
		}
	}

	private static void injectMockEventMessageTypeMetadataInModule(Set<String> eventTypes) {
		Map<String, EventMessageTypeMapping__mdt> mockMetadata = new Map<String, EventMessageTypeMapping__mdt>();
		for (String eventType: eventTypes) {
			mockMetadata.put(eventType, new EventMessageTypeMapping__mdt(Label=eventType, DeveloperName=eventType, Category__c='None', ColourCode__c='None'));
		}
		EventMessageUnifiedCaseAutomationModule.automationEligibleEventTypeDefinitions.putAll(mockMetadata);
	}

}