/**
 * @description       : This is a test class for CustomerDataSyncEventCPPhoneHelper
 * @author            : Sreenish Krishnan
 * @domain            : Connecetd Customer
 * @last modified on  : 07-26-2022
 * @last modified by  : Sreenish Krishnan
 **/
@isTest
public with sharing class CustomerDataSyncEventCPPhoneHelper_Test {
	@isTest
	static void deserialisePayload() {
		CustomerDataSync__e event = new CustomerDataSync__e();
		List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper> payloadWrappers = new List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>();
		CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper wr = new CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper();
		wr.phone = '+61452626262';
		payloadWrappers.add(wr);
		event.phones__c = JSON.serialize(payloadWrappers);
		CustomerDataSyncEventCPPhoneHelper helper = new CustomerDataSyncEventCPPhoneHelper();
		CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper actual = helper.deserialisePayload(event)[0];
		System.assertEquals(wr.phone, actual.phone);
	}

	@isTest
	static void updateCPPhonesFromPayload() {
        // =====================================
		// Data Preparation
		// =====================================

        //wrappers created
		List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper> pw = new List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>();
		CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper pw1 = new CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper();
        pw1.phone='+61425363727';
        pw1.isPrimary='true';
        pw1.isVerified='true';
        pw1.type='Mobile';
        pw1.isUnique='true';

        //CPPhones created
		CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper pw2 = new CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper();
        pw2.phone='+61425363728';
        pw2.isPrimary='false';
        pw2.isVerified='false';
        pw2.type='Mobile';
        pw2.isUnique='true';

        pw.add(pw1);
        pw.add(pw2);

        Map<String, List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>> input = new Map<String, List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>>();
		Map<String, List<ContactPointPhone>> existing = new Map<String, List<ContactPointPhone>>();
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> customers = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();

        //apcn vs cpphones map
		input.put('1125338659', pw);

        //create test data for existing phones
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1125338659';
		personAccount.apcn__pc = '1125338659';

		//Prepare contacts related to the account
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true);
		Contact ct1 = contacts[0];

        //prepare the contact point phones
		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, personAccount.Id, true);
		ContactPointPhone cpp1 = cpPhones[0];
		cpp1.TelephoneNumber = '+61425363727';
		cpp1.contact__c = ct1.Id;
		cpp1.Verified__c = false;
		cpp1.Preferred__c = false;
		cpp1.PhoneType = 'Mobile';

        ContactPointPhone cpp2 = cpPhones[1];
		cpp2.TelephoneNumber = '+61425363728';
		cpp2.contact__c = ct1.Id;
		cpp2.Verified__c = true;
		cpp2.Preferred__c = true;
		cpp2.PhoneType = 'Mobile';

		//create existing
		existing.put('1125338659', cpPhones);

        //create upsert result
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> resultMap = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> uResult = new List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		CustomerDataSyncEventCustomerHelper.CustomerUpsertResult u1 = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
		u1.personContactId = ct1.Id;
		u1.recId = personAccount.Id;
		u1.isSuccess = true;

		uResult.add(u1);
		resultMap.put('1125338659', u1);


        // =====================================
		// Testing
		// =====================================
		Test.startTest();

		CustomerDataSyncEventCPPhoneHelper helper = new CustomerDataSyncEventCPPhoneHelper();
		helper.syncContactPointPhone(
			input,
			(Map<String, List<ContactPointPhone>>) existing,
			(Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>) resultMap
		);

		Test.stopTest();

        // =====================================
		// Assert
		// =====================================
		System.assertEquals(true, helper.getCPPhonesUpsertList().size() > 0, 'Contact Point Phones Updated');

	}

    @isTest
	static void insertCPPhonesFromPayload() {
        // =====================================
		// Data Preparation
		// =====================================

        //wrappers created
		List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper> pw = new List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>();
		CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper pw1 = new CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper();
        pw1.phone='+61425363727';
        pw1.isPrimary='true';
        pw1.isVerified='true';
        pw1.type='Mobile';
        pw1.isUnique='true';

        //CPPhones created
		CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper pw2 = new CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper();
        pw2.phone='+61425363728';
        pw2.isPrimary='false';
        pw2.isVerified='false';
        pw2.type='Mobile';
        pw2.isUnique='true';

        pw.add(pw1);
        pw.add(pw2);

        Map<String, List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>> input = new Map<String, List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>>();
		Map<String, List<ContactPointPhone>> existing = new Map<String, List<ContactPointPhone>>();
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> customers = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();

        //apcn vs cpphones map
		input.put('1125338659', pw);

        //create test data for existing phones
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1125338659';
		personAccount.apcn__pc = '1125338659';

		//Prepare contacts related to the account
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true);
		Contact ct1 = contacts[0];

        //prepare the contact point phones
		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, personAccount.Id, true);
		ContactPointPhone cpp1 = cpPhones[0];
		cpp1.TelephoneNumber = '+61425363729';
		cpp1.contact__c = ct1.Id;
		cpp1.Verified__c = false;
		cpp1.Preferred__c = false;
		cpp1.PhoneType = 'Mobile';

        ContactPointPhone cpp2 = cpPhones[1];
		cpp2.TelephoneNumber = '+61425363730';
		cpp2.contact__c = ct1.Id;
		cpp2.Verified__c = true;
		cpp2.Preferred__c = true;
		cpp2.PhoneType = 'Mobile';

		//create existing
		existing.put('1125338659', cpPhones);

        //create upsert result
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> resultMap = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> uResult = new List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		CustomerDataSyncEventCustomerHelper.CustomerUpsertResult u1 = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
		u1.personContactId = ct1.Id;
		u1.recId = personAccount.Id;
		u1.isSuccess = true;

		uResult.add(u1);
		resultMap.put('1125338659', u1);


        // =====================================
		// Testing
		// =====================================
		Test.startTest();

		CustomerDataSyncEventCPPhoneHelper helper = new CustomerDataSyncEventCPPhoneHelper();
		helper.syncContactPointPhone(
			input,
			(Map<String, List<ContactPointPhone>>) existing,
			(Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>) resultMap
		);

		Test.stopTest();

        // =====================================
		// Assert
		// =====================================
		System.assertEquals(true, helper.getCPPhonesUpsertList().size() > 0, 'Contact Point Phones Inserted');

	}

    @isTest
    static void deleteCPPhonesFromPayload() {
        // =====================================
		// Data Preparation
		// =====================================

        //wrappers created
		List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper> pw = new List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>();
		CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper pw1 = new CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper();
        pw1.phone='+61425363727';
        pw1.isPrimary='true';
        pw1.isVerified='true';
        pw1.type='Mobile';
        pw1.isUnique='true';

        pw.add(pw1);

        Map<String, List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>> input = new Map<String, List<CustomerDataSyncEventCPPhoneHelper.PhonePayloadWrapper>>();
		Map<String, List<ContactPointPhone>> existing = new Map<String, List<ContactPointPhone>>();
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> customers = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();

        //apcn vs cpphones map
		input.put('1125338659', pw);

        //create test data for existing phones
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1125338659';
		personAccount.apcn__pc = '1125338659';

		//Prepare contacts related to the account
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true);
		Contact ct1 = contacts[0];

        //prepare the contact point phones
		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, personAccount.Id, true);
		ContactPointPhone cpp1 = cpPhones[0];
		cpp1.TelephoneNumber = '+61425363728';
		cpp1.contact__c = ct1.Id;
		cpp1.Verified__c = false;
		cpp1.Preferred__c = false;
		cpp1.PhoneType = 'Mobile';

        ContactPointPhone cpp2 = cpPhones[1];
		cpp2.TelephoneNumber = '+61425363729';
		cpp2.contact__c = ct1.Id;
		cpp2.Verified__c = true;
		cpp2.Preferred__c = true;
		cpp2.PhoneType = 'Mobile';

		//create existing
		existing.put('1125338659', cpPhones);

        //create upsert result
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> resultMap = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> uResult = new List<CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		CustomerDataSyncEventCustomerHelper.CustomerUpsertResult u1 = new CustomerDataSyncEventCustomerHelper.CustomerUpsertResult();
		u1.personContactId = ct1.Id;
		u1.recId = personAccount.Id;
		u1.isSuccess = true;

		uResult.add(u1);
		resultMap.put('1125338659', u1);


        // =====================================
		// Testing
		// =====================================
		Test.startTest();

		CustomerDataSyncEventCPPhoneHelper helper = new CustomerDataSyncEventCPPhoneHelper();
		helper.syncContactPointPhone(
			input,
			(Map<String, List<ContactPointPhone>>) existing,
			(Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>) resultMap
		);

		Test.stopTest();

        // =====================================
		// Assert
		// =====================================
		System.assertEquals(true, helper.getCPPhonesUpsertList().size() > 0, 'Contact Point Phones Deleted');

	}

}