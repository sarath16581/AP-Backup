/**
* Created by avula.jansirani@auspost.com.au on 19/04/2021.
*/

@IsTest
public class BCAFormBase_Test {
	
	@testSetup static void setup() {
		// Create common test accounts
		List<Account> testAccts = new List<Account>();
		for(Integer i=0;i<2;i++) {
			testAccts.add(new Account(Name = 'TestAcct'+i));
		}
		insert testAccts;
	}
	
	@IsTest
	private static void testCSSettings() {
		// =====================================
		// Data Preparation
		// =====================================
		BCA_Settings__c bcaSetting1 = new BCA_Settings__c();
		bcaSetting1.Name = BCAFormConstants.CREDIT_LIMIT_TIMES;
		bcaSetting1.Number_Value__c = 2;
		bcaSetting1.Boolean_Value__c = false;
		bcaSetting1.Text_Value__c = 'https://www.google.com';
		
		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		// Database
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
			.thenReturn(new Map<String, BCA_Settings__c>{
				BCAFormConstants.CREDIT_LIMIT_TIMES => bcaSetting1
					});
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		//insert bcaSetting;
		Test.startTest();
		BCAFormBase.getSummryTCDownloadURL();
		BCAFormBase.getMinimumCreditLimit();
		BCAFormBase.noOfTimesCreditLimit();
		BCAFormBase.getDirectDebitTCDownloadURL();
		BCAFormBase.getSummryPrivacyNoticeURL();
		System.assertEquals(2,  BCAFormBase.noOfTimesCreditLimit().get('noOfTimes'), 'success');
		
		Boolean underMaintenance = BCAFormBase.getIsUnderMaintenance();
		System.assertEquals(bcaSetting1.Boolean_Value__c, underMaintenance
							, 'Under Maintenance setting incorrect, expected:' + bcaSetting1.Boolean_Value__c + ' got:' + underMaintenance);
		Test.stopTest();
		
	}
	
	@IsTest
	private static void testGetArticles()
	{
		// =====================================
		// Data Preparation
		// =====================================
		String testMessage = 'test message';
		Knowledge__kav ka = new Knowledge__kav();
		ka.Message__c = testMessage;
		
		// =====================================
		// Stubbing
		// =====================================
		KnowledgeArticleVersionsSelector kavSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		// Database
		MockUtility.Mocks.when(kavSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean()))
			.thenReturn(new List<SObject>{ka});
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		//insert bcaSetting;
		Test.startTest();
		System.assertEquals(ka, BCAFormBase.getWelcomeMessage(), 'Welcome failed');
		System.assertEquals(ka, BCAFormBase.getDirectTC(), 'Direct T&C failed');
		System.assertEquals(ka, BCAFormBase.getSummaryTC(), 'Summary T&C failed');
		//System.assertEquals(ka, BCAFormBase.getSummaryPrivacyContent(), 'Summary Privacy Content failed');
		
		Test.stopTest();
		
	}
	
	@IsTest
	private static void testWelcomeAndTCText() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> kav = ApplicationTestDataFactoryKnowledge.getBCAs(1, true);

		// =====================================
		// Stubbing
		// =====================================
		KnowledgeArticleVersionsSelector kavSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		// Database
		MockUtility.Mocks.when(kavSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean()))
			.thenReturn(kav);
		MockUtility.Mocks.stopStubbing();
		
		Test.startTest();
		BCAFormBase.getWelcomeMessage();		
		((KnowledgeArticleVersionsSelector)MockUtility.Mocks.verify(kavSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		System.assertEquals(kav[0].Message__c,  BCAFormBase.getWelcomeMessage().Message__c, 'success');
		Test.stopTest();
		
	}
	
	@IsTest
	private static void testDirectTC() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> kav = ApplicationTestDataFactoryKnowledge.getBCAs(1, true);

		// =====================================
		// Stubbing
		// =====================================
		KnowledgeArticleVersionsSelector kavSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		// Database
		MockUtility.Mocks.when(kavSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean()))
			.thenReturn(kav);
		MockUtility.Mocks.stopStubbing();
		// Testing
		Test.startTest();
		BCAFormBase.getDirectTC();
		((KnowledgeArticleVersionsSelector)MockUtility.Mocks.verify(kavSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		System.assertEquals(kav[0].Message__c,  BCAFormBase.getDirectTC().Message__c, 'success');
		Test.stopTest();
	}
	
	
	@IsTest
	private static void testSummaryTC() {

		
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> kav = ApplicationTestDataFactoryKnowledge.getBCAs(1, true);

		// =====================================
		// Stubbing
		// =====================================
		KnowledgeArticleVersionsSelector kavSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		// Database
		MockUtility.Mocks.when(kavSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean()))
			.thenReturn(kav);
		MockUtility.Mocks.stopStubbing();
		// Testing
		Test.startTest();
		BCAFormBase.getSummaryTC();
		((KnowledgeArticleVersionsSelector)MockUtility.Mocks.verify(kavSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		System.assertEquals(kav[0].Message__c,  BCAFormBase.getSummaryTC().Message__c, 'success');
		Test.stopTest();
		
	}
	
	@IsTest
	private static void testAccountDuplicateCheck() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Account> accList = [SELECT Id, ABN__c FROM Account LIMIT 2];
		for (Account acc : accList) {
			acc.ABN__c = '31061621832';
		}
		update accList;

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.findDuplicates((List<SObject>) fflib_Match.anyObject()))
			.thenReturn(new List<DatacloudProxy.FindDuplicatesResult>{ DatacloudProxy_Test.mockFindDuplicatesResult(ApplicationTestDataFactory.getAccounts(1, true)[0], 80) });
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		Boolean isDuplicate = BCAFormBase.containDuplicateABNACN(accList, accList[0].Id);
		Test.stopTest();
		System.assertEquals(true, isDuplicate);		
	}

	@IsTest
	private static void testGetIndustryDivisionValues() {
		// =====================================
		// Data Preparation
		// =====================================
		ANZSIC_code__c anzCode = new ANZSIC_code__c();
		anzCode.ANZSIC_Division__c = 'A Agriculture, Forestry and Fishing xxx';
		anzCode.Code_Description__c  = 'Apple & Pear Growing xxx';
		insert anzCode;
		Test.startTest();
		List<bspEnquiryUplift.SelectOptionCustom> option1List1= BCAFormBase.getIndustryDivisionValues();
		List<bspEnquiryUplift.SelectOptionCustom> option1List2= BCAFormBase.getObjectRecordFieldValues('ANZSIC_Code__c', 'Code_Description__c', 'WHERE ANZSIC_Division__c=\'A Agriculture, Forestry and Fishing xxx\'', false);
		System.assertEquals(1, option1List2.size(), 'success');
		System.assertEquals(1, option1List1.size(), 'success');
		Test.stopTest();
		
		
	}
	
	@IsTest
	private static void testForExistingBillingAccountUser() {
		Account testAccount = [SELECT Id,ABN__c FROM Account Limit 1];
		Billing_Account__c b = ApplicationTestDataFactory.getBillingAccounts(1,testAccount.Id, 'SAP ERP', false)[0];
		b.Type__c ='CUST';
		b.SAP_marked_for_deletion__c = false;
		// =====================================
		// Data Preparation
		// =====================================
		// create user
		
		Contact c = ApplicationTestDataFactory.getContacts(1, new Set<Id>{testAccount.Id}, false)[0];
		insert c;
		Id bcaProfileId = [SELECT Id from Profile WHERE Name='Mypost Business Help & Support Community User' Limit 1].Id;
		User bcaUser = new User(Alias = 'bcaUser', Email='user@testorg.a', ContactId = c.Id, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
								LocaleSidKey='en_US', ProfileId = bcaProfileId, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
		
		Database.insert(bcaUser);
		
		Test.startTest();
		System.runAs(bcaUser){
			BCAFormBase.UserDetails uDetails = BCAFormBase.checkUserAccessToBCACreation(bcaUser.Id);

			System.assertEquals(uDetails.allowBCACreation, true, 'Success');
		}
		
		Test.stopTest();
	}
	
	@IsTest
	private static void testForExistingCreditAssesment() {
		Account testAccount = [SELECT Id,ABN__c FROM Account Limit 1];
		
		APT_Credit_Assessment__c caRecord = new APT_Credit_Assessment__c();
		caRecord.APT_ABN__c = '11111111111';
		caRecord.APT_Email_Address__c = 'test@example.com';
		caRecord.APT_Credit_Assessment_Status__c=BCAFormConstants.CREDIT_ASSESSMENT_STATUS_WORK_IN_PROGRESS;
		caRecord.APT_Organisation_Name__c = testAccount.Id;
		caRecord.APT_Legal_Entity_Name__c = 'Text xxx';
		insert caRecord;
		
		Contact c = ApplicationTestDataFactory.getContacts(1, new Set<Id>{testAccount.Id}, false)[0];
		insert c;
		Id bcaProfileId = [SELECT Id from Profile WHERE Name='Mypost Business Help & Support Community User' Limit 1].Id;
		User bcaUser = new User(Alias = 'bcaUser', Email='user@testorg.a', ContactId = c.Id, EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
								LocaleSidKey='en_US', ProfileId = bcaProfileId, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
		
		Database.insert(bcaUser);
		
		Test.startTest();
		BCAFormBase.UserDetails uDetails = BCAFormBase.checkUserAccessToBCACreation(bcaUser.Id);
		Test.stopTest();
		
		System.assertEquals(uDetails.allowBCACreation, false, 'Success');
		
	}

	@IsTest
	private static void testValidateBSB()
	{
		// =====================================
		// Data Preparation
		// =====================================
		BSB__c bsb = new BSB__c();
		bsb.Name = '003048';

		// =====================================
		// Stubbing
		// =====================================
		CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Database
		MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
				.thenReturn(new Map<String, BSB__c>{
				bsb.Name => bsb
		});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		//insert bcaSetting;
		Test.startTest();
		BCAFormBase.BSB_Result result = BCAFormBase.validateBSB(bsb.Name);
		System.assertEquals(bsb.Name,  result.name, 'incorrect bsb result:' + result);
		Test.stopTest();

	}
	
}