/***
 * @description Test class for CaseRelatedListPanelContExt
 * @author Fuqi Tan
 * @date 2014-06-20
 * @group Tests
 * @changelog
 * 2017-10-11 - boris.bachovski@auspost.com.au - Merged code from CaseRelatedListSafeDropController_Test (deleted)
 * 2020-08-14 - Nathan Franklin - Update failing tests from refactoring
 * 2022-06-07 - Talib Raza - INC1979490: testGeneral - due to version uplift changed FeedItem and added contentversion and feedattachment
 * 2024-09-20 - Vasu Gorakati - Case Hand-off - Voice call records visibility to classic users
 */
@isTest
public with sharing class CaseRelatedListPanelContExtTest {
	@IsTest
	static void testGeneral(){
		// Changed profile from AP Integration to AusPost Integration for REQ0973842 : Nandan - 09/11/2016
		Profile p = [SELECT Id FROM Profile WHERE Name='AusPost Integration'];
		User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
				EmailEncodingKey='UTF-8', LastName='AP Integration', LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = p.Id,
				TimeZoneSidKey='America/Los_Angeles', UserName='standarduserapInti@testorg.com');
		insert u;
		test.starttest();
		Case testCase = TestDataProvider.createCase();
		insert testCase;
		//insert case comment
		CaseComment cc = new CAseComment(ParentId = testCase.Id,CommentBody='test comment',CreatedById=u.Id);
		insert cc;
		//insert cn18 form
		Attachment attcn18 = new Attachment();
		attcn18.ParentId = testCase.Id;
		attcn18.Body = blob.valueOf('test');
		attcn18.Name = 'CN 18 Form';
		insert attcn18;

		Attachment att = new Attachment();
		att.ParentId = testCase.Id;
		att.Body = blob.valueOf('test');
		att.Name = 'test';
		insert att;

		// INC1979490: testGeneral - due to version uplift changed FeedItem and added contentversion and feedattachment
		FeedItem fi = new FeedItem();
		fi.ParentId = testCase.Id;
		fi.Body = 'HelloThere';
		fi.Title = 'test';
		insert fi;
		
		ContentVersion cv = new ContentVersion();
		cv.Title = 'Test';
		cv.PathOnClient = 'test';
		cv.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body');
		insert cv;
		FeedAttachment feedAttachment = new FeedAttachment();
		feedAttachment.FeedEntityId = fi.Id;
		feedAttachment.RecordId = cv.Id;
		//feedAttachment.Title = 'FileName';
		feedAttachment.Type = 'CONTENT';
		insert feedAttachment;

		List<VoiceCall> voiceCalls = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{testCase.Id}, false);
		voiceCalls.get(0).CallType = 'Inbound';
		voiceCalls.get(0).VendorType = 'ContactCenter';
		voiceCalls.get(0).CallStartDateTime = System.now();
		voiceCalls.get(0).CallEndDateTime = System.now().addMinutes(5);
		voiceCalls.get(0).FromPhoneNumber = '+61 432 077 455';
		voiceCalls.get(0).ToPhoneNumber = 'CS_Test';
		insert voiceCalls;

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(testCase);
		CaseRelatedListPanelContExt ext = new CaseRelatedListPanelContExt(stdCtrl);
		ext.getNetworkResponseSize();

		System.assert(ext.voiceCalls.size() > 0);

		test.stoptest();
	}

	/**
	 * Scenario:
	 * Case has a safe drop image linked via event messages...
	 */
	public static testMethod void testCoverageTest() {
		// article to be assigned to the case
		List<Article__c> articles = TestDataProvider.createArticle('My Article', 1, null);
		articles[0].Name = '1234567890A';
		articles[0].ArticleID__c = '1234567890A';
		articles[0].recordTypeId = [Select Id from recordtype where Name='Consignment' and SObjectType='Article__c'].Id;
		insert articles[0];

		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
		testCase.ReferenceID__c = '1234567890A';
		testCase.Origin = 'Web';
		testCase.ArticleTest__c = articles[0].Id;
		insert testCase;

		EmailMessage[] newEmail = new EmailMessage[0];

		newEmail.add(new EmailMessage(FromAddress = 'test@test.com',
		FromName = 'test@test.com',
		ToAddress = 'test2@test.com',
		CcAddress = 'test3@test.com',
		Subject = 'Test',
		TextBody = 'Test',
		HtmlBody = 'test',
		ParentId =  testCase.Id));   // (newCase and newTask are the newly created case and task from earlier code)
		insert newEmail;

		Attachment newAttachment = new Attachment(ParentId = newEmail[0].Id,
											Name = 'filename',
											Body = Blob.valueof('email.binaryAttachments[i].'));
		insert newAttachment;

		QM__c qm = new QM__c(NetworkEmail__c='test@TestNW.com');
		insert qm;
		Test.startTest();

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(testCase);
			CaseRelatedListPanelContExt ext = new CaseRelatedListPanelContExt(stdCtrl);
			ext.reloadAttachments();
			//ext.initArticlesAndEventMessages(testCase.Id);
		Test.stopTest();
	}

	/**
	 * Scenario: Happy path when attaching a delivery proof to a case
	 */
	@IsTest
	private static void testAttachDeliveryProof_HappyPath_EndToEnd() {
		// =====================================
		// Data Preparation
		// =====================================

		String articleId = '1234567890A';

		// article to be assigned to the case
		List<Article__c> articles = TestDataProvider.createArticle('My Article', 1, null);
		articles[0].Name = articleId;
		articles[0].ArticleID__c = articleId;
		insert articles[0];

		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
		testCase.ReferenceID__c = articleId;
		testCase.Origin = 'Web';
		testCase.ArticleTest__c = articles[0].Id;
		insert testCase;

		// =====================================
		// Stubbing
		// =====================================
		Set<String> articlesSet = new Set<String>{articleId};
		Set<Id> caseIdsSet = new Set<Id>{testCase.Id};

		DeliveryProofService mockService = (DeliveryProofService)MockUtility.mockUtility(DeliveryProofService.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getDeliveryProofAvailable((Set<String>)fflib_Match.eq(articlesSet))).thenReturn(new Set<String>{articleId});
		((DeliveryProofService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).attachAPDeliveryProofPdf((Set<Id>)fflib_Match.eq(caseIdsSet));
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Object> output = CaseRelatedListPanelContExt.attachDeliveryProof(testCase.Id);

		Test.stopTest();

		System.assert(Boolean.valueOf(output.get('success')), 'The delivery proof was not attached successfully');

		((DeliveryProofService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getDeliveryProofAvailable((Set<String>)fflib_Match.eq(articlesSet));
		((DeliveryProofService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).attachAPDeliveryProofPdf((Set<Id>)fflib_Match.eq(caseIdsSet));

	}

	/**
	 * Scenario: Attemp to attach delivery proof where article does not include a signature/safedrop scan event
	 */
	@IsTest
	private static void testAttachDeliveryProof_ProofNotAvailableOnArticle_EndToEnd() {
		// =====================================
		// Data Preparation
		// =====================================

		String articleId = '1234567890A';

		// article to be assigned to the case
		List<Article__c> articles = TestDataProvider.createArticle('My Article', 1, null);
		articles[0].Name = articleId;
		articles[0].ArticleID__c = articleId;
		insert articles[0];

		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
		testCase.ReferenceID__c = articleId;
		testCase.Origin = 'Web';
		testCase.ArticleTest__c = articles[0].Id;
		insert testCase;

		// =====================================
		// Stubbing
		// =====================================
		Set<String> articlesSet = new Set<String>{articleId};

		DeliveryProofService mockService = (DeliveryProofService)MockUtility.mockUtility(DeliveryProofService.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockService.getDeliveryProofAvailable((Set<String>)fflib_Match.eq(articlesSet))).thenReturn(new Set<String>());
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Object> output = CaseRelatedListPanelContExt.attachDeliveryProof(testCase.Id);

		Test.stopTest();

		System.assertEquals(false, Boolean.valueOf(output.get('success')), 'Delivery proof should not be available on article');
		((DeliveryProofService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getDeliveryProofAvailable((Set<String>)fflib_Match.eq(articlesSet));

	}

	/**
	 * Scenario: Happy path when attaching a delivery proof to a case
	 */
	@IsTest
	private static void testAttachDeliveryProof_DeliveryProofAlreadyExists_EndToEnd() {
		// =====================================
		// Data Preparation
		// =====================================

		String articleId = '1234567890A';

		// article to be assigned to the case
		List<Article__c> articles = TestDataProvider.createArticle('My Article', 1, null);
		articles[0].Name = articleId;
		articles[0].ArticleID__c = articleId;
		insert articles[0];

		Case testCase = TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery');
		testCase.ReferenceID__c = articleId;
		testCase.Origin = 'Web';
		testCase.ArticleTest__c = articles[0].Id;
		insert testCase;

		Attachment att = new Attachment(ParentId = testCase.Id, Name = DeliveryProofService.DELIVERY_PROOF_CASE_FILENAME, Body = Blob.valueOf('Test'), IsPrivate = false);
		insert att;

		// =====================================
		// Stubbing
		// =====================================
		DeliveryProofService mockService = (DeliveryProofService)MockUtility.mockUtility(DeliveryProofService.class);


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Object> output = CaseRelatedListPanelContExt.attachDeliveryProof(testCase.Id);

		Test.stopTest();

		System.assertEquals(false, Boolean.valueOf(output.get('success')), 'The delivery proof should not have been attached');
		System.assert(String.valueOf(output.get('error')).contains('already exists'), 'The method should have returned an error that the attachment already exists. Instead it returned: ' + output.get('error'));

		((DeliveryProofService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(0))).getDeliveryProofAvailable((Set<String>)fflib_Match.anyObject());
		((DeliveryProofService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(0))).attachAPDeliveryProofPdf((Set<Id>)fflib_Match.anyObject());

	}
}