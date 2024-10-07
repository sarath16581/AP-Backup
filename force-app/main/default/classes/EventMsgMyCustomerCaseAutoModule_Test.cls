/**
 * @description Test Class covering EventMessageMyCustomerCaseAutoModule
 * @author Ranjeewa Silva
 * @date 2024-09-19
 * @changelog
 */
@IsTest
private class EventMsgMyCustomerCaseAutoModule_Test {
	/**
	 * Test to ensure event messages not eligible for case closure do not trigger case automation.
	 */
	@IsTest
	static void testEventMessagesNotEligibleForCaseClosureDoNotTriggerCaseAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		EventMessage__c eventMessage = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		eventMessage.EventType__c = 'TEST-123';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageMyCustomerCaseAutoModule().onAfterInsert(new List<EventMessage__c>{eventMessage}, mockUow);

		Test.stopTest();

		// verify impacted articles are not queried
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 0)).search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyBoolean());

		// verify async work is not registered with unit of work.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure event messages enabled for case automation do not trigger case automation if there are no eligible
	 * cases (e.g. SSSW or Social) linked to the article.
	 */
	@IsTest
	static void testEligibleEventMessagesWithNoEligibleUnifiedCasesDoNotTriggerCaseAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		EventMessage__c eventMessage = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		eventMessage.EventType__c = EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_AWAITING_COLLECTION.iterator().next();

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<Case>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageMyCustomerCaseAutoModule().onAfterInsert(new List<EventMessage__c>{eventMessage}, mockUow);

		Test.stopTest();

		// verify search method was called to select impacted articles for the parent article linked to event message
		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).search((Map<String, Object>)searchParamsCaptor.capture(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		Assert.areEqual(new Set<Id>{article.Id}, searchParams.get('relatedArticleIds'));
		Assert.isInstanceOfType(searchParams.get('recordTypeIds'), Set<Id>.class);
		Assert.isFalse(((Set<Id>)searchParams.get('recordTypeIds')).isEmpty(), 'Expected case record type ids parameter to be non empty, but is empty.');
		Assert.isTrue(((Set<Id>)searchParams.get('recordTypeIds')).containsAll(EventMessageMyCustomerCaseAutoModule.AUTOMATION_ENABLED_CASE_RECORDTYPES));
		Assert.isFalse(Boolean.valueOf(searchParams.get('isClosed')), 'Expected to query open cases only.');

		// verify async work is not registered with unit of work.
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure closure eligible event messages register async work to close My Customer cases only.
	 */
	@IsTest
	static void testClosureEventMessagesRegisterAsyncWorkForMyCustomerCases() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0]);
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0]);

		String aligibleEventType = EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_AWAITING_COLLECTION.iterator().next();
		eventMessages[0].EventType__c = aligibleEventType;
		eventMessages[1].EventType__c = aligibleEventType;
		eventMessages[2].EventType__c = aligibleEventType;

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(2, true);
		cases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseSSSWDeliveryRecordType;
		cases[1].RecordTypeId = ApplicationTestDataFactoryCase.caseSSSWGeneralEnquiryRecordType;


		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(cases);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new EventMessageMyCustomerCaseAutoModule().onAfterInsert(eventMessages, mockUow);

		Test.stopTest();

		// verify search method was called to select impacted articles.
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		// verify async work is registered with unit of work.
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncWorker = (ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.getValue();
		Assert.areEqual(EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker.class, asyncWorker.classType,
				'Expected AsyncWorker type that handle unified case automation, but got something else');
		Assert.isNotNull(asyncWorker.params, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isInstanceOfType(asyncWorker.params, Map<Id, Set<String>>.class, 'AsyncWorker parameters are not of the expected type');

		Map<Id, Set<String>> params = (Map<Id, Set<String>>)asyncWorker.params;
		Assert.areEqual(2, params.size(), 'Expected parameters not passed into async process');
		Assert.isTrue(params.containsKey(cases[0].Id), 'My Customer case record (SSSW) must be passed into async process to perform case automation.');
		Assert.isTrue(params.containsKey(cases[1].Id), 'My Customer case record (SSSW) must be passed into async process to perform case automation.');
	}

	/**
	 * Test to ensure async worker closes my customer case when receiving eligible closure scan event type for a case.
	 */
	@IsTest
	static void testAsyncWorkerCaseClosure() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_AWAITING_COLLECTION.iterator().next();

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, true);
		cases[0].EnquirySubType__c = EventMessageMyCustomerCaseAutoModule.CASE_CLOSURE_ELIGIBLE_ENQUIRY_SUBTYPES.iterator().next();
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].ClosedBySystem__c = false;
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => false,
				'ContactEmail'=> 'test@test.invalid'
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Set<String>> params = new Map<Id, Set<String>>{cases[0].Id => new Set<String>{eventMessages[0].EventType__c}};
		EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker worker = new EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(params));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}));

		// verify case is closed
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updatableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updatableCases.size(), 'Expected only one case to be updated.');
		Assert.areEqual(cases[0].Id, updatableCases[0].Id, 'Expected only one case to be updated.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_CLOSED, updatableCases[0].Status, 'Expected the case to be closed.');
		Assert.isTrue(updatableCases[0].ClosedBySystem__c, 'Expected ClosedBySystem__c to be set when closing case by system automation.');
		Assert.areEqual('Delivered as addressed', updatableCases[0].Resolution_Status__c, 'Expected the case resolution status to be set.');

		// verify notification emails are queued for case closed.
		fflib_ArgumentCaptor caseIdsArgCaptor = fflib_ArgumentCaptor.forClass(Id.class);
		fflib_ArgumentCaptor emailAlertArgCaptor = fflib_ArgumentCaptor.forClass(String.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).queueEmailNotification((Id)caseIdsArgCaptor.capture(), fflib_Match.eqSObjectType(Case.SObjectType), (String)emailAlertArgCaptor.capture());

		List<Object> caseIds = (List<Object>)caseIdsArgCaptor.getAllValues();
		Assert.areEqual(1, caseIds.size(), 'Emails are expected for one case record.');
		Assert.isTrue(caseIds.contains(cases[0].Id), 'Expected email notification not sent for cases[0]');

		List<Object> emailAlertNames = (List<Object>)emailAlertArgCaptor.getAllValues();
		Assert.areEqual(1, emailAlertNames.size(), 'Emails are expected for one case records.');
		Assert.isNotNull(emailAlertNames[0], 'Valid email alert is expected.');
	}

	/**
	 * Test to ensure async worker reassigns my customer case when receiving eligible closure scan event type for a case
	 * when customer contact email address is not available.
	 */
	@IsTest
	static void testAsyncWorkerReassignsCaseWhenNoContactEmail() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_AWAITING_COLLECTION.iterator().next();

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, true);
		cases[0].EnquirySubType__c = EventMessageMyCustomerCaseAutoModule.CASE_CLOSURE_ELIGIBLE_ENQUIRY_SUBTYPES.iterator().next();
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].ClosedBySystem__c = false;
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => false
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Set<String>> params = new Map<Id, Set<String>>{cases[0].Id => new Set<String>{eventMessages[0].EventType__c}};
		EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker worker = new EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(params));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}));

		// verify case is not closed, but reassigned.
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updatableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updatableCases.size(), 'Expected only one case to be updated.');
		Assert.areEqual(cases[0].Id, updatableCases[0].Id, 'Expected only one case to be updated.');
		Assert.areNotEqual(SSSWConstants.CASE_STATUS_CLOSED, updatableCases[0].Status, 'Expected the case should not be closed.');
		Assert.isTrue(updatableCases[0].AllocateToQueue__c, 'Expected the case should be reassigned.');


		// verify notification emails are not queued.
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).queueEmailNotification(fflib_Match.anyId(), fflib_Match.eqSObjectType(Case.SObjectType), fflib_Match.anyString());
	}

	/**
	 * Test to ensure async worker do not reassign or close my customer case when receiving eligible closure scan event
	 * type if the case is flagged as a 'HLC' case or 'Customer Recovery' case.
	 */
	@IsTest
	static void testAsyncWorkerDoNotReassignOrCloseFlaggedCase() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_AWAITING_COLLECTION.iterator().next();

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(2, true);
		for (Case caseRecord: cases) {
			caseRecord.EnquirySubType__c = new List<String>(EventMessageMyCustomerCaseAutoModule.CASE_CLOSURE_ELIGIBLE_ENQUIRY_SUBTYPES)[0];
			caseRecord.ArticleTest__c = articles[0].Id;
			caseRecord.ClosedBySystem__c = false;
			caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{
					'IsClosed' => false
			});
		}
		cases[0].IsHLC__c = true;
		cases[1].IsCR__c = true;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Set<String>> params = new Map<Id, Set<String>>{
				cases[0].Id => new Set<String>{eventMessages[0].EventType__c},
				cases[1].Id => new Set<String>{eventMessages[0].EventType__c}
		};
		EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker worker = new EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(params));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id, cases[1].Id}));

		// verify case is not closed or reassigned, but case resolution code updated.
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updatableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(2, updatableCases.size(), 'Expected both cases to be updated.');
		for (Case updatableCase: updatableCases) {
			Assert.areNotEqual(SSSWConstants.CASE_STATUS_CLOSED, updatableCase.Status, 'Expected the case should not be closed.');
			Assert.isFalse(updatableCase.AllocateToQueue__c, 'Expected the case should not be reassigned.');
			Assert.areEqual('Network resolution', updatableCase.ResolutionCode__c, 'Expected the case resolution code should be updated.');
		}

		// verify notification emails are not queued.
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).queueEmailNotification(fflib_Match.anyId(), fflib_Match.eqSObjectType(Case.SObjectType), fflib_Match.anyString());
	}

	/**
	 * Test to ensure async worker updates enquiry sub type of eligible cases to 'General Enquiry' on receiving eligible
	 * event types.
	 */
	@IsTest
	static void testAsyncWorkerUpdateCaseToGeneralEnquiry() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

		// setup event messages for each article.
		List<EventMessage__c> eventMessages = new List<EventMessage__c>();
		eventMessages.add(ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0]);
		eventMessages[0].EventType__c = EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_MISSING_ITEM_DELIVERY.iterator().next();

		// setup case records
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, true);
		cases[0].EnquirySubType__c = 'Missing Item';
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].ClosedBySystem__c = false;
		cases[0].Type = 'Investigation';
		cases[0].ProductCategory__c = 'Domestic Parcels';
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
				'IsClosed' => false
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>(cases));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Set<String>> params = new Map<Id, Set<String>>{
				cases[0].Id => new Set<String>{eventMessages[0].EventType__c}
		};
		EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker worker = new EventMessageMyCustomerCaseAutoModule.AsyncEventMessageMyCustomerCaseAutomationWorker();
		worker.deserialiseParams(JSON.serialize(params));
		worker.execute(mockUow);

		Test.stopTest();

		// verify case selector was called to query case details
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id}));

		// verify case is not closed or reassigned, but case resolution code updated.
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updatableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updatableCases.size(), 'Expected one case to be updated.');
		Assert.areEqual('General Enquiry', updatableCases[0].Type, 'Expected the case type to be updated.');
		Assert.areEqual('Tracking', updatableCases[0].EnquirySubType__c, 'Expected the case type to be updated.');

		// verify notification emails are not queued.
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).queueEmailNotification(fflib_Match.anyId(), fflib_Match.eqSObjectType(Case.SObjectType), fflib_Match.anyString());
	}

	/**
	 * Test to ensure correct email template is used to notify customer on case closure.
	 */
	@IsTest
	static void testGetCaseClosureCustomerNotificationEmailAlert() {
		// =====================================
		// Data Preparation
		// =====================================
		// None

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Assert.areEqual('SSSW_Awaiting_Collection', EventMessageMyCustomerCaseAutoModule.getCaseClosureCustomerNotificationEmailAlert(EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_AWAITING_COLLECTION.iterator().next()));
		Assert.areEqual('SSSW_Email_Delivered', EventMessageMyCustomerCaseAutoModule.getCaseClosureCustomerNotificationEmailAlert(EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_DELIVERED.iterator().next()));
		Assert.areEqual('SSSW_Email_Delivered_in_a_Safe_Place', EventMessageMyCustomerCaseAutoModule.getCaseClosureCustomerNotificationEmailAlert(EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_DELIVERED_IN_SAFE_PLACE.iterator().next()));
		Assert.areEqual('SSSW_Onboard_with_Driver', EventMessageMyCustomerCaseAutoModule.getCaseClosureCustomerNotificationEmailAlert(EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_ONBOARD_WITH_DRIVER.iterator().next()));
		Assert.areEqual('SSSW_Onboard_with_driver_international', EventMessageMyCustomerCaseAutoModule.getCaseClosureCustomerNotificationEmailAlert(EventMessageMyCustomerCaseAutoModule.EVENT_TYPES_ONBOARD_WITH_DRIVER_INTERNATIONAL.iterator().next()));

		Test.stopTest();
	}
}