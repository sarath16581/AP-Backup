/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactPointPhoneDomainModule
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class ContactPointPhoneDomainModule_Test {
	@IsTest
	static void onBeforeInsert() {
		ContactService mockService = (ContactService) MockUtility.mockUtility(ContactService.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		ContactPointPhoneDomainModule module = ContactPointPhoneDomainModule.newInstance();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<ContactPointPhone> contactPointPhones = ApplicationTestDataFactory.getContactPointPhones(1, accounts[0].Id, true);

		Test.startTest();

		module.onBeforeInsert(contactPointPhones, uow);
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.applyPhoneNumberFormatting(
				(List<ContactPointPhone>) fflib_Match.eq(contactPointPhones),
				(Map<Id, ContactPointPhone>) fflib_Match.isNull()
			);

		// PMD warning
		System.assert(true);

		Test.stopTest();
	}

	@IsTest
	static void onBeforeUpdate() {
		ContactService mockService = (ContactService) MockUtility.mockUtility(ContactService.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		ContactPointPhoneDomainModule module = ContactPointPhoneDomainModule.newInstance();
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<ContactPointPhone> contactPointPhones = ApplicationTestDataFactory.getContactPointPhones(1, accounts[0].Id, true);
		ContactPointPhone ctp1 = contactPointPhones[0];
		ContactPointPhone oldCtp1 = ctp1.clone(true, true, false, false);
		Map<Id, ContactPointPhone> existingRecords = new Map<Id, ContactPointPhone>{ oldCtp1.Id => oldCtp1 };

		Test.startTest();

		module.onBeforeUpdate(contactPointPhones, existingRecords, uow);
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.applyPhoneNumberFormatting(
				(List<ContactPointPhone>) fflib_Match.eq(contactPointPhones),
				(Map<Id, ContactPointPhone>) fflib_Match.eq(existingRecords)
			);

		// PMD warning
		System.assert(true);

		Test.stopTest();
	}

	@isTest
	static void onAfterInsert() {
		ContactService mockService = (ContactService) MockUtility.mockUtility(ContactService.class);

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

		List<ContactPointPhone> cpPhones1 = new List<ContactPointPhone>();
		cpPhones1.add(cpp1);
		cpPhones1.add(cpp2);

		//mock selectors
		ContactPointPhoneSelector cpPhoneSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(ContactPointPhoneSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				cpPhoneSelector.selectByContact(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ ct1.Id }),
					(Set<Object>) fflib_Match.eq(new Set<Object>())
				)
			)
			.thenReturn(new List<ContactPointPhone>(cpPhones1));

		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		//test start and stop
		Test.startTest();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointPhoneDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		System.debug('cpPhones1 >>' + cpPhones1);
		System.debug('uow >>' + uow);
		ContactPointPhoneDomainModule module = ContactPointPhoneDomainModule.newInstance();
		module.onAfterInsert((List<SObject>) cpPhones1, uow);

		Test.stopTest();
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointPhoneToContacts(
				(List<ContactPointPhone>) fflib_Match.eq(cpPhones1),
				(List<ContactPointPhone>) fflib_Match.isNull()
			);
	}

	@isTest
	static void onAfterUpdate() {
		ContactService mockService = (ContactService) MockUtility.mockUtility(ContactService.class);

		//create the dummy data
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc.Id, true);
		Contact ct1 = contacts[0];

		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, acc.Id, true);
		Map<Id, ContactPointPhone> existing = new Map<Id, ContactPointPhone>{ cpPhones[0].Id => cpPhones[0] };

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

		List<ContactPointPhone> cpPhones1 = new List<ContactPointPhone>();
		cpPhones1.add(cpp1);
		cpPhones1.add(cpp2);

		//mock selectors
		ContactPointPhoneSelector cpPhoneSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(ContactPointPhoneSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				cpPhoneSelector.selectByContact(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ ct1.Id }),
					(Set<Object>) fflib_Match.eq(new Set<Object>())
				)
			)
			.thenReturn(new List<ContactPointPhone>(cpPhones1));

		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		//test start and stop
		Test.startTest();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointPhoneDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		ContactPointPhoneDomainModule module = ContactPointPhoneDomainModule.newInstance();
		module.onAfterUpdate((List<SObject>) cpPhones1, (Map<Id, SObject>) existing, uow);

		Test.stopTest();
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointPhoneToContacts(
				(List<ContactPointPhone>) fflib_Match.eq(cpPhones1),
				(List<ContactPointPhone>) fflib_Match.isNull()
			);
	}
	@isTest
	static void onAfterDelete() {
		ContactService mockService = (ContactService) MockUtility.mockUtility(ContactService.class);

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

		List<ContactPointPhone> cpPhones1 = new List<ContactPointPhone>();
		cpPhones1.add(cpp1);
		cpPhones1.add(cpp2);

		//mock selectors
		ContactPointPhoneSelector cpPhoneSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(ContactPointPhoneSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				cpPhoneSelector.selectByContact(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ ct1.Id }),
					(Set<Object>) fflib_Match.eq(new Set<Object>())
				)
			)
			.thenReturn(new List<ContactPointPhone>(cpPhones1));

		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		//test start and stop
		Test.startTest();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointPhoneDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		ContactPointPhoneDomainModule module = ContactPointPhoneDomainModule.newInstance();
		module.onAfterDelete((List<SObject>) cpPhones1, uow);

		Test.stopTest();
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointPhoneToContacts(
				(List<ContactPointPhone>) fflib_Match.isNull(),
				(List<ContactPointPhone>) fflib_Match.eq(cpPhones1)
			);
	}
}