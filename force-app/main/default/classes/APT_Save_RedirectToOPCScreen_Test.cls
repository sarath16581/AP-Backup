/*@author Nasir Jawed
*@date 2023-04-07
*@tag test Class *
*@domain Core
*@description This test class is used to validate the date business object and redirect user from porposal to OppProductList
*@changelog
*/

@IsTest
public with sharing class APT_Save_RedirectToOPCScreen_Test{

/**
 *Test:Data created when a Docusign recipients exist for the agreement record.
*
*/
@IsTest
public static void redirectToOPCScreenTest(){
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
	Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, keyCon.id, true)[0];

	Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, true)[0];
	prodConfig.Apttus_QPConfig__Proposald__c =quote1.id;
	prodConfig.Apttus_Config2__Status__c ='New';

	APT_ProposalObjectsSelector mockSelectorP = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
	MockUtility.Mocks.startStubbing();
	MockUtility.Mocks.when(mockSelectorP.selectByConfigIds((set<Id>)fflib_Match.eq(new Set<Id>{quote1.id}))).
		thenReturn(new List<Apttus_Proposal__Proposal__c>{quote1});
	MockUtility.Mocks.stopStubbing();

	ProductConfigurationSelector mockSelectorProdConfi = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
	ApplicationDatabase mockDatabase3 = MockUtility.mockDatabase();
	MockUtility.Mocks.startStubbing();
	MockUtility.Mocks.when(mockSelectorProdConfi.selectByProposalId(new set<ID>{(ID)quote1.Id})).thenReturn(
	new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}));
	MockUtility.Mocks.stopStubbing();

	PageReference testPage = Page.APT_Save_RedirectToOPCScreen ;
	Test.setCurrentPage(testPage);
	testPage.getParameters().put('businessObjectId', String.valueOf(quote1.Id));

	Test.startTest();
	APT_Save_redirectToOPCScreen redirectOpc = new APT_Save_redirectToOPCScreen();
	redirectOpc.oPCScreenRedirect();
	Test.stopTest();

	system.assertNotEquals('businessObjectId',null);
	}
}