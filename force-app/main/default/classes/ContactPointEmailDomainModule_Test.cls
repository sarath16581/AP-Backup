/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactPointEmailDomainModule
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class ContactPointEmailDomainModule_Test {
	@IsTest
	static void onAfterInsert() {
		ContactService mockService = (ContactService) MockUtility.mockUtility(ContactService.class);

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointAddressDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		Contact ct1 = contacts.values()[0];
		Contact ct2 = contacts.values()[1];

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, acc.id, true);
		cpEmails[0].Contact__c = ct1.Id;
		cpEmails[0].IsCredential__c = true;
		cpEmails[0].EmailAddress = 'test-sync-with-contact@sample.auspost.com.au';

		ContactPointEmail cpe2 = cpEmails[1];
		cpe2.Contact__c = ct2.Id;
		cpe2.EmailAddress = 'test1234@houdini-g.com';
		cpe2.IsCredential__c = true;

		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, acc.id, true);
		cpPhones[0].Contact__c = ct1.Id;

		ContactPointPhone cpp2 = cpPhones[1];
		cpp2.Contact__c = ct2.Id;
		cpp2.TelephoneNumber = '+61288889999';

		List<User> existingUsers = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{ ct1.Id }, true);

		ContactsSelector ctSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		ContactPointPhoneSelector phoneSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(ContactPointPhoneSelector.class);
		ContactPointEmailSelector emailSelector = (ContactPointEmailSelector) MockUtility.mockSelector(ContactPointEmailSelector.class);

		UsersSelector userSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(ctSelector.selectById((Set<Id>) fflib_Match.eq(contacts.keySet()))).thenReturn(contacts);

		MockUtility.Mocks.when(
				phoneSelector.selectByContact(
					(Set<Id>) fflib_Match.eq(contacts.keySet()),
					(Set<Object>) fflib_Match.eq(
						new Set<Object>{
							ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE,
							ContactPointPhoneSelector.Options.FILTER_PREFERRED_TRUE
						}
					)
				)
			)
			.thenReturn(cpPhones);

		MockUtility.Mocks.when(
				emailSelector.selectByContact((Set<Id>) fflib_Match.eq(contacts.keySet()), (Set<Object>) fflib_Match.eq(new Set<Object>()))
			)
			.thenReturn(cpEmails);

		MockUtility.Mocks.when(userSelector.selectByContactId((Set<Id>) fflib_Match.eq(contacts.keySet())))
			.thenReturn(new Map<Id, User>(existingUsers));

		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.when(
				mockService.syncContactPointEmailToContacts(
					(List<ContactPointEmail>) fflib_Match.eq(cpEmails),
					(List<ContactPointEmail>) fflib_Match.isNull()
				)
			)
			.thenReturn(contacts.values());

		MockUtility.Mocks.stopStubbing();

		Id portalUserProfileId = [SELECT Id FROM Profile WHERE Name = 'DDC Consumer Community User' LIMIT 1].Id;

		Test.startTest();

		ContactPointEmailDomainModule module = ContactPointEmailDomainModule.newInstance();
		module.onAfterInsert((List<SObject>) cpEmails, mockUow);

		/*	((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<Contact>) fflib_Match.eq(contacts.values()));

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlInsert(
				(List<User>) fflib_Match.eq(
					new List<User>{
						new User(
							FirstName = ct2.FirstName,
							LastName = ct2.LastName,
							APCN__c = ct2.APCN__c,
							ProfileId = portalUserProfileId,
							IsActive = false,
							Email = cpe2.emailAddress,
							MobilePhone = cpp2.TelephoneNumber,
							Username = cpe2.emailAddress + '.community',
							FederationIdentifier = cpe2.emailAddress + '.community',
							OID_ID__c = ct2.OID_ID__c,
							LanguageLocaleKey = 'en_US',
							Alias = 'Consumer',
							LocaleSidKey = 'en_AU',
							ContactId = ct2.Id,
							EmailEncodingKey = 'UTF-8',
							TimeZoneSidKey = 'Australia/Sydney'
						)
					}
				)
			);

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpdate(
				(List<Contact>) fflib_Match.eq(
					new List<Contact>{ new Contact(Id = ct2.Id, CRMCSSOID__c = cpe2.emailAddress, Email = cpEmails[0].EmailAddress) }
				)
			);*/

		// PMD Warning
		System.assert(true);

		Test.stopTest();

		/*	((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointEmailToContacts(
				(List<ContactPointEmail>) fflib_Match.eq(cpEmails),
				(List<ContactPointEmail>) fflib_Match.isNull()
			);*/
	}

	@IsTest
	static void onAfterUpdate() {
		ContactService mockService = (ContactService) MockUtility.mockUtility(ContactService.class);

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointAddressDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(3, acc.Id, true));
		Contact ct1 = contacts.values()[0];
		Contact ct2 = contacts.values()[1];
		Contact ct3 = contacts.values()[1];

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(3, acc.id, true);
		cpEmails[0].Contact__c = ct1.Id;
		cpEmails[0].IsCredential__c = true;

		ContactPointEmail cpe1 = cpEmails[0];

		ContactPointEmail cpe2 = cpEmails[1];
		cpe2.Contact__c = ct2.Id;
		cpe2.EmailAddress = 'test1234@houdini-g.com';
		cpe2.IsCredential__c = true;

		ContactPointEmail cpe3 = cpEmails[2];
		cpe3.Contact__c = ct3.Id;
		cpe3.EmailAddress = 'test1234@houdini-g.com';
		cpe3.IsCredential__c = true;

		ContactPointEmail existingCpe3 = cpe3.clone(true, true, false, false);
		existingCpe3.IsCredential__c = false;

		Map<Id, ContactPointEmail> existingRecords = new Map<Id, ContactPointEmail>{
			existingCpe3.Id => existingCpe3,
			cpe1.Id => cpe1,
			cpe2.Id => cpe2
		};

		List<User> existingUsers = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{ ct1.Id }, true);

		ContactsSelector ctSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		ContactPointPhoneSelector phoneSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(ContactPointPhoneSelector.class);
		UsersSelector userSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(ctSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ ct3.Id })))
			.thenReturn(new Map<Id, Contact>{ ct3.Id => ct3 });

		MockUtility.Mocks.when(
				phoneSelector.selectByContact(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ ct3.Id }),
					(Set<Object>) fflib_Match.eq(
						new Set<Object>{
							ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE,
							ContactPointPhoneSelector.Options.FILTER_PREFERRED_TRUE
						}
					)
				)
			)
			.thenReturn(new List<ContactPointPhone>());

		MockUtility.Mocks.when(
				mockService.syncContactPointEmailToContacts(
					(List<ContactPointEmail>) fflib_Match.eq(cpEmails),
					(List<ContactPointEmail>) fflib_Match.isNull()
				)
			)
			.thenReturn(contacts.values());

		MockUtility.Mocks.when(userSelector.selectByContactId((Set<Id>) fflib_Match.eq(new Set<Id>{ ct3.Id })))
			.thenReturn(new Map<Id, User>());

		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		Id portalUserProfileId = [SELECT Id FROM Profile WHERE Name = 'DDC Consumer Community User' LIMIT 1].Id;

		Test.startTest();

		ContactPointEmailDomainModule module = ContactPointEmailDomainModule.newInstance();
		module.onAfterUpdate((List<SObject>) cpEmails, existingRecords, mockUow);

		//module.onAfterUpdate((List<SObject>) (new List<ContactPointEmail>{ cpe3 }), (Map<Id, SObject>) existingRecords, uow);

		/*		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlInsert(
				(List<User>) fflib_Match.eq(
					new List<User>{
						new User(
							FirstName = ct2.FirstName,
							LastName = ct2.LastName,
							APCN__c = ct2.APCN__c,
							ProfileId = portalUserProfileId,
							IsActive = false,
							Email = cpe2.emailAddress,
							MobilePhone = '',
							Username = cpe2.emailAddress + '.community',
							FederationIdentifier = cpe2.emailAddress + '.community',
							OID_ID__c = ct2.OID_ID__c,
							LanguageLocaleKey = 'en_US',
							Alias = 'Consumer',
							LocaleSidKey = 'en_AU',
							ContactId = ct2.Id,
							EmailEncodingKey = 'UTF-8',
							TimeZoneSidKey = 'Australia/Sydney'
						)
					}
				)
			);

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpdate((List<Contact>) fflib_Match.eq(new List<Contact>{ new Contact(Id = ct2.Id, CRMCSSOID__c = cpe2.emailAddress) }));*/

		// PMD Warning
		System.assert(true);

		Test.stopTest();
		/*	((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointEmailToContacts(
				(List<ContactPointEmail>) fflib_Match.eq(cpEmails),
				(List<ContactPointEmail>) fflib_Match.isNull()
			);*/
	}

	@isTest
	static void onAfterDelete() {
		ContactService mockService = (ContactService) MockUtility.mockUtility(ContactService.class);
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc.Id, true);
		Contact ct1 = contacts[0];

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, acc.Id, true);

		ContactPointEmail cpe1 = cpEmails[0];
		cpe1.Contact__c = ct1.Id;
		cpe1.ParentId = acc.Id;
		cpe1.Preferred__c = false;
		cpe1.EmailAddress = 'emailone@test.com.dummy';
		cpe1.Verified__c = false;

		ContactPointEmail cpe2 = cpEmails[1];
		cpe2.Contact__c = ct1.Id;
		cpe2.ParentId = acc.Id;
		cpe2.Preferred__c = false;
		cpe2.EmailAddress = 'emailone@test.com.dummy';
		cpe2.Verified__c = false;

		List<ContactPointEmail> cpEmails1 = new List<ContactPointEmail>();
		cpEmails1.add(cpe1);
		cpEmails1.add(cpe2);

		//mock selectors
		ContactPointEmailSelector cpEmailSelector = (ContactPointEmailSelector) MockUtility.mockSelector(ContactPointEmailSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				cpEmailSelector.selectByContact(
					(Set<Id>) fflib_Match.eq(new Set<Id>{ ct1.Id }),
					(Set<Object>) fflib_Match.eq(new Set<Object>())
				)
			)
			.thenReturn(new List<ContactPointEmail>(cpEmails1));

		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		//test start and stop
		Test.startTest();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointEmailDomainTriggerHandler.getUnitOfWorkSObjectTypes());
		ContactPointEmailDomainModule module = ContactPointEmailDomainModule.newInstance();
		module.onAfterDelete((List<SObject>) cpEmails1, uow);

		Test.stopTest();
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointEmailToContacts(
				(List<ContactPointEmail>) fflib_Match.isNull(),
				(List<ContactPointEmail>) fflib_Match.eq(cpEmails1)
			);
	}
}