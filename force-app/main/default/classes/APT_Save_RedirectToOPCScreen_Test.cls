/*@author Nasir Jawed
*@date 2023-04-07
*@tag test Class *
*@domain Core
*@description This test class is used to validate the date business object and redirect user from porposal to OppProductList
*@changelog
18/07/2023 Ken Mcguire Extended mocking of test
12/05/2023 Bharat Patel : STP-8932 : add Product Configuration's APT_Configuration_Update_Version__c in redirectToOPCScreenTest() and replace space by tab
*/

@IsTest
public with sharing class APT_Save_RedirectToOPCScreen_Test{

/**
 *Test:Data created when a Docusign recipients exist for the agreement record.
*
*/
@IsTest
public static void redirectToOPCScreenTest(){
	Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
	User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
			EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
			LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
			TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
			UserName=APT_Constants.EMAIL_TEST_USER);
	insert testuser;

	// Retrieve the Permission Set
	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'APT_Apttus_R2T_User' LIMIT 1];

	// Assign the Permission Set to the User
	PermissionSetAssignment psAssignment = new PermissionSetAssignment(
		PermissionSetId = ps.Id,
		AssigneeId = testuser.Id
	);

	insert psAssignment;
	Apttus_Proposal__Proposal__c quote1;
	Apttus_Config2__ProductConfiguration__c prodConfig;

	system.runAs(testuser) {

		//creating Account record
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];

		//creating Contact record
		Contact keyCon = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

		//creating Opportunity record
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Identify';
		opp.KeyContact__c = keyCon.id;


		//creating proposal record
		quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, keyCon.id, true)[0];

		prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, true)[0];
		prodConfig.APT_Configuration_Update_Version__c = 1;
		prodConfig.Apttus_QPConfig__Proposald__c =quote1.id;
		prodConfig.Apttus_Config2__Status__c ='New';
	}

	// =====================================
	// Stubbing
	// =====================================
	APT_ProposalObjectsSelector mockSelectorP = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
	ProductConfigurationSelector mockSelectorProdConfi = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
	ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

	MockUtility.Mocks.startStubbing();
	MockUtility.Mocks.when(mockSelectorP.selectByConfigIds((set<Id>)fflib_Match.eq(new Set<Id>{quote1.id}))).
		thenReturn(new List<Apttus_Proposal__Proposal__c>{quote1});

	MockUtility.Mocks.when(mockSelectorProdConfi.selectByProposalId(new set<ID>{(ID)quote1.Id})).thenReturn(
	new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}));

	MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
	MockUtility.Mocks.stopStubbing();

	PageReference testPage = Page.APT_Save_RedirectToOPCScreen ;
	Test.setCurrentPage(testPage);
	testPage.getParameters().put('businessObjectId', String.valueOf(quote1.Id));

	Test.startTest();
	system.runAs(testuser) {
		APT_Save_redirectToOPCScreen redirectOpc = new APT_Save_redirectToOPCScreen();
		redirectOpc.oPCScreenRedirect();
	}
	Test.stopTest();

	system.assertNotEquals('businessObjectId',null);
	}
}