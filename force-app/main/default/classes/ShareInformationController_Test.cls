/**
  * @author       :
  * @date         :
  * @description  : Class created to cover the controller ShareInformationController, as it had no
  *                 test class when it was originally created or subsequently updated.
--------------------------------------- History --------------------------------------------------
Dion Gunn   04.01.2017  Created for INC0867295
Dilshan Egodawela	08.09.2017 added testSendInvite method
**/
@isTest
public class ShareInformationController_Test {

    //Method to create Test Data
    @testSetup static void createTestData() {
        Account OrgAccount = TestDataProvider.createBusinessAccount('Testname', 'Organisation');
        OrgAccount.Root_Id__c = '12345';
        insert OrgAccount;

        RecordType pAccountRtype = [select Id from RecordType where sobjectType = 'Account' and IsPersonType = True limit 1];

        Account personAccount1 = new Account();
        personAccount1.FirstName = 'Test';
        personAccount1.LastName = 'Person1';
        personAccount1.PersonEmail = 'test@example.com';
        personAccount1.RecordType = pAccountRtype;
        personAccount1.Phone = '123456789';
        insert personAccount1;

        Account personAccount2 = new Account();
        personAccount2.FirstName = 'Test';
        personAccount2.LastName = 'Person2';
        personAccount2.RecordType = pAccountRtype;
        personAccount2.PersonEmail = 'test2@example.com';
        personAccount2.Phone = '987654321';
        insert personAccount2;

        Article__c art = new Article__c();
        art.Name = '726';
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        insert art;

        PushEDM_Domain__c pd = new PushEDM_Domain__c();
        pd.Force_Com_URL__c = 'http://ap1.content.force.com/';
        pd.Site_URL__c = 'http://auspost.force.com/PKB';
        pd.Supported_Article_Types__c = 'FAQ;Push_EDM';
        insert pd;

        QM__c qm = new QM__c();
        qm.CusEmail__c = 'test@example.com';
        insert qm;
    }

    public static void setPageReference(Id recordId) {
        PageReference prAccount = new PageReference('/apex/ShareInformation?id=' + recordId);
        Test.setCurrentPageReference(prAccount);
    }

    public static testMethod void testConstructor() {
        //Test with Account
        Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
        Contact pAccountContact = [select id from contact where AccountId =: pAccount1.Id];
        setPageReference(pAccount1.Id);
        ShareInformationController sic1 = new ShareInformationController();
        System.assertEquals(pAccountContact.Id,sic1.aContact.Id);

        //Test with Contact
        setPageReference(pAccountContact.Id);
        ShareInformationController sic2 = new ShareInformationController();
        System.assertEquals(pAccountContact.Id,sic2.aContact.Id);
    }

    public static testMethod void testSaveMarketingOptions() {
        //Calling the save marketing options method, which just updates.
        Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
        setPageReference(pAccount1.Id);
        ShareInformationController sic = new ShareInformationController();
        sic.SaveMarketingOptions();
    }

    public static testMethod void testClearSearchAndSearchArticles() {
        Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
        setPageReference(pAccount1.Id);
        ShareInformationController sic = new ShareInformationController();
        sic.searchKeyword = 'Here is my keyword';
        sic.displayResult = true;
        sic.clearSearch();
        System.assertEquals('',sic.searchKeyword);
        System.assertEquals(false,sic.displayResult);

        sic.displayResult = false;
        sic.searchArticles();
        System.assertEquals(true, sic.displayResult);
    }

    public static testMethod void testPopulateEmailTemplate() {
        Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
        setPageReference(pAccount1.Id);
        ShareInformationController sic = new ShareInformationController();
        System.assertEquals(null,sic.template);
        sic.populateEmailTempalte();
        System.assertNotEquals(null,sic.template);
        System.assert(!sic.template.contains('Error: Unable to generate the template because'));
    }

    public static testMethod void testArticleHandling() {
        Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
        setPageReference(pAccount1.Id);
        ShareInformationController sic = new ShareInformationController();

        sic.articleBody = 'articleBody';
        Article__c art =  [Select Id from Article__c where name = '726'];
        sic.articleId = art.Id;
        sic.addToArticleBody();
        System.assertEquals(1,sic.articleBodys.size());
        System.assertEquals(1,sic.articleIds.size());
        sic.articlePosition = 0;
        sic.moveToArticleBody();
        sic.removeFromArticleBody();
        System.assertEquals(0,sic.articleBodys.size());
        System.assertEquals(0,sic.articleIds.size());
    }

    public static testMethod void testSendEmail() {
        Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
        setPageReference(pAccount1.Id);
        ShareInformationController sic = new ShareInformationController();
        sic.sendEmail();
    }
    
    public static testMethod void testSendInvite() {
        Account pAccount1 = [Select Id,PersonContactId from Account where LastName = 'Person1'];
        setPageReference(pAccount1.Id);
        insert new AusPostSettings__c(Name = 'Customer Invitations', Username__c = 'Username', Password__c = 'Password',URL__c = 'https://ptest.npe.auspost.com.au/mypost/dashboard/#/home');
        insert new CIProducts__c(Name = 'Home Dashboard',Order__c=1, Product__c = 'Product', ProductType__c = 'product type',RegistrationNextURL__c = 'https://ptest.npe.auspost.com.au/mypost/dashboard/#/home');
        //Test.setMock(HttpCalloutMock.class, new POBSearchHttpCalloutMock());
        Test.startTest();
        ShareInformationController con = new ShareInformationController();
        con.getProdTypes();
        con.getProds();
        Test.setMock(HttpCalloutMock.class, new SendCustomerNotificationHttpCalloutMock());
        String result = ShareInformationController.sendNotification('https://ptest.npe.auspost.com.au/mypost/dashboard/#/home', pAccount1.PersonContactId);
        System.assertEquals(Label.InviteSent, result);
        Test.stopTest();
    }

    public static testMethod void testDataCategoryArticleNode() {
        Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
        setPageReference(pAccount1.Id);
        ShareInformationController sic = new ShareInformationController();
        Push_EDM__kav articleTest = new Push_EDM__kav(
                Title = 'test apex',
                Summary = 'test from apex',
                Answer__c = 'test',
                //Question__c = 'test',
                //Category__c = 'test',
                URLName = 'testURL' + system.now().getTime()
        );

        insert articleTest;
        //using object because all objects have the same properties
        KnowledgeArticleVersion kav = [SELECT KnowledgeArticleId FROM KnowledgeArticleVersion WHERE Id = :(Id) articleTest.get('id')];
        KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);
        ShareInformationController.DataCategoryArticleNode sData = new ShareInformationController.DataCategoryArticleNode((sObject)articleTest);
        System.debug(sData.childCategories);
        System.debug(sData.articles);
        System.debug(sic.rootData);
        //System.debug(sic.categorisedArticles);
    }
}