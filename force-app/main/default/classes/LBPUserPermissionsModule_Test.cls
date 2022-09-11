/**
 * @description
 * Test class the covers LBPUserPermissionsModule. Used for LBP Community Users
 *
 * @author Nathan Franklin
 * @date 2022-08-24
 * @changelog
 */
@IsTest
private class LBPUserPermissionsModule_Test {

	/**
	 * Happy path scenario that verifies when a user record is created with a valid Network WCIS code that
	 */
	@IsTest
	public static void testEnsureAccessSynchronisationIsEnqueuedForLPO() {

		// =====================================
		// Data Preparation
		// =====================================
		Id facilityRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Facility').values()[0].Id;
		Id licenceRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Licence').values()[0].Id;
		Id organisationRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Business_Account').values()[0].Id;
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'LPO Partner Community User'][0].Id;

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(UserTriggerHandler.getUnitOfWorkSObjectTypes());

		List<Account> accountsHierarchy = ApplicationTestDataFactory.getAccounts(3, true);

		accountsHierarchy[0].RecordTypeId = facilityRecordTypeId;
		accountsHierarchy[0].ParentId = accountsHierarchy[1].Id;

		accountsHierarchy[1].RecordTypeId = licenceRecordTypeId;
		accountsHierarchy[1].ParentId = accountsHierarchy[2].Id;

		// Note the order in joining this data
		accountsHierarchy[1] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[1], new Map<String, Object>{'Parent' => accountsHierarchy[2]});
		accountsHierarchy[0] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[0], new Map<String, Object>{'Parent' => accountsHierarchy[1], 'WCIS_Code__c' => 'ORG123'});

		accountsHierarchy[2].RecordTypeId = organisationRecordTypeId;

		Contact contactRecord = ApplicationTestDataFactory.getContacts(1, accountsHierarchy[2].Id, true)[0];
		contactRecord = (Contact)ApplicationTestDataFactory.setUnwritableFields(contactRecord, new Map<String, Object>{'Account' => accountsHierarchy[2]});

		User user = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contactRecord.Id}, false)[0];
		user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{'Contact' => contactRecord});
		user.ProfileId = profileId;
		user.Network__c = 'ORG123';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		ContactsSelector mockContactsSelector = (ContactsSelector)MockUtility.mockSelector(ContactsSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contactRecord.Id}))).thenReturn(new Map<Id, Contact>{contactRecord.Id => contactRecord});
		MockUtility.Mocks.when(mockAccountsSelector.selectLPOAndCPOAccountsByAccIds((Set<Id>)fflib_Match.eq(new Set<Id>{accountsHierarchy[2].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{accountsHierarchy[0].Id => accountsHierarchy[0]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		LBPUserPermissionsModule module = LBPUserPermissionsModule.newInstance();

		module.onBeforeInsert(new List<User>{user}, uow);

		Test.stopTest();

		((ContactsSelector)MockUtility.Mocks.verify(mockContactsSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contactRecord.Id}));
		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectLPOAndCPOAccountsByAccIds((Set<Id>)fflib_Match.eq(new Set<Id>{accountsHierarchy[2].Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).enqueueJob(fflib_Match.anyObject());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 0)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);

	}

	/**
	 * Happy path scenario that verifies when a user record is created with a valid Network WCIS code that for Corporate Post Office account structure
	 */
	@IsTest
	public static void testEnsureAccessSynchronisationIsEnqueuedForCPO() {

		// =====================================
		// Data Preparation
		// =====================================
		Id facilityRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Facility').values()[0].Id;
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'LPO Partner Community User'][0].Id;

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(UserTriggerHandler.getUnitOfWorkSObjectTypes());

		List<Account> accountsHierarchy = ApplicationTestDataFactory.getAccounts(1, true);

		accountsHierarchy[0].RecordTypeId = facilityRecordTypeId;
		accountsHierarchy[0] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[0], new Map<String, Object>{'WCIS_Code__c' => 'ORG123'});

		Contact contactRecord = ApplicationTestDataFactory.getContacts(1, accountsHierarchy[0].Id, true)[0];
		contactRecord = (Contact)ApplicationTestDataFactory.setUnwritableFields(contactRecord, new Map<String, Object>{'Account' => accountsHierarchy[0]});

		User user = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contactRecord.Id}, false)[0];
		user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{'Contact' => contactRecord});
		user.ProfileId = profileId;
		user.Network__c = 'ORG123';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		ContactsSelector mockContactsSelector = (ContactsSelector)MockUtility.mockSelector(ContactsSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contactRecord.Id}))).thenReturn(new Map<Id, Contact>{contactRecord.Id => contactRecord});
		MockUtility.Mocks.when(mockAccountsSelector.selectLPOAndCPOAccountsByAccIds((Set<Id>)fflib_Match.eq(new Set<Id>{accountsHierarchy[0].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{accountsHierarchy[0].Id => accountsHierarchy[0]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		LBPUserPermissionsModule module = LBPUserPermissionsModule.newInstance();

		module.onBeforeInsert(new List<User>{user}, uow);

		Test.stopTest();

		((ContactsSelector)MockUtility.Mocks.verify(mockContactsSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contactRecord.Id}));
		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectLPOAndCPOAccountsByAccIds((Set<Id>)fflib_Match.eq(new Set<Id>{accountsHierarchy[0].Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).enqueueJob(fflib_Match.anyObject());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 0)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);

	}

	/**
	 * This makes sure that when the user enters an invalid value in the Network__c field that it won't let the user proceed
	 * The value entered must be a WCIS code of a facility they are connected to.
	 */
	@IsTest
	public static void testEnsureValidationErrorsPreventQueueableForLPO() {

		// =====================================
		// Data Preparation
		// =====================================
		Id facilityRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Facility').values()[0].Id;
		Id licenceRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Licence').values()[0].Id;
		Id organisationRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Business_Account').values()[0].Id;
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'LPO Partner Community User'][0].Id;

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(UserTriggerHandler.getUnitOfWorkSObjectTypes());

		List<Account> accountsHierarchy = ApplicationTestDataFactory.getAccounts(3, true);

		accountsHierarchy[0].RecordTypeId = facilityRecordTypeId;
		accountsHierarchy[0].ParentId = accountsHierarchy[1].Id;

		accountsHierarchy[1].RecordTypeId = licenceRecordTypeId;
		accountsHierarchy[1].ParentId = accountsHierarchy[2].Id;

		// Note the order in joining this data
		accountsHierarchy[1] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[1], new Map<String, Object>{'Parent' => accountsHierarchy[2]});
		accountsHierarchy[0] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[0], new Map<String, Object>{'Parent' => accountsHierarchy[1], 'WCIS_Code__c' => 'ORG123'});

		accountsHierarchy[2].RecordTypeId = organisationRecordTypeId;

		Contact contactRecord = ApplicationTestDataFactory.getContacts(1, accountsHierarchy[2].Id, true)[0];
		contactRecord = (Contact)ApplicationTestDataFactory.setUnwritableFields(contactRecord, new Map<String, Object>{'Account' => accountsHierarchy[2]});

		User user = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contactRecord.Id}, false)[0];
		user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{'Contact' => contactRecord});
		user.ProfileId = profileId;
		user.Network__c = 'ORGINVALID';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		ContactsSelector mockContactsSelector = (ContactsSelector)MockUtility.mockSelector(ContactsSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contactRecord.Id}))).thenReturn(new Map<Id, Contact>{contactRecord.Id => contactRecord});
		MockUtility.Mocks.when(mockAccountsSelector.selectLPOAndCPOAccountsByAccIds((Set<Id>)fflib_Match.eq(new Set<Id>{accountsHierarchy[2].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{accountsHierarchy[0].Id => accountsHierarchy[0]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		LBPUserPermissionsModule module = LBPUserPermissionsModule.newInstance();

		module.onBeforeInsert(new List<User>{user}, uow);

		Test.stopTest();

		((ContactsSelector)MockUtility.Mocks.verify(mockContactsSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contactRecord.Id}));
		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectLPOAndCPOAccountsByAccIds((Set<Id>)fflib_Match.eq(new Set<Id>{accountsHierarchy[2].Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 0)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// Make sure the queueable isn't run
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 0)).enqueueJob(fflib_Match.anyObject());

		// PMD warning
		System.assert(true);

	}

	/**
	 * This makes sure that when the user does not enter a value in the Network__c that the record should still be able to be saved
	 */
	@IsTest
	public static void testEnsureEmptyNetworkValueAllowsContinuationForLPO() {

		// =====================================
		// Data Preparation
		// =====================================
		Id facilityRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Facility').values()[0].Id;
		Id licenceRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Licence').values()[0].Id;
		Id organisationRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Business_Account').values()[0].Id;
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'LPO Partner Community User'][0].Id;

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(UserTriggerHandler.getUnitOfWorkSObjectTypes());

		List<Account> accountsHierarchy = ApplicationTestDataFactory.getAccounts(3, true);

		accountsHierarchy[0].RecordTypeId = facilityRecordTypeId;
		accountsHierarchy[0].ParentId = accountsHierarchy[1].Id;

		accountsHierarchy[1].RecordTypeId = licenceRecordTypeId;
		accountsHierarchy[1].ParentId = accountsHierarchy[2].Id;

		// Note the order in joining this data
		accountsHierarchy[1] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[1], new Map<String, Object>{'Parent' => accountsHierarchy[2]});
		accountsHierarchy[0] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[0], new Map<String, Object>{'Parent' => accountsHierarchy[1], 'WCIS_Code__c' => 'ORG123'});

		accountsHierarchy[2].RecordTypeId = organisationRecordTypeId;

		Contact contactRecord = ApplicationTestDataFactory.getContacts(1, accountsHierarchy[2].Id, true)[0];
		contactRecord = (Contact)ApplicationTestDataFactory.setUnwritableFields(contactRecord, new Map<String, Object>{'Account' => accountsHierarchy[2]});

		User user = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{contactRecord.Id}, false)[0];
		user = (User)ApplicationTestDataFactory.setUnwritableFields(user, new Map<String, Object>{'Contact' => contactRecord});
		user.ProfileId = profileId;
		user.Network__c = '';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		ContactsSelector mockContactsSelector = (ContactsSelector)MockUtility.mockSelector(ContactsSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contactRecord.Id}))).thenReturn(new Map<Id, Contact>{contactRecord.Id => contactRecord});
		MockUtility.Mocks.when(mockAccountsSelector.selectLPOAndCPOAccountsByAccIds((Set<Id>)fflib_Match.eq(new Set<Id>{accountsHierarchy[2].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{accountsHierarchy[0].Id => accountsHierarchy[0]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		LBPUserPermissionsModule module = LBPUserPermissionsModule.newInstance();

		module.onBeforeInsert(new List<User>{user}, uow);

		Test.stopTest();

		((ContactsSelector)MockUtility.Mocks.verify(mockContactsSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{contactRecord.Id}));
		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectLPOAndCPOAccountsByAccIds((Set<Id>)fflib_Match.eq(new Set<Id>{accountsHierarchy[2].Id}), (Set<Object>)fflib_Match.anyObject());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 0)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// Make sure the queueable isn't run
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 0)).enqueueJob(fflib_Match.anyObject());

		// PMD warning
		System.assert(true);

	}




//
//
//	@TestSetup
//	static void setup() {
//		List<Account> accounts = TestDataProvider.createAccount('Test Account', 1);
//		insert new Contact(AccountId = accounts[0].Id, FirstName = 'test', LastName = 'lpo', Email = 'lpo@test.com');
//		setDataForLPOReparentTest();
//	}
//
//	@Future static void setDataForLPOReparentTest() {
//		Contact commContact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Email = 'lpo@test.com' LIMIT 1];
//		Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User'];
//		UserRole role = [SELECT Id FROM UserRole WHERE PortalType = 'Partner' LIMIT 1];
//		insert new User(
//			Email = commContact.Email,
//			EmailEncodingKey = 'UTF-8',
//			FirstName = commContact.FirstName,
//			LastName = commContact.LastName,
//			ContactId = commContact.Id,
//			LanguageLocaleKey = 'en_US',
//			LocaleSidKey = 'en_US',
//			ProfileId = communityUserProfile.Id,
//			Alias = commContact.FirstName,
//			TimeZoneSidKey = 'America/Los_Angeles',
//			MobilePhone = '098765432',
//			Username = 'commUser@lpoTest.com',
//			IsActive = true,
//			UserRoleId = role.Id
//		);
//	}
//
//	@IsTest
//	static void testCreateNewPortalUser() {
//		User adminUser = new User(
//			ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
//			Username = 'testAdmin@sf.com.au',
//			Alias = 'GDS',
//			TimeZoneSidKey = 'America/New_York',
//			EmailEncodingKey = 'ISO-8859-1',
//			LocaleSidKey = 'en_US',
//			LanguageLocaleKey = 'en_US',
//			FirstName = 'Genelia',
//			LastName = 'Dsouza',
//			UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Business_Reporting' LIMIT 1].Id,
//			Email = 'test@please.work.au'
//		);
//		insert adminUser;
//		Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User'];
//
//		System.runAs(adminUser) {
//			MockUtility.disableTriggerExecution();
//			Test.startTest();
//			List<Account> orgAccounts = new List<Account>(ApplicationTestDataFactory.getAccounts(2, false));
//
//			List<Network__c> networkFacilities = ApplicationTestDataFactory.getLPONetwork(1, false);
//			networkFacilities[0].Org_ID__c = 'test1';
//			insert networkFacilities;
//
//			Id orgRtId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
//			orgAccounts[0].RecordTypeId = orgRtId;
//			orgAccounts[0].ABN__c = '12345678901';
//			orgAccounts[0].Post_Office_Assigned__c = networkFacilities[0].Id;
//			orgAccounts[1].Post_Office_Assigned__c = networkFacilities[0].Id;
//			insert orgAccounts;
//			orgAccounts[0].IsPartner = true;
//			update orgAccounts;
//
//			List<Account> licenceAccounts = new List<Account>{
//				ApplicationTestDataFactory.getLPOAccounts(1, orgAccounts[0].Id, null, false)[0]
//			};
//			insert licenceAccounts;
//
//			Account facilityAccount1 = ApplicationTestDataFactory.getFacilityAccounts(1, networkFacilities[0].Id, false)[0];
//
//			facilityAccount1.ParentId = licenceAccounts[0].Id;
//			insert facilityAccount1;
//
//			List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, orgAccounts[0].Id, false);
//			insert contacts;
//			User testUsr = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>{
//				contacts[0].Id
//			}, communityUserProfile.Id, false)[0];
//
//			testUsr.Username = 'cpoAndLpoTest@ausPost' + System.currentTimeMillis() + '.au';
//			System.assertEquals(0, [SELECT COUNT() FROM AccountTeamMember], 'No account team membership should have been created before the start of the test');
//			SystemSettings__c settings = SystemSettings__c.getInstance();
//			settings.Disable_Triggers__c = false;
//			upsert settings;
//			insert testUsr;
//			Test.stopTest();
//			System.assertEquals(1, [SELECT COUNT() FROM AccountTeamMember WHERE UserId = :testUsr.Id AND AccountId = :orgAccounts[1].Id], 'test user should get access to the account');
//
//		}
//	}

}