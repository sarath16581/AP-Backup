/**
 * Test class that covers MyCustomerDeliveryProofPdfController
 *
 * @author Nathan Franklin
 * @date 2021-10-15
 * @changelog
 * @changelog
 * 2024-06-12 - Seth Heang - Fixed existing test classes and added new test methods to cover changes related to multiple proof of delivery creation
 **/
@IsTest
public with sharing class MyCustomerDeliveryProofPdfControllerTest {
	/**
	 *	Scenario: Test that ensures the correct signature attachment id will be rendered to the PDF
	 */
	@IsTest
	private static void testEnsureSignatureAttachmentIdIsSetCorrectly() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		article.ConsignmentTrackingNumber__c = 'TN000001';
		article.ProductID__c = '001';

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => article });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 14, 30, 0);

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.SignatureXString__c = '1';
		event2.EventType__c = 'DD-ER13'; // delivered - signature
		event2.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 0, 0);

		// NOTE: Any event messages with SignatureXString__c field set are automatically added as a signature attachment in the EventMessageTrigger (EventMessageUtil.createSignatureAttachments method)
		// We can always rely on this attachment existing therefore we can mock it
		Attachment signatureAttachment = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		signatureAttachment.Name = 'Signature-123.png';
		signatureAttachment.Body = null; // Blobs do not work with serialisation

		event2 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event2, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ signatureAttachment } });
		event2 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{ 'Article__r' => article });

		// Reset the attachment body
		event2.Attachments[0].Body = Blob.valueOf('test');

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event3.EventType__c = 'DD-ER33';
		event3 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{ 'Article__r' => article });

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{ 'Article__r' => article });

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4 };
		Set<String> articleIdNames = new Set<String>{ article.Name };

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<MyCustomerDeliveryProofPdfController.DeliveryProofAttributes> podAttributesResult = MyCustomerDeliveryProofPdfController.buildAttributesForPDFDisplay(new Set<String>{ article.Name });
		Test.stopTest();

		Assert.areNotEqual(null, podAttributesResult, 'podAttributesResult should not be null');
		Assert.areEqual(signatureAttachment.Id, podAttributesResult.get(0).signatureAttachmentId, 'Signature attachment id was not set correctly');
		Assert.areEqual(null, podAttributesResult.get(0).safeDropAttachmentId, 'Safedrop attachment id has been assigned but shouldnt: ' + podAttributesResult.get(0).safeDropAttachmentId);
		Assert.isTrue(String.isEmpty(MyCustomerDeliveryProofPdfController.pageError), 'Page error should be null: ' + MyCustomerDeliveryProofPdfController.pageError);
		((EventMessagesSelector) MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject());
	}

	/**
	 *	Scenario: Test that ensures the correct safedrop attachment id will be rendered to the PDF where a safedrop image already exists in local cache (no callout needed)
	 */
	@IsTest
	private static void testEnsureSafeDropAttachmentIdSetSuccessfullyForExistingCachedSafeDropImage() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		article.ConsignmentTrackingNumber__c = 'TN000001';
		article.ProductID__c = '001';

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => article });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 14, 30, 0);

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safe drop
		event2.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		Attachment safedropAttachment = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		safedropAttachment.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
		safedropAttachment.Body = null; // Blobs do not work with serialisation

		event2 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event2, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ safedropAttachment } });
		event2 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{ 'Article__r' => article });

		// Reset the attachment body
		event2.Attachments[0].Body = Blob.valueOf('test');

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event3.EventType__c = 'DD-ER33';
		event3 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{ 'Article__r' => article });
		event3.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 2, 0);

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{ 'Article__r' => article });
		event4.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 3, 0);

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4 };
		Set<String> articleIdNames = new Set<String>{ article.Name };
		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<MyCustomerDeliveryProofPdfController.DeliveryProofAttributes> podAttributesResult = MyCustomerDeliveryProofPdfController.buildAttributesForPDFDisplay(new Set<String>{ article.Name });
		Test.stopTest();

		Assert.areNotEqual(null, podAttributesResult, 'podAttributesResult should not be null');
		Assert.areEqual(safedropAttachment.Id, podAttributesResult.get(0).safeDropAttachmentId, 'Safedrop attachment id was not set correctly');
		Assert.areEqual(null, podAttributesResult.get(0).signatureAttachmentId, 'Signature attachment id has been assigned but shouldnt: ' + podAttributesResult.get(0).signatureAttachmentId);
		Assert.areEqual(null, podAttributesResult.get(0).requiredSafeDropCallout, 'Should not require a Safe Drop Callout as the image already exists in Salesforce');
		Assert.isTrue(String.isEmpty(MyCustomerDeliveryProofPdfController.pageError), 'Page error should be null: ' + MyCustomerDeliveryProofPdfController.pageError);
		((EventMessagesSelector) MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject());
	}

	/**
	 *	Scenario: Test that ensures the correct safedrop attachment id will be rendered to the PDF where safedrop image needs to be requested via a callout
	 */
	@IsTest
	private static void testEnsureSafeDropAttachmentIdSetSuccessfullyWithCallout() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		article.ConsignmentTrackingNumber__c = 'TN000001';
		article.ProductID__c = '001';

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => article });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 14, 30, 0);

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safedrop
		event2 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{ 'Article__r' => article });
		event2.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event3.EventType__c = 'DD-ER33';
		event3 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{ 'Article__r' => article });
		event3.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 2, 0);

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{ 'Article__r' => article });
		event4.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 3, 0);

		// this is used when attachSafedropToRecord is called after the Continuation response is invoked
		Attachment safedropAttachment = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		safedropAttachment.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4 };
		Set<String> articleIdNames = new Set<String>{ article.Name };

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);
		SafeDropUtility mockSafeDropUtility = (SafeDropUtility) MockUtility.mockUtility(SafeDropUtility.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.when(mockSafeDropUtility.attachSafeDropToRecord((Id) fflib_Match.eq(event2.Id), (Blob) fflib_Match.anyObject())).thenReturn(safedropAttachment);
		MockUtility.Mocks.when(mockSafeDropUtility.getHttpRequest(fflib_Match.anyString())).thenReturn(new HttpRequest());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<MyCustomerDeliveryProofPdfController.DeliveryProofAttributes> podAttributesResult = MyCustomerDeliveryProofPdfController.buildAttributesForPDFDisplay(new Set<String>{ article.Name });
		Assert.areEqual(true, podAttributesResult.get(0).requiredSafeDropCallout, 'Should Require a Safe Drop Callout as the image does not exists in Salesforce');

		// Invoke the continuation
		Continuation cont = (Continuation) MyCustomerDeliveryProofPdfController.getSafeDropImage(event2.Safe_Drop_GUID__c, event2.Id);

		// setup the continuation mock provider
		String requestLabel = new List<String>(cont.getRequests().keySet())[0];
		SafeDropUtility_Test.setSuccessContinuationResponse(requestLabel);
		Map<String, String> state = new Map<String, String>();
		state.put('guidId', event2.Safe_Drop_GUID__c);
		state.put('eventMessageId', event2.Id);

		SafeDropUtility.SafeDropApiResponse response = (SafeDropUtility.SafeDropApiResponse) MyCustomerDeliveryProofPdfController.safeDropImageCallback(new List<String>{ requestLabel }, state);

		Test.stopTest();

		Assert.areNotEqual(null, response, 'Response should not be null');
		Assert.areEqual(false, response.isError, 'Response should not has any error');
		Assert.areNotEqual(null, response.imageBody, 'Image body should not be empty');
		Assert.isTrue(String.isEmpty(MyCustomerDeliveryProofPdfController.pageError), 'Page error should be null: ' + MyCustomerDeliveryProofPdfController.pageError);
		((EventMessagesSelector) MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject());
		((SafeDropUtility) MockUtility.Mocks.verify(mockSafeDropUtility, MockUtility.Mocks.times(1))).attachSafeDropToRecord((Id) fflib_Match.eq(event2.Id), (Blob) fflib_Match.anyObject());
	}

	/**
	 *	Scenario: Test that ensures the safedrop attachment id is not set when the safedrop callout fails
	 */
	@IsTest
	private static void testEnsureSafeDropAttachmentIdNotSetWhenSafedropCalloutFails() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		article.ConsignmentTrackingNumber__c = 'TN000001';
		article.ProductID__c = '001';

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => article });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 14, 30, 0);

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safedrop
		event2 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{ 'Article__r' => article });
		event2.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event3.EventType__c = 'DD-ER33';
		event3 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{ 'Article__r' => article });
		event3.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 2, 0);

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{ 'Article__r' => article });
		event4.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 3, 0);

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4 };
		Set<String> articleIdNames = new Set<String>{ article.Name };

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);
		SafeDropUtility mockSafeDropUtility = (SafeDropUtility) MockUtility.mockUtility(SafeDropUtility.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.when(mockSafeDropUtility.attachSafeDropToRecord((Id) fflib_Match.eq(event2.Id), (Blob) fflib_Match.anyObject())).thenReturn(null);
		MockUtility.Mocks.when(mockSafeDropUtility.getHttpRequest(fflib_Match.anyString())).thenReturn(new HttpRequest());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<MyCustomerDeliveryProofPdfController.DeliveryProofAttributes> podAttributesResult = MyCustomerDeliveryProofPdfController.buildAttributesForPDFDisplay(new Set<String>{ article.Name });
		Assert.areEqual(true, podAttributesResult.get(0).requiredSafeDropCallout, 'Should Require a Safe Drop Callout as the image does not exists in Salesforce');

		// Invoke the continuation
		Continuation cont = (Continuation) MyCustomerDeliveryProofPdfController.getSafeDropImage(event2.Safe_Drop_GUID__c, event2.Id);

		// setup the continuation mock provider
		String requestLabel = new List<String>(cont.getRequests().keySet())[0];
		SafeDropUtility_Test.setErrorContinuationResponse(requestLabel);

		Map<String, String> state = new Map<String, String>();
		state.put('guidId', event2.Safe_Drop_GUID__c);
		state.put('eventMessageId', event2.Id);

		SafeDropUtility.SafeDropApiResponse response;
		try {
			response = (SafeDropUtility.SafeDropApiResponse) MyCustomerDeliveryProofPdfController.safeDropImageCallback(new List<String>{ requestLabel }, state);
			Assert.fail('Integration failure is expected here!');
		} catch (AuraHandledException e) {
			Assert.isNotNull(e, 'Error Message should not be null');
		}
		Test.stopTest();

		Assert.areEqual(false, String.isEmpty(MyCustomerDeliveryProofPdfController.pageError), 'The pageError property should have been set but wasnt');
		Assert.areEqual(null, podAttributesResult.get(0).safeDropAttachmentId, 'safe drop attachment ID should be null but instead got: ' + podAttributesResult.get(0).safeDropAttachmentId);
		Assert.areEqual(null, podAttributesResult.get(0).signatureAttachmentId, 'Signature attachment ID should be null but instead got: ' + podAttributesResult.get(0).signatureAttachmentId);
		Assert.areEqual(null, response, 'Response should be null but instead got: ' + response);

		((EventMessagesSelector) MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject());
		((SafeDropUtility) MockUtility.Mocks.verify(mockSafeDropUtility, MockUtility.Mocks.times(0))).attachSafeDropToRecord((Id) fflib_Match.eq(event2.Id), (Blob) fflib_Match.anyObject());
	}

	/**
	 *	Scenario: Ensures that an article without any eligible safedrop/signature scans set the pageError field
	 */
	@IsTest
	private static void testEnsureInvalidArticleIsReportedAsError() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		article.ConsignmentTrackingNumber__c = 'TN000001';
		article.ProductID__c = '001';

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => article });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 14, 30, 0);

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1 };
		Set<String> articleIdNames = new Set<String>{ article.Name };
		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<MyCustomerDeliveryProofPdfController.DeliveryProofAttributes> podAttributesResult = MyCustomerDeliveryProofPdfController.buildAttributesForPDFDisplay(new Set<String>{ article.Name });
		Test.stopTest();

		System.assertEquals(false, String.isEmpty(MyCustomerDeliveryProofPdfController.pageError), 'The pageError property should have been set but was not');
		System.assertEquals(null, podAttributesResult, 'No delivery attribute/event should be created but instead got: ' + podAttributesResult); // "event" here is not a technical term but a business term
		((EventMessagesSelector) MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>) fflib_Match.eq(articleIdNames), (Set<Object>) fflib_Match.anyObject());
	}

	/**
	 *	Scenario: When some safe drop images are not yet cached in Salesforce within the entire consignment set, and required to be downloaded
	 *			Validate that the current state of the safe drop images including those that required to be downloaded should be returned by the backend controller
	 */
	@IsTest
	private static void testRetrieveSafeDropImageStateThatRequireMultipleDownloads() {
		// =====================================
		// Data Preparation
		// =====================================
		String consignmentNumber = 'TN000001';
		String article1Number = 'TN000001EXP01';
		String article2Number = 'TN000001EXP02';
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		consignment.Name = consignmentNumber;
		consignment.ArticleID__c = consignmentNumber;
		consignment.RecordType = ApplicationTestDataFactory.articleConsignmentRecordType;

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		articles[0].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[0].Name = article1Number;
		articles[0].ArticleID__c = article1Number;
		articles[0].ProductID__c = '001';
		articles[0].Consignment__c = consignment.Id;
		articles[0].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[0] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{ 'Consignment__r' => consignment });
		articles[1].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[1].Name = article2Number;
		articles[1].ArticleID__c = article2Number;
		articles[1].ProductID__c = '001';
		articles[1].Consignment__c = consignment.Id;
		articles[1].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[1] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[1], new Map<String, Object>{ 'Consignment__r' => consignment });

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => articles[0] });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 14, 30, 0);

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0];
		event2.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safedrop
		event2 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{ 'Article__r' => articles[0] });
		event2.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0];
		event3.Safe_Drop_GUID__c = '23123-35435-gf-555';
		event3.EventType__c = 'DD-ER38';
		event3 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{ 'Article__r' => articles[1] });
		event3.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 2, 0);

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{ 'Article__r' => articles[1] });
		event4.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 3, 0);

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4 };
		Map<Id, Article__c> articlesResult = new Map<Id, Article__c>{ consignment.Id => consignment, articles[0].Id => articles[0], articles[1].Id => articles[1] };
		Map<Id, Article__c> articles1Result = new Map<Id, Article__c>{ articles[0].Id => articles[0] };
		Set<String> consignmentSet = new Set<String>{ consignment.Name };
		Set<String> article1set = new Set<String>{ articles[0].Name };
		Set<String> articleNumberset = new Set<String>{ consignment.Name, articles[0].Name, articles[1].Name };

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByIdOrTracking((Set<String>) fflib_Match.eq(article1set), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.eq(true))
			)
			.thenReturn(articles1Result);
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByIdOrTracking((Set<String>) fflib_Match.eq(consignmentSet), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.eq(true))
			)
			.thenReturn(articlesResult);
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleNumberset), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<MyCustomerDeliveryProofPdfController.SafeDropImageState> states = MyCustomerDeliveryProofPdfController.getCurrentStateOfSafeDropImageRequiredForDownload(articles[0].Name);
		Test.stopTest();

		Assert.isNotNull(states, 'Expected safe drop image state to not be null');
		Assert.areEqual(2, states.size(), 'Expected safe drop image state with count of 2 but instead got : ' + states.size());
		Assert.areEqual(true, states.get(0).requireDownload, 'Expected requireDownload flag to be true but instead got: ' + states.get(0).requireDownload);
		Assert.areEqual(event2.Safe_Drop_GUID__c, states.get(0).guidID, 'Expected guidID to match ' + event2.Safe_Drop_GUID__c + ' but instead got: ' + states.get(0).guidID);
		Assert.areEqual(event2.Id, states.get(0).eventMessageId, 'Expected event message ID to match ' + event2.Id + ' but instead got: ' + states.get(0).eventMessageId);

		Assert.areEqual(true, states.get(1).requireDownload, 'Expected requireDownload flag to be true but instead got: ' + states.get(1).requireDownload);
		Assert.areEqual(event3.Safe_Drop_GUID__c, states.get(1).guidID, 'Expected guidID to match ' + event3.Safe_Drop_GUID__c + ' but instead got: ' + states.get(1).guidID);
		Assert.areEqual(event3.Id, states.get(1).eventMessageId, 'Expected event message ID to match ' + event3.Id + ' but instead got: ' + states.get(1).eventMessageId);
	}

	/**
	 *	Scenario: When there is one delivery event containing 2 articles and the Consignment tracking number is passed to the VF PDF Page controller,
	 *			Validate that the correct delivery results including relevant attributes are returned back by the controller
	 *
	 */
	@IsTest
	private static void testOneDeliveryEventWithMultipleArticles() {
		// =====================================
		// Data Preparation
		// =====================================
		String consignmentNumber = 'TN000001';
		String article1Number = 'TN000001EXP01';
		String article2Number = 'TN000001EXP02';
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		consignment.Name = consignmentNumber;
		consignment.ArticleID__c = consignmentNumber;
		consignment.RecordType = ApplicationTestDataFactory.articleConsignmentRecordType;
		consignment.FurtherReferences__c = 'ABC123, DEF456';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
		articles[0].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[0].Name = article1Number;
		articles[0].ArticleID__c = article1Number;
		articles[0].ProductID__c = '001';
		articles[0].Consignment__c = consignment.Id;
		articles[0].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[0].IsDelivered__c = true;
		articles[0] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{ 'Consignment__r' => consignment });
		articles[1].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[1].Name = article2Number;
		articles[1].ArticleID__c = article2Number;
		articles[1].ProductID__c = '002';
		articles[1].Consignment__c = consignment.Id;
		articles[1].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[1].IsDelivered__c = true;
		articles[1] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[1], new Map<String, Object>{ 'Consignment__r' => consignment });

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0];
		event1.SignatureXString__c = '1';
		event1.EventType__c = 'DD-ER13'; // delivered - signature
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => articles[0] });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0];
		event2.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safedrop
		event2 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{ 'Article__r' => articles[1] });
		event2.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		Attachment signatureAttachment = ApplicationTestDataFactory.getAttachments(1, event1.Id, true)[0];
		signatureAttachment.Name = 'Signature-123.png';
		signatureAttachment.Body = null; // Blobs do not work with serialisation
		event1 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event1, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ signatureAttachment } });
		event1.Attachments[0].Body = Blob.valueOf('test');

		Attachment safedropAttachment = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		safedropAttachment.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
		safedropAttachment.Body = null; // Blobs do not work with serialisation
		event2 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event2, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ safedropAttachment } });
		// Reset the attachment body
		event2.Attachments[0].Body = Blob.valueOf('test');

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1, event2.Id => event2 };
		Map<Id, Article__c> articlesResult = new Map<Id, Article__c>{ consignment.Id => consignment, articles[0].Id => articles[0], articles[1].Id => articles[1] };
		Map<Id, Article__c> article1Result = new Map<Id, Article__c>{ articles[0].Id => articles[0] };
		Set<String> consignmentSet = new Set<String>{ consignment.Name };
		Set<String> article1Set = new Set<String>{ articles[0].Name };
		Set<String> articleNumberSet = new Set<String>{ consignment.Name, articles[0].Name, articles[1].Name };

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByIdOrTracking((Set<String>) fflib_Match.eq(article1Set), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.eq(true))
			)
			.thenReturn(article1Result);
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByIdOrTracking((Set<String>) fflib_Match.eq(consignmentSet), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.eq(true))
			)
			.thenReturn(articlesResult);
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleNumberSet), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PageReference deliveryProofPdfPage = Page.MyCustomerDeliveryProofPdfWrapper;
		deliveryProofPdfPage.getParameters().put('articleId', consignmentNumber); // pass consignment number here
		Test.setCurrentPage(deliveryProofPdfPage);

		new MyCustomerDeliveryProofPdfController();
		List<MyCustomerDeliveryProofPdfController.DeliveryProofAttributes> podAttributesResult = MyCustomerDeliveryProofPdfController.deliveryProofAttributes;

		Test.stopTest();

		Set<String> deliveryEvents = new Set<String>();
		for (MyCustomerDeliveryProofPdfController.DeliveryProofAttributes pod : podAttributesResult) {
			deliveryEvents.add(pod.deliveryKey);
		}
		// Verify Delivery Event attributes that should be displayed on the PDF layout
		Assert.isNotNull(podAttributesResult, 'Delivery event result should not be null');
		Assert.areEqual(1, deliveryEvents.size(), 'There should be one delivery event but instead got: ' + deliveryEvents.size());
		Assert.areEqual(2, podAttributesResult.size(), 'There should be two delivery results but instead got: ' + podAttributesResult.size());
		Assert.isTrue(
			podAttributesResult.get(0).articlesInDeliveryEvent.contains(articles[0].Name),
			'Delivery Event Result should contain article ' + articles[0].Name + 'but instead got ' + podAttributesResult.get(0).articlesInDeliveryEvent
		);
		Assert.isTrue(
			podAttributesResult.get(0).articlesInDeliveryEvent.contains(articles[1].Name),
			'Delivery Event Result should contain article ' + articles[1].Name + 'but instead got ' + podAttributesResult.get(0).articlesInDeliveryEvent
		);
		Assert.isFalse(podAttributesResult.get(0).isStarTrackProduct, 'Expected a non-StarTrack product but instead got a StarTrack Product');
		Assert.isFalse(podAttributesResult.get(1).isStarTrackProduct, 'Expected a StarTrack product but it wasn\'t');
		Assert.areEqual(2, podAttributesResult.get(0).consigned, 'Expected 2 consigned articles but instead got ' + podAttributesResult.get(0).consigned);
		Assert.areEqual(2, podAttributesResult.get(0).delivered, 'Expected 2 delivered articles but instead got ' + podAttributesResult.get(0).delivered);
		Assert.areEqual(podAttributesResult.get(0).deliveryKey, podAttributesResult.get(1).deliveryKey, 'Expected that the delivery key should match between the two delivery events but they were\'t matched');
		Assert.areEqual('\nABC123\nDEF456', podAttributesResult.get(0).eventMessage.Article__r.FurtherReferences__c, 'Expected that the delivery key should match between the two delivery events but they were\'t matched');
	}

	/**
	 *	Scenario: When there is two delivery events where each containing 2 articles, one pending delivery and the Consignment tracking number is passed to the VF PDF Page controller,
	 *			Validate that the correct delivery results including relevant attributes are returned back by the controller.
	 *			Ensure that all delivery events are returned for all articles that are under the same parent consignment set
	 *
	 */
	@IsTest
	private static void testMultipleDeliveryEventsWithMultipleArticlesWhenConsignmentNumberIsProvided() {
		// =====================================
		// Data Preparation
		// =====================================
		String consignmentNumber = 'TN000001';
		String article1Number = 'TN000001EXP01';
		String article2Number = 'TN000001EXP02';
		String article3Number = 'TN000001EXP03';
		String article4Number = 'TN000001EXP04';
		String article5Number = 'TN000001EXP05';
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		consignment.Name = consignmentNumber;
		consignment.ArticleID__c = consignmentNumber;
		consignment.RecordType = ApplicationTestDataFactory.articleConsignmentRecordType;
		consignment.FurtherReferences__c = 'ABC123, DEF456';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(5, true);
		articles[0].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[0].Name = article1Number;
		articles[0].ArticleID__c = article1Number;
		articles[0].ProductID__c = '001';
		articles[0].Consignment__c = consignment.Id;
		articles[0].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[0].IsDelivered__c = true;
		articles[0] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{ 'Consignment__r' => consignment });

		articles[1].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[1].Name = article2Number;
		articles[1].ArticleID__c = article2Number;
		articles[1].ProductID__c = '002';
		articles[1].Consignment__c = consignment.Id;
		articles[1].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[1].IsDelivered__c = true;
		articles[1] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[1], new Map<String, Object>{ 'Consignment__r' => consignment });

		articles[2].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[2].Name = article3Number;
		articles[2].ArticleID__c = article3Number;
		articles[2].Consignment__c = consignment.Id;
		articles[2].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[2].IsDelivered__c = true;
		articles[2] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[2], new Map<String, Object>{ 'Consignment__r' => consignment });

		articles[3].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[3].Name = article4Number;
		articles[3].ArticleID__c = article4Number;
		articles[3].Consignment__c = consignment.Id;
		articles[3].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[3].IsDelivered__c = true;
		articles[3] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[3], new Map<String, Object>{ 'Consignment__r' => consignment });

		articles[4].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[4].Name = article5Number;
		articles[4].ArticleID__c = article5Number;
		articles[4].Consignment__c = consignment.Id;
		articles[4].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[4].IsDelivered__c = false;
		articles[4] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[4], new Map<String, Object>{ 'Consignment__r' => consignment });

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0];
		event1.SignatureXString__c = '1';
		event1.EventType__c = 'DD-ER13'; // delivered - signature
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => articles[0] });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0];
		event2.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safedrop
		event2 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{ 'Article__r' => articles[1] });
		event2.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0];
		event3.SignatureXString__c = '1';
		event3.EventType__c = 'DD-ER13'; // delivered - signature
		event3 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{ 'Article__r' => articles[2] });
		event3.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 2, 1, 0);

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, articles[3].Id, true)[0];
		event4.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event4.EventType__c = 'DD-ER38'; // delivered - safedrop
		event4 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{ 'Article__r' => articles[3] });
		event4.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 2, 1, 0);

		EventMessage__c event5 = ApplicationTestDataFactory.getEventMessages(1, articles[4].Id, true)[0];
		event5.EventType__c = 'AFC-ER7'; // not delivered
		event5 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event5, new Map<String, Object>{ 'Article__r' => articles[4] });
		event5.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 3, 2, 0);

		Attachment signatureAttachment1 = ApplicationTestDataFactory.getAttachments(1, event1.Id, true)[0];
		signatureAttachment1.Name = 'Signature-123.png';
		signatureAttachment1.Body = null; // Blobs do not work with serialisation
		event1 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event1, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ signatureAttachment1 } });
		event1.Attachments[0].Body = Blob.valueOf('test');

		Attachment safedropAttachment1 = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		safedropAttachment1.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
		safedropAttachment1.Body = null; // Blobs do not work with serialisation
		event2 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event2, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ safedropAttachment1 } });
		// Reset the attachment body
		event2.Attachments[0].Body = Blob.valueOf('test');

		Attachment signatureAttachment2 = ApplicationTestDataFactory.getAttachments(1, event3.Id, true)[0];
		signatureAttachment2.Name = 'Signature-123.png';
		signatureAttachment2.Body = null; // Blobs do not work with serialisation
		event3 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event3, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ signatureAttachment2 } });
		event3.Attachments[0].Body = Blob.valueOf('test');

		Attachment safedropAttachment2 = ApplicationTestDataFactory.getAttachments(1, event4.Id, true)[0];
		safedropAttachment2.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
		safedropAttachment2.Body = null; // Blobs do not work with serialisation
		event4 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event4, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ safedropAttachment2 } });
		// Reset the attachment body
		event4.Attachments[0].Body = Blob.valueOf('test');

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4, event5.Id => event5 };
		Map<Id, Article__c> articlesResult = new Map<Id, Article__c>{
			consignment.Id => consignment,
			articles[0].Id => articles[0],
			articles[1].Id => articles[1],
			articles[2].Id => articles[2],
			articles[3].Id => articles[3],
			articles[4].Id => articles[4]
		};
		Map<Id, Article__c> article1Result = new Map<Id, Article__c>{ articles[0].Id => articles[0] };
		Set<String> consignmentSet = new Set<String>{ consignment.Name };
		Set<String> article1Set = new Set<String>{ articles[0].Name };
		Set<String> articleNumberSet = new Set<String>{ consignment.Name, articles[0].Name, articles[1].Name, articles[2].Name, articles[3].Name, articles[4].Name };

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByIdOrTracking((Set<String>) fflib_Match.eq(article1Set), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.eq(true))
			)
			.thenReturn(article1Result);
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByIdOrTracking((Set<String>) fflib_Match.eq(consignmentSet), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.eq(true))
			)
			.thenReturn(articlesResult);
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleNumberSet), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PageReference deliveryProofPdfPage = Page.MyCustomerDeliveryProofPdfWrapper;
		deliveryProofPdfPage.getParameters().put('articleId', consignmentNumber); // pass consignment number here
		Test.setCurrentPage(deliveryProofPdfPage);

		new MyCustomerDeliveryProofPdfController();
		List<MyCustomerDeliveryProofPdfController.DeliveryProofAttributes> podAttributesResult = MyCustomerDeliveryProofPdfController.deliveryProofAttributes;

		Test.stopTest();

		Set<String> deliveryEvents = new Set<String>();
		for (MyCustomerDeliveryProofPdfController.DeliveryProofAttributes pod : podAttributesResult) {
			deliveryEvents.add(pod.deliveryKey);
		}
		// Verify Delivery Event attributes that should be displayed on the PDF layout
		Assert.isNotNull(podAttributesResult, 'Delivery event result should not be null');
		Assert.areEqual(2, deliveryEvents.size(), 'There should be 2 delivery events but instead got: ' + deliveryEvents.size());
		Assert.areEqual(4, podAttributesResult.size(), 'There should be four delivery result but instead got: ' + podAttributesResult.size());
		Assert.isTrue(
			podAttributesResult.get(0).articlesInDeliveryEvent.contains(articles[0].Name),
			'Delivery Event Result should contain article ' + articles[0].Name + 'but instead got ' + podAttributesResult.get(0).articlesInDeliveryEvent
		);
		Assert.isTrue(
			podAttributesResult.get(1).articlesInDeliveryEvent.contains(articles[1].Name),
			'Delivery Event Result should contain article ' + articles[1].Name + 'but instead got ' + podAttributesResult.get(1).articlesInDeliveryEvent
		);
		Assert.isTrue(
			podAttributesResult.get(2).articlesInDeliveryEvent.contains(articles[2].Name),
			'Delivery Event Result should contain article ' + articles[2].Name + 'but instead got ' + podAttributesResult.get(2).articlesInDeliveryEvent
		);
		Assert.isTrue(
			podAttributesResult.get(3).articlesInDeliveryEvent.contains(articles[3].Name),
			'Delivery Event Result should contain article ' + articles[3].Name + 'but instead got ' + podAttributesResult.get(3).articlesInDeliveryEvent
		);
		Assert.isFalse(podAttributesResult.get(0).isStarTrackProduct, 'Expected a non-StarTrack product but instead got a StarTrack Product');
		Assert.isFalse(podAttributesResult.get(1).isStarTrackProduct, 'Expected a StarTrack product but it wasn\'t');
		Assert.areEqual(5, podAttributesResult.get(0).consigned, 'Expected 5 consigned articles but instead got ' + podAttributesResult.get(0).consigned);
		Assert.areEqual(4, podAttributesResult.get(0).delivered, 'Expected 4 delivered article but instead got ' + podAttributesResult.get(0).delivered);
		Assert.areNotEqual(podAttributesResult.get(0).deliveryKey, podAttributesResult.get(2).deliveryKey, 'Expected that the delivery key should NOT match between the two delivery events but they were matched');
		Assert.areNotEqual(podAttributesResult.get(1).deliveryKey, podAttributesResult.get(3).deliveryKey, 'Expected that the delivery key should NOT match between the two delivery events but they were matched');
		Assert.areEqual(podAttributesResult.get(0).deliveryKey, podAttributesResult.get(1).deliveryKey, 'Expected that the delivery key should match between the two delivery events but they were NOT matched');
		Assert.areEqual(podAttributesResult.get(2).deliveryKey, podAttributesResult.get(3).deliveryKey, 'Expected that the delivery key should match between the two delivery events but they were NOT matched');
		Assert.areEqual('\nABC123\nDEF456', podAttributesResult.get(0).eventMessage.Article__r.FurtherReferences__c, 'Expected that the delivery key should match between the two delivery events but they were\'t matched');
	}

	/**
	 *	Scenario: When there is two delivery events where each containing 2 articles, one pending delivery and the article tracking number is passed to the VF PDF Page controller,
	 *			Validate that the correct delivery results including relevant attributes are returned back by the controller.
	 *			Ensure that not all delivery events are returned, only those delivered in the same delivery as the article should be returned.
	 */
	@IsTest
	private static void testMultipleDeliveryEventsWithMultipleArticlesWhenArticleNumberIsProvided() {
		// =====================================
		// Data Preparation
		// =====================================
		String consignmentNumber = 'TN000001';
		String article1Number = 'TN000001EXP01';
		String article2Number = 'TN000001EXP02';
		String article3Number = 'TN000001EXP03';
		String article4Number = 'TN000001EXP04';
		String article5Number = 'TN000001EXP05';
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, true)[0];
		consignment.Name = consignmentNumber;
		consignment.ArticleID__c = consignmentNumber;
		consignment.RecordType = ApplicationTestDataFactory.articleConsignmentRecordType;
		consignment.FurtherReferences__c = 'ABC123, DEF456';

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(5, true);
		articles[0].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[0].Name = article1Number;
		articles[0].ArticleID__c = article1Number;
		articles[0].ProductID__c = '001';
		articles[0].Consignment__c = consignment.Id;
		articles[0].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[0].IsDelivered__c = true;
		articles[0] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[0], new Map<String, Object>{ 'Consignment__r' => consignment });

		articles[1].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[1].Name = article2Number;
		articles[1].ArticleID__c = article2Number;
		articles[1].ProductID__c = '002';
		articles[1].Consignment__c = consignment.Id;
		articles[1].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[1].IsDelivered__c = true;
		articles[1] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[1], new Map<String, Object>{ 'Consignment__r' => consignment });

		articles[2].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[2].Name = article3Number;
		articles[2].ArticleID__c = article3Number;
		articles[2].Consignment__c = consignment.Id;
		articles[2].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[2].IsDelivered__c = true;
		articles[2] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[2], new Map<String, Object>{ 'Consignment__r' => consignment });

		articles[3].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[3].Name = article4Number;
		articles[3].ArticleID__c = article4Number;
		articles[3].Consignment__c = consignment.Id;
		articles[3].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[3].IsDelivered__c = true;
		articles[3] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[3], new Map<String, Object>{ 'Consignment__r' => consignment });

		articles[4].ConsignmentTrackingNumber__c = consignmentNumber;
		articles[4].Name = article5Number;
		articles[4].ArticleID__c = article5Number;
		articles[4].Consignment__c = consignment.Id;
		articles[4].RecordType = ApplicationTestDataFactory.articleArticleRecordType;
		articles[4].IsDelivered__c = false;
		articles[4] = (Article__c) ApplicationTestDataFactory.setUnwritableFields(articles[4], new Map<String, Object>{ 'Consignment__r' => consignment });

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, articles[0].Id, true)[0];
		event1.SignatureXString__c = '1';
		event1.EventType__c = 'DD-ER13'; // delivered - signature
		event1 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{ 'Article__r' => articles[0] });
		event1.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true)[0];
		event2.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safedrop
		event2 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{ 'Article__r' => articles[1] });
		event2.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 1, 1, 0);

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, articles[2].Id, true)[0];
		event3.SignatureXString__c = '1';
		event3.EventType__c = 'DD-ER13'; // delivered - signature
		event3 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{ 'Article__r' => articles[2] });
		event3.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 2, 1, 0);

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, articles[3].Id, true)[0];
		event4.Safe_Drop_GUID__c = '23123-35435-gf-454';
		event4.EventType__c = 'DD-ER38'; // delivered - safedrop
		event4 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{ 'Article__r' => articles[3] });
		event4.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 2, 1, 0);

		EventMessage__c event5 = ApplicationTestDataFactory.getEventMessages(1, articles[4].Id, true)[0];
		event5.EventType__c = 'AFC-ER7'; // not delivered
		event5 = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(event5, new Map<String, Object>{ 'Article__r' => articles[4] });
		event5.ActualDateTime__c = DateTime.newInstance(System.today().year(), System.today().month(), System.today().day(), 3, 2, 0);

		Attachment signatureAttachment1 = ApplicationTestDataFactory.getAttachments(1, event1.Id, true)[0];
		signatureAttachment1.Name = 'Signature-123.png';
		signatureAttachment1.Body = null; // Blobs do not work with serialisation
		event1 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event1, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ signatureAttachment1 } });
		event1.Attachments[0].Body = Blob.valueOf('test');

		Attachment safedropAttachment1 = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		safedropAttachment1.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
		safedropAttachment1.Body = null; // Blobs do not work with serialisation
		event2 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event2, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ safedropAttachment1 } });
		// Reset the attachment body
		event2.Attachments[0].Body = Blob.valueOf('test');

		Attachment signatureAttachment2 = ApplicationTestDataFactory.getAttachments(1, event3.Id, true)[0];
		signatureAttachment2.Name = 'Signature-123.png';
		signatureAttachment2.Body = null; // Blobs do not work with serialisation
		event3 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event3, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ signatureAttachment2 } });
		event3.Attachments[0].Body = Blob.valueOf('test');

		Attachment safedropAttachment2 = ApplicationTestDataFactory.getAttachments(1, event4.Id, true)[0];
		safedropAttachment2.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
		safedropAttachment2.Body = null; // Blobs do not work with serialisation
		event4 = (EventMessage__c) ApplicationTestDataFactory.setChildRelationships(event4, new Map<String, List<SObject>>{ 'Attachments' => new List<SObject>{ safedropAttachment2 } });
		// Reset the attachment body
		event4.Attachments[0].Body = Blob.valueOf('test');

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{ event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4, event5.Id => event5 };
		Map<Id, Article__c> articlesResult = new Map<Id, Article__c>{
			consignment.Id => consignment,
			articles[0].Id => articles[0],
			articles[1].Id => articles[1],
			articles[2].Id => articles[2],
			articles[3].Id => articles[3],
			articles[4].Id => articles[4]
		};
		Map<Id, Article__c> article1Result = new Map<Id, Article__c>{ articles[0].Id => articles[0] };
		Set<String> consignmentSet = new Set<String>{ consignment.Name };
		Set<String> article1Set = new Set<String>{ articles[0].Name };
		Set<String> articleNumberSet = new Set<String>{ consignment.Name, articles[0].Name, articles[1].Name, articles[2].Name, articles[3].Name, articles[4].Name };

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector) MockUtility.mockSelector(EventMessagesSelector.class);
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByIdOrTracking((Set<String>) fflib_Match.eq(article1Set), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.eq(true))
			)
			.thenReturn(article1Result);
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByIdOrTracking((Set<String>) fflib_Match.eq(consignmentSet), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject(), (Boolean) fflib_Match.eq(true))
			)
			.thenReturn(articlesResult);
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>) fflib_Match.eq(articleNumberSet), (Set<Object>) fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PageReference deliveryProofPdfPage = Page.MyCustomerDeliveryProofPdfWrapper;
		deliveryProofPdfPage.getParameters().put('articleId', article1Number); // pass article number here
		Test.setCurrentPage(deliveryProofPdfPage);

		new MyCustomerDeliveryProofPdfController();
		List<MyCustomerDeliveryProofPdfController.DeliveryProofAttributes> podAttributesResult = MyCustomerDeliveryProofPdfController.deliveryProofAttributes;

		Test.stopTest();

		Set<String> deliveryEvents = new Set<String>();
		for (MyCustomerDeliveryProofPdfController.DeliveryProofAttributes pod : podAttributesResult) {
			deliveryEvents.add(pod.deliveryKey);
		}
		// Verify Delivery Event attributes that should be displayed on the PDF layout
		Assert.isNotNull(podAttributesResult, 'Delivery event result should not be null');
		Assert.areEqual(1, deliveryEvents.size(), 'There should be 1 delivery events but instead got: ' + deliveryEvents.size());
		Assert.areEqual(2, podAttributesResult.size(), 'There should be two delivery result but instead got: ' + podAttributesResult.size());
		Assert.isTrue(
			podAttributesResult.get(0).articlesInDeliveryEvent.contains(articles[0].Name),
			'Delivery Event Result should contain article ' + articles[0].Name + 'but instead got ' + podAttributesResult.get(0).articlesInDeliveryEvent
		);
		Assert.isTrue(
			podAttributesResult.get(1).articlesInDeliveryEvent.contains(articles[1].Name),
			'Delivery Event Result should contain article ' + articles[1].Name + 'but instead got ' + podAttributesResult.get(1).articlesInDeliveryEvent
		);
		Assert.isFalse(podAttributesResult.get(0).isStarTrackProduct, 'Expected a non-StarTrack product but instead got a StarTrack Product');
		Assert.isFalse(podAttributesResult.get(1).isStarTrackProduct, 'Expected a StarTrack product but it wasn\'t');
		Assert.areEqual(5, podAttributesResult.get(0).consigned, 'Expected 5 consigned articles but instead got ' + podAttributesResult.get(0).consigned);
		Assert.areEqual(4, podAttributesResult.get(0).delivered, 'Expected 4 delivered article but instead got ' + podAttributesResult.get(0).delivered);
		Assert.areEqual(podAttributesResult.get(0).deliveryKey, podAttributesResult.get(1).deliveryKey, 'Expected that the delivery key should match between the two delivery events but they were NOT matched');
		Assert.areEqual('\nABC123\nDEF456', podAttributesResult.get(0).eventMessage.Article__r.FurtherReferences__c, 'Expected that the delivery key should match between the two delivery events but they were\'t matched');
	}
}