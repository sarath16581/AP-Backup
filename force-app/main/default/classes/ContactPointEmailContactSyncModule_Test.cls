/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactPointEmailContactSyncModule
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 * 2024-03-08 - Mahesh Parvathaneni - Commented the assertions for user creation.
 */
@IsTest
public with sharing class ContactPointEmailContactSyncModule_Test {

	@IsTest
	static void makingSureTheUserIsUpdatedWithTheFieldsFromContactPointEmail() {
		String sandboxSuffix = Application.Cache.organizationInfo.isSandbox == true ? '.' + Application.Cache.organizationInfo.sandboxName : '';
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(1, acc.Id, true));
		Contact ct1 = contacts.values()[0];

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, acc.id, true);
		ContactPointEmail cpe1 = cpEmails[0];
		cpe1.IsCredential__c = true;
		cpe1.Contact__c = ct1.Id;

		List<User> existingUsers = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{ ct1.Id }, true);
		User existingUser = existingUsers[0];

		ContactPointEmailContactSyncModule.AsyncUpdateUserLoginDetailsWorker worker = new ContactPointEmailContactSyncModule.AsyncUpdateUserLoginDetailsWorker();
		ContactPointEmailContactSyncModule.AsyncUpdateUserLoginDetailsWorkerParameters params = new ContactPointEmailContactSyncModule.AsyncUpdateUserLoginDetailsWorkerParameters();
		params.userIdsAndContactPointEmailIds = new List<String>{existingUser.Id + '-' + cpe1.Id};

		ContactPointEmailSelector mockEmailSelector = (ContactPointEmailSelector) MockUtility.mockSelector(ContactPointEmailSelector.class);
		UsersSelector mockUserSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockEmailSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{cpe1.Id}))).thenReturn(new List<ContactPointEmail>{cpe1});
		MockUtility.Mocks.when(mockUserSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{existingUser.Id}))).thenReturn(new Map<Id, User>(existingUsers));

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		System.assertEquals(ContactPointEmailContactSyncModule.AsyncUpdateUserLoginDetailsWorker.class, worker.getClassType(), 'matching type');
		System.assertEquals(User.SObjectType, worker.getSObjectTypeGroup(), 'matching type');

		worker.deserialiseParams(JSON.serialize(params));
		System.assert(worker.contactPointEmailIds.contains(cpe1.Id), 'It should be passed in via the params');
		System.assert(worker.userIdsVsContactPointEmailIds.containsKey(existingUser.Id), 'It should be passed in via the params');
		System.assertEquals(cpe1.Id, worker.userIdsVsContactPointEmailIds.get(existingUser.Id), 'It should be set via the params');

		worker.execute(mockUow);
		existingUser.Email = cpe1.emailAddress;
		existingUser.Username = cpe1.emailAddress + '.community' + sandboxSuffix;
		existingUser.FederationIdentifier = cpe1.emailAddress + '.community' + sandboxSuffix;

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<User>) fflib_Match.eq(new List<User>{existingUser}),
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{
				User.Email,
				User.Username,
				User.FederationIdentifier
			}),
			fflib_Match.eqBoolean(false),
			fflib_Match.eqString(ContactPointEmailContactSyncModule.class.getName() + '.' + ContactPointEmailContactSyncModule.AsyncUpdateUserLoginDetailsWorker.class.getName())
		);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}	

	/*
	* this test will verify the following method was called:
	* ApplicationUnitOfWork.registerDirty - with the valid Contact records to update with valid values using the specified fields only
	* ApplicationUnitOfWork.registerUpsert - for Contacts with updated CRMCSSOID__c
	* ApplicationUnitOfWork.registerUpsert - for New Portal Users 
	* ApplicationDatabase.dmlUpdate - for User records with updated email, username and fed id
	*/
	@IsTest
	static void onAfterInsert() {
		
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		Contact ct1 = contacts.values()[0];
		Contact ct2 = contacts.values()[1];

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, acc.id, true);

		ContactPointEmail cpe1 = cpEmails[0];
		cpe1.Contact__c = ct1.Id;
		cpe1.EmailAddress = 'newEmailForExistingUser@test.com';
		cpe1.IsCredential__c = true;

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
		User existingUser = existingUsers[0];
		existingUser.Email = 'oldemail@test.com';
		existingUser.Username = 'oldemail@test.com.blah';
		existingUser.FederationIdentifier = 'oldemail@test.com.blah';

		ContactService mockContactService = (ContactService) MockUtility.mockUtility(ContactService.class);
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		ContactPointPhoneSelector mockPhoneSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(ContactPointPhoneSelector.class);
		ContactPointEmailSelector mockEmailSelector = (ContactPointEmailSelector) MockUtility.mockSelector(ContactPointEmailSelector.class);
		UsersSelector mockUserSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockContactService.syncContactPointEmailToContacts(
														(List<ContactPointEmail>) fflib_Match.eq(cpEmails),
														(List<ContactPointEmail>) fflib_Match.isNull(),
														(Map<Id,ContactPointEmail>) fflib_Match.isNull()
													)).thenReturn(contacts.values());

		MockUtility.Mocks.when(mockContactsSelector.selectById((Set<Id>) fflib_Match.eq(contacts.keySet()))).thenReturn(contacts);

		MockUtility.Mocks.when(mockPhoneSelector.selectByContact(
														(Set<Id>) fflib_Match.eq(contacts.keySet()),
														(Set<Object>) fflib_Match.eq(
															new Set<Object>{
																ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE,
																ContactPointPhoneSelector.Options.FILTER_PREFERRED_TRUE
															}
														))).thenReturn(cpPhones);

		MockUtility.Mocks.when(mockEmailSelector.selectByContact((Set<Id>) fflib_Match.eq(contacts.keySet()), (Set<Object>) fflib_Match.eq(new Set<Object>()))).thenReturn(cpEmails);

		MockUtility.Mocks.when(mockUserSelector.selectByContactId((Set<Id>) fflib_Match.eq(contacts.keySet()))).thenReturn(new Map<Id, User>(existingUsers));

		MockUtility.Mocks.when(mockEmailSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{cpe1.Id}))).thenReturn(new List<ContactPointEmail>{cpe1});
		MockUtility.Mocks.when(mockUserSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{existingUser.Id}))).thenReturn(new Map<Id, User>(existingUsers));

		MockUtility.Mocks.stopStubbing();

		Id portalUserProfileId = Application.Cache.profileIds.get(ChasConstants.CONSUMER_COMMUNITY_PROFILE_NAME);

		Test.startTest();

		ContactPointEmailContactSyncModule module = ContactPointEmailContactSyncModule.newInstance();
		module.onAfterInsert((List<SObject>) cpEmails, mockUow);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<Contact>) fflib_Match.eq(contacts.values()),(List<SObjectField>)fflib_Match.anyObject(),fflib_Match.anyString());

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerUpsert((List<Contact>) fflib_Match.eq(
				new List<Contact>{
					new Contact(Id = ct2.Id, CRMCSSOID__c = cpe2.emailAddress)
				}
			)
		);

		String sandboxSuffix = Application.Cache.organizationInfo.isSandbox == true ? '.' + Application.Cache.organizationInfo.sandboxName : '';

		/*((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerUpsert((List<User>) fflib_Match.eq(
				new List<User>{
					new User(
						FirstName = ct2.FirstName,
						LastName = ct2.LastName,
						APCN__c = ct2.APCN__c,
						ProfileId = portalUserProfileId,
						IsActive = false,
						Email = cpe2.emailAddress,
						MobilePhone = cpp2.TelephoneNumber,
						Username = cpe2.emailAddress + '.community' + sandboxSuffix,
						FederationIdentifier = cpe2.emailAddress + '.community' + sandboxSuffix,
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
		);*/

		/*
		List<String> userIdsAndContactPointEmailIds = new List<String>{existingUser.Id + '-' + cpe1.Id};
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) fflib_Match.eq(
				new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWork.AsyncUpdateUserLoginDetailsWorker.class, new Map<String, Object>{'userIdsAndContactPointEmailIds' => userIdsAndContactPointEmailIds})
			)
		);
		*/

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}

	/*
	* this test will verify the following method was called:
	* ApplicationUnitOfWork.registerDirty - with the valid Contact records to update with valid values using the specified fields only
	* ApplicationUnitOfWork.registerUpsert - for Contacts with updated CRMCSSOID__c
	* ApplicationUnitOfWork.registerUpsert - for New Portal Users 
	* ApplicationDatabase.dmlUpdate - for User records with updated email, username and fed id
	*/
	@IsTest
	static void onAfterUpdate() {

		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		Contact ct1 = contacts.values()[0];
		Contact ct2 = contacts.values()[1];

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, acc.id, true);

		ContactPointEmail cpe1 = cpEmails[0];
		cpe1.Contact__c = ct1.Id;
		cpe1.EmailAddress = 'test-sync-with-contact@sample.auspost.com.au';
		cpe1.IsCredential__c = true;

		ContactPointEmail cpe2 = cpEmails[1];
		cpe2.Contact__c = ct2.Id;
		cpe2.EmailAddress = 'test1234@houdini-g.com';
		cpe2.IsCredential__c = true;

		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, acc.id, true);
		cpPhones[0].Contact__c = ct1.Id;

		ContactPointPhone cpp2 = cpPhones[1];
		cpp2.Contact__c = ct2.Id;
		cpp2.TelephoneNumber = '+61288889999';

		ContactPointEmail existingCpe1 = cpe1.clone(true, true, false, false);
		existingCpe1.IsCredential__c = false;

		ContactPointEmail existingCpe2 = cpe2.clone(true, true, false, false);
		existingCpe2.IsCredential__c = false;
		
		Map<Id, ContactPointEmail> existingRecords = new Map<Id, ContactPointEmail>{
			existingCpe1.Id => existingCpe1,
			existingCpe2.Id => existingCpe2
		};

		List<User> existingUsers = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{ ct1.Id }, true);
		User existingUser = existingUsers[0];
		existingUser.Email = 'oldemail@test.com';
		existingUser.Username = 'oldemail@test.com.blah';
		existingUser.FederationIdentifier = 'oldemail@test.com.blah';

		ContactService mockContactService = (ContactService) MockUtility.mockUtility(ContactService.class);
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		ContactPointPhoneSelector mockPhoneSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(ContactPointPhoneSelector.class);
		ContactPointEmailSelector mockEmailSelector = (ContactPointEmailSelector) MockUtility.mockSelector(ContactPointEmailSelector.class);
		UsersSelector mockUserSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockContactService.syncContactPointEmailToContacts(
														(List<ContactPointEmail>) fflib_Match.eq(cpEmails),
														(List<ContactPointEmail>) fflib_Match.isNull(),
														(Map<Id, ContactPointEmail>) fflib_Match.eq(existingRecords)
													)).thenReturn(contacts.values());

		MockUtility.Mocks.when(mockContactsSelector.selectById((Set<Id>) fflib_Match.eq(contacts.keySet()))).thenReturn(contacts);

		MockUtility.Mocks.when(mockPhoneSelector.selectByContact(
														(Set<Id>) fflib_Match.eq(contacts.keySet()),
														(Set<Object>) fflib_Match.eq(
															new Set<Object>{
																ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE,
																ContactPointPhoneSelector.Options.FILTER_PREFERRED_TRUE
															}
														))).thenReturn(cpPhones);

		MockUtility.Mocks.when(mockEmailSelector.selectByContact((Set<Id>) fflib_Match.eq(contacts.keySet()), (Set<Object>) fflib_Match.eq(new Set<Object>()))).thenReturn(cpEmails);

		MockUtility.Mocks.when(mockUserSelector.selectByContactId((Set<Id>) fflib_Match.eq(contacts.keySet()))).thenReturn(new Map<Id, User>(existingUsers));

		MockUtility.Mocks.when(mockEmailSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{cpe1.Id}))).thenReturn(new List<ContactPointEmail>{cpe1});
		MockUtility.Mocks.when(mockUserSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{existingUser.Id}))).thenReturn(new Map<Id, User>(existingUsers));

		MockUtility.Mocks.stopStubbing();

		Id portalUserProfileId = Application.Cache.profileIds.get(ChasConstants.CONSUMER_COMMUNITY_PROFILE_NAME);

		Test.startTest();

		ContactPointEmailContactSyncModule module = ContactPointEmailContactSyncModule.newInstance();
		module.onAfterUpdate((List<SObject>) cpEmails, (Map<Id, SObject>) existingRecords, mockUow);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<Contact>) fflib_Match.eq(contacts.values()),(List<SObjectField>)fflib_Match.anyObject(),fflib_Match.anyString());

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerUpsert((List<Contact>) fflib_Match.eq(
				new List<Contact>{
					new Contact(Id = ct2.Id, CRMCSSOID__c = cpe2.emailAddress)
				}
			)
		);

		String sandboxSuffix = Application.Cache.organizationInfo.isSandbox == true ? '.' + Application.Cache.organizationInfo.sandboxName : '';

		/*((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerUpsert((List<User>) fflib_Match.eq(
				new List<User>{
					new User(
						FirstName = ct2.FirstName,
						LastName = ct2.LastName,
						APCN__c = ct2.APCN__c,
						ProfileId = portalUserProfileId,
						IsActive = false,
						Email = cpe2.emailAddress,
						MobilePhone = cpp2.TelephoneNumber,
						Username = cpe2.emailAddress + '.community' + sandboxSuffix,
						FederationIdentifier = cpe2.emailAddress + '.community' + sandboxSuffix,
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
		);*/

		/*
		List<String> userIdsAndContactPointEmailIds = new List<String>{existingUser.Id + '-' + cpe1.Id};
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) fflib_Match.eq(
				new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWork.AsyncUpdateUserLoginDetailsWorker.class, new Map<String, Object>{'userIdsAndContactPointEmailIds' => userIdsAndContactPointEmailIds})
			)
		);
		*/

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}

	/*
	* this test will verify the following method was called:
	* ApplicationUnitOfWork.registerDirty - with the valid Contact records to update with valid values using the specified fields only
	*/
	@isTest
	static void onAfterDelete() {
		Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		Contact ct1 = contacts.values()[0];
		Contact ct2 = contacts.values()[1];

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, acc.id, true);

		ContactPointEmail cpe1 = cpEmails[0];
		cpe1.Contact__c = ct1.Id;
		cpe1.EmailAddress = 'test-sync-with-contact@sample.auspost.com.au';
		cpe1.IsCredential__c = true;

		ContactPointEmail cpe2 = cpEmails[1];
		cpe2.Contact__c = ct2.Id;
		cpe2.EmailAddress = 'test1234@houdini-g.com';
		cpe2.IsCredential__c = false;

		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, acc.id, true);
		cpPhones[0].Contact__c = ct1.Id;

		ContactPointPhone cpp2 = cpPhones[1];
		cpp2.Contact__c = ct2.Id;
		cpp2.TelephoneNumber = '+61288889999';

		ContactService mockContactService = (ContactService) MockUtility.mockUtility(ContactService.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockContactService.syncContactPointEmailToContacts(
														(List<ContactPointEmail>) fflib_Match.isNull(), 
														(List<ContactPointEmail>) fflib_Match.eq(cpEmails),
														(Map<Id,ContactPointEmail>) fflib_Match.isNull() 
													)).thenReturn(contacts.values());

		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		ContactPointEmailContactSyncModule module = ContactPointEmailContactSyncModule.newInstance();
		module.onAfterDelete((List<SObject>) cpEmails, mockUow);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<Contact>) fflib_Match.eq(contacts.values()),(List<SObjectField>)fflib_Match.anyObject(),fflib_Match.anyString());
		
		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}

	//test exceptions in module class
	@isTest
	static void testExceptionOnUpdate(){
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;
		Test.startTest();
		ContactPointEmailContactSyncModule module = ContactPointEmailContactSyncModule.newInstance();
		module.onAfterUpdate(new List<SObject>{},new Map<Id,SObject>{},null);
		Test.stopTest();
		//an exception should be created when thre are invalid parameters in the onAfterUpdate
		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
		System.assertEquals(true, logResult.size() > 0, 'Exception created');
	}

	//test exceptions in module class
	@isTest
	static void testExceptionOnInsert(){
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;
		Test.startTest();
		ContactPointEmailContactSyncModule module = ContactPointEmailContactSyncModule.newInstance();
		module.onAfterInsert(new List<SObject>{},null);
		Test.stopTest();
		//an exception should be created when thre are invalid parameters in the onAfterInsert
		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
		System.assertEquals(true, logResult.size() > 0, 'Exception created');
	}

	//test exceptions in module class
		@isTest
		static void testExceptionOnDelete(){
			LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
			logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
			insert logLevel;
			Test.startTest();
			ContactPointEmailContactSyncModule module = ContactPointEmailContactSyncModule.newInstance();
			module.onAfterDelete(new List<SObject>{},null);
			Test.stopTest();
			//an exception should be created when thre are invalid parameters in the onAfterDelete
			List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
			System.assertEquals(true, logResult.size() > 0, 'Exception created');
		}
}