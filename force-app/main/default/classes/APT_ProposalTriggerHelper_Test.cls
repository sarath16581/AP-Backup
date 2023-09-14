/**
 * @description: This is the test class for Proposal Trigger Helper
 * @author: Darshan Chauhan
 * @group:
 * @last modified on: 06-25-2021
 * @last modified by: Darshan Chauhan
 * Modifications Log
 * Ken McGuire 2023.04.19 Proposal field migration to opportunity
 * Paul Perry	2023-09-14 Decommissioned StarTrek Pricing Matrix logic MW0005472
**/
@isTest
public with sharing class APT_ProposalTriggerHelper_Test {
	@TestSetup
	static void createData(){
		Account acc = APT_TestUtils.createOrganisation();
			insert acc;

			//Create PriceList
			Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
			insert priceList;

			APT_Post_Code_Mapping__c pcm1 = APT_TestUtils.createPostCodeMapping('3000', 'AUSTRALIAN NATIONAL UNIVERSITY', 'MIL', 'VC3', 'AC3');
			insert pcm1;

			Network__c ntwk = APT_TestUtils.createNetwork();
			insert ntwk;

			//Create Opportunity
			Opportunity opty = APT_TestUtils.createOpportunity(acc.id);
			opty.IsStartrackProposal__c = 'Yes';
			opty.APTMinimumMonthlySpend__c = 1200;
			opty.APTPostcodeSuburb__c = pcm1.id;
			opty.IsStartrackProposal__c = 'Yes';
			insert opty;

			Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.id,opty.id,'Proposal','Quote', priceList.id);
			Proposal.Apttus_Proposal__Approval_Stage__c='Draft';
			Proposal.Expected_Revenue_Start_Date__c = System.today();
			Proposal.Expected_Revenue_End_Date__c = System.today() +90;
			Proposal.Apttus_Proposal__Primary__c =false;
			Proposal.APT_Selected_LP__c = ntwk.id;
			Proposal.Apttus_QPApprov__Approval_Status__c = 'Approval Required';
			insert Proposal;
	}
}