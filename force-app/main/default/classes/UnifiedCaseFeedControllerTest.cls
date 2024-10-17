/**
 * @description Test Class for `UnifiedCaseFeedController`
 * @author Seth Heang
 * @changelog:
 * 2024-09-25 - Seth Heang - created
 * 2024-10-09 - Seth Heang - updated selector query selectByArticleIdAndEventType for EventMessage
 */
@IsTest(IsParallel=true)
private class UnifiedCaseFeedControllerTest {
	/**
	 * Test retrieve related scheduled contact requests in bulk with matched and non-matched result
	 * And verify that only SCR where status is not 'Abandoned is returned back
	 */
	@IsTest
	static void testRetrieveRelatedScheduledContactRequests() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		List<ContactRequest> conReqs = ApplicationTestDataFactoryCase.getContactRequests(2, new List<Id>{ testCase.Id, testCase.Id }, null, true);
		// set second contact request status to 'Abandoned' to fail the criteria check
		conReqs[1].Status = 'Abandoned';

		// =====================================
		// Stubbing
		// =====================================
		ContactRequestsSelector mockContactRequestsSelector = (ContactRequestsSelector) MockUtility.mockSelector(ContactRequestsSelector.class);
		MockUtility.Mocks.startStubbing();
		// Selectors
		MockUtility.Mocks.when(mockContactRequestsSelector.search((Map<String, Object>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean()))
			.thenReturn(new List<ContactRequest>{ conReqs[0] });
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<ContactRequest> result = UnifiedCaseFeedController.getRelatedScheduledContactRequests(testCase.Id);
		Test.stopTest();

		Assert.isNotNull(result, 'SCR result should not be null');
		// contact request with 'Abandoned' status should not be returned
		Assert.areEqual(1, result.size(), 'SCR result size should be 1 but instead got ' + result.size());
		Assert.areEqual(conReqs[0].Id, result[0].Id, 'SCR result Id should match but instead got ' + result[0].Id);
		Assert.areNotEqual('Abandoned', result[0].Status, 'SCR result status should not be Abandoned');
	}

	/**
	 * Test retrieve related email message in bulk with matched and non-matched result
	 * And verify that only incoming email message is returned back
	 */
	@IsTest
	static void testRetrieveRelatedEmailMessages() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		List<EmailMessage> emails = ApplicationTestDataFactoryCase.getEmailMessages(2, true, true, 'seth@from.com', 'seth@to.com', 'test subject', testCase.Id);
		// set second email message incoming flag to false to fail the criteria check
		emails[1] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(emails[1], new Map<String, Object>{ 'Incoming' => false });

		// =====================================
		// Stubbing
		// =====================================
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector) MockUtility.mockSelector(EmailMessagesSelector.class);
		MockUtility.Mocks.startStubbing();
		// Selectors
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByParentIds((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new List<EmailMessage>{ emails[0] });
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<EmailMessage> result = UnifiedCaseFeedController.getRelatedEmailMessages(testCase.Id);
		Test.stopTest();

		Assert.isNotNull(result, 'Email result should not be null');
		// email message with false incoming status should not be returned
		Assert.areEqual(1, result.size(), 'Email result size should be 1 but instead got ' + result.size());
		Assert.areEqual(emails[0].Id, result[0].Id, 'Email result Id should match but instead got ' + result[0].Id);
	}

	/**
	 * Test retrieve related scan events in bulk with matched and non-matched result
	 * And verify that only scan event whose type matches 'isFeature=true' in the EventMessageTypeMapping table is returned back
	 */
	@IsTest
	static void testRetrieveRelatedEventMessages() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		List<Article__c> testArticles = ApplicationTestDataFactory.getArticles(2, true);
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(2, testCase.Id, null, true);
		impactedArticles[0].Article__c = testArticles[0].Id;
		impactedArticles[1].Article__c = testArticles[1].Id;

		List<EventMessage__c> scanEvents = ApplicationTestDataFactory.getEventMessages(2, null, true);
		scanEvents[0] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(scanEvents[0], new Map<String, Object>{ 'Article__c' => testArticles[0].Id });
		scanEvents[1] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(scanEvents[1], new Map<String, Object>{ 'Article__c' => testArticles[1].Id });
		// set scan event type to 'ADMIN-ER39' whose isFeature flag is true in the 'EventMessageTypeMapping__mdt' mapping table to meet criteria check
		scanEvents[0].EventType__c = 'ADMIN-ER39';
		// set scan event type to 'INT-2119' whose isFeature flag is false in the 'EventMessageTypeMapping__mdt' mapping table to fail the criteria check
		scanEvents[1].EventType__c = 'INT-2119';

		// =====================================
		// Stubbing
		// =====================================
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);
		EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);

		MockUtility.Mocks.startStubbing();
		// Selectors
		MockUtility.Mocks.when(mockImpactedArticlesSelector.selectByCaseId((Set<Id>) fflib_Match.anyObject())).thenReturn(impactedArticles);
		MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleIdAndEventType((Set<Id>) fflib_Match.anyObject(), (Set<String>) fflib_Match.anyObject())).thenReturn(new List<EventMessage__c>{ scanEvents[0] });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<EventMessage__c> result = UnifiedCaseFeedController.getRelatedEventMessages(testCase.Id);
		Test.stopTest();

		Assert.isNotNull(result, 'EventMessage__c result should not be null');
		Assert.areEqual(1, result.size(), 'EventMessage__c result size should be 1 but instead got ' + result.size());
		Assert.areEqual(scanEvents[0].Id, result[0].Id, 'EventMessage__c result Id should match but instead got ' + result[0].Id);
		Assert.areEqual(scanEvents[0].EventType__c, result[0].EventType__c, 'EventMessage__c result event type should match but instead got ' + result[0].EventType__c);
	}

	/**
	 * Test retrieve all related feed records(SCR, Email, Scan Events) in bulk with matched and non-matched result
	 * And verify that only those that meet criteria are returned back as results
	 */
	@IsTest
	static void testRetrieveAllCaseFeedsRecords() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		List<Article__c> testArticles = ApplicationTestDataFactory.getArticles(2, true);
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(2, testCase.Id, null, true);
		impactedArticles[0].Article__c = testArticles[0].Id;
		impactedArticles[1].Article__c = testArticles[1].Id;

		List<EventMessage__c> scanEvents = ApplicationTestDataFactory.getEventMessages(2, null, true);
		scanEvents[0] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(scanEvents[0], new Map<String, Object>{ 'Article__c' => testArticles[0].Id });
		scanEvents[1] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(scanEvents[1], new Map<String, Object>{ 'Article__c' => testArticles[1].Id });
		// set scan event type to 'ADMIN-ER39' whose isFeature flag is true in the 'EventMessageTypeMapping__mdt' mapping table to meet criteria check
		scanEvents[0].EventType__c = 'ADMIN-ER39';
		// set scan event type to 'INT-2119' whose isFeature flag is false in the 'EventMessageTypeMapping__mdt' mapping table to fail the criteria check
		scanEvents[1].EventType__c = 'INT-2119';

		List<EmailMessage> emails = ApplicationTestDataFactoryCase.getEmailMessages(2, true, true, 'seth@from.com', 'seth@to.com', 'test subject', testCase.Id);
		// set second email message incoming flag to false to fail the criteria check
		emails[1] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(emails[1], new Map<String, Object>{ 'Incoming' => false });

		List<ContactRequest> conReqs = ApplicationTestDataFactoryCase.getContactRequests(2, new List<Id>{ testCase.Id, testCase.Id }, null, true);
		// set second contact request status to 'Abandoned' to fail the criteria check
		conReqs[1].Status = 'Abandoned';

		// =====================================
		// Stubbing
		// =====================================
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);
		EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector) MockUtility.mockSelector(EmailMessagesSelector.class);
		ContactRequestsSelector mockContactRequestsSelector = (ContactRequestsSelector) MockUtility.mockSelector(ContactRequestsSelector.class);

		MockUtility.Mocks.startStubbing();
		// Selectors
		MockUtility.Mocks.when(mockImpactedArticlesSelector.selectByCaseId((Set<Id>) fflib_Match.anyObject())).thenReturn(impactedArticles);
		MockUtility.Mocks.when(mockContactRequestsSelector.search((Map<String, Object>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean()))
			.thenReturn(new List<ContactRequest>{ conReqs[0] });
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByParentIds((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new List<EmailMessage>{ emails[0] });
		MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleIdAndEventType((Set<Id>) fflib_Match.anyObject(), (Set<String>) fflib_Match.anyObject())).thenReturn(new List<EventMessage__c>{ scanEvents[0] });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<SObject> result = UnifiedCaseFeedController.getAllCaseFeedsRecords(testCase.Id);
		Test.stopTest();

		Assert.isNotNull(result, 'result should not be null');
		Assert.areEqual(3, result.size(), 'result size should be 3 but instead got ' + result.size());

		ContactRequest resultContactRequest;
		EventMessage__c resultEventMessage;
		EmailMessage resultEmail;
		for (SObject obj : result) {
			if (obj instanceof ContactRequest) {
				resultContactRequest = (ContactRequest) obj;
			} else if (obj instanceof EmailMessage) {
				resultEmail = (EmailMessage) obj;
			} else if (obj instanceof EventMessage__c) {
				resultEventMessage = (EventMessage__c) obj;
			}
		}
		Assert.isNotNull(resultEventMessage, 'resultEventMessage should not be null');
		Assert.isNotNull(resultEmail, 'resultEmail should not be null');
		Assert.isNotNull(resultContactRequest, 'resultContactRequest should not be null');
		Assert.areEqual(scanEvents[0].Id, resultEventMessage.Id, 'EventMessage__c result Id should match but instead got ' + resultEventMessage.Id);
		Assert.areEqual(emails[0].Id, resultEmail.Id, 'Email result Id should match but instead got ' + resultEmail.Id);
		Assert.areEqual(conReqs[0].Id, resultContactRequest.Id, 'SCR result Id should match but instead got ' + resultContactRequest.Id);
	}

	/**
	 * Test build feed wrapper list from SCR, Email and Scan Events
	 * And verify all attribute mapping are correctly mapped for respective feed records
	 */
	@IsTest
	static void testBuildFeedResults() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		Article__c testArticle = ApplicationTestDataFactory.getArticles(1, true)[0];
		EventMessage__c scanEvent = ApplicationTestDataFactory.getEventMessages(1, testArticle.Id, true)[0];
		EmailMessage email = ApplicationTestDataFactoryCase.getEmailMessages(1, true, true, 'seth@from.com', 'seth@to.com', 'test subject', testCase.Id)[0];
		ContactRequest conReq = ApplicationTestDataFactoryCase.getContactRequests(1, new List<Id>{ testCase.Id, testCase.Id }, null, true)[0];
		conReq.PreferredChannel = 'Phone';
		conReq.ScheduledDate__c = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		email = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(email, new Map<String, Object>{ 'Incoming' => true, 'CreatedDate' => Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)) });
		scanEvent.EventType__c = 'ADMIN-ER39';
		scanEvent.EventDescription__c = 'Onboard for Delivery';
		List<SObject> feedList = new List<SObject>();
		feedList.add(conReq);
		feedList.add(email);
		feedList.add(scanEvent);
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<UnifiedCaseFeedController.UnifiedCaseFeedsResult> result = UnifiedCaseFeedController.buildFeedResults(feedList);
		Test.stopTest();

		// SCR mappings
		Assert.areEqual(UnifiedCaseFeedController.FEED_HEADER_SCR, result[0].feedHeader, 'SCR feed header should match but instead got ' + result[0].feedHeader);
		Assert.areEqual(conReq.PreferredChannel, result[0].feedBody, 'SCR feed body should match ContactRequest.PreferredChannel but instead got ' + result[0].feedBody);
		Assert.areEqual(conReq.ScheduledDate__c, result[0].feedDateTime, 'SCR feed date time should match ContactRequest.ScheduledDate__c but instead got ' + result[0].feedDateTime);
		Assert.areEqual(UnifiedCaseFeedController.FEED_ICON_SCR, result[0].feedCustomIcon, 'SCR feed custom icon should match but instead got ' + result[0].feedCustomIcon);
		Assert.areEqual(conReq.Id, result[0].feedRecordId, 'SCR record Id should match but instead got ' + result[0].feedRecordId);

		// Email mappings
		Assert.areEqual(UnifiedCaseFeedController.FEED_HEADER_EMAIL, result[1].feedHeader, 'Email feed header should match but instead got ' + result[1].feedHeader);
		Assert.areEqual(email.FromAddress, result[1].feedBody, 'Email feed body should match EmailMessage.FromAddress but instead got ' + result[1].feedBody);
		Assert.areEqual(email.CreatedDate, result[1].feedDateTime, 'Email feed date time should match EmailMessage.CreatedDate but instead got ' + result[1].feedDateTime);
		Assert.areEqual(UnifiedCaseFeedController.FEED_ICON_EMAIL, result[1].feedCustomIcon, 'Email feed custom icon should match but instead got ' + result[1].feedCustomIcon);

		// Scan Event mappings
		Assert.areEqual(UnifiedCaseFeedController.FEED_HEADER_SCAN_EVENT, result[2].feedHeader, 'Scan Event feed header should match but instead got ' + result[2].feedHeader);
		Assert.areEqual(scanEvent.EventDescription__c, result[2].feedBody, 'Scan Event feed body should match EventMessage__c.EventDescription__c but instead got ' + result[2].feedBody);
		Assert.areEqual(scanEvent.ActualDateTime__c, result[2].feedDateTime, 'Scan Event feed date time should match EventMessage__c.ActualDateTime__c but instead got ' + result[2].feedDateTime);
		Assert.areEqual(UnifiedCaseFeedController.FEED_ICON_SCAN_EVENT, result[2].feedCustomIcon, 'Scan Event feed custom icon should match but instead got ' + result[2].feedCustomIcon);
	}

	/**
	 * Test successfully retrieve all case related feed records
	 * And verify that a list of feed wrappers records are returned with correct attribute mappings
	 */
	@IsTest
	static void testRetrieveLatestCaseFeedsResultsSuccessfully() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		List<Article__c> testArticles = ApplicationTestDataFactory.getArticles(2, true);
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(2, testCase.Id, null, true);
		impactedArticles[0].Article__c = testArticles[0].Id;
		impactedArticles[1].Article__c = testArticles[1].Id;

		List<EventMessage__c> scanEvents = ApplicationTestDataFactory.getEventMessages(2, null, true);
		scanEvents[0] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(scanEvents[0], new Map<String, Object>{ 'Article__c' => testArticles[0].Id });
		scanEvents[1] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(scanEvents[1], new Map<String, Object>{ 'Article__c' => testArticles[1].Id });
		scanEvents[0].ActualDateTime__c = Datetime.now();
		scanEvents[0].EventDescription__c = 'Onboard for Delivery';
		// set scan event type to 'ADMIN-ER39' whose isFeature flag is true in the 'EventMessageTypeMapping__mdt' mapping table to meet criteria check
		scanEvents[0].EventType__c = 'ADMIN-ER39';
		// set scan event type to 'INT-2119' whose isFeature flag is false in the 'EventMessageTypeMapping__mdt' mapping table to fail the criteria check
		scanEvents[1].EventType__c = 'INT-2119';

		List<EmailMessage> emails = ApplicationTestDataFactoryCase.getEmailMessages(2, true, true, 'seth@from.com', 'seth@to.com', 'test subject', testCase.Id);
		emails[0] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(emails[0], new Map<String, Object>{ 'CreatedDate' => Datetime.now() });
		// set second email message incoming flag to false to fail the criteria check
		emails[1] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(emails[1], new Map<String, Object>{ 'Incoming' => false });

		List<ContactRequest> conReqs = ApplicationTestDataFactoryCase.getContactRequests(2, new List<Id>{ testCase.Id, testCase.Id }, null, true);
		conReqs[0].ScheduledDate__c = Datetime.now();
		conReqs[0].PreferredChannel = 'Phone';
		// set second contact request status to 'Abandoned' to fail the criteria check
		conReqs[1].Status = 'Abandoned';

		// =====================================
		// Stubbing
		// =====================================
		ImpactedArticlesSelector mockImpactedArticlesSelector = (ImpactedArticlesSelector) MockUtility.mockSelector(ImpactedArticlesSelector.class);
		EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);
		EmailMessagesSelector mockEmailMessagesSelector = (EmailMessagesSelector) MockUtility.mockSelector(EmailMessagesSelector.class);
		ContactRequestsSelector mockContactRequestsSelector = (ContactRequestsSelector) MockUtility.mockSelector(ContactRequestsSelector.class);

		MockUtility.Mocks.startStubbing();
		// Selectors
		MockUtility.Mocks.when(mockImpactedArticlesSelector.selectByCaseId((Set<Id>) fflib_Match.anyObject())).thenReturn(impactedArticles);
		MockUtility.Mocks.when(mockContactRequestsSelector.search((Map<String, Object>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean()))
			.thenReturn(new List<ContactRequest>{ conReqs[0] });
		MockUtility.Mocks.when(mockEmailMessagesSelector.selectByParentIds((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new List<EmailMessage>{ emails[0] });
		MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleIdAndEventType((Set<Id>) fflib_Match.anyObject(), (Set<String>) fflib_Match.anyObject())).thenReturn(new List<EventMessage__c>{ scanEvents[0] });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<UnifiedCaseFeedController.UnifiedCaseFeedsResult> result = UnifiedCaseFeedController.getLatestCaseFeedsResults(testCase.Id);
		Test.stopTest();

		Assert.isNotNull(result, 'result should not be null');
		Assert.areEqual(3, result.size(), 'result size should be 3 but instead got ' + result.size());

		// SCR mappings
		Assert.areEqual(UnifiedCaseFeedController.FEED_HEADER_SCR, result[0].feedHeader, 'SCR feed header should match but instead got ' + result[0].feedHeader);
		Assert.areEqual(conReqs[0].PreferredChannel, result[0].feedBody, 'SCR feed body should match ContactRequest.PreferredChannel but instead got ' + result[0].feedBody);
		Assert.areEqual(conReqs[0].ScheduledDate__c, result[0].feedDateTime, 'SCR feed date time should match ContactRequest.ScheduledDate__c but instead got ' + result[0].feedDateTime);
		Assert.areEqual(UnifiedCaseFeedController.FEED_ICON_SCR, result[0].feedCustomIcon, 'SCR feed custom icon should match but instead got ' + result[0].feedCustomIcon);
		Assert.areEqual(conReqs[0].Id, result[0].feedRecordId, 'SCR record Id should match but instead got ' + result[0].feedRecordId);

		// Email mappings
		Assert.areEqual(UnifiedCaseFeedController.FEED_HEADER_EMAIL, result[1].feedHeader, 'Email feed header should match but instead got ' + result[1].feedHeader);
		Assert.areEqual(emails[0].FromAddress, result[1].feedBody, 'Email feed body should match EmailMessage.FromAddress but instead got ' + result[1].feedBody);
		Assert.areEqual(emails[0].CreatedDate, result[1].feedDateTime, 'Email feed date time should match EmailMessage.CreatedDate but instead got ' + result[1].feedDateTime);
		Assert.areEqual(UnifiedCaseFeedController.FEED_ICON_EMAIL, result[1].feedCustomIcon, 'Email feed custom icon should match but instead got ' + result[1].feedCustomIcon);

		// Scan Event mappings
		Assert.areEqual(UnifiedCaseFeedController.FEED_HEADER_SCAN_EVENT, result[2].feedHeader, 'Scan Event feed header should match but instead got ' + result[2].feedHeader);
		Assert.areEqual(scanEvents[0].EventDescription__c, result[2].feedBody, 'Scan Event feed body should match EventMessage__c.EventDescription__c but instead got ' + result[2].feedBody);
		Assert.areEqual(scanEvents[0].ActualDateTime__c, result[2].feedDateTime, 'Scan Event feed date time should match EventMessage__c.ActualDateTime__c but instead got ' + result[2].feedDateTime);
		Assert.areEqual(UnifiedCaseFeedController.FEED_ICON_SCAN_EVENT, result[2].feedCustomIcon, 'Scan Event feed custom icon should match but instead got ' + result[2].feedCustomIcon);
	}

	/**
	 * Test retrieve all case related feed records with unexpected exception
	 * And verify appropriate aura exception error message is returned
	 */
	@IsTest
	static void testRetrieveLatestCaseFeedsResultsWithUnexpectedException() {
		// =====================================
		// Testing
		// =====================================
		List<UnifiedCaseFeedController.UnifiedCaseFeedsResult> result;
		try {
			Test.startTest();
			result = UnifiedCaseFeedController.getLatestCaseFeedsResults(null);
			Test.stopTest();
		}
		catch(AuraHandledException ex) {
			Assert.areEqual(UnifiedCaseFeedController.GENERIC_ERROR_MESSAGE, ex.getMessage(), 'Error Message should match but instead got: ' + ex.getMessage());
		}

		Assert.isNull(result, 'result should be null but instead got ' + result);
	}
}