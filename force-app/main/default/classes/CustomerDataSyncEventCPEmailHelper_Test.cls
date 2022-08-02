/**
 * @description       : This is a test class for CustomerDataSyncEventCPEmailHelper
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-22-2022
 * @last modified by  : Sreenish Krishnan
 **/
@isTest
public with sharing class CustomerDataSyncEventCPEmailHelper_Test {
	/**
	* @description :deserialise the payload to the wrapper
	* @author Sreenish Krishnan | 07-22-2022 
	**/
	@isTest
	static void deserialisePayload() {
		CustomerDataSync__e event = new CustomerDataSync__e();
		List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper> payloadWrappers = new List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>();
		CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper wr = new CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper();
		wr.emailAddress = 'emailone@test.com.au.dummy';
		payloadWrappers.add(wr);
		event.emails__c = JSON.serialize(payloadWrappers);
		CustomerDataSyncEventCPEmailHelper helper = new CustomerDataSyncEventCPEmailHelper();
		CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper actual = helper.deserialisePayload(event)[0];
		System.assertEquals(wr.emailAddress, actual.emailAddress);
	}

	
	/**
	* @description :logic executed when existing emails are updated from the payload
	* @author Sreenish Krishnan | 07-22-2022 
	**/
	@isTest
	static void updateCPEmailsFromPayload() {

		List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper> ew = new List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>();
		CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper ew1 = new CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper();
		ew1.emailAddress = 'emailone@sample.com.test';
		ew1.isVerified = 'true';
		ew1.isPrimary = 'true';
		ew1.isCredentialEmail = 'false';

		CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper ew2 = new CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper();
		ew2.emailAddress = 'emailtwo@sample.com.test';
		ew2.isVerified = 'false';
		ew2.isPrimary = 'false';
		ew2.isCredentialEmail = 'false';

		ew.add(ew1);
		ew.add(ew2);

		Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>> input = new Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>>();
		Map<String, List<ContactPointEmail>> existing = new Map<String, List<ContactPointEmail>>();
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> customers = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();

		input.put('1234', ew);

		//create test data for existing emails
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';

		//Prepare contacts related to the account
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true);
		Contact ct1 = contacts[0];

		//prepare the contact point emails
		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, personAccount.Id, true);
		ContactPointEmail cpe1 = cpEmails[0];
		cpe1.EmailAddress = 'emailone@sample.com.test';
		cpe1.contact__c = ct1.Id;
		cpe1.Verified__c = false;
		cpe1.Preferred__c = false;

		ContactPointEmail cpe2 = cpEmails[1];
		cpe2.EmailAddress = 'emailtwo@sample.com.test';
		cpe2.contact__c = ct1.Id;
		cpe2.Verified__c = true;
		cpe2.Preferred__c = true;

		//create existing
		existing.put('1234', cpEmails);

		//create upsert result
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> resultMap = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> uResult = new List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		CustomerDataSyncEventCustomerHelper.CustomerUpsertResult u1 = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
		u1.personContactId = ct1.Id;
		u1.recId = personAccount.Id;
		u1.isSuccess = true;

		uResult.add(u1);
		resultMap.put('1234', u1);

		CustomerDataSyncEventCPEmailHelper helper = new CustomerDataSyncEventCPEmailHelper();
		helper.syncContactPointEmail(
			input,
			(Map<String, List<ContactPointEmail>>) existing,
			(Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>) resultMap
		);

		System.assertEquals(true, helper.getCPEmailsUpsertList().size()>0, 'Contact Point Emails Updated');

	}

	/**
	* @description :logic executed when existing emails are inserted from the payload
	* @author Sreenish Krishnan | 07-22-2022 
	**/
	@isTest
	static void insertCPEmailsFromPayload() {

		List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper> ew = new List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>();
		CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper ew1 = new CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper();
		ew1.emailAddress = 'emailone@sample.com.test';
		ew1.isVerified = 'true';
		ew1.isPrimary = 'true';
		ew1.isCredentialEmail = 'false';

		CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper ew2 = new CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper();
		ew2.emailAddress = 'emailtwo@sample.com.test';
		ew2.isVerified = 'false';
		ew2.isPrimary = 'false';
		ew2.isCredentialEmail = 'false';

		ew.add(ew1);
		ew.add(ew2);

		Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>> input = new Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>>();
		Map<String, List<ContactPointEmail>> existing = new Map<String, List<ContactPointEmail>>();
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> customers = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();

		input.put('1234', ew);

		//create test data for existing emails
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';

		//Prepare contacts related to the account
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true);
		Contact ct1 = contacts[0];

		//no contact point emails exist

		//create upsert result
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> resultMap = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> uResult = new List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		CustomerDataSyncEventCustomerHelper.CustomerUpsertResult u1 = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
		u1.personContactId = ct1.Id;
		u1.recId = personAccount.Id;
		u1.isSuccess = true;

		uResult.add(u1);
		resultMap.put('1234', u1);

		CustomerDataSyncEventCPEmailHelper helper = new CustomerDataSyncEventCPEmailHelper();
		helper.syncContactPointEmail(
			input,
			(Map<String, List<ContactPointEmail>>) existing,
			(Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>) resultMap
		);

		System.assertEquals(true, helper.getCPEmailsUpsertList().size()>0, 'Contact Point Emails Inserted');

	}

	/**
	* @description :logic executed when existing emails are deleted from the payload
	* @author Sreenish Krishnan | 07-22-2022 
	**/
	@isTest
	static void deleteCPEmailsFromPayload() {

		List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper> ew = new List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>();
		CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper ew1 = new CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper();
		ew1.emailAddress = 'emailone@sample.com.test';
		ew1.isVerified = 'true';
		ew1.isPrimary = 'true';
		ew1.isCredentialEmail = 'false';

		ew.add(ew1);

		Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>> input = new Map<String, List<CustomerDataSyncEventCPEmailHelper.EmailPayloadWrapper>>();
		Map<String, List<ContactPointEmail>> existing = new Map<String, List<ContactPointEmail>>();
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> customers = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();

		input.put('1234', ew);

		//create test data for existing emails
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';

		//Prepare contacts related to the account
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true);
		Contact ct1 = contacts[0];

		//prepare the contact point emails
		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, personAccount.Id, true);
		ContactPointEmail cpe1 = cpEmails[0];
		cpe1.EmailAddress = 'emailexist1@sample.com.test';
		cpe1.contact__c = ct1.Id;
		cpe1.Verified__c = false;
		cpe1.Preferred__c = false;

		ContactPointEmail cpe2 = cpEmails[1];
		cpe2.EmailAddress = 'emailexist2@sample.com.test';
		cpe2.contact__c = ct1.Id;
		cpe2.Verified__c = true;
		cpe2.Preferred__c = true;

		//create existing
		existing.put('1234', cpEmails);

		//create upsert result
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> resultMap = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> uResult = new List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		CustomerDataSyncEventCustomerHelper.CustomerUpsertResult u1 = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
		u1.personContactId = ct1.Id;
		u1.recId = personAccount.Id;
		u1.isSuccess = true;

		uResult.add(u1);
		resultMap.put('1234', u1);

		CustomerDataSyncEventCPEmailHelper helper = new CustomerDataSyncEventCPEmailHelper();
		helper.syncContactPointEmail(
			input,
			(Map<String, List<ContactPointEmail>>) existing,
			(Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>) resultMap
		);

		System.assertEquals(true, helper.getCPEmailsDeleteList().size()>0, 'Contact Point Emails Deleted');

	}


}