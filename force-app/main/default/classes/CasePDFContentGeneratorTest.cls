/**
* @author       : haraprasad.sahoo@auspost.com.au
* @date         : 26/05/2020
* @description  : Test class for MyNetworkCasePDFController(landing page) and CasePDFContentGenerator(redirect page)
* History
--------------------------------------------------
26/05/2020 - Hara Sahoo Created
12/08/2020 - Disha Kariya Updated for changes to use AME instead of google API
21/08/2020 - Disha Updated to use mocking
15/03/2021 - Naveen Rajanna -REQ2408232 Add code coverage for getCaseCount method
29/06/2021 - Ranjeewa Silva - Updated for changes to include event message attachments in the PDF.
01/10/2021 - Seth Heang - Uplift SF API Version to 52
*/
@isTest
private class CasePDFContentGeneratorTest {
    @testSetup
    static void testDataSetup() {
         // Create articles.
//        Article__c article1 = new Article__c(Name = 'a1');
//        Article__c article2 = new Article__c(Name = 'a2');
//        Article__c article3 = new Article__c(Name = 'a3');
//        Article__c article4 = new Article__c(Name = 'a4');
//        insert new Article__c[]{
//                article1, article2,article3,article4
//        };
//        RecordType articleRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Article__c', new Set<String>{'Article'}).values()[0];
//        RecordType consignmentRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('Article__c', new Set<String>{'Consignment'}).values()[0];
////        Id article_recordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName()
////                  .get('Article').getRecordTypeId();
////        Id consignment_recordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName()
////                  .get('Consignment').getRecordTypeId();
//         //Assign article ref id
//        article1.TrackingID__c = article2.Id;
//        article1.ArticleID__c = article1.Id;
//        article1.RecordTypeId=articleRecordType.Id;
//        update article1;
//
//        article2.Consignment__c = article3.Id;
//        article2.ArticleID__c = article2.Id;
//        article2.recordtypeId=consignmentRecordType.Id;
//        update article2;
//
//        article3.ArticleID__c = article3.Id;
//        update article3;
//
//        article4.Consignment__c = article3.Id;
//        article4.ArticleID__c = article4.Id;
//        update article4;
//
//        //Get attempted delivery code
//        Map<String, List<EventMessageTypeMapping__mdt>> eventMessageType = EventMessageUtil.getEventMessageTypesByCategory();
//
//        // Create event messages for articles. These messages will form articleDetails and consignmentDetails.
//        EventMessage__c event1 = new EventMessage__c(Article__c = article1.Id,EventType__c=eventMessageType.get('AttemptedDelivery')[0].Label,DriverContract__c='U8890',Safe_Drop_GUID__c='23123-35435-gf-454',EventGeoLocation__Latitude__s=13.0429,EventGeoLocation__Longitude__s=80.2739);
//        EventMessage__c event2 = new EventMessage__c(Article__c = article1.Id,EventType__c='DD-ER11',DriverContract__c='U8890',Safe_Drop_GUID__c='23123-35435-gf-454',EventGeoLocation__Latitude__s=13.0429,EventGeoLocation__Longitude__s=80.2739);
//        EventMessage__c event3 = new EventMessage__c(Article__c = article2.Id, EventType__c=eventMessageType.get('Delivered')[0].Label ,EventGeoLocation__Latitude__s=13.0429,EventGeoLocation__Longitude__s=80.273);
//        EventMessage__c event4 = new EventMessage__c(Article__c = article3.Id);
//
//        insert new EventMessage__c[]{
//                event1, event2, event3, event4
//        };

        AusPostSettings__c setting = new AusPostSettings__c();
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
    }
  
//    @isTest
//    static void testCasePDFContentGenerator()
//    {
        // Get sample articles
//        Article__c article1 = [SELECT Id, Name, ArticleID__c FROM Article__c WHERE Name = 'a1'];
//        Article__c article2 = [SELECT Id, Name, ArticleID__c FROM Article__c WHERE Name = 'a2'];

//        Contact contact = new Contact(
//                LastName = 'King',
//                FirstName = 'Inthenorth',
//                Phone = '12345'
//        );
//
//        insert contact;

        // Form dependent cases
//        Case case1 = new Case(
//                ContactId = contact.Id,
//                ReferenceID__c = article1.Id,
//                ArticleTest__c = article1.Id,
//                Address2__c = 'Test address'
//        );
//
//        insert case1;

//        Case case2 = new Case(
//                ContactId = contact.Id,
//                ParentId = case1.Id,
//                ArticleTest__c = article2.Id,
//                ReferenceID__c = article2.Id,
//                Address2__c = 'Test address'
//        );

//        insert case2;

//        case2 = [SELECT Id, ArticleTest__r.ArticleID__c FROM Case WHERE ParentId = :case1.Id];

        //Test for multiple cases, passed in the parameter string
//        List<String> caseList = new List<String>();
//        caseList.add(case1.Id);
//        caseList.add(case2.Id);
//        String result = String.join(caseList, ',' );
//        List<String> lstCaseIds = result.split(',');

        // Create wrappers to mock test data
//        TIBCOConsignmentWrapper consignmentDetails = new TIBCOConsignmentWrapper(null, null);
//
//        TIBCOArticleWrapper article1Wrapper = new TIBCOArticleWrapper(null);
//        article1Wrapper.selected = true;
//        article1Wrapper.proxyArticle = articles[0];
//
//        TIBCOArticleWrapper article2Wrapper = new TIBCOArticleWrapper(null);
//        article2Wrapper.selected = true;
//        article2Wrapper.proxyArticle = article2;
//
//        // Now the details.articles contains two article wrappers
//        consignmentDetails.articles = new TIBCOArticleWrapper[]{
//                article1Wrapper, article2Wrapper
//        };
//
//        Test.startTest();
//        Apexpages.currentpage().getparameters().put('selectedIds' , result);
        //Test the landing page controller
//        MyNetworkCasePDFController controller = new MyNetworkCasePDFController();
        //Test the redirect page controller
//        CasePDFContentGenerator redirectControlller = new CasePDFContentGenerator();
//        redirectControlller.updatePrintFlag();
//        Test.stopTest();

//    }

    /**
	 * Test:
	 *  Test for MyNetworkCasePDFController
	 */
    @IsTest
    private static void testMyNetworkCasePDFController() {

        // =====================================
        // Data Preparation
        // =====================================
        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
        EventMessage__c event = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
        event.Safe_Drop_GUID__c='23123-35435-gf-454';
        Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Contact contacts = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0];
        Case cases = ApplicationTestDataFactory.getCases(1, new List<Id>{contacts.Id}, true)[0];
        cases.ReferenceID__c = article.Id;
        cases.ArticleTest__c = article.Id;

        // =====================================
        // Stubbing
        // =====================================
        //SSSWCasesSelector mockCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
        EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{cases.Id => cases});
        MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>{event.Id => event});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        Apexpages.currentpage().getparameters().put('selectedIds' , cases.Id);
        //Test the landing page controller
        MyNetworkCasePDFController controller = new MyNetworkCasePDFController();

        Test.stopTest();
        System.assertNotEquals('', controller.eventMessagesWithAttachments, 'Safe drop GUID not added');
    }

    /**
	 * Test:
	 *  Test for getcasetoEventMessageMap
	 */
    @IsTest
    private static void testGetcasetoEventMessageMap() {

        // =====================================
        // Data Preparation
        // =====================================
        Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
        Map<String, List<EventMessageTypeMapping__mdt>> eventMessageType = EventMessageUtil.getEventMessageTypesByCategory();
        List<EventMessage__c> events = ApplicationTestDataFactory.getEventMessages(2, article.Id, true);
        events[0].EventType__c=eventMessageType.get('AttemptedDelivery')[0].Label;
        events[0].DriverContract__c='U8890';
        events[0].Safe_Drop_GUID__c='23123-35435-gf-454';
        events[0].EventGeoLocation__Latitude__s=13.0429;
        events[0].EventGeoLocation__Longitude__s=80.2739;
        events[1].EventType__c=eventMessageType.get('Delivered')[0].Label;
        events[1].DriverContract__c='U8890';
        events[1].Safe_Drop_GUID__c='23123-35435-gf-454';
        events[1].EventGeoLocation__Latitude__s=13.0429;
        events[1].EventGeoLocation__Longitude__s=80.2739;
        Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Contact contacts = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0];
        Case cases = ApplicationTestDataFactory.getCases(1, new List<Id>{contacts.Id}, true)[0];
        cases.ReferenceID__c = article.Id;
        cases.ArticleTest__c = article.Id;

        // =====================================
        // Stubbing
        // =====================================
        CasePDFContentGenerator mockService = (CasePDFContentGenerator)MockUtility.mockUtility(CasePDFContentGenerator.class);
        EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.caseArticleIds).thenReturn(new Set<Id>{article.Id});
        MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleId((Set<Id>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>{events[0].Id => events[0], events[1].Id => events[1]});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.WebServiceMockResponseGeo());
        Apexpages.currentpage().getparameters().put('selectedIds' , cases.Id);
        //Test the landing page controller
        CasePDFContentGenerator controller = new CasePDFContentGenerator();
        Map<String,EventMessage__c> eventMap = controller.getcasetoEventMessageMap();
        Map<String,String> addressMap = controller.getcaseToDeliveredAddressMap();

        Test.stopTest();
        System.assertNotEquals(0, eventMap.size(), 'EventMessages not found');
        System.assertNotEquals(0, addressMap.size(), 'Address not found from AME');
    }

    @isTest
    static void testupdatePrintFlagIntegration()
    {
        // =====================================
        // Data Preparation
        // =====================================
        Article__c article2 = ApplicationTestDataFactory.getConsignments(1, false)[0];
        insert article2;
        article2.ArticleID__c = article2.Id;
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(3, article2.Id, false);
        insert articles;

        //Create Account
        Account testAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
        testAccount.name = 'Social Account';
        insert testAccount;

        //Create Contact
        Contact contacts = ApplicationTestDataFactory.getContacts(1, testAccount.Id, false)[0];
        insert contacts;

        RecordType rt = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'SSSWGeneralEnquiry'}).values()[0];

        //Create Cases
        List<Case> cases = ApplicationTestDataFactory.getCases(2, new List<Id>{contacts.Id, contacts.Id}, false);
        cases[0].ReferenceID__c = articles[0].Id;
        cases[0].ArticleTest__c = articles[0].Id;
        cases[0].Address2__c = 'TestAddress';
        cases[0].RecordTypeId = rt.Id;
        cases[0].Type = 'General Enquiry';
        cases[1].ReferenceID__c = article2.Id;
        cases[1].ArticleTest__c = article2.Id;
        cases[1].Address2__c = 'TestAddress';
        cases[1].RecordTypeId = rt.Id;
        cases[1].Type = 'General Enquiry';
        insert cases;

        // =====================================
        // Testing
        // =====================================
        //Test for multiple cases, passed in the parameter string
        List<String> caseList = new List<String>();
        caseList.add(cases[0].Id);
        caseList.add(cases[1].Id);
        String result = String.join(caseList, ',' );

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.WebServiceMockResponseGeo());
        System.debug('result--->'+result);
        Apexpages.currentpage().getparameters().put('selectedIds' , result);
        CasePDFContentGenerator redirectControlller = new CasePDFContentGenerator();
        redirectControlller.updatePrintFlag();
        Test.stopTest();

        cases = [SELECT Id, Checkbox__c FROM Case WHERE Id in :caseList];
        System.assertEquals(true, cases[0].Checkbox__c, 'Print flag not marked true');
        System.assertEquals(caseList.size(), redirectControlller.getCaseCount(), 'Case count is not matching');
    }

    @IsTest
    private static void testGetCaseArticleToEventMessageAttachmentsMap() {

        // =====================================
        // Data Preparation
        // =====================================
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, true);
        Map<String, List<EventMessageTypeMapping__mdt>> eventMessageType = EventMessageUtil.getEventMessageTypesByCategory();
        List<Attachment> attachments = ApplicationTestDataFactory.getAttachments(5, null, true);

        // article one has 4 event messages. each with an attachment.
        // articleOneEventMessages[0] has a SAFE_DROP_PICTURE
        // articleOneEventMessages[1] has a CARDED_PICTURE
        // articleOneEventMessages[2] has some attachment type not recognised for case printout
        // articleOneEventMessages[3] has a DAMAGED_PICTURE

        List<EventMessage__c> articleOneEventMessages = ApplicationTestDataFactory.getEventMessages(4, articles[0].Id, true);
        articleOneEventMessages[0].EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
        articleOneEventMessages[0].Safe_Drop_GUID__c = '99999-2c7f-42bc-90e4-999999999999';
        articleOneEventMessages[0].AttachmentGUID__c = '99999-2c7f-42bc-90e4-999999999999';
        articleOneEventMessages[0].AttachmentType__c = 'SAFE_DROP_PICTURE';

        attachments[0].Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
        attachments[0].Body = null;
        articleOneEventMessages[0] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(articleOneEventMessages[0], new Map<String, Object>{'Attachments' => new Map<String, Object>{'totalSize' => 1, 'done' => true,'records' => new List<Attachment>{attachments[0]}}});

        articleOneEventMessages[1].EventType__c=eventMessageType.get('AttemptedDelivery')[0].Label;
        articleOneEventMessages[1].AttachmentGUID__c='99999-2c7f-42bc-90e4-111111111111';
        articleOneEventMessages[1].AttachmentType__c='CARDED_PICTURE';

        attachments[1].Name = EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX + articleOneEventMessages[1].AttachmentGUID__c;
        attachments[1].Body = null;
        articleOneEventMessages[1] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(articleOneEventMessages[1], new Map<String, Object>{'Attachments' => new Map<String, Object>{'totalSize' => 1, 'done' => true,'records' => new List<Attachment>{attachments[1]}}});

        articleOneEventMessages[2].EventType__c=eventMessageType.get('AttemptedDelivery')[0].Label;
        articleOneEventMessages[2].AttachmentGUID__c='99999-2c7f-42bc-90e4-222222222222';
        articleOneEventMessages[2].AttachmentType__c='UNKNOWN_TYPE';

        attachments[2].Name = EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX + articleOneEventMessages[2].AttachmentGUID__c;
        attachments[2].Body = null;
        articleOneEventMessages[2] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(articleOneEventMessages[2], new Map<String, Object>{'Attachments' => new Map<String, Object>{'totalSize' => 1, 'done' => true,'records' => new List<Attachment>{attachments[2]}}});

        articleOneEventMessages[3].EventType__c=eventMessageType.get('AttemptedDelivery')[0].Label;
        articleOneEventMessages[3].AttachmentGUID__c='99999-2c7f-42bc-90e4-333333333333';
        articleOneEventMessages[3].AttachmentType__c='DAMAGED_PICTURE';

        attachments[3].Name = EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX + articleOneEventMessages[3].AttachmentGUID__c;
        attachments[3].Body = null;
        articleOneEventMessages[3] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(articleOneEventMessages[3], new Map<String, Object>{'Attachments' => new Map<String, Object>{'totalSize' => 1, 'done' => true,'records' => new List<Attachment>{attachments[3]}}});

        List<EventMessage__c> articleTwoEventMessages = ApplicationTestDataFactory.getEventMessages(1, articles[1].Id, true);
        articleTwoEventMessages[0].EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
        articleTwoEventMessages[0].Safe_Drop_GUID__c = '99999-2c7f-42bc-90e4-444444444444';
        articleTwoEventMessages[0].AttachmentGUID__c = '99999-2c7f-42bc-90e4-444444444444';
        articleTwoEventMessages[0].AttachmentType__c = 'SAFE_DROP_PICTURE';

        attachments[4].Name = SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME;
        attachments[4].Body = null;
        articleTwoEventMessages[0] = (EventMessage__c) ApplicationTestDataFactory.setUnwritableFields(articleTwoEventMessages[0], new Map<String, Object>{'Attachments' => new Map<String, Object>{'totalSize' => 1, 'done' => true,'records' => new List<Attachment>{attachments[4]}}});

        List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
        cases[0].ReferenceID__c = articles[0].Id;
        cases[0].ArticleTest__c = articles[0].Id;
        cases[1].ReferenceID__c = articles[1].Id;
        cases[1].ArticleTest__c = articles[1].Id;

        // =====================================
        // Stubbing
        // =====================================
        EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);

        MockUtility.Mocks.startStubbing();
        List<EventMessage__c> eventMessages = new List<EventMessage__c>(articleOneEventMessages);
        eventMessages.addAll(articleTwoEventMessages);
        MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>(eventMessages));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.WebServiceMockResponseGeo());
        Apexpages.currentpage().getparameters().put('selectedIds' , cases[0].Id + ',' + cases[1].Id);
        //Test the landing page controller
        CasePDFContentGenerator controller = new CasePDFContentGenerator();
        Map<String, CasePDFContentGenerator.ArticleEventMessageAttachments> attachmentsMap = controller.getCaseArticleToEventMessageAttachmentsMap();

        Test.stopTest();

        System.assertEquals(1, attachmentsMap.size(), 'Only articles with event message attachments to be included in Case PDF should be returned.');
        System.assert(attachmentsMap.keySet().contains(articles[0].Id), 'Article with CARDED_PICTURE and DAMAGED_PICTURE not returned.');

        CasePDFContentGenerator.ArticleEventMessageAttachments emAttachmentsForCasePrintOut = attachmentsMap.get(articles[0].Id);
        System.assertEquals(2, emAttachmentsForCasePrintOut.attachments.size(), 'Expected CARDED_PICTURE and DAMAGED_PICTURE attachments for the article.');
        for (CasePDFContentGenerator.EventMessageAttachment emAttachmentForCasePrintOut: emAttachmentsForCasePrintOut.attachments) {
            System.assert(emAttachmentForCasePrintOut.name.startsWith(EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX), 'Only non-safedrop event message attachments expected.');
        }
    }

	/**
	 * @test: Test case investigations are printed when case investigations record Ids are passed.
	 * @scenario: Simulating selection of Case Investigations records to print. Records are selected on mynetwork portal.  
	 */
	@IsTest
	private static void testCasePDFContentGenerator_starTrackCaseInvestigations() {

		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = ApplicationTestDataFactory.getArticles(1, true)[0];
		EventMessage__c event = ApplicationTestDataFactory.getEventMessages(1, article.Id, true)[0];
		event.Safe_Drop_GUID__c='23123-35435-gf-454';
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact contacts = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0];
		Case cases = ApplicationTestDataFactory.getCases(1, new List<Id>{contacts.Id}, true)[0];
		cases.ReferenceID__c = article.Id;
		cases.ArticleTest__c = article.Id;

		article.Name = '12345';
		article.ArticleID__c = '12345';
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseinvestigations(3, cases.Id, article, null, true);


		// =====================================
		// Stubbing
		// =====================================
		//SSSWCasesSelector mockCasesSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		EventMessagesSelector mockEventMessagesSelector = (EventMessagesSelector)MockUtility.mockSelector(EventMessagesSelector.class);
		CaseInvestigationsSelector mockCaseInvestigationsSelector = (CaseInvestigationsSelector)MockUtility.mockSelector(CaseInvestigationsSelector.class);

		TIBCOArticleService mockUtil = (TIBCOArticleService) MockUtility.mockUtility(TIBCOArticleService.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockCasesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Case>{cases.Id => cases});
		MockUtility.Mocks.when(mockEventMessagesSelector.selectByArticleId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, EventMessage__c>{event.Id => event});
		MockUtility.Mocks.when(mockCaseInvestigationsSelector.selectById(new Set<Id>{caseInvestigations[0].Id, caseInvestigations[1].Id}, 
																			new Set<Object>{CaseInvestigationsSelector.Options.WITH_ARTICLES, 
																				CaseInvestigationsSelector.Options.WITH_OWNER_DETAILS, 
																				CaseInvestigationsSelector.Options.WITH_NETWORKS, 
																				CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, 
																				CaseInvestigationsSelector.Options.WITH_FEEDS, 
																				FeedItemsSelector.Options.TEXTPOST_ONLY}))
			.thenReturn(new Map<Id, CaseInvestigation__c>{caseInvestigations[0].Id => caseInvestigations[0],
														caseInvestigations[1].Id => caseInvestigations[1]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		String recordIds = cases.Id + ','+caseInvestigations[0].Id + ','+caseInvestigations[1].Id;
		Apexpages.currentpage().getparameters().put('selectedIds' , recordIds);
		CasePDFContentGenerator controller = new CasePDFContentGenerator();

		Test.stopTest();

		List<CaseInvestigation__c> stCaseInvestigations = controller.starTrackCaseToCaseInvestigationsMap.get(cases.Id);
		
		system.assert(stCaseInvestigations.contains(caseInvestigations[0]), 'Case Investigation record should have been included in a map');
		system.assert(!stCaseInvestigations.contains(caseInvestigations[2]), 'Case Investigation record should have NOT been included in a map');
		
		//verify that CaseInvestigationsSelector is called 
		((CaseInvestigationsSelector)MockUtility.Mocks.verify(mockCaseInvestigationsSelector, MockUtility.Mocks.times(1)))
														.selectById(new Set<Id>{caseInvestigations[0].Id, caseInvestigations[1].Id}, 
																									new Set<Object>{CaseInvestigationsSelector.Options.WITH_ARTICLES, 
																										CaseInvestigationsSelector.Options.WITH_OWNER_DETAILS, 
																										CaseInvestigationsSelector.Options.WITH_NETWORKS, 
																										CaseInvestigationsSelector.Options.WITH_CASE_DETAILS, 
																										CaseInvestigationsSelector.Options.WITH_FEEDS, 
																										FeedItemsSelector.Options.TEXTPOST_ONLY});
	}

}