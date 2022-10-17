/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactPointPhoneContactSyncModule
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class ContactPointPhoneContactSyncModule_Test {
	
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
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointPhoneTriggerHandler.getUnitOfWorkSObjectTypes());
		ContactPointPhoneContactSyncModule module = ContactPointPhoneContactSyncModule.newInstance();
		module.onAfterInsert((List<SObject>) cpPhones1, uow);

		Test.stopTest();
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointPhoneToContacts(
				(List<ContactPointPhone>) fflib_Match.eq(cpPhones1),
				(List<ContactPointPhone>) fflib_Match.isNull(),
				(Map<Id,ContactPointPhone>) fflib_Match.isNull()
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
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointPhoneTriggerHandler.getUnitOfWorkSObjectTypes());
		ContactPointPhoneContactSyncModule module = ContactPointPhoneContactSyncModule.newInstance();
		module.onAfterUpdate((List<SObject>) cpPhones1, (Map<Id, SObject>) existing, uow);

		Test.stopTest();
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointPhoneToContacts(
				(List<ContactPointPhone>) fflib_Match.eq(cpPhones1),
				(List<ContactPointPhone>) fflib_Match.isNull(),
				(Map<Id, ContactPointPhone>) fflib_Match.eq(existing)
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
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointPhoneTriggerHandler.getUnitOfWorkSObjectTypes());
		ContactPointPhoneContactSyncModule module = ContactPointPhoneContactSyncModule.newInstance();
		module.onAfterDelete((List<SObject>) cpPhones1, uow);

		Test.stopTest();
		((ContactService) MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1)))
			.syncContactPointPhoneToContacts(
				(List<ContactPointPhone>) fflib_Match.isNull(),
				(List<ContactPointPhone>) fflib_Match.eq(cpPhones1),
				(Map<Id,ContactPointPhone>) fflib_Match.isNull()
			);
	}


	//test exceptions in module class
	@isTest
	static void testExceptionOnAfterUpdate(){
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;
		Test.startTest();
		ContactPointPhoneContactSyncModule module = ContactPointPhoneContactSyncModule.newInstance();
		module.onAfterUpdate(new List<SObject>{},new Map<Id,SObject>{},null);
		Test.stopTest();
		//an exception should be created when thre are invalid parameters in the onAfterUpdate
		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
		System.assertEquals(true, logResult.size() > 0, 'Exception created');
	}

	//test exceptions in module class
	@isTest
	static void testExceptionOnAfterInsert(){
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;
		Test.startTest();
		ContactPointPhoneContactSyncModule module = ContactPointPhoneContactSyncModule.newInstance();
		module.onAfterInsert(new List<SObject>{},null);
		Test.stopTest();
		//an exception should be created when thre are invalid parameters in the onAfterInsert
		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
		System.assertEquals(true, logResult.size() > 0, 'Exception created');
	}

	//test exceptions in module class
		@isTest
		static void testExceptionOnAfterDelete(){
			LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
			logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
			insert logLevel;
			Test.startTest();
			ContactPointPhoneContactSyncModule module = ContactPointPhoneContactSyncModule.newInstance();
			module.onAfterDelete(null,null);
			Test.stopTest();
			//an exception should be created when thre are invalid parameters in the onAfterDelete
			List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
			System.assertEquals(true, logResult.size() > 0, 'Exception created');
		}

}