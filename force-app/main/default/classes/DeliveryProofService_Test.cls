/**
 * Test class for DeliveryProofService
 *
 * @author Nathan Franklin
 * @date 2021-10-10
 * @changelog
 * 2022/09/12 prerna.rahangdale@auspost.com.au test method testSafeDropGuidHttpRequest
 */
@IsTest
public with sharing class DeliveryProofService_Test {

	/***
     * Test that a Delivery Proof is successfully generated and attached
     */
	@IsTest
	private static void testADeliveryProofIsGeneratedAndAttachedSynchronously() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

		EventMessage__c event = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event.Safe_Drop_GUID__c='23123-35435-gf-454';
		event.EventType__c = 'DD-ER38'; // delivered - with safe drop

		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Case ssswCase = ApplicationTestDataFactory.getCases(1, new Set<Id>{contact.Id}, true)[0];
		ssswCase.ReferenceID__c = article.Id;
		ssswCase.ArticleTest__c = article.Id;
		ssswCase = (Case)ApplicationTestDataFactory.setUnwritableFields(ssswCase, new Map<String, Object>{'ArticleTest__r' => article});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		SSSWCasesSelector mockCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{ssswCase.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{ssswCase.Id => ssswCase});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		DeliveryProofService.getInstance().attachAPDeliveryProofPdf(new Set<Id>{ssswCase.Id});

		Test.stopTest();

		((SSSWCasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{ssswCase.Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());

		System.assertEquals(DeliveryProofService.DELIVERY_PROOF_CASE_FILENAME, ((Attachment)MockUtility.mockDMLInsertedRecords[0]).Name);
		System.assertEquals(false, ((Attachment)MockUtility.mockDMLInsertedRecords[0]).IsPrivate);
	}

	/***
     * Test that a Delivery Proof is successfully generated and attached
     */
	@IsTest
	private static void testADeliveryProofIsGeneratedAndAttachedAsynchronous() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

		EventMessage__c event = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event.Safe_Drop_GUID__c='23123-35435-gf-454';
		event.EventType__c = 'DD-ER38'; // delivered - with safe drop

		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		Case ssswCase = ApplicationTestDataFactory.getCases(1, new Set<Id>{contact.Id}, true)[0];
		ssswCase.ReferenceID__c = article.Id;
		ssswCase.ArticleTest__c = article.Id;
		ssswCase = (Case)ApplicationTestDataFactory.setUnwritableFields(ssswCase, new Map<String, Object>{'ArticleTest__r' => article});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		SSSWCasesSelector mockCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{ssswCase.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{ssswCase.Id => ssswCase});
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		DeliveryProofService.getInstance().enqueueAttachAPDeliveryProof(new Set<Id>{ssswCase.Id});

		Test.stopTest();

		((SSSWCasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{ssswCase.Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());

		System.assertEquals(DeliveryProofService.DELIVERY_PROOF_CASE_FILENAME, ((Attachment)MockUtility.mockDMLInsertedRecords[0]).Name);
		System.assertEquals(false, ((Attachment)MockUtility.mockDMLInsertedRecords[0]).IsPrivate);

	}

	/***
     * Test that an article with safedrop is eligible for delivery proof generation
     */
	@IsTest
	private static void testArticleWithSafedropIsEligibleForDeliveryProofAttachment() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; // delivered - with safe drop
		event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.Safe_Drop_GUID__c='23123-35435-gf-454';
		event2.EventType__c = 'DD-ER38'; // delivered - with safe drop
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
		Set<Id> articleIds = new Set<Id>{article.Id};
		Set<String> articleIdNames = new Set<String>{article.Name};

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleId((Set<Id>)fflib_Match.eq(articleIds), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages);
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Set<Id> articleIdsOutput = DeliveryProofService.getInstance().getDeliveryProofAvailable(articleIds);
		Set<String> articleIdNamesOutput = DeliveryProofService.getInstance().getDeliveryProofAvailable(articleIdNames);

		System.assertEquals(articleIds, articleIdsOutput, 'Checking eligibility by Article Ids failed');
		System.assertEquals(articleIdNames, articleIdNamesOutput, 'Checking eligibility by Article Names failed');

		Test.stopTest();

		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleId((Set<Id>)fflib_Match.eq(articleIds), (Set<Object>)fflib_Match.anyObject());
		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject());

	}

	/***
     * Test that an article with delivery signature is eligible for delivery proof generation
     */
	@IsTest
	private static void testArticleWithSignatureIsEligibleForDeliveryProofAttachment() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];

		EventMessage__c event1 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event1.EventType__c = 'ADMIN-ER39'; // delivered - with safe drop
		event1 = (EventMessage__c)ApplicationTestDataFactory.setUnwritableFields(event1, new Map<String, Object>{'Article__r' => article});

		EventMessage__c event2 = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event2.SignatureXString__c = '1';
		event2.EventType__c = 'DD-ER13'; // delivered - signature
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
		Set<Id> articleIds = new Set<Id>{article.Id};
		Set<String> articleIdNames = new Set<String>{article.Name};

		EventMessagesSelector mockEventmessageSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleId((Set<Id>)fflib_Match.eq(articleIds), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages);
		MockUtility.Mocks.when(mockEventmessageSelector.selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject())).thenReturn(eventMessages.values());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Set<Id> articleIdsOutput = DeliveryProofService.getInstance().getDeliveryProofAvailable(articleIds);
		Set<String> articleIdNamesOutput = DeliveryProofService.getInstance().getDeliveryProofAvailable(articleIdNames);

		System.assertEquals(articleIds, articleIdsOutput, 'Checking eligibility by Article Ids failed');
		System.assertEquals(articleIdNames, articleIdNamesOutput, 'Checking eligibility by Article Names failed');

		Test.stopTest();

		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleId((Set<Id>)fflib_Match.eq(articleIds), (Set<Object>)fflib_Match.anyObject());
		((EventMessagesSelector)MockUtility.Mocks.verify(mockEventmessageSelector, MockUtility.Mocks.times(1))).selectByArticleNumber((Set<String>)fflib_Match.eq(articleIdNames), (Set<Object>)fflib_Match.anyObject());

	}

	/***
     * Test that an article with delivery signature is eligible for delivery proof generation
     */
	@IsTest
	private static void testSafeDropGuidHttpRequest() {
		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new DeliveryProofServiceHttpMock());
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
			System.assertEquals('aa92d596-879e-4a4e-85ae-6a8c68f8d5b4',DeliveryProofService.getSafeDropGuidHttpRequest('JDQ168278501000600803'));
		Test.stopTest();


	}

	public class DeliveryProofServiceHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			if (req.getEndpoint().containsIgnoreCase('guid')) {
				res.setStatusCode(200);
				res.setBody('{\n' +
						'	"safeDropImageGuid":"aa92d596-879e-4a4e-85ae-6a8c68f8d5b4"\n' +
						'}');
				return res;
			}
			return res;
		}
	}
}