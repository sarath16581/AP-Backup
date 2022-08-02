/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactService selector
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class ContactService_Test {
	@IsTest
	static void applyPhoneNumberFormatting() {
		StringFormattingService service = StringFormattingService.getInstance();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		Contact ct1 = contacts[0];
		ct1.Phone = '(02) 1111 0001';
		ct1.MobilePhone = '0404 11 22 22';
		ct1.VerifiedMobile__c = '0404 11 22 33';
		ct1.HomePhone = '(02) 1111 2222';
		ContactService.getInstance().applyPhoneNumberFormatting(contacts, null);
		String expected = service.formatPhoneNumber(ct1.Phone);
		System.assertEquals(expected, ct1.Phone);
		expected = service.formatPhoneNumber(ct1.MobilePhone);
		System.assertEquals(expected, ct1.MobilePhone);
		expected = service.formatPhoneNumber(ct1.VerifiedMobile__c);
		System.assertEquals(expected, ct1.VerifiedMobile__c);
		expected = service.formatPhoneNumber(ct1.HomePhone);
		System.assertEquals(expected, ct1.HomePhone);

		Contact oldCt1 = ct1.clone(true, true, false, false);
		Map<Id, Contact> oldContactMap = new Map<Id, Contact>{ oldCt1.Id => oldCt1 };
		ct1.Phone = '(02) 4444 1111';
		ct1.MobilePhone = '0404 44 22 11';
		ct1.VerifiedMobile__c = '0404 44 22 11';
		ct1.HomePhone = '(02) 4444 2211';
		ContactService.getInstance().applyPhoneNumberFormatting(contacts, oldContactMap);
		expected = service.formatPhoneNumber(ct1.Phone);
		System.assertEquals(expected, ct1.Phone);
		expected = service.formatPhoneNumber(ct1.MobilePhone);
		System.assertEquals(expected, ct1.MobilePhone);
		expected = service.formatPhoneNumber(ct1.VerifiedMobile__c);
		System.assertEquals(expected, ct1.VerifiedMobile__c);
		expected = service.formatPhoneNumber(ct1.HomePhone);
		System.assertEquals(expected, ct1.HomePhone);

		List<ContactPointPhone> contactPointPhones = ApplicationTestDataFactory.getContactPointPhones(1, accounts[0].Id, true);
		ContactPointPhone ctp1 = contactPointPhones[0];
		ctp1.TelephoneNumber = '(02) 1111 0001';
		ContactService.getInstance().applyPhoneNumberFormatting(contactPointPhones, null);
		expected = service.formatPhoneNumber(ctp1.TelephoneNumber);
		System.assertEquals(expected, ctp1.TelephoneNumber);

		ContactPointPhone oldCtp1 = ctp1.clone(true, true, false, false);
		Map<Id, ContactPointPhone> oldContactPointPhoneMap = new Map<Id, ContactPointPhone>{ oldCtp1.Id => oldCtp1 };
		ctp1.TelephoneNumber = '(02) 3333 4444';
		ContactService.getInstance().applyPhoneNumberFormatting(contactPointPhones, oldContactPointPhoneMap);
		expected = service.formatPhoneNumber(ctp1.TelephoneNumber);
		System.assertEquals(expected, ctp1.TelephoneNumber);
	}

	@isTest
	static void syncContactPointPhonetoContact() {
		//create the dummy data
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc.Id, true);
		Contact ct1 = contacts[0];

		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, acc.Id, true);

		ContactPointPhone cpp1 = cpPhones[0];
		cpp1.Contact__c = ct1.Id;
		cpp1.ParentId = acc.Id;
		cpp1.Preferred__c = false;
		cpp1.TelephoneNumber = '+61491570161';
		cpp1.UniqueMobile__c = false;
		cpp1.Verified__c = false;
		cpp1.PhoneType = 'Mobile';

		ContactPointPhone cpp2 = cpPhones[1];
		cpp2.Contact__c = ct1.Id;
		cpp2.ParentId = acc.Id;
		cpp2.Preferred__c = true;
		cpp2.TelephoneNumber = '+61491570162';
		cpp2.UniqueMobile__c = true;
		cpp2.Verified__c = true;
		cpp2.PhoneType = 'Mobile';

		List<ContactPointPhone> cpRecords = new List<ContactPointPhone>();
		cpRecords.add(cpp1);
		cpRecords.add(cpp2);

		List<ContactPointPhone> cpExisting = new List<ContactPointPhone>();

		//create mock selectors
		ContactPointPhoneSelector cpPhoneSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(ContactPointPhoneSelector.class);
		ContactsSelector contactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				cpPhoneSelector.selectByContact(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ ct1.Id }),
					(Set<Object>) fflib_Match.eq(new Set<Object>())
				)
			)
			.thenReturn(new List<ContactPointPhone>(cpRecords));

		MockUtility.Mocks.when(contactsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ ct1.Id })))
			.thenReturn(new List<Contact>(contacts));

		MockUtility.Mocks.stopStubbing();

		//test block
		Test.startTest();

		ContactService service = ContactService.getInstance();
		List<Contact> assertContacts = service.syncContactPointPhoneToContacts(cpRecords, cpExisting);
		Test.stopTest();

		System.assert(assertContacts.size() > 0, 'Contact Point Phones Records Sync Success');
	}

	@isTest
	static void syncContactPointEmailToContacts() {
		//create the dummy data
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc.Id, true);
		Contact ct1 = contacts[0];

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, acc.Id, true);

		ContactPointEmail cpe1 = cpEmails[0];
		cpe1.EmailAddress = 'emailone@test.com.dummy';
        cpe1.contact__c=ct1.Id;

		ContactPointEmail cpe2 = cpEmails[1];
		cpe2.EmailAddress = 'emailtwo@test.com.dummy';
        cpe2.contact__c=ct1.Id;

		List<ContactPointEmail> cpRecords = new List<ContactPointEmail>();
		cpRecords.add(cpe1);
		cpRecords.add(cpe2);

		List<ContactPointEmail> cpExisting = new List<ContactPointEmail>();

		//create mock selectors
		ContactPointEmailSelector cpEmailSelector = (ContactPointEmailSelector) MockUtility.mockSelector(ContactPointEmailSelector.class);
		ContactsSelector contactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				cpEmailSelector.selectByContact(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ ct1.Id }),
					(Set<Object>) fflib_Match.eq(new Set<Object>())
				)
			)
			.thenReturn(new List<ContactPointEmail>(cpRecords));

		MockUtility.Mocks.when(contactsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ ct1.Id })))
			.thenReturn(new List<Contact>(contacts));

		MockUtility.Mocks.stopStubbing();

		//test block
		Test.startTest();

		ContactService service = ContactService.getInstance();
		System.debug('cpRecords>>' + cpRecords);
		List<Contact> assertContacts = service.syncContactPointEmailToContacts(cpRecords, null);
		Test.stopTest();

		System.assert(assertContacts.size() > 0, 'Contact Point Emails Records Sync Success');
	}
}