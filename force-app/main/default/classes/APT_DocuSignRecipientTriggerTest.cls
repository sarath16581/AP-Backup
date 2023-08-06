/**
*Description: This apex class is test class for apex trigger - APT_DocuSignRecipientTrigger.
*Created By - Mahesh Patel
*Created Date - 8th Dec, 2020
*ChangeLog : 2023-05-24 - Nasir Jawed - fixed test class failure and covered test coverage
**/
@isTest
private class APT_DocuSignRecipientTriggerTest
{
	@TestSetup
	static void testDataSetup(){
		//Get Profile
		Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];

		//Create User
		User user = APT_TestUtil2.createUser(profile.Id);
		insert user;
		System.Assert(user.Id != null);

		//Create Contact
		Contact contact = APT_TestUtils.createContact();
		insert contact;

		//Create Agreement
		Apttus__APTS_Agreement__c agreement = APT_TestUtils.createAgreement(contact.Id);
		insert agreement;
		System.Assert(agreement.Id != null);
	}

	@IsTest
	static void testMaxOneContactUserRecipientsValidation()
	{
		User user = [SELECT Id FROM User LIMIT 1];

		System.runAs(user)
		{
			//Creating a User with profile
			profile p =[select id,name from profile where name='System Administrator'];
			user u= ApplicationTestDataFactory.getUsers(1,p.id,false)[0];
			u.Work_Center_Code__c ='123456';
			insert u;
			//Fetch Contact
			Contact contact = [SELECT Id FROM Contact LIMIT 1];

			//Fetch Agreement
			Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

			Test.StartTest();

			//Create DocuSign Recipients
			Apttus_DocuApi__DocuSignDefaultRecipient2__c docSignRecipContact = APT_TestUtil2.createDocuSignRecipient(agreement.Id, APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_CONTACT, contact.Id, null, 'Test FName', 'Test LName', 'testuser@auspost.com');
			insert docSignRecipContact;
			system.assert(docSignRecipContact.Id !=null);

			Id userRecordTypeId =Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Sales Professional (User)').getRecordTypeId();


			Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientUser =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
			recipientUser.recordTypeId = userRecordTypeId;
			recipientUser.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
			recipientUser.APT_Docusign_Recipient_Type__c = 'Sales User';
			recipientUser.Apttus_DocuApi__Email__c = u.email;
			insert recipientUser;
			system.assert(recipientUser.Id !=null);

			Test.StopTest();
		}
	}

	@IsTest
	static void testEmailRecordUpdateFromContactToUser()
	{
		User user = [SELECT Id FROM User LIMIT 1];

		System.runAs(user)
		{
			profile p =[select id,name from profile where name='System Administrator'];
			user u= ApplicationTestDataFactory.getUsers(1,p.id,false)[0];
			u.Work_Center_Code__c ='123456';
			insert u;
			Id emailrecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Email(Manually enter the customer details)').getRecordTypeId();


			//Fetch Contact
			Contact contact = [SELECT Id FROM Contact LIMIT 1];

			//Fetch Agreement
			Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

			Test.StartTest();

			//Create DocuSign Recipients
			Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientEmail =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
			recipientEmail.recordTypeId = emailrecordTypeId;
			recipientEmail.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
			recipientEmail.APT_Docusign_Recipient_Type__c = 'Sales User';
			recipientEmail.Apttus_DocuApi__Email__c = u.email;
			insert recipientEmail;

			//Update DocuSign Recipients
			recipientEmail.Apttus_DocuApi__Email__c = 'testuser@auspost.com';
			update recipientEmail;

			Apttus_DocuApi__DocuSignDefaultRecipient2__c updatedRecord = [SELECT Apttus_DocuApi__Email__c FROM Apttus_DocuApi__DocuSignDefaultRecipient2__c WHERE Id =:recipientEmail.Id LIMIT 1];

			system.assertEquals('zztest1@test1.test1.com',updatedRecord.Apttus_DocuApi__Email__c);

			Test.StopTest();
		}
	}

	@IsTest
	static void testEmailRecordUpdateFromUserToContact()
	{
		User user = [SELECT Id FROM User LIMIT 1];

		System.runAs(user)
		{
			profile p =[select id,name from profile where name='System Administrator'];
			user u= ApplicationTestDataFactory.getUsers(1,p.id,false)[0];
			u.Work_Center_Code__c ='123456';
			insert u;
			Id emailrecordTypeId = Schema.SObjectType.Apttus_DocuApi__DocuSignDefaultRecipient2__c.getRecordTypeInfosByName().get('Email(Manually enter the customer details)').getRecordTypeId();

			//Fetch Contact
			Contact contact = [SELECT Id FROM Contact LIMIT 1];

			//Fetch Agreement
			Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

			Test.StartTest();

			//Create DocuSign Recipients
			Apttus_DocuApi__DocuSignDefaultRecipient2__c recipientEmail =APT_TestDataFactory.getDocuSignRecipientsRecord(1,agreement.id,u.id,null,false)[0];
			recipientEmail.recordTypeId = emailrecordTypeId;
			recipientEmail.Apttus_DocuApi__RecipientType__c ='Carbon Copy';
			recipientEmail.APT_Docusign_Recipient_Type__c = 'Sales User';
			recipientEmail.Apttus_DocuApi__Email__c = u.email;
			insert recipientEmail;

			system.assert(recipientEmail.Id != null);

			//Update DocuSign Recipients
			recipientEmail.Apttus_DocuApi__Email__c = 'testuser@test.com';
			update recipientEmail;

			Apttus_DocuApi__DocuSignDefaultRecipient2__c updatedRecord = [SELECT Apttus_DocuApi__Email__c FROM Apttus_DocuApi__DocuSignDefaultRecipient2__c WHERE Id =:recipientEmail.Id LIMIT 1];

			system.assertEquals('zztest1@test1.test1.com',updatedRecord.Apttus_DocuApi__Email__c);

			Test.StopTest();
		}
	}

	@IsTest
	static void testException()
	{
		User user = [SELECT Id FROM User LIMIT 1];

		System.runAs(user)
		{
			Test.StartTest();

			try
			{
				//Fetch Agreement
				Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

				//Create DocuSign Recipients
				Apttus_DocuApi__DocuSignDefaultRecipient2__c docSignRecipEmail = APT_TestUtil2.createDocuSignRecipient(agreement.Id, APT_Constants.DOCUSIGN_RECIPIENT_RECORDTYPE_EMAIL, null, null, null, null, null);
				insert docSignRecipEmail;

				//Update DocuSign Recipients
				docSignRecipEmail.Apttus_DocuApi__Email__c = 'testuser@test.com';
				update docSignRecipEmail;
			}
			catch(Exception ex)
			{
				System.assert(ex.getMessage().contains('error'), ex.getMessage());
			}

			Test.StopTest();
		}
	}
}