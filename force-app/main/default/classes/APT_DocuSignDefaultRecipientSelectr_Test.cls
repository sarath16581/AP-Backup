/**
*@author Nasir Jawed
*@date 2023-04-07
*@group Tests
*@tag Selector
*@tag Apttus_DocuApi__DocuSignDefaultRecipient2__c SObject
*@domain Apttus
*@description Apttus_DocuApi__DocuSignDefaultRecipient2__c to validate Data.
*/
@IsTest
private with sharing class APT_DocuSignDefaultRecipientSelectr_Test{

	/**
	*Test:
	*Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		APT_DocuSignDefaultRecipient2Selector  selector = APT_DocuSignDefaultRecipient2Selector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus_DocuApi__DocuSignDefaultRecipient2__c\\b').matcher(soql).find(), 'Resulting query does not select from docuSign Receipient object');

		Test.stopTest();

	}

	//Testing setupdata;
	@IsTest
	private static void docuSignDefaultRecipientSelector(){
		string userRecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Sales Professional (User)').getRecordTypeId();
		//Inserting the value because Recipient record is not recognised
		profile p =[select id,name from profile where name='System Administrator'];
		//creating User record
		user u= ApplicationTestDataFactory.getUsers(1,p.id,false)[0];
		insert u;
		//creating Account record
		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
		//creating Contact record
		Contact keyCon = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert keycon;
		//creating Opportunity record
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Identify';
		opp.KeyContact__c = keyCon.id;
		insert opp;

		//creating proposal record
		Apttus_Proposal__Proposal__c quote1 = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, account.Id, keyCon.id, false)[0];
		quote1.Apttus_Proposal__Approval_Stage__c = 'Accepted';
		insert quote1;
		//creating Agreement record
		Apttus__APTS_Agreement__c agreement = ApplicationTestDataFactory.getApttusContracts(1,keyCon.id,opp.id,false)[0];
		agreement.Apttus_QPComply__RelatedProposalId__c =quote1.id;
		agreement.Apttus__Account__c=account.id;
		insert agreement;

		//creating DocuSign user record
		Apttus_DocuApi__DocuSignDefaultRecipient2__c recipient1 =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
		recipient1.recordTypeId = userRecordTypeId;
		recipient1.APT_Docusign_Recipient_Type__c = 'Sales user';
		recipient1.Apttus_DocuApi__Email__c = u.email;
		insert recipient1;

		Test.startTest();
		APT_DocuSignDefaultRecipient2Selector selector = APT_DocuSignDefaultRecipient2Selector.newInstance();
		List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> recipientResult = selector.selectById(new Set<ID>{recipient1.id});
		List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> agreementresults = selector.selectByAgreementId(new Set<ID>{agreement.id});
		system.assertEquals(recipientResult.size(),1);
		system.assertEquals(agreementresults.size(),1);
		Test.stopTest();
	}
}