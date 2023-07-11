/*@author Yatika Bansal
*@date 05-05-2023
*@group Tests
*@tag ApexController
*@domain Apttus
*@description A test class for APT_AbandonCartController
*/

@IsTest
public with sharing class APT_AbandonCartControllerTest{

	/**
	*Test: Checks when redirectToOpp method is called, it works successfully
	*
	*/
	@IsTest
	public static void redirectToOppTest(){
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

		PageReference testPage = Page.APT_AbandonCart ;
		Test.setCurrentPage(testPage);
		testPage.getParameters().put('businessObjectId', String.valueOf(quote1.Id));

		Test.startTest();
		APT_AbandonCartController redirectOp = new APT_AbandonCartController();
		redirectOp.redirectToOpp();
		Test.stopTest();

		System.assertNotEquals('businessObjectId', null);
	}
}