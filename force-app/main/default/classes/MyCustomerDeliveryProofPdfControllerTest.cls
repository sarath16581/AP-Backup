/**
 * Test class that covers MyCustomerDeliveryProofPdfController
 *
 * @author Nathan Franklin
 * @date 2021-10-15
 * @changelog
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

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.SignatureXString__c = '1';
		event2.EventType__c = 'DD-ER13'; // delivered - signature

		// NOTE: Any event messages with SignatureXString__c field set are automatically added as a signature attachment in the EventMessageTrigger (EventMessageUtil.createSignatureAttachments method)
		// We can always rely on this attachment existing therefore we can mock it
		Attachment signatureAttachment = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		signatureAttachment.Name = 'Signature-123.png';
		signatureAttachment.Body = null; // Blobs do not work with serialisation

		event2 = (EventMessage__c)ApplicationTestDataFactory.setChildRelationships(event2, new Map<String, List<SObject>>{'Attachments' => new List<SObject>{signatureAttachment}});
		event2 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{'Article__r' => article});

		// Reset the attachment body
		event2.Attachments[0].Body = Blob.valueOf('test');

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event3.EventType__c = 'DD-ER33';
		event3 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{'Article__r' => article});


		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4};
		Set<String> articleIdNames = new Set<String>{article.Name};
		Set<Id> signatureEventIds = new Set<Id>{event2.Id};

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.when(mockEventmessageSelector.selectById((Set<Id>)fflib_Match.eq(signatureEventIds), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>{event2.Id => event2});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PageReference deliveryProofPdfPage = Page.MyCustomerDeliveryProofPdfWrapper;
		deliveryProofPdfPage.getParameters().put('articleId', article.Name);
		Test.setCurrentPage(deliveryProofPdfPage);

		MyCustomerDeliveryProofPdfController controller = new MyCustomerDeliveryProofPdfController();
		Object output = controller.getSafeDropOrSignature();

		Test.stopTest();

		System.assertEquals(null, output, 'getSafeDropOrSignature should have returned null since no callout was needed for signature delivery proofs');
		System.assertEquals(signatureAttachment.Id, controller.signatureAttachmentId, 'Signature attachment id was not set correctly');
		System.assertEquals(null, controller.safeDropAttachmentId, 'Safedrop attachment id has been assigned but shouldnt: ' + controller.safeDropAttachmentId);
		System.assert(String.isEmpty(controller.pageError), 'Page error should be null: ' + controller.pageError);
		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject());
		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(signatureEventIds), (Set<Object>)fflib_Match.anyObject());
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

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.Safe_Drop_GUID__c='23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safe drop

		Attachment safedropAttachment = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		safedropAttachment.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
		safedropAttachment.Body = null; // Blobs do not work with serialisation

		event2 = (EventMessage__c)ApplicationTestDataFactory.setChildRelationships(event2, new Map<String, List<SObject>>{'Attachments' => new List<SObject>{safedropAttachment}});
		event2 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{'Article__r' => article});

		// Reset the attachment body
		event2.Attachments[0].Body = Blob.valueOf('test');

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event3.EventType__c = 'DD-ER33';
		event3 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{'Article__r' => article});


		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4};
		Set<String> articleIdNames = new Set<String>{article.Name};
		Set<Id> signatureEventIds = new Set<Id>{event2.Id};

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.when(mockEventmessageSelector.selectById((Set<Id>)fflib_Match.eq(signatureEventIds), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>{event2.Id => event2});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PageReference deliveryProofPdfPage = Page.MyCustomerDeliveryProofPdfWrapper;
		deliveryProofPdfPage.getParameters().put('articleId', article.Name);
		Test.setCurrentPage(deliveryProofPdfPage);

		MyCustomerDeliveryProofPdfController controller = new MyCustomerDeliveryProofPdfController();
		Object output = controller.getSafeDropOrSignature();

		Test.stopTest();

		System.assertEquals(null, output, 'getSafeDropOrSignature should have returned null since no callout was needed for safedrop delivery proofs where safedrop image is already cached locally');
		System.assertEquals(safedropAttachment.Id, controller.safeDropAttachmentId, 'Safedrop attachment id was not set correctly');
		System.assertEquals(null, controller.signatureAttachmentId, 'Signature attachment id has been assigned but shouldnt: ' + controller.signatureAttachmentId);
		System.assert(String.isEmpty(controller.pageError), 'Page error should be null: ' + controller.pageError);

		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject());
		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(signatureEventIds), (Set<Object>)fflib_Match.anyObject());
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

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.Safe_Drop_GUID__c='23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safedrop
		event2 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event3.EventType__c = 'DD-ER33';
		event3 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{'Article__r' => article});

		// this is used when attachSafedropToRecord is called after the Continuation response is invoked
		Attachment safedropAttachment = ApplicationTestDataFactory.getAttachments(1, event2.Id, true)[0];
		safedropAttachment.Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4};
		Set<String> articleIdNames = new Set<String>{article.Name};
		Set<Id> signatureEventIds = new Set<Id>{event2.Id};

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);
		SafeDropUtility mockSafeDropUtility = (SafeDropUtility)MockUtility.mockUtility(SafeDropUtility.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.when(mockEventmessageSelector.selectById((Set<Id>)fflib_Match.eq(signatureEventIds), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>{event2.Id => event2});
		MockUtility.Mocks.when(mockSafeDropUtility.attachSafeDropToRecord((Id)fflib_Match.eq(event2.Id), (Blob)fflib_Match.anyObject())).thenReturn(safedropAttachment);
		MockUtility.Mocks.when(mockSafeDropUtility.getHttpRequest(fflib_Match.anyString())).thenReturn(new HttpRequest());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PageReference deliveryProofPdfPage = Page.MyCustomerDeliveryProofPdfWrapper;
		deliveryProofPdfPage.getParameters().put('articleId', article.Name);
		Test.setCurrentPage(deliveryProofPdfPage);

		MyCustomerDeliveryProofPdfController controller = new MyCustomerDeliveryProofPdfController();

		// this method will return a continuation since the safedrop image is not cache locally yet
		Object output = controller.getSafeDropOrSignature();

		// Verify the return type is a continuation
		System.assert(output instanceof Continuation, 'A continuation should have been enqueued to retrieve safe drop image');

		// setup the continuation mock provider
		String requestLabel = new List<String>(((Continuation)output).getRequests().keySet())[0];
		SafeDropUtility_Test.setSuccessContinuationResponse(requestLabel);

		// this method will set the safedropAttachmentId
		controller.safeDropImageCallback();

		Test.stopTest();

		System.assertEquals(safedropAttachment.Id, controller.safeDropAttachmentId, 'Safedrop attachment id was not set correctly');
		System.assertEquals(null, controller.signatureAttachmentId, 'Signature attachment id has been assigned but shouldnt: ' + controller.signatureAttachmentId);
		System.assert(String.isEmpty(controller.pageError), 'Page error should be null: ' + controller.pageError);

		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject());
		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(signatureEventIds), (Set<Object>)fflib_Match.anyObject());
		((SafeDropUtility)MockUtility.Mocks.verify(mockSafeDropUtility, MockUtility.Mocks.times(1))).attachSafeDropToRecord((Id)fflib_Match.eq(event2.Id), (Blob)fflib_Match.anyObject());
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

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.Safe_Drop_GUID__c='23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - safedrop
		event2 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event2, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event3 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event3.EventType__c = 'DD-ER33';
		event3 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event3, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event4 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event4.EventType__c = 'AFC-ER7';
		event4 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event4, new Map<String, Object>{'Article__r' => article});

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{event1.Id => event1, event2.Id => event2, event3.Id => event3, event4.Id => event4};
		Set<String> articleIdNames = new Set<String>{article.Name};
		Set<Id> signatureEventIds = new Set<Id>{event2.Id};

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);
		SafeDropUtility mockSafeDropUtility = (SafeDropUtility)MockUtility.mockUtility(SafeDropUtility.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.when(mockEventmessageSelector.selectById((Set<Id>)fflib_Match.eq(signatureEventIds), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>{event2.Id => event2});
		MockUtility.Mocks.when(mockSafeDropUtility.attachSafeDropToRecord((Id)fflib_Match.eq(event2.Id), (Blob)fflib_Match.anyObject())).thenReturn(null);
		MockUtility.Mocks.when(mockSafeDropUtility.getHttpRequest(fflib_Match.anyString())).thenReturn(new HttpRequest());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PageReference deliveryProofPdfPage = Page.MyCustomerDeliveryProofPdfWrapper;
		deliveryProofPdfPage.getParameters().put('articleId', article.Name);
		Test.setCurrentPage(deliveryProofPdfPage);

		MyCustomerDeliveryProofPdfController controller = new MyCustomerDeliveryProofPdfController();

		// this method will return a continuation since the safedrop image is not cache locally yet
		Object output = controller.getSafeDropOrSignature();

		// Verify the return type is a continuation
		System.assert(output instanceof Continuation, 'A continuation should have been enqueued to retrieve safe drop image');

		// setup the continuation mock provider
		String requestLabel = new List<String>(((Continuation)output).getRequests().keySet())[0];
		SafeDropUtility_Test.setErrorContinuationResponse(requestLabel);

		// this method will set the pageError response since the continuation has failed
		controller.safeDropImageCallback();

		Test.stopTest();

		System.assertEquals(false, String.isEmpty(controller.pageError), 'The pageError property should have been set but wasnt');
		System.assertEquals(null, controller.safeDropAttachmentId, 'Safedrop attachment id has been assigned but shouldnt: ' + controller.safeDropAttachmentId);
		System.assertEquals(null, controller.signatureAttachmentId, 'Signature attachment id has been assigned but shouldnt: ' + controller.signatureAttachmentId);

		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject());
		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(signatureEventIds), (Set<Object>)fflib_Match.anyObject());

		// make sure attachSafeDropToRecord was NOT called since there was a continuation error
		((SafeDropUtility)MockUtility.Mocks.verify(mockSafeDropUtility, MockUtility.Mocks.times(0))).attachSafeDropToRecord((Id)fflib_Match.eq(event2.Id), (Blob)fflib_Match.anyObject());
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

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; //
		event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

		// =====================================
		// Stubbing
		// =====================================
		Map<Id, EventMessage__c> eventMessages = new Map<Id, EventMessage__c>{event1.Id => event1};
		Set<String> articleIdNames = new Set<String>{article.Name};

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PageReference deliveryProofPdfPage = Page.MyCustomerDeliveryProofPdfWrapper;
		deliveryProofPdfPage.getParameters().put('articleId', article.Name);
		Test.setCurrentPage(deliveryProofPdfPage);

		MyCustomerDeliveryProofPdfController controller = new MyCustomerDeliveryProofPdfController();

		// this method will return a continuation since the safedrop image is not cache locally yet
		controller.getSafeDropOrSignature();

		Test.stopTest();

		System.assertEquals(false, String.isEmpty(controller.pageError), 'The pageError property should have been set but wasnt');
		System.assertEquals(null, controller.safeDropAttachmentId, 'Safedrop attachment id has been assigned but shouldnt: ' + controller.safeDropAttachmentId);
		System.assertEquals(null, controller.signatureAttachmentId, 'Signature attachment id has been assigned but shouldnt: ' + controller.signatureAttachmentId);

		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject());

		// Ensure selectById was NOT called, this means no valid scan events were found
		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(0))).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());
	}

}