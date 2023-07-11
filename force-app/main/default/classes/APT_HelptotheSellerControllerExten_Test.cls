/*@author Nasir Jawed
*@date 2023-04-04
*@tag test Class *
*@domain Core
*@description This class test the functionality to create Docusign recipients on the fly and user can edit the recipients
*and add user as Carbon copy
*@changelog
*/

@IsTest
public with sharing class APT_HelptotheSellerControllerExten_Test{
  /**
  *Test:Data created when a  Docusign recipients exist for the agreement record.
  *
  */
  @IsTest
  public static void getContractWithRecipientTest(){
	string contactRecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Customer (Contact)').getRecordTypeId();
	string userRecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Sales Professional (User)').getRecordTypeId();
	profile p =[select id,name from profile where name='System Administrator'];
	//creating User record
	user u= ApplicationTestDataFactory.getUsers(1,p.id,false)[0];
	insert u;
	//creating Account record
	Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
	insert account;
	//creating Contact record
	Contact keyCon = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
	insert keyCon;
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

	//creating DocuSign user record
	Apttus_DocuApi__DocuSignDefaultRecipient2__c recipient2 =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,null,keyCon.id,false)[0];
	recipient2.recordTypeId = contactRecordTypeId;
	recipient2.APT_Docusign_Recipient_Type__c = 'Customer';
	recipient2.Apttus_DocuApi__Email__c = keyCon.email;
	insert recipient2;

	List<Apttus_DocuApi__DocuSignDefaultRecipient2__c> docusignRecipientList = new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>();
	docusignRecipientList.add(recipient1);
	docusignRecipientList.add(recipient2);

	ContactsSelector mockSelectorContact = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
	ApplicationDatabase mockDatabaseContact = MockUtility.mockDatabase();
	MockUtility.Mocks.startStubbing();
	MockUtility.Mocks.when(mockSelectorContact.selectById((set<Id>)fflib_Match.eq(new Set<Id>{keyCon.id}))).thenReturn(
	new map<Id,contact>(new List<contact>{keyCon}));
	MockUtility.Mocks.stopStubbing();

	APT_DocuSignDefaultRecipient2Selector mockSelectorDocusignRecipient = (APT_DocuSignDefaultRecipient2Selector) MockUtility.mockSelector(APT_DocuSignDefaultRecipient2Selector.class);
	ApplicationDatabase mockDatabaseDocusignRecipient = MockUtility.mockDatabase();
	MockUtility.Mocks.startStubbing();
	MockUtility.Mocks.when(mockSelectorDocusignRecipient.selectByAgreementId((set<Id>)fflib_Match.eq(new Set<Id>{agreement.id}))).thenReturn(
	new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>(new List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>{recipient1}));
	MockUtility.Mocks.stopStubbing();

	Test.startTest();
	map<string,List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>> docReci = APT_HelptotheSellerControllerExtended.getContractRecord(agreement.id);
	Test.stopTest();
	system.assertEquals(docReci.values().size(),1);
  }


  /**
  *Test: Data created to create Docusign recipients for the agreement record.
  *
  */
  @IsTest
  public static void getContractWithoutRecipientTest(){
	//creating User record
	profile p =[select id,name from profile where name='System Administrator'];
	user u= ApplicationTestDataFactory.getUsers(1,p.id,false)[0];
	insert u;
	//creating account record
	Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
	insert account;
	//creating contact record
	Contact keyCon = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
	insert keyCon;
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
	//creating attachments record
	Attachment attach = ApplicationTestDataFactory.getAttachments(1,agreement.id,false)[0];
	insert attach;

	ContactsSelector mockSelectorContact = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
	ApplicationDatabase mockDatabaseContact = MockUtility.mockDatabase();
	MockUtility.Mocks.startStubbing();
	MockUtility.Mocks.when(mockSelectorContact.selectById((set<Id>)fflib_Match.eq(new Set<Id>{keyCon.id}))).thenReturn(
	new map<Id,contact>(new List<contact>{keyCon}));
	MockUtility.Mocks.stopStubbing();

	Test.startTest();
	map<string,List<Apttus_DocuApi__DocuSignDefaultRecipient2__c>> docReci = APT_HelptotheSellerControllerExtended.getContractRecord(agreement.id);
	system.assertEquals(docReci.values().size(),2);
  }

  @IsTest
  public static void addEditCCTest(){
	//getting the recordType id
	Id emailrecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Email(Manually enter the customer details)').getRecordTypeId();
	Id contactRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Customer (Contact)').getRecordTypeId();
	Id userRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Sales Professional (User)').getRecordTypeId();

	//creating User record
	profile p =[select id,name from profile where name='System Administrator'];
	user u= ApplicationTestDataFactory.getUsers(1,p.id,false)[0];
	insert u;
	//creating account record
	Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
	insert account;
	//creating contact record
	Contact keyCon = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
	insert keyCon;
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

	Attachment attach = ApplicationTestDataFactory.getAttachments(1,agreement.id,false)[0];
	insert attach;

	//creating DocuSign user record
	Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientEmail =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
	recipientEmail.recordTypeId = emailrecordTypeId;
	recipientEmail.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
	recipientEmail.APT_Docusign_Recipient_Type__c = 'Sales User';
	recipientEmail.Apttus_DocuApi__Email__c = u.email;
	insert recipientEmail;

	ContactsSelector mockSelectorContact = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
	ApplicationDatabase mockDatabaseContact = MockUtility.mockDatabase();
	MockUtility.Mocks.startStubbing();
	MockUtility.Mocks.when(mockSelectorContact.selectById((set<Id>)fflib_Match.eq(new Set<Id>{keyCon.id}))).thenReturn(
	new map<Id,contact>(new List<contact>{keyCon}));
	MockUtility.Mocks.stopStubbing();

	Test.startTest();
	//Call for Email record type
	APT_HelptotheSellerControllerExtended.addCC('Email');
	APT_HelptotheSellerControllerExtended.editCC(recipientEmail.id);

	Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientUser =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
	recipientUser.recordTypeId = userRecordTypeId;
	recipientUser.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
	recipientUser.APT_Docusign_Recipient_Type__c = 'Sales User';
	recipientUser.Apttus_DocuApi__Email__c = u.email;
	insert recipientUser;
	//Call for User record type
	APT_HelptotheSellerControllerExtended.addCC('User');
	APT_HelptotheSellerControllerExtended.editCC(recipientUser.id);

	Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientCustomer =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
	recipientCustomer.recordTypeId = contactRecordTypeId;
	recipientCustomer.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
	recipientCustomer.APT_Docusign_Recipient_Type__c = 'Customer';
	recipientCustomer.Apttus_DocuApi__Email__c = u.email;
	insert recipientCustomer;
	//Call for Customer record type
	APT_HelptotheSellerControllerExtended.addCC('Customer');
	APT_HelptotheSellerControllerExtended.editCC(recipientCustomer.id);
	Test.stopTest();
	system.assertEquals(recipientUser.Apttus_DocuApi__RecipientType__c,'Carbon Copy');
  }
	/*
  @IsTest
  public static void deleteCCTest(){
	Id emailrecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Email(Manually enter the customer details)').getRecordTypeId();
	Id contactRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Customer (Contact)').getRecordTypeId();
	Id userRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Sales Professional (User)').getRecordTypeId();

	//creating User record
	profile p =[select id,name from profile where name='System Administrator'];
	user u= ApplicationTestDataFactory.getUsers(1,p.id,false)[0];
	insert u;
	//creating account record
	Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
	insert account;
	//creating contact record
	Contact keyCon = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
	insert keyCon;

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
	Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientEmail =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
	recipientEmail.recordTypeId = emailrecordTypeId;
	recipientEmail.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
	recipientEmail.APT_Docusign_Recipient_Type__c = 'Sales User';
	recipientEmail.Apttus_DocuApi__Email__c = u.email;
	insert recipientEmail;

	Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientUser =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
	recipientUser.recordTypeId = userRecordTypeId;
	recipientUser.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
	recipientUser.APT_Docusign_Recipient_Type__c = 'Sales User';
	recipientUser.Apttus_DocuApi__Email__c = u.email;
	insert recipientUser;

	Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientCustomer =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
	recipientCustomer.recordTypeId = contactRecordTypeId;
	recipientCustomer.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
	recipientCustomer.APT_Docusign_Recipient_Type__c = 'Customer';
	recipientCustomer.Apttus_DocuApi__Email__c = u.email;
	insert recipientCustomer;

	Test.startTest();
	APT_HelptotheSellerControllerExtended.deleteCC(recipientEmail.id);

	system.assertEquals([select id from Apttus_DocuApi__DocuSignDefaultRecipient2__c where Apttus_CMDSign__AgreementId__c=:agreement.id].size(),2);
	Test.stopTest();
  }*/
}