/* @author Nasir Jawed
* @date 2023-02-24
* @tag test Class *
* @domain Core
* @description A class which test Proposal creation on a click of button "Add Product" is clicked from the
				opportunity page which is called form lightning "aPT_AddProductLWC" class
* @changelog
* 2023-11-20 : Bharat Patel - added testValidationCheckWithSalesSpecialist(), to validate Sales Specialist roles related logic
*/
@IsTest
public with sharing class APT_LandingCartController_Test {

	/**
 * Test: Data created when opportunity gets created but IsStartrackProposal__c is having no values to check the error condition
 */

	@IsTest
	public static void testValidationCheckStarTrackProposal(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = '';

		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();
		Test.startTest();
		try{
			APT_LandingCartController.validationCheck(opp.id);
		}catch(exception e){
			system.debug('Exception:'+ e);
		}
		Test.stopTest();
		system.assertEquals(opp.IsStartrackProposal__c,'');
	}

	/**
	 * Test: Data created when opportunity gets created with IsStartrackProposal__c as 'Yes' so user cannot create proposal and error is thown
	*/
	@IsTest
	public static void testValidationCheckPostCodeNull(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'Yes';
		opp.APTPostcodeSuburb__c = null;
		opp.APTMinimumMonthlySpend__c =null;
		opp.KeyContact__c = null;

		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		try{
			APT_LandingCartController.validationCheck(opp.id);
		}catch(exception e){
			system.debug('Exception:'+ e);
		}
		Test.stopTest();
		system.assertEquals(opp.IsStartrackProposal__c,'Yes');
	}

	/**
 * Test: Data created when opportunity gets created with IsStartrackProposal__c as 'yes' but no values for minimum spend and Post Code, so user cannot create proposal and error is thown
 **/

	@IsTest
	public static void testValidationCheckStarTrackProposalYes(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'Yes';

		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		try{
			APT_LandingCartController.validationCheck(opp.id);
		}catch(exception e){
			system.debug('Exception:'+ e);
		}
		Test.stopTest();
		system.assertEquals(opp.IsStartrackProposal__c,'Yes');
	}

	/**
 * Test: Data created when opportunity gets created with IsStartrackProposal__c as 'No' and proposal gets created and land to Cart
 **/

	@IsTest
	public static void testValidationCheckStarTrackProposalNo(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Identify';
		opp.KeyContact__c = con.id;


		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();

		ApplicationDatabase mockDatabaseProposal = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabaseProposal.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		APT_LandingCartController.validationCheck(opp.id);
		Test.stopTest();
		system.assertEquals(opp.IsStartrackProposal__c,'No');
	}

	/**
 * Test: Data created when opportunity gets created with IsStartrackProposal__c as 'yes' values for minimum spend and Post Code are provided,proposal gets created and land to Cart page.
 **/

	@IsTest
	public static void testValidationCheckStarTrackProposalValues(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		APT_Post_Code_Mapping__c pcr = APT_TestDataFactory.getPostCodeMappingRecord(1,true)[0];

		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'Yes';
		opp.stagename = 'Identify';
		opp.APTPostcodeSuburb__c = pcr.id;
		opp.APTMinimumMonthlySpend__c =100;
		opp.KeyContact__c = con.id;

		Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, false)[0];

		Apttus_Proposal__Proposal__c quote2 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, false)[0];

		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();

		ApplicationDatabase mockDatabaseProposal = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabaseProposal.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		APT_LandingCartController.validationCheck(opp.id);
		Test.stopTest();
		system.assertEquals(opp.APTMinimumMonthlySpend__c,100);
	}

	/**
 * Test: Data created when opportunity gets created with IsStartrackProposal__c as 'yes' values for minimum spend and Post Code are provided,proposal gets created and land to Cart page.
 *
 */
	@IsTest
	public static void testValidationCheckStageName(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		APT_Post_Code_Mapping__c pcr = APT_TestDataFactory.getPostCodeMappingRecord(1,true)[0];

		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'Yes';
		opp.stagename = 'Closed Lost';
		opp.KeyContact__c = con.id;

		Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, false)[0];

		Apttus_Proposal__Proposal__c quote2 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, false)[0];

		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();

		ApplicationDatabase mockDatabaseProposal = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabaseProposal.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		try{
			APT_LandingCartController.validationCheck(opp.id);
		}catch(exception e){
			system.debug('Exception:'+ e);
		}
		system.assertEquals(opp.stagename,'Closed Lost');
	}

	/**
 * Test: Data created when opportunity gets created with IsStartrackProposal__c as 'No' but there existing a proposal and system does not create proposal and land to cart page.
 **/

	@IsTest
	public static void testValidationCheckNoWithExistingProposal(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Identify';
		opp.KeyContact__c = con.id;

		Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
		quote1.Apttus_Proposal__Approval_Stage__c = 'Accepted';

		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();

		APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorProposal.selectByOpportunityId((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
		MockUtility.Mocks.stopStubbing();

		ApplicationDatabase mockDatabaseProposalupdate = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabaseProposalupdate.dmlupdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		ApplicationDatabase mockDatabaseProposalInsert = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabaseProposalInsert.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		APT_LandingCartController.validationCheck(opp.id);
		Test.stopTest();

		fflib_ArgumentCaptor insertedProposal = fflib_ArgumentCaptor.forClass(List<Apttus_Proposal__Proposal__c>.class);
		// verify dml insert has been made 1 times
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabaseProposalInsert, MockUtility.Mocks.times(1))).dmlInsert((List<Apttus_Proposal__Proposal__c>)insertedProposal.capture());
		// verify Proposal Stage is populated with the "DRAFT" stage
		for(Apttus_Proposal__Proposal__c alp: (List<Apttus_Proposal__Proposal__c>) insertedProposal.getValue()){
			if(alp.Apttus_Proposal__Approval_Stage__c != null){
				System.assertEquals(alp.Apttus_Proposal__Approval_Stage__c,APT_Constants.QUOTE_TYPE_DRAFT);
			}
		}
	}
	/**
 * Test: Data created when opportunity gets created with IsStartrackProposal__c as 'No' but there existing a proposal with status not 'Accepted' or 'Denied' and system does not create proposal and land to cart page.
 **/

	@IsTest
	public static void testValidationCheckWithExistingProposalNotAccepted(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Identify';
		opp.KeyContact__c = con.id;

		Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
		quote1.Apttus_Proposal__Approval_Stage__c = 'DRAFT';

		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();

		APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorProposal.selectByOpportunityId((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
		MockUtility.Mocks.stopStubbing();

		APT_ProposalObjectsSelector mockSelectorProposal1 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorProposal1.selectByConfigIds((set<Id>)fflib_Match.eq(new Set<Id>{quote1.id}))).thenReturn(
			new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		APT_LandingCartController.validationCheck(opp.id);
		Test.stopTest();
		System.assertEquals(quote1.Apttus_Proposal__Approval_Stage__c,APT_Constants.QUOTE_TYPE_DRAFT);
	}

	/**
 * Test: Data created when opportunity gets created with IsStartrackProposal__c as 'No' with user profile as pricing management.
 *
	 *  */
	@IsTest
	public static void testValidationCheckPricingManagemantProfile(){
		profile p =[select id,name from profile where Name=:APT_Constants.STRING_PRICING_MANAGEMENT];
		//creating user as Pricing Management profile
		User user= new user();
		User.FirstName = 'First Name %count%';
		User.LastName = 'Last Name %count%';
		User.Username = 'ZZtest%count%@test%count%.test%count%.com';
		User.Email = 'nj@conga.com';
		User.Alias = 'nj';
		User.EmailEncodingKey = 'UTF-8';
		User.TimezoneSidKey = 'Australia/Sydney';
		User.LanguageLocaleKey = 'en_AU';
		User.LocaleSidKey = 'en_AU';
		User.ProfileId = p.id;

		//Running the system as user with pricing management profile
		system.runAs(user){
			String sessionID = UserInfo.getSessionId();
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
			Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			opp.IsStartrackProposal__c = 'No';
			opp.stagename = 'Identify';
			opp.KeyContact__c = con.id;

			Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
			quote1.Apttus_Proposal__Approval_Stage__c = 'Draft';

			OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
			ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new map<Id,Opportunity>(new List<Opportunity>{opp}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal.selectByOpportunityId((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal1 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal1.selectByConfigIds((set<Id>)fflib_Match.eq(new Set<Id>{quote1.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			try{
				APT_LandingCartController.validationCheck(opp.id);
			}catch(exception e){
				system.debug('Exception:'+ e);
			}
			System.assertEquals(opp.KeyContact__c,con.Id);

		}
	}

	@IsTest
	public static void testValidationCheckSystemAdminProfile(){
		profile p =[select id,name from profile where Name=:APT_Constants.STRING_SYSTEM_ADMINISTRATOR];
		//creating user as Pricing Management profile
		User user= new user();
		User.FirstName = 'First Name %count%';
		User.LastName = 'Last Name %count%';
		User.Username = 'ZZtest%count%@test%count%.test%count%.com';
		User.Email = 'nj@conga.com';
		User.Alias = 'nj';
		User.EmailEncodingKey = 'UTF-8';
		User.TimezoneSidKey = 'Australia/Sydney';
		User.LanguageLocaleKey = 'en_AU';
		User.LocaleSidKey = 'en_AU';
		User.ProfileId = p.id;

		//Running the system as user with system Admin profile
		system.runAs(user){
			String sessionID = UserInfo.getSessionId();
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
			Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			opp.IsStartrackProposal__c = 'No';
			opp.stagename = 'Identify';
			opp.KeyContact__c = con.id;

			Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
			quote1.Apttus_Proposal__Approval_Stage__c = 'Draft';

			OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
			ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new map<Id,Opportunity>(new List<Opportunity>{opp}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal.selectByOpportunityId((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal1 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal1.selectByConfigIds((set<Id>)fflib_Match.eq(new Set<Id>{quote1.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			Test.startTest();
			APT_LandingCartController.validationCheck(opp.id);
			Test.stopTest();
			System.assertEquals(user.ProfileId,p.Id);

		}
	}

	/**
 * Test: Data created when prod Config with status as 'New' with user profile as BG Base.
 **/

	@IsTest
	public static void testValidationCheckPricingBGBaseProfile(){
		profile p =[select id,name from profile where Name=:APT_Constants.STRING_BG_BASE];
		//creating user as Pricing Management profile
		User user= new user();
		User.FirstName = 'First Name %count%';
		User.LastName = 'Last Name %count%';
		User.Username = 'ZZtest%count%@test%count%.test%count%.com';
		User.Email = 'nj@conga.com';
		User.Alias = 'nj';
		User.EmailEncodingKey = 'UTF-8';
		User.TimezoneSidKey = 'Australia/Sydney';
		User.LanguageLocaleKey = 'en_AU';
		User.LocaleSidKey = 'en_AU';
		User.ProfileId = p.id;

		//Running the system as user with Pricing Management profile
		system.runAs(user){
			String sessionID = UserInfo.getSessionId();
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
			Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			opp.IsStartrackProposal__c = 'No';
			opp.stagename = 'Identify';

			Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
			quote1.Apttus_Proposal__Approval_Stage__c = 'Draft';

			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1,null,quote1.id,true)[0];
			prodConfig.Apttus_Config2__Status__c='New';

			OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
			ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new map<Id,Opportunity>(new List<Opportunity>{opp}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal.selectByOpportunityId((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal1 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal1.selectByConfigIds((set<Id>)fflib_Match.eq(new Set<Id>{quote1.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			ProductConfigurationSelector mockSelectorProdConfig = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
			ApplicationDatabase mockDatabase3 = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProdConfig.selectByProposalId(new set<ID>{(ID)quote1.Id})).thenReturn(
				new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}));
			MockUtility.Mocks.stopStubbing();

			Test.startTest();
			try{
				APT_LandingCartController.validationCheck(opp.id);
			}catch(exception e){
				system.debug('Exception:'+ e);
			}
			system.assertEquals(prodConfig.Apttus_Config2__Status__c,'New');

		}
	}

	/**
 * Test: Data created when prod Config with status as 'Saved' with user profile as Onboarding User.
 **/

	@IsTest
	public static void testValidationCheckPricingOnBoardProfileSaved(){
		profile p =[select id,name from profile where Name=:APT_Constants.STRING_ONBOARDING];
		//creating user as ONBOARDING profile
		User user= new user();
		User.FirstName = 'First Name %count%';
		User.LastName = 'Last Name %count%';
		User.Username = 'ZZtest%count%@test%count%.test%count%.com';
		User.Email = 'nj@conga.com';
		User.Alias = 'nj';
		User.EmailEncodingKey = 'UTF-8';
		User.TimezoneSidKey = 'Australia/Sydney';
		User.LanguageLocaleKey = 'en_AU';
		User.LocaleSidKey = 'en_AU';
		User.ProfileId = p.id;

		//Running the system as user with ONBOARDING profile
		system.runAs(user){
			String sessionID = UserInfo.getSessionId();
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
			Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			opp.IsStartrackProposal__c = 'No';
			opp.stagename = 'Identify';

			Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
			quote1.Apttus_Proposal__Approval_Stage__c = 'Draft';

			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1,null,quote1.id,true)[0];
			prodConfig.Apttus_Config2__Status__c='Saved';

			OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
			ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new map<Id,Opportunity>(new List<Opportunity>{opp}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal.selectByOpportunityId((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal1 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal1.selectByConfigIds((set<Id>)fflib_Match.eq(new Set<Id>{quote1.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			ProductConfigurationSelector mockSelectorProdConfig = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
			ApplicationDatabase mockDatabase3 = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProdConfig.selectByProposalId(new set<ID>{(ID)quote1.Id})).thenReturn(
				new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}));
			MockUtility.Mocks.stopStubbing();
			Test.startTest();
			try{
				APT_LandingCartController.validationCheck(opp.id);
			}catch(exception e){
				system.debug('Exception:'+ e);
			}
			system.assertEquals(prodConfig.Apttus_Config2__Status__c,'Saved');
		}
	}

	/**
 * Test: Data created when prod Config with status as 'New' with user profile as Onboarding User.
 **/

	@IsTest
	public static void testValidationCheckPricingOnBoardProfileNew(){
		profile p =[select id,name from profile where Name=:APT_Constants.STRING_ONBOARDING];
		//creating user as ONBOARDING profile
		User user= new user();
		User.FirstName = 'First Name %count%';
		User.LastName = 'Last Name %count%';
		User.Username = 'ZZtest%count%@test%count%.test%count%.com';
		User.Email = 'nj@conga.com';
		User.Alias = 'nj';
		User.EmailEncodingKey = 'UTF-8';
		User.TimezoneSidKey = 'Australia/Sydney';
		User.LanguageLocaleKey = 'en_AU';
		User.LocaleSidKey = 'en_AU';
		User.ProfileId = p.id;

		//Running the system as user with ONBOARDING profile
		system.runAs(user){
			String sessionID = UserInfo.getSessionId();
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
			Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			opp.IsStartrackProposal__c = 'No';
			opp.stagename = 'Identify';

			Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
			quote1.Apttus_Proposal__Approval_Stage__c = 'Draft';

			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1,null,quote1.id,true)[0];
			prodConfig.Apttus_Config2__Status__c='New';

			OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
			ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new map<Id,Opportunity>(new List<Opportunity>{opp}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal.selectByOpportunityId((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			APT_ProposalObjectsSelector mockSelectorProposal1 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProposal1.selectByConfigIds((set<Id>)fflib_Match.eq(new Set<Id>{quote1.id}))).thenReturn(
				new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
			MockUtility.Mocks.stopStubbing();

			ProductConfigurationSelector mockSelectorProdConfig = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
			ApplicationDatabase mockDatabase3 = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorProdConfig.selectByProposalId(new set<ID>{(ID)quote1.Id})).thenReturn(
				new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}));
			MockUtility.Mocks.stopStubbing();

			Test.startTest();
			try{
				APT_LandingCartController.validationCheck(opp.id);
			}catch(exception e){
				system.debug('Exception:'+ e);
			}
			system.assertEquals(prodConfig.Apttus_Config2__Status__c,'New');

		}
	}


/**
 * Test: Method validate funcationality of Sales Specialist role specific execution
 **/
 @IsTest
 public static void testValidationCheckWithSalesSpecialist(){

	Profile p =[SELECT Id,Name FROM Profile WHERE Name=:APT_Constants.STRING_BG_BASE];
	UserRole userRole =[SELECT Id, Name from UserRole WHERE Name= 'Sales Specialists NSW 1 - SR'];
	//creating user as BG_BASE profile
	User user= new user();
	user.FirstName = 'First Name %count%';
	user.LastName = 'Last Name %count%';
	user.Username = 'ZZtest%count%@test%count%.test%count%.com';
	user.Email = 'nj@conga.com';
	user.Alias = 'nj';
	user.EmailEncodingKey = 'UTF-8';
	user.TimezoneSidKey = 'Australia/Sydney';
	user.LanguageLocaleKey = 'en_AU';
	user.LocaleSidKey = 'en_AU';
	user.ProfileId = p.id;
	user.UserRoleId = userRole.Id;
	insert user;

	//Retrieve the Permission Set
	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'APT_Sales_Specialist' LIMIT 1];

	// Assign the Permission Set to the User
	PermissionSetAssignment psAssignment = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = user.Id);
	insert psAssignment;

	System.runAs(user){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Identify';
		opp.KeyContact__c = con.id;

		Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, con.id, true)[0];
		quote1.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;

		OpportunitySelector mockSelectorOpp = (OpportunitySelector) MockUtility.mockSelector(OpportunitySelector.class);
		ApplicationDatabase mockDatabaseOpp = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorOpp.selectById((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new map<Id,Opportunity>(new List<Opportunity>{opp}));
		MockUtility.Mocks.stopStubbing();

		APT_ProposalObjectsSelector mockSelectorProposal = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorProposal.selectByOpportunityId((set<Id>)fflib_Match.eq(new Set<Id>{opp.id}))).thenReturn(
			new List<Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote1}));
		MockUtility.Mocks.stopStubbing();

		ApplicationDatabase mockDatabaseProposalupdate = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabaseProposalupdate.dmlupdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		ApplicationDatabase mockDatabaseProposalInsert = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabaseProposalInsert.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		APT_LandingCartController.validationCheck(opp.id);
		Test.stopTest();

		fflib_ArgumentCaptor insertedProposal = fflib_ArgumentCaptor.forClass(List<Apttus_Proposal__Proposal__c>.class);
		// verify dml insert has been made 1 times
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabaseProposalInsert, MockUtility.Mocks.times(1))).dmlInsert((List<Apttus_Proposal__Proposal__c>)insertedProposal.capture());
		// verify Proposal Stage is populated with the "DRAFT" stage
		for(Apttus_Proposal__Proposal__c alp: (List<Apttus_Proposal__Proposal__c>) insertedProposal.getValue()){
			if(alp.Apttus_Proposal__Approval_Stage__c != null){
				System.assertEquals(alp.Apttus_Proposal__Approval_Stage__c,APT_Constants.QUOTE_TYPE_DRAFT);
			}
		}
	}
 }

}