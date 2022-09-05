/**************************************************
Type:       ContactUtility_Test
History:
--------------------------------------------------
Jul-2014:  yuanyuan.zhang@bluewolf.com  Created
May-2016:  Lyndon Lavapie Added test2 to test Nominated Parter Contact check
Jun-2016:  Andrew Judd (Salesforce.com)  Extended test2 in line with check to include facilities associated to the Licence
Jun-2018:  TDO-71 : hector.huang@coroma.com.au Unit tests re-written with scenario based tests.
Jul-2019:  Andrew Judd (Salesforce.com)  Added ContactUtility_Test_deleteConApps1 a 2 to test ContactUtility.deleteConApps
Aug-2019:  Andrew Judd (Salesforce.com)  Update to ContactUtility_Test_deleteConApps2 to not trigger Duplicate Check Rules
Aug-2019:  Andrew Judd (Salesforce.com)  Commented out ContactUtility_Test_checkContactEmail_notUnique as conflicting with Contact Duplicate Rule
Mar-2020:  alex.volkov@auspost.com.au	 Added testSetMailingAddress
Oct-2021:  naveen.rajanna@auspost.com.au Changed testSetMailingAddress to meet coverage and changed api version to 52
**************************************************/
@isTest
private class ContactUtility_Test {

	@testSetup
	static void setupTestData() {
		// create lists of accounts to support user creation
		List<Account> accounts = TestDataProvider.createAccount('Test Account', 4);
		accounts[0].BillingCity = 'Test City';
		accounts[0].BillingStreet = 'Test Street';
		accounts[0].BillingPostalCode = '1234';
		accounts[0].Billing_DPID__c = '12345678';
		insert accounts;

		List<Contact> contacts = new list<Contact>();
		for (Integer i = 0; i < 3; i++) {
			contacts.add(
					new Contact(
							FirstName = 'test' + i,
							LastName = 'miao',
							MobilePhone = '041111111' + i,
							Email = 'henry@gmail.com' + i,
							AccountId = accounts[i].Id,
							Contact_Type__c = StarTrack_Constants.CONTACT_TYPE,
							Status__c = StarTrack_Constants.CON_STAT_ACTIVE
					)
			);
		}

		insert contacts;

		// update accounts which have Nominated Partner Contact for checkContactEmail test
		for (Integer i = 0; i < 3; i++) {
			accounts[i].Nominated_Partner_Contact_Incent_User__c = contacts[i].Id;
		}

		update accounts;

		// pull a profile for the user
		Profile profile = [
				SELECT Id
				FROM Profile
				WHERE Name = 'BSP Community User'
		];

		// create lists of users
		List<User> users = new List<User>();
		for (Contact c : contacts) {
			User ur = new User(
					Email = c.Email,
					EmailEncodingKey = 'UTF-8',
					FirstName = c.FirstName,
					LastName = c.LastName,
					ContactId = c.Id,
					LanguageLocaleKey = 'en_US',
					LocaleSidKey = 'en_US',
					ProfileId = profile.Id,
					Alias = c.FirstName,
					TimeZoneSidKey = 'America/Los_Angeles',
					MobilePhone = c.MobilePhone,
					UserName = c.FirstName + System.currentTimeMillis() + '@testorg.com'
			);
			users.add(ur);
		}
		insert users;

        // create a contact that is not associated with any user for deletion test
        Contact delContact = TestDataProvider.createTestContact();
        delContact.accountid = accounts[3].Id;
        delContact.MobilePhone = '0422222222';
        insert delContact;
        
        
    }

	/**
	 * SCENARIO: user details updated successfully
	 **/
	@isTest
	static void ContactUtility_Test_updateUserDetails_updated() {
		test.startTest();
		// old contacts
		Map<id, Contact> oldContacts = new Map<id, Contact>([
				SELECT
						Id, firstname, lastname, MailingStreet, MailingStreet2__c, MailingCity,
						MailingState, MailingPostalCode, MailingCountry,
						Mailing_DPID__c, Phone, MobilePhone
				FROM
						Contact
		]);

		// new contacts with updated MobilePhone
		Map<id, Contact> newContacts = new Map<id, Contact>();
		for (Contact c : [
				SELECT Id, firstname, lastname, MailingStreet, MailingStreet2__c, MailingCity,
						MailingState, MailingPostalCode, MailingCountry,
						Mailing_DPID__c, Phone, MobilePhone
				From Contact
		]) {
			c.MobilePhone = c.MobilePhone + '5';
			newContacts.put(c.Id, c);
		}

		// update contacts
		ContactUtility.updateUserDetails(newContacts, oldContacts);

		test.stopTest();

		// verify the updated user
		for (Integer i = 0; i < 3; i++) {
			User user = [SELECT MobilePhone from User where Email = :('henry@gmail.com' + i)];
			System.assertEquals('+6141111111' + i + '5', user.MobilePhone,
					'ContactUtility_Test_updateUserDetails_updated : Mobile Phone of the user has been updated by adding 5 in the end');
		}
	}

	/**
	 * SCENARIO: phone numbers in contacts will be processed by Util.reversePhoneString method
	 */
	@isTest
	static void ContactUtility_Test_reversePhoneFields_generated() {
		test.startTest();
		// old contacts
		Map<id, Contact> oldContacts = new Map<id, Contact>([
				SELECT Id, Phone, HomePhone, MobilePhone, OtherPhone
				FROM Contact
		]);

		// new contacts with updated MobilePhone
		Map<id, Contact> newContacts = new Map<id, Contact>();
		for (Contact c : [
				SELECT Id, Phone, HomePhone, MobilePhone, OtherPhone
				FROM Contact
		]) {
			c.MobilePhone = c.MobilePhone + '5';
			newContacts.put(c.Id, c);
		}

		// generate contacts with Reverse PhoneFields
		ContactUtility.generateReversePhoneFields(newContacts, oldContacts);

		test.stopTest();

		// verify the updated ReversePhoneFields
		for (Contact c : [SELECT MobilePhone, ReversePhoneFields__c FROM Contact]) {
			System.assertEquals(Util.reversePhoneString(c.MobilePhone), c.ReversePhoneFields__c,
					'ContactUtility_Test_updateUserDetails_updated : ReversePhoneFields__c has been processed according to Util.reversePhoneString');
		}
	}

	/**
	 * SCENARIO: try to delete contact when it is locked
	 **/
	@isTest
	static void ContactUtility_Test_deleteUserContact_locked() {
		test.startTest();
		// lock the contact
		Contact contact = [SELECT Id From Contact where Email = 'dsf@df.com' LIMIT 1];
		contact.Delete_locked__c = true;
		contact.Delete_Locked_Reason__c = 'Lodgement User';
		update contact;

		test.stopTest();

		// verify the error message of trying to delete locked contact
		try {
			delete contact;
		} catch (System.DmlException ex) {
			System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, ex.getDmlType(0),
					'ContactUtility_Test_deleteUserContact_locked : Error will show when trying to delete the locked contact');
		}
	}

	/**
	 * SCENARIO: try to delete contact when it is unlocked
	 **/
	@isTest
	static void ContactUtility_Test_deleteUserContact_unlocked() {
		test.startTest();
		// unlock the contact
		Contact contact = [SELECT Id From Contact where Email = 'dsf@df.com' LIMIT 1];
		contact.Delete_Locked__c = false;
		contact.Delete_Locked_Reason__c = '';
		update contact;

		delete contact;
		// verify the error message of trying to query unlocked contact after it has been deleted
		List<Contact> tempCons = [SELECT id FROM contact WHERE id = :contact.id];
		system.assertEquals(0, tempCons.size(),
				'ContactUtility_Test_deleteUserContact_locked : 0 record will show when trying to query the contact after deletion');
	}

	/**
	 * SCENARIO: Nominated Partner Contact has the same email address
	 **/
/*
    @isTest
    static void ContactUtility_Test_checkContactEmail_notUnique() {
        test.startTest();
        // update contacts with changed email
        for (Contact c : [
                SELECT  Email From Contact
        ]) {
            c.Email= 'henry@gmail.com0';
            update c;
        }
        //TDO_TODO: Trigger and assert the error message of UNIQUE_EMAIL_ADDRESS , thi users a Flow.Interview behind and need more time as planned to understand the out put

        test.stopTest();
    }
*/
	//AJ BAM Test Delete contact applications.
	//Confirm that an Active Contact with an Active Contact App can not be deleted
	@isTest
	static void ContactUtility_Test_deleteConApps1() {
		test.startTest();
		// Create BAM records
		Map<String, Id> recordIdMap = new Map<String, Id>();

		//Create test data
		recordIdMap = BAMTestUtility.createBamBasicRecords();

		//Get contact and con app Ids
		Id contactId = recordIdMap.get('con');
		Id conAppId = recordIdMap.get('conapp');

		//Get contact
		Contact contact = [SELECT Id, Status__c FROM Contact WHERE Id = :contactId];
		test.stopTest();

		//Verify the error message of trying to delete Active Contact with Active Contact App
		try {
			delete contact;
		} catch (System.DmlException ex) {
			System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, ex.getDmlType(0),
					'The class ContactUtility.deleteConApps should have raised an error due to deletion of an Active contact with Active contact apps');
		}
	}
	//AJ BAM Test Delete contact applications.
	//Confirm that an Inactive Contact with an Active Contact App can be deleted as part of a merge
	@isTest
	static void ContactUtility_Test_deleteConApps2() {
		test.startTest();
		// Create BAM records
		Map<String, Id> recordIdMap = new Map<String, Id>();

		//Create test data
		recordIdMap = BAMTestUtility.createBamBasicRecords();

		//Get Ids
		Id accId = recordIdMap.get('acc');
		Id contactId = recordIdMap.get('con');
		Id conAppId = recordIdMap.get('conapp');

		//Get contact and update status to Inactive
		Contact contactLose = [SELECT Id, Status__c FROM Contact WHERE Id = :contactId];
		contactLose.Status__c = 'Inactive';
		update contactLose;

		//Create a win contact to merge contact above into
		Contact contactWin = TestDataProvider.createTestContact();
		contactWin.accountid = accId;
		contactWin.MobilePhone = '0422222233';
		contactWin.Email = 'dsf123@df.com';
		contactWin.FirstName = 'sss';
		contactWin.LastName = 'aaa';
		insert contactWin;

		test.stopTest();

		//Merge contacts and confirm merge success. This should result in deletion of lose contact and lose contact's contact apps
		merge contactWin contactLose;

		//get old contact and contact app
		Contact[] con = [SELECT Id FROM Contact WHERE Id = :contactId];
		BAMContactApplication__c[] conapp = [SELECT Id FROM BAMContactApplication__c WHERE Id = :conAppId];

		//Verify that the conact and contact app was deleted
		System.assertEquals(0, con.size(), 'The contact should have been deleted by the merge');
		System.assertEquals(0, conapp.size(), 'The contact app should have been deleted by the merge, as a result of the trigger ContactUtility.deleteConApps');
	}

	/**
	* @description Test for setMailingAddress method
	*/
	@IsTest
	static void testSetMailingAddress() {
		/** Get a test account */
		Account vAcc = [SELECT Id FROM Account WHERE Billing_DPID__c != NULL LIMIT 1];
		/** Instantiate a new contact without an address */
		Contact vNewContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = vAcc.Id, Email = 'test@test.com.invalid');
		Test.startTest();
		/** Insert the contact */
		Database.insert(vNewContact);
		Test.stopTest();
		/** Assert that the address was inherited from parent account */
		Contact vInsertedContact = [SELECT Mailing_DPID__c, MailingDPID__c FROM Contact WHERE Id = :vNewContact.Id];
		System.assertNotEquals(null, vInsertedContact.Mailing_DPID__c);
		System.assertNotEquals(null, vInsertedContact.MailingDPID__c);
	}
}