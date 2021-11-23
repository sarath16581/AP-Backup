/****************************************************************************************
Description: Test class to cover EmailTemplateDISCompCont
Author:      heguang.miao@coroma.com.au
History:
-----------------------------------------------------------------------------------------
28-06-2018  heguang.miao@coroma.com.au  [TDO-81] Rewrote tests based on scenarios
05-06-2020  heguang.miao@coroma.com.au  Made removeUnselectedArticles public
*****************************************************************************************/

@isTest
private class EmailTemplateCompContTest {

    @testSetup
    static void testDataSetup() {

        // Create articles.
        Article__c article1 = new Article__c(Name = 'a1');
        Article__c article2 = new Article__c(Name = 'a2');
        Article__c article3 = new Article__c(Name = 'a3');
        Article__c article4 = new Article__c(Name = 'a4');

        insert new Article__c[]{
                article1, article2, article3, article4
        };

        // For convenience, each article's article Id points to itself.
        article1.TrackingID__c = article2.Id;
        article1.ArticleID__c = article1.Id;
        update article1;

        article2.Consignment__c = article3.Id;
        article2.ArticleID__c = article2.Id;
        update article2;

        article3.ArticleID__c = article3.Id;
        update article3;

        article4.Consignment__c = article3.Id;
        article4.ArticleID__c = article4.Id;
        update article4;

        // Create event messages for articles. These messages will form articleDetails and consignmentDetails.
        EventMessage__c event1 = new EventMessage__c(Article__c = article1.Id);
        EventMessage__c event2 = new EventMessage__c(Article__c = article1.Id);
        EventMessage__c event3 = new EventMessage__c(Article__c = article2.Id);
        EventMessage__c event4 = new EventMessage__c(Article__c = article3.Id);

        insert new EventMessage__c[]{
                event1, event2, event3, event4
        };
    }

    /**
     * SCENARIO: assign a case Id to the controller
     */
    @isTest
    static void EmailTemplateDISCompCont_caseIdAssignment() {
        Article__c article2 = [SELECT Id, Name FROM Article__c WHERE Name = 'a2'];
        Article__c article3 = [SELECT Id, Name FROM Article__c WHERE Name = 'a3'];

        Contact contact = new Contact(
                LastName = 'King',
                FirstName = 'Inthenorth',
                Phone = '12345'
        );

        insert contact;

        // Create cases and assign article ids to their reference ids
        Case case1 = new Case(
                ContactId = contact.Id,
                ReferenceID__c = article2.Id
        );

        insert case1;


        Case case2 = new Case(
                ContactId = contact.Id,
                ReferenceID__c = article3.Id
        );

        insert case2;

        Test.startTest();
        // Create a controller
        // this.caseId will be called inside the constructor
        ApexPages.StandardController objController = new ApexPages.StandardController(case1);
        EmailTemplateDISCompCont controller = new EmailTemplateDISCompCont(objController);

        Test.stopTest();

        System.assert(null != controller.myCase,
                'EmailTemplateDISCompCont_caseIdAssignment : case should be selected');

        System.assert(null != controller.myContact,
                'EmailTemplateDISCompCont_caseIdAssignment : contact should be found');

        System.assert(null != controller.articleDetails,
                'EmailTemplateDISCompCont_caseIdAssignment : for this case, article details should have content');

    }

    /**
     * SCENARIO: removeUnselectedArticles being called
     */
    @isTest
    public static void EmailTemplateDISCompCont_removeUnselectedArticles() {

        // Get sample articles
        Article__c article1 = [SELECT Id, Name, ArticleID__c FROM Article__c WHERE Name = 'a1'];
        Article__c article2 = [SELECT Id, Name, ArticleID__c FROM Article__c WHERE Name = 'a2'];

        Contact contact = new Contact(
                LastName = 'King',
                FirstName = 'Inthenorth',
                Phone = '12345'
        );

        insert contact;

        // Form dependent cases
        Case case1 = new Case(
                ContactId = contact.Id
        );

        insert case1;

        Case case2 = new Case(
                ContactId = contact.Id,
                ParentId = case1.Id,
                ArticleTest__c = article1.Id
        );

        insert case2;

        case2 = [SELECT Id, ArticleTest__r.ArticleID__c FROM Case WHERE ParentId = :case1.Id];

        // Create wrappers to mock test data
        TIBCOConsignmentWrapper consignmentDetails = new TIBCOConsignmentWrapper(null, null);

        TIBCOArticleWrapper article1Wrapper = new TIBCOArticleWrapper(null);
        article1Wrapper.selected = true;
        article1Wrapper.proxyArticle = article1;

        TIBCOArticleWrapper article2Wrapper = new TIBCOArticleWrapper(null);
        article2Wrapper.selected = true;
        article2Wrapper.proxyArticle = article2;

        // Now the details.articles contains two article wrappers, but one should be removed
        consignmentDetails.articles = new TIBCOArticleWrapper[]{
                article1Wrapper, article2Wrapper
        };

        Test.startTest();

        EmailTemplateDISCompCont controller = new EmailTemplateDISCompCont();
        EmailTemplateDISCompCont.removeUnselectedArticles(consignmentDetails, case1.Id);

        Test.stopTest();

        // Only one article remains
        System.assertEquals(1, consignmentDetails.articles.size(),
                'EmailTemplateDISCompCont_removeUnselectedArticles : if the article Id is not included in the child case, ' +
                        'it should be removed');
    }

    /**
     * SCENARIO: getItemSearchArticleFields being called
     */
    @isTest
    static void EmailTemplateDISCompCont_getItemSearchArticleFields() {
        EmailTemplateDISCompCont controller = new EmailTemplateDISCompCont();

        Test.startTest();

        // A helper method to get all fields of the Article object
        List<Schema.FieldSetMember> fields = controller.getItemSearchArticleFields();

        Test.stopTest();

        System.assert(fields.size() > 0, 'EmailTemplateDISCompCont_getItemSearchArticleFields : all fields of Article should be picked');
    }

    /**
     * SCENARIO: getItemSearchEventMessagesFields being called
     */
    @isTest
    static void EmailTemplateDISCompCont_getItemSearchEventMessagesFields() {
        EmailTemplateDISCompCont controller = new EmailTemplateDISCompCont();

        Test.startTest();

        // A helper method to get all fields of the EventMessage object
        List<Schema.FieldSetMember> fields = controller.getItemSearchEventMessagesFields();

        Test.stopTest();

        System.assert(fields.size() > 0, 'EmailTemplateDISCompCont_getItemSearchEventMessagesFields : all fields of EventMessage ' +
                'should be picked');
    }
}