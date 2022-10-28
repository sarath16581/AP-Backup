/**
 * @description
 * Test class the covers LBPContactPermissionsModule. Used for LBP Community Users
 *
 * @author Nathan Franklin
 * @date 2022-08-24
 * @changelog
 */
@IsTest
private class LBPContactPermissionsModule_Test {

	/**
	 * Happy path scenario that verifies when a CPO contact is reparented to another Facility that the queueable job is enqueued with the correct parameters
	 */
	@IsTest
	public static void testEnsureQueueableFiresWhenCPOIsReparented() {

		// =====================================
		// Data Preparation
		// =====================================

		// The data we create is:
		// 1. One LBP User Record -> Contact -> Account(Facility - CPO1) -> Network_Facility__r
		// 1. One LBP User Record -> Contact -> Account(Facility - CPO2) -> Network_Facility__r (Used as the old record)
		// 1. One BSP User Record -> Contact -> Account(Business_Account - Business Account 1)
		// 1. One BSP User Record -> Contact -> Account(Business_Account - Business Account 2) (Used as the old record)

		RecordType facilityRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Facility').values()[0];
		RecordType businessAccountRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Business_Account').values()[0];
		Id lbpProfileId = [SELECT Id FROM Profile WHERE Profile.Name = 'LPO Partner Community User'][0].Id;
		Id bspCommunityId = [SELECT Id FROM Profile WHERE Profile.Name = 'BSP Community User'][0].Id;

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());

		// 0 index is for positive scenario, 1 index is for negative scenario
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(2, true);
		networks[0].Org_ID__c = 'CPO1';
		networks[1].Org_ID__c = 'CPO2';

		List<Account> accountsHierarchy = ApplicationTestDataFactory.getAccounts(4, true);
		List<Id> accountIds = new List<Id>((new Map<Id, Account>(accountsHierarchy)).keySet());

		// this record should be included
		accountsHierarchy[0].RecordTypeId = facilityRecordType.Id;
		accountsHierarchy[0].Network_Facility__c = networks[0].Id;
		accountsHierarchy[0] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[0], new Map<String, Object>{'WCIS_Code__c' => 'CPO1', 'Network_Facility__r' => networks[0], 'RecordType' => facilityRecordType});

		accountsHierarchy[1].RecordTypeId = facilityRecordType.Id;
		accountsHierarchy[1].Network_Facility__c = networks[1].Id;
		accountsHierarchy[1] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[1], new Map<String, Object>{'WCIS_Code__c' => 'CPO2', 'Network_Facility__r' => networks[1], 'RecordType' => facilityRecordType});

		accountsHierarchy[2].RecordTypeId = businessAccountRecordType.Id;
		accountsHierarchy[2] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[2], new Map<String, Object>{'RecordType' => businessAccountRecordType});

		accountsHierarchy[3].RecordTypeId = businessAccountRecordType.Id;
		accountsHierarchy[3] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[3], new Map<String, Object>{'RecordType' => businessAccountRecordType});

		Set<Id> contactAccounts = new Set<Id>{accountIds[0], accountIds[2]};
		List<Contact> contactRecords = ApplicationTestDataFactory.getContacts(2, contactAccounts, true);
		contactRecords[0] = (Contact)ApplicationTestDataFactory.setUnwritableFields(contactRecords[0], new Map<String, Object>{'Account' => accountsHierarchy[0]});
		contactRecords[1] = (Contact)ApplicationTestDataFactory.setUnwritableFields(contactRecords[1], new Map<String, Object>{'Account' => accountsHierarchy[2]});

		// this is passed into module as the old record state to flag that the records have changed Accounts
		List<Contact> oldContactRecords = contactRecords.deepClone(true);
		oldContactRecords[0].AccountId = accountsHierarchy[1].Id;
		oldContactRecords[0] = (Contact)ApplicationTestDataFactory.setUnwritableFields(oldContactRecords[0], new Map<String, Object>{'Account' => null});
		oldContactRecords[1].AccountId = accountsHierarchy[3].Id;
		oldContactRecords[1] = (Contact)ApplicationTestDataFactory.setUnwritableFields(oldContactRecords[1], new Map<String, Object>{'Account' => null});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>(contactAccounts), true);
		users[0] = (User)ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Contact' => contactRecords[0]});
		users[0].ProfileId = lbpProfileId;
		users[0].Network__c = 'CPO1';

		users[1] = (User)ApplicationTestDataFactory.setUnwritableFields(users[1], new Map<String, Object>{'Contact' => contactRecords[1]});
		users[1].ProfileId = bspCommunityId;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(users);
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{oldContactRecords[0].AccountId, oldContactRecords[1].AccountId}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{accountsHierarchy[1].Id => accountsHierarchy[1], accountsHierarchy[3].Id => accountsHierarchy[3]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		LBPContactPermissionsModule module = LBPContactPermissionsModule.newInstance();

		module.onAfterUpdate(contactRecords, new Map<Id, Contact>(oldContactRecords), uow);

		Test.stopTest();

		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true));

		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		System.assertEquals(lbpProfileId, searchParams.get('profileIds'));
		System.assertEquals(new Set<Id>{contactRecords[0].Id, contactRecords[1].Id}, searchParams.get('contactIds')); // <-- NOTE that both contact will be here

		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{oldContactRecords[0].AccountId, oldContactRecords[1].AccountId}), (Set<Object>)fflib_Match.anyObject());

		// make sure no exceptions were thrown
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 0)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// check that the queueable fired
		fflib_ArgumentCaptor queueableCaptor = fflib_ArgumentCaptor.forClass(LpoCpoAccessHandlerQueueable.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).enqueueJob((Object)queueableCaptor.capture());

		LpoCpoAccessHandlerQueueable queueable = (LpoCpoAccessHandlerQueueable)queueableCaptor.getValue();
		System.assertEquals(new Map<String, Set<Id>>{'CPO1' => new Set<Id>{contactRecords[0].AccountId}}, queueable.contactIdsByNetworkFacility);
		System.assertEquals(new Set<Id>{contactRecords[0].Id}, queueable.contactIdsToRemoveMembership);
		System.assertEquals(null, queueable.membershipsToRemove);
		System.assertEquals(null, queueable.membershipsToInsert);

	}

	/**
	 * Scenario: To make sure there is no queueable that is fired if the contacts that are passed in are not eligible
	 */
	@IsTest
	public static void testEnsureQueueableDoesNotFireWhenNoEligibleContacts() {

		// =====================================
		// Data Preparation
		// =====================================

		// The data we create is:
		// 1. One BSP User Record -> Contact -> Account(Business_Account - Business Account 1)
		// 1. One BSP User Record -> Contact -> Account(Business_Account - Business Account 2) (Used as the old record)

		RecordType facilityRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Facility').values()[0];
		RecordType businessAccountRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Business_Account').values()[0];
		Id lbpProfileId = [SELECT Id FROM Profile WHERE Profile.Name = 'LPO Partner Community User'][0].Id;
		Id bspCommunityId = [SELECT Id FROM Profile WHERE Profile.Name = 'BSP Community User'][0].Id;

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());

		List<Account> accountsHierarchy = ApplicationTestDataFactory.getAccounts(2, true);
		List<Id> accountIds = new List<Id>((new Map<Id, Account>(accountsHierarchy)).keySet());

		accountsHierarchy[0].RecordTypeId = businessAccountRecordType.Id;
		accountsHierarchy[0] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[0], new Map<String, Object>{'RecordType' => businessAccountRecordType});

		accountsHierarchy[1].RecordTypeId = businessAccountRecordType.Id;
		accountsHierarchy[1] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[1], new Map<String, Object>{'RecordType' => businessAccountRecordType});

		Set<Id> contactAccounts = new Set<Id>{accountIds[0]};
		List<Contact> contactRecords = ApplicationTestDataFactory.getContacts(1, contactAccounts, true);
		contactRecords[0] = (Contact)ApplicationTestDataFactory.setUnwritableFields(contactRecords[0], new Map<String, Object>{'Account' => accountsHierarchy[0]});

		// this is passed into module as the old record state to flag that the records have changed Accounts
		List<Contact> oldContactRecords = contactRecords.deepClone(true);
		oldContactRecords[0].AccountId = accountsHierarchy[1].Id;
		oldContactRecords[0] = (Contact)ApplicationTestDataFactory.setUnwritableFields(oldContactRecords[0], new Map<String, Object>{'Account' => null});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>(contactAccounts), true);
		users[0] = (User)ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Contact' => contactRecords[0]});
		users[0].ProfileId = bspCommunityId;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(users);
		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{oldContactRecords[0].AccountId}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>{accountsHierarchy[1].Id => accountsHierarchy[1]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		LBPContactPermissionsModule module = LBPContactPermissionsModule.newInstance();

		module.onAfterUpdate(contactRecords, new Map<Id, Contact>(oldContactRecords), uow);

		Test.stopTest();

		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true));

		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		System.assertEquals(lbpProfileId, searchParams.get('profileIds'));
		System.assertEquals(new Set<Id>{contactRecords[0].Id}, searchParams.get('contactIds')); // <-- NOTE that both contact will be here

		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{oldContactRecords[0].AccountId}), (Set<Object>)fflib_Match.anyObject());

		// make sure no exceptions were thrown
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 0)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// check that the queueable was not fired
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 0)).enqueueJob(fflib_Match.anyObject());

	}

	/**
	 * This tests to make sure that we don't queue up removing account team members where the account id of the contact was null
	 * This is a fringe scenario but might occur
	 */
	@IsTest
	public static void testEnsureOnlyNewAccountTeamsAreAddedWhenPreviousAccountWasInvalid() {

		// =====================================
		// Data Preparation
		// =====================================

		// The data we create is:
		// 1. One LBP User Record -> Contact -> Account(Facility - CPO1) -> Network_Facility__r
		// 1. One LBP User Record -> Contact -> Account null

		RecordType facilityRecordType = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Account', 'Facility').values()[0];
		Id lbpProfileId = [SELECT Id FROM Profile WHERE Profile.Name = 'LPO Partner Community User'][0].Id;

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());

		// 0 index is for positive scenario, 1 index is for negative scenario
		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = 'CPO1';

		List<Account> accountsHierarchy = ApplicationTestDataFactory.getAccounts(1, true);
		List<Id> accountIds = new List<Id>((new Map<Id, Account>(accountsHierarchy)).keySet());

		// this record should be included
		accountsHierarchy[0].RecordTypeId = facilityRecordType.Id;
		accountsHierarchy[0].Network_Facility__c = networks[0].Id;
		accountsHierarchy[0] = (Account)ApplicationTestDataFactory.setUnwritableFields(accountsHierarchy[0], new Map<String, Object>{'WCIS_Code__c' => 'CPO1', 'Network_Facility__r' => networks[0], 'RecordType' => facilityRecordType});

		Set<Id> contactAccounts = new Set<Id>{accountIds[0]};
		List<Contact> contactRecords = ApplicationTestDataFactory.getContacts(1, contactAccounts, true);
		contactRecords[0] = (Contact)ApplicationTestDataFactory.setUnwritableFields(contactRecords[0], new Map<String, Object>{'Account' => accountsHierarchy[0]});

		// this is passed into module as the old record state to flag that the records have changed Accounts
		List<Contact> oldContactRecords = contactRecords.deepClone(true);
		oldContactRecords[0].AccountId = null;
		oldContactRecords[0] = (Contact)ApplicationTestDataFactory.setUnwritableFields(oldContactRecords[0], new Map<String, Object>{'Account' => null});

		List<User> users = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id>(contactAccounts), true);
		users[0] = (User)ApplicationTestDataFactory.setUnwritableFields(users[0], new Map<String, Object>{'Contact' => contactRecords[0]});
		users[0].ProfileId = lbpProfileId;
		users[0].Network__c = 'CPO1';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(users);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		LBPContactPermissionsModule module = LBPContactPermissionsModule.newInstance();

		module.onAfterUpdate(contactRecords, new Map<Id, Contact>(oldContactRecords), uow);

		Test.stopTest();

		fflib_ArgumentCaptor searchParamsCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, MockUtility.Mocks.times(1))).search((Map<String, Object>)searchParamsCaptor.capture(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true));

		Map<String, Object> searchParams = (Map<String, Object>)searchParamsCaptor.getValue();
		System.assertEquals(lbpProfileId, searchParams.get('profileIds'));
		System.assertEquals(new Set<Id>{contactRecords[0].Id}, searchParams.get('contactIds')); // <-- NOTE that both contact will be here

		// accountsselector should not be fired since the previous account id was null
		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 0)).selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

		// make sure no exceptions were thrown
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 0)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// check that the queueable fired
		fflib_ArgumentCaptor queueableCaptor = fflib_ArgumentCaptor.forClass(LpoCpoAccessHandlerQueueable.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).enqueueJob((Object)queueableCaptor.capture());

		LpoCpoAccessHandlerQueueable queueable = (LpoCpoAccessHandlerQueueable)queueableCaptor.getValue();
		System.assertEquals(new Map<String, Set<Id>>{'CPO1' => new Set<Id>{contactRecords[0].AccountId}}, queueable.contactIdsByNetworkFacility);
		System.assertEquals(new Set<Id>(), queueable.contactIdsToRemoveMembership);
		System.assertEquals(null, queueable.membershipsToRemove);
		System.assertEquals(null, queueable.membershipsToInsert);

	}

}