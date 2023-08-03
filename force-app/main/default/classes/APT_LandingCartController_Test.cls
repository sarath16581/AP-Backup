/* @author Nasir Jawed
 * @date 2023-02-24
 * @tag test Class *
 * @domain Core
 * @description A class which test Proposal creation on a click of button "Add Product" is clicked from the
				   opportunity page which is called form lightning "aPT_AddProductLWC" class
 * @changelog
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
	* Test: Data created when opportunity gets created with stagename as 'Closed Lost' so user cannot create proposal and error is thown
	*/
	@IsTest
	public static void testValidationCheckStageName(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Closed Lost';


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
		system.assertEquals(opp.stagename,'Closed Lost');
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
	public static void testValidationCheckStarTrackProposaValues(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		APT_Post_Code_Mapping__c pcr = APT_TestDataFactory.getPostCodeMappingRecord(1,true)[0];

		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'Yes';
		opp.stagename = 'Identify';
		opp.APTPostcodeSuburb__c = pcr.id;
		opp.APTMinimumMonthlySpend__c =100;

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
	* Test: Data created when opportunity gets created with IsStartrackProposal__c as 'No' but there existing a proposal and system does not create proposal and land to cart page.
	**/

	@IsTest
	public static void testValidationCheckNoWithExistingProposal(){
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Identify';

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
	**/

	@IsTest
	public static void testValidationCheckPricingManagementProfile(){
		profile p =[select id,name from profile where Name='Pricing Management'];
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

}