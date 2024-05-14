/**
  * @author   :
  * @date :
  * @description  : Class created to cover the controller ShareInformationController, as it had no
  * test class 		when it was originally created or subsequently updated.
--------------------------------------- History --------------------------------------------------
Dion Gunn   04.01.2017  Created for INC0867295
Dilshan Egodawela	08.09.2017 added testSendInvite method
**/
@isTest
public class ShareInformationController_Test {

	//Method to create Test Data
	@testSetup static void createTestData() {
		Account orgAccount = TestDataProvider.createBusinessAccount('Testname', 'Organisation');
		orgAccount.Root_Id__c = '12345';
		insert orgAccount;

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
	@isTest
	public static void testConstructor() {
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
	@isTest
	public static void testSaveMarketingOptions() {
		//Calling the save marketing options method, which just updates.
		Account pAccount1 = [Select Id, Legal_Marketing_Opt_In__pc from Account where LastName = 'Person1'];
		setPageReference(pAccount1.Id);
		ShareInformationController sic = new ShareInformationController();
		sic.currentContact.Legal_Marketing_Opt_In__c = true;
		sic.SaveMarketingOptions();		
		Boolean marketingOptIn = [Select Legal_Marketing_Opt_In__pc from Account where Id =: pAccount1.Id].Legal_Marketing_Opt_In__pc;
		System.assertEquals(true, marketingOptIn, 'Legal_Marketing_Opt_In__c field updated');
	}
	@isTest
	public static void testClearSearchAndSearchArticles() {
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
	@isTest
	public static void testPopulateEmailTemplate() {
		Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
		setPageReference(pAccount1.Id);
		ShareInformationController sic = new ShareInformationController();
		System.assertEquals(null,sic.template);
		sic.populateEmailTempalte();
		System.assertNotEquals(null,sic.template);
		System.assert(!sic.template.contains('Error: Unable to generate the template because'));
	}
	@isTest
	public static void testArticleHandling() {
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
	@isTest
	public static void testSendEmail() {
		// =====================================
		//Data
		// =====================================
		List<Knowledge__kav> pushEDMs = ApplicationTestDataFactoryKnowledge.getPushEDMs(1, false);
		insert pushEDMs;
		// =====================================
		// Stubbing
		// =====================================
		KnowledgeArticleVersionsSelector kavSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		MockUtility.Mocks.when(kavSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject()))
			.thenReturn(pushEDMs);
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Account pAccount1 = [Select Id, PersonContactId from Account where LastName = 'Person1'];
		setPageReference(pAccount1.Id);
		ShareInformationController sic = new ShareInformationController();
		sic.articleID = pushEDMs[0].Id;
		// this method should create ShareInfoActivity__c and ShareInfoArticle__c records
		sic.sendEmail();
		List<ShareInfoActivity__c> shareInfoActivities =  [SELECT Id FROM ShareInfoActivity__c];
		List<ShareInfoArticle__c> shareInfoArticles =  [SELECT Id FROM ShareInfoArticle__c WHERE ShareInfoActivity__c =:shareInfoActivities[0].Id];
		System.assertEquals(1,shareInfoActivities.size(), 'Share information activity record created');
		System.assertEquals(1,shareInfoArticles.size(), 'Share information article record created');
		((KnowledgeArticleVersionsSelector)MockUtility.Mocks.verify(kavSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());
		Test.stopTest();
	}
	@isTest
	public static void testSendInvite() {
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
	@isTest
	public static void testDataCategoryArticleNode() {
		Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
		setPageReference(pAccount1.Id);
		ShareInformationController sic = new ShareInformationController();
		List<Knowledge__kav> pushEDMs = ApplicationTestDataFactoryKnowledge.getPushEDMs(1, false);
		insert pushEDMs;
		//using object because all objects have the same properties
		KnowledgeArticleVersion kav = [SELECT KnowledgeArticleId FROM KnowledgeArticleVersion WHERE Id = :(Id) pushEDMs[0].get('id')];
		KbManagement.PublishingService.publishArticle(kav.KnowledgeArticleId, true);
		ShareInformationController.DataCategoryArticleNode sData = new ShareInformationController.DataCategoryArticleNode((sObject)pushEDMs[0]);
	}
}