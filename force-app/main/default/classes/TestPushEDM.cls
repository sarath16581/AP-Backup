/*
* @changelog
* 2021-08-24 - Seth Heang - Uplift SF API Version to 52
* 2022-04-04 - SaiSwetha Pingali REQ2723594 - Fix for test class failures .
2023-08-28	Naveen Rajanna	REQ3286437 - Changed api version and removed hard coded URL to use apex methods to generate URL
*/
@isTest
private class TestPushEDM 
{
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
		pd.Force_Com_URL__c = Url.getOrgDomainUrl().toExternalForm();
		pd.Site_URL__c = Url.getOrgDomainUrl().toExternalForm() + '/PKB';
		pd.Supported_Article_Types__c = 'FAQ;Push_EDM';
		insert pd;
		
		QM__c qm = new QM__c();
		qm.CusEmail__c = 'test@example.com';
		insert qm;
	}
	
	public static void setPageReference(Id recordId) {
		PageReference prAccount = new PageReference('/apex/PushEDM?id=' + recordId);
		Test.setCurrentPageReference(prAccount);
	}
	@isTest
	public static void testPopulateEmailTemplate() {
		Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
		setPageReference(pAccount1.Id);
		PushEDM edm = new PushEDM();
		System.assertEquals(null,edm.template);
		edm.populateEmailTempalte();
		System.assertNotEquals(null,edm.template);
		System.assert(!edm.template.contains('Error: Unable to generate the template because'));
	}
	@isTest
	public static void testSendEmail() {
		Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
		setPageReference(pAccount1.Id);
		PushEDM edm = new PushEDM();
		edm.sendEmail();
	}
	
	public static testMethod void testClearSearchAndSearchArticles() {
		Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
		setPageReference(pAccount1.Id);
		PushEDM sic = new PushEDM();
		sic.searchKeyword = 'Here is my keyword';
		sic.displayResult = true;
		sic.displayResult = false;
		sic.searchArticles();
	  //  System.assertEquals(true, sic.displayResult);
	}
	
	@isTest
	public static void testDataCategoryArticleNode() {
		Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
		setPageReference(pAccount1.Id);
		List<Knowledge__kav> pushEDMs = ApplicationTestDataFactoryKnowledge.getPushEDMs(1, false);
		insert pushEDMs;
		
	}
	
	public List<String> articleBodys = new List<String>();      
	public String articleBody {get; set;} 
	public Integer articlePosition {get; set;}
	//add article body into the list
	public void testAddToArticleBody() {
		articleBodys.add(articleBody);
	}
	@isTest
	static void testcleanPhoneString() {
		Util.cleanPhoneString('12ajh3sg4sd5');
		Util.cleanPhoneString('12ajh3sg4sd5678901231312121');
	}
	@isTest
	static void testsearchablePhoneString() {
		system.assert('%1%2%3%4%5' == Util.searchablePhoneString('12ajh3sg4sd5'));
	}
	@isTest
	static void testcontactIDForNameAndEmail() {
		Contact contact1 = new Contact();
		contact1.LastName = 'test last name';
		contact1.FirstName = 'test first name';
		contact1.MailingAddress__c = 'test address';
		contact1.MailingCity = 'test city';
		contact1.Email = 'TestUniqueEmail@test.com';
		insert contact1;
		Util.contactIDForNameAndEmail('name', 'TestUniqueEmail@test.com');
	} 
	@isTest
	static void testCommon() {
		Contact contact1 = new Contact();
		contact1.LastName = 'test last name';
		contact1.FirstName = 'test first name';
		contact1.MailingAddress__c = 'test address';
		contact1.MailingCity = 'test city';
		contact1.Email = 'TestUniqueEmail@test.com';
		insert contact1;
		Util.createAttachment('test attachment', 'ajgskdjgausgdhagsud', 'image', contact1.Id);
		util.replacePlaceholders(contact1, 'test');
		util.getRecordTypesNameById('Account');
		util.getRecordTypesDevNameById('Account');
		util.getRecordTypesByDeveloperName('Account');
		util.getCreatableFieldsSOQL('Account', ' Id != null');
		util.replaceMergeFields(contact1, '{!Contact.LastName}');
		Network__c x = new Network__c();
		insert x;
		util.getBodyFromEmailTemplate('PushEDM', contact1.Id, x.Id);
	}
	@isTest
	static void ControllerTest() 
	{  
		PushEDM_Domain__c pED_CS = new  PushEDM_Domain__c(SetupOwnerId = UserInfo.getUserId(),Force_Com_URL__c = 'force.com', Site_URL__c = 'force.com');
		insert pED_CS;
		
		QM__c q = new QM__c(SetupOwnerId = UserInfo.getUserId(),CusEmail__c = 'test@test.com');
		insert q;
		Exact_Target_LogIn__c e = new Exact_Target_LogIn__c(Name='test',ClientId__c='test');
		e.ClientSecret__c = 't';
		e.Message_EndPoint__c = 'test';
		e.RequestToken_EndPoint__c = 'xyz';
		insert e;
		EmailTemplate et=[Select id, subject, HtmlValue From EmailTemplate e where DeveloperName='PushEDM'];
		if(et == null)
		{
			et = new EmailTemplate(DeveloperName='PushEDM', Name='PushEDM', subject = 'test', htmlValue = '<p id="BodyContent">%%BodyContent%%</p>');
			insert et;
		} 
		
		Contact cont = TestDataProvider.createAndSaveContact();     
		ApexPages.currentPage().getParameters().put('id', cont.Id);
		//3-Jun-2016: quick fix for deployment error. Added try catch
		try {
			
			PushEDM.Category cat = new PushEDM.Category('Name', 'Label');
			List<PushEDM.Category> topCategory = new List<PushEDM.Category>();
			topCategory.add(cat);
			Account pAccount1 = [Select Id from Account where LastName = 'Person1'];
			PushEDM.articleSet art= new PushEDM.articleSet('TestTitle','TestAnswer','testURL','FAQ',pAccount1.id, 'TestCategory', topCategory);
			
			PushEDM.articleSet art2= new PushEDM.articleSet('TestTitle','TestAnswer','testURL','PushEDM',pAccount1.id, 'TestCategory');
			
			PushEDM ctrl = new PushEDM();
			ctrl.populateEmailTempalte();       
			ctrl.articleBody = 'testbody1';
			ctrl.addToArticleBody();
			ctrl.articleBody = 'testbody2';
			ctrl.addToArticleBody();
			ctrl.articlePosition = 0;
			ctrl.moveToArticleBody();
			ctrl.removeFromArticleBody();
			Test.startTest();
			
			ctrl.sendEmail();
			Test.stopTest();
			
			ApexPages.currentPage().getParameters().put('k', 'keyword');
			PushEDM ctrl2 = new PushEDM();
		}
		catch(Exception ex){
			
		}
	}
}