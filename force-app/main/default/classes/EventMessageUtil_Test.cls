/**************************************************
Description:    This test class is for EventMessageUtil.
History:
--------------------------------------------------
2014-06-23  Frank Chen  Created
2019-03-18  gunith.devasurendra@auspost.com.au  Added additional tests to disable routing to event types CE-TR01, CE-TR02, CE-EN01, CE-EN02
2019-09-19  gunith.devasurendra@auspost.com.au  Getting event codes from Custom settings
2020-04-10  nathan.franklin@auspost.com.au  Adding tests for new EventMessageTypeMapping__mdt methods
2021-06-30 - Ranjeewa Silva - Adding tests for retrieving EventMessageAttachmentTypeMapping__mdt and attaching images to event messages.
2021-10-10 - Nathan Franklin - Updating create signature test classes
**************************************************/
@isTest
private class EventMessageUtil_Test {

    @testSetup
    static void setup(){
        insert new SSSWNonRoutingEventCodes__c(Codes__c='CE-TR01,CE-TR02,CE-EN01,CE-EN02,NSS-ER42');
    }

    static testMethod void myUnitTest() {
        Contact con = TestDataProvider.createTestContact();
        insert con;

        EventMessageTypes__c newType = new EventMessageTypes__c(Name = 'DD-ER13', SignatureAttachmentOnCase__c = true);
        insert newType;

        Article__c art = createArticle();

        Case case1 = createCase(con, art);

        EventMessage__c em = new EventMessage__c();
        em.Article__c = art.Id;
        em.SenderID__c = 'bg';
        em.ActualDateTime__c = date.today() + 1;
        em.EventType__c = 'DD-ER13';
        em.SignatureXString__c = '1';
        insert em;

        list<EventMessage__c> events = new list<EventMessage__c>();
        events.add(em);

        List<Case> list_case = new List<Case>();
        list_case.add(case1);

        Map<Id, List<Case>> articleToCases = new Map<Id, List<Case>>();
        articleToCases.put(art.Id,list_case);

        Test.startTest();

        EventMessageUtil.updateCases(events);
        EventMessageUtil.createSignatureAttachments(events);
        EventMessageUtil.createSignatureAttachments(events, articleToCases);
        EventMessageUtil.linkToNetworkFacility(events);

        system.assert(true);

        Case case1After = [SELECT SystemUpdate__c FROM Case WHERE Id = :case1.Id];
        System.assertEquals(case1After.SystemUpdate__c, 'Tracking Update');

        Test.stopTest();
    }

    private static Case createCase(Contact con, Article__c art) {
        RecordType rt;

        for (RecordType ret : [select Id, Name, DeveloperName from RecordType where sobjecttype = 'case' and DeveloperName LIKE 'StarTrack%']) {
            if (!ret.DeveloperName.contains('SSSW')) {
                rt = ret;
                break;
            }
        }

        Case case1 = new Case();
        case1.ContactId = con.Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Network Responded';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ArticleTest__c = art.Id;
        if (rt != null) case1.RecordTypeId = rt.Id;
        insert case1;
        return case1;
    }

    private static Article__c createArticle() {
        Article__c art = new Article__c();
        art.Name = '123';
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        insert art;
        return art;
    }

    static testMethod void selectedEventTypesDoesNotRouteCases() {
        Contact con = TestDataProvider.createTestContact();
        insert con;

        Article__c art = createArticle();
        Case eventCase = createCase(con, art);

        Set<String> nonRoutingEventCodes = new Set<String>{'CE-TR01', 'CE-TR02', 'CE-EN01', 'CE-EN02', 'NSS-ER42'};
        List<EventMessage__c> events = new List<EventMessage__c>();

        for (String nonRoutingEventCode : nonRoutingEventCodes) {
            EventMessage__c em = new EventMessage__c();
            em.Article__c = art.Id;
            em.SenderID__c = 'bg';
            em.ActualDateTime__c = Date.today() + 1;
            em.EventType__c = nonRoutingEventCode;
            em.SignatureXString__c = '1';
            insert em;

            events.add(em);
        }

        List<Case> cases = new List<Case>();
        cases.add(eventCase);

        Map<Id, List<Case>> articleToCases = new Map<Id, List<Case>>();
        articleToCases.put(art.Id, cases);

        EventMessageUtil.updateCases(events);

        Case case1After  = [SELECT SystemUpdate__c FROM Case WHERE Id = :eventCase.Id];
        System.assertEquals(case1After.SystemUpdate__c, null);
    }

    /**
     * Scenario: Simple test to grab all the event types using the new methods
     */
    @IsTest
    private static void testGetEventTypes() {
        // a bit risky using hard-coded items here, but I suspect we won't have any problems
        List<EventMessageTypeMapping__mdt> events = EventMessageUtil.getEventMessageTypesByCategory('Delivered');
        System.assertNotEquals(0, events.size());

        EventMessageTypeMapping__mdt event = EventMessageUtil.getEventMessageType('DD-ER13');
        System.assertNotEquals(null, event);
    }

    /**
    * Scenario: Simple test to grab all the event message attachment types
    */
    @IsTest
    private static void testGetEventMessageAttachmentTypes() {
        Map<String, EventMessageAttachmentTypeMapping__mdt> attachmentTypes = EventMessageUtil.getEventMessageAttachmentTypes();
        System.assertNotEquals(0, attachmentTypes.size(), 'Ensure configured event message attachment type metadata is returned.');
    }

    /**
    * Scenario: Simple test to grab all the event message attachment types
    */
    @IsTest
    private static void testAttachArticleImages() {

        Article__c article = createArticle();

        EventMessage__c eventMessageWithSafedrop = new EventMessage__c();
        eventMessageWithSafedrop.Article__c = article.Id;
        eventMessageWithSafedrop.SenderID__c = 'bg';
        eventMessageWithSafedrop.ActualDateTime__c = date.today() + 1;
        eventMessageWithSafedrop.EventType__c = 'DD-ER13';
        eventMessageWithSafedrop.Safe_Drop_GUID__c = '111111-2222222';
        eventMessageWithSafedrop.AttachmentGUID__c = '111111-2222222';
        eventMessageWithSafedrop.AttachmentType__c = new List<String>(SafeDropUtility.getSafeDropAttachmentTypes())[0];

        EventMessage__c eventMessageWithAttachmentGUID = new EventMessage__c();
        eventMessageWithAttachmentGUID.Article__c = article.Id;
        eventMessageWithAttachmentGUID.SenderID__c = 'bg';
        eventMessageWithAttachmentGUID.ActualDateTime__c = date.today() + 1;
        eventMessageWithAttachmentGUID.EventType__c = 'DD-ER13';
        eventMessageWithAttachmentGUID.AttachmentGUID__c = '2222222-3333333333';
        eventMessageWithAttachmentGUID.AttachmentType__c = 'CARDED_PICTURE';

        insert new List<EventMessage__c>{eventMessageWithSafedrop, eventMessageWithAttachmentGUID};

        Test.startTest();

        EventMessageUtil.attachArticleImage(eventMessageWithSafedrop.Id, EncodingUtil.base64Decode('test'), eventMessageWithSafedrop.Safe_Drop_GUID__c, true);
        EventMessageUtil.attachArticleImage(eventMessageWithAttachmentGUID.Id, EncodingUtil.base64Decode('test2'), eventMessageWithAttachmentGUID.AttachmentGUID__c, false);

        Test.stopTest();

        Map<Id, EventMessage__c> eventMessagesWithAttachments = EventMessagesSelector.newInstance().selectById(new Set<Id>{eventMessageWithSafedrop.Id, eventMessageWithAttachmentGUID.Id}, new Set<Object>{EventMessagesSelector.Options.WITH_ATTACHMENT});

        System.assertEquals(1, eventMessagesWithAttachments.get(eventMessageWithSafedrop.Id).Attachments.size(), 'Expected the safedrop image to be created as an attachment on event message');
        System.assertEquals(SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME, eventMessagesWithAttachments.get(eventMessageWithSafedrop.Id).Attachments[0].Name, 'Expected the safedrop image to be created as an attachment on event message');

        System.assertEquals(1, eventMessagesWithAttachments.get(eventMessageWithAttachmentGUID.Id).Attachments.size(), 'Expected the event message image to be created as an attachment on event message');
        System.assertEquals(EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX + '-' + eventMessageWithAttachmentGUID.AttachmentGUID__c + '.jpg', eventMessagesWithAttachments.get(eventMessageWithAttachmentGUID.Id).Attachments[0].Name, 'Expected event message attachment to be named ' + EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX + '<AttachmentGUID>');
    }

}