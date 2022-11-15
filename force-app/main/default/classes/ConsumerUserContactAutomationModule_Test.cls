/**
 * @author Naveen Rajanna
 * @date 2022-10-28
 * @group Tests
 * @description Test class covering ConsumerUserContactAutomationModule
 * @changelog
 */
@IsTest
private class ConsumerUserContactAutomationModule_Test {
	/**
	 * This test method verifies the business logic and if the eligible params are passed on to Asyncworker
	 * Business Logic - If a User has been inserted and is opted in for Marketing then only trigger Asyncworker to update opt in flag for their relevant contacts
	 */
	@IsTest
	private static void testOnAfterInsertUpdateContactFields() {
		// Disable trigger execution
		MockUtility.disableTriggerExecution();

		// =====================================
		// Data Preparation
		// =====================================
		// Generate Consumer Account - Person Account
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'DDC Consumer Community User'][0].Id;

		// Generate 2 community users having valid profile
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>(contacts.keySet()), true);
		users[0].ProfileId = profileId;
		users[0].Opt_In_For_Marketing__c = true; // positive scenario - which requires a contact update

		users[1].ProfileId = profileId;
		users[1].Opt_In_For_Marketing__c = false; // This user's contact doesn't need a update

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ConsumerUserContactAutomationModule module = ConsumerUserContactAutomationModule.newInstance();
		module.onAfterInsert(users, mockUow);
		Test.stopTest();

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class); // <-- grab the contact update that was passed

		// THIS IS THE IMPORTANT TEST HERE TO MAKE SURE IT ONLY FIRED ONCE!
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1)))
			.registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());

		// verify both cases passed in were queued for updating
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();

		Set<Id> contactIdsEnqueued = ((Set<Id>) ((Map<String, Object>) stagedWorker.params).get('contactIds'));
		System.assertEquals(1, contactIdsEnqueued.size(), 'Expected to update 1 contact');
		System.assertEquals(users[0].ContactId, (new List<Id>(contactIdsEnqueued))[0], 'Expected to update 1 contact');
	}

	/**
	 * This test method verifies the business logic and if the eligible params are passed on to Asyncworker
	 * Business Logic - If a User has been updated to opt in for Marketing then only trigger Asyncworker to update opt in flag for their relevant contacts
	 */
	@IsTest
	private static void testOnAfterUpdateUpdateContactFields() {
		// Disable trigger execution
		MockUtility.disableTriggerExecution();

		// =====================================
		// Data Preparation
		// =====================================
		// Generate Consumer Account - Person Account
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'DDC Consumer Community User'][0].Id;

		// Generate 2 community users having valid profile
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>(contacts.keySet()), true);
		users[0].ProfileId = profileId;
		users[0].Opt_In_For_Marketing__c = false;
		users[1].ProfileId = profileId;
		users[1].Opt_In_For_Marketing__c = true;
		List<User> oldUsers = new List<User>{ users[0].clone(true), users[1].clone(true) };
		// User updated to Opt In
		users[0].Opt_In_For_Marketing__c = true; // positive scenario - which requires a contact update
		users[1].Opt_In_For_Marketing__c = false; // This user's contact doesn't need a update

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ConsumerUserContactAutomationModule module = ConsumerUserContactAutomationModule.newInstance();
		module.onAfterUpdate(users, new Map<Id, User>(oldUsers), mockUow);
		Test.stopTest();

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class); // <-- grab the contact update that was passed

		// THIS IS THE IMPORTANT TEST HERE TO MAKE SURE IT ONLY FIRED ONCE!
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUOW, MockUtility.Mocks.times(1)))
			.registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());

		// verify both cases passed in were queued for updating
		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();

		Set<Id> contactIdsEnqueued = ((Set<Id>) ((Map<String, Object>) stagedWorker.params).get('contactIds'));
		System.assertEquals(1, contactIdsEnqueued.size(), 'Expected to update 1 contact');
		System.assertEquals(users[0].ContactId, (new List<Id>(contactIdsEnqueued))[0], 'Expected to update 1 contact');
	}

	/**
	 * This test method verifies Contact Update (DML) which the Asyncworker will execute in async fashion
	 */
	@IsTest
	static void testAsyncUpdateContactDetailsWorkerUpdatesContact() {
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		con.Legal_Marketing_Opt_In__c = false;

		ConsumerUserContactAutomationModule.AsyncUpdateContactDetailsWorker worker = new ConsumerUserContactAutomationModule.AsyncUpdateContactDetailsWorker();
		Map<String, Object> params = new Map<String, Object>{ 'contactIds' => new Set<Id>{ con.Id } };
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		List<Contact> updateableContacts = new List<Contact>();
		updateableContacts.add(new Contact(Id = con.Id, Legal_Marketing_Opt_In__c = true));

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		System.assertEquals(
			ConsumerUserContactAutomationModule.AsyncUpdateContactDetailsWorker.class,
			worker.getClassType(),
			'matching type'
		);
		System.assertEquals(Contact.SObjectType, worker.getSObjectTypeGroup(), 'matching type');

		worker.deserialiseParams(JSON.serialize(params));
		System.assertEquals(1, worker.contactIds.size(), 'It should contain Contact Set<Id> in params after deserialise');
		System.assertEquals(con.Id, (new List<Id>(worker.contactIds))[0], 'It should contain Contact Set<Id> in params after deserialise');

		worker.execute(mockUow);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1))
			.registerDirty(
				(List<Contact>) fflib_Match.eq(updateableContacts),
				fflib_Match.eqBoolean(false),
				fflib_Match.eqString(
					ConsumerUserContactAutomationModule.class.getName() +
					'.' +
					ConsumerUserContactAutomationModule.AsyncUpdateContactDetailsWorker.class.getName()
				)
			);

		Test.stopTest();
	}

	private class MockException extends Exception {
	}

	@IsTest
	private static void testOnAfterInsertException() {
		// Disable trigger execution
		MockUtility.disableTriggerExecution();

		// =====================================
		// Data Preparation
		// =====================================
		// Generate Consumer Account - Person Account
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'DDC Consumer Community User'][0].Id;

		// Generate 2 community users having valid profile
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>(contacts.keySet()), true);
		users[0].ProfileId = profileId;
		users[0].Opt_In_For_Marketing__c = true; // positive scenario - which requires a contact update

		users[1].ProfileId = profileId;
		users[1].Opt_In_For_Marketing__c = false; // This user's contact doesn't need a update

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger) MockUtility.mockUtility(ApplicationLogger.class);
		MockUtility.Mocks.startStubbing();
		((ApplicationUnitOfWork) MockUtility.Mocks.doThrowWhen(new MockException(), mockUow))
			.registerAsyncWork(
				new ApplicationUnitOfWork.AsyncStagingWorker(
					ConsumerUserContactAutomationModule.AsyncUpdateContactDetailsWorker.class,
					(Map<String, Object>) fflib_Match.anyObject()
				)
			);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ConsumerUserContactAutomationModule module = ConsumerUserContactAutomationModule.newInstance();
		module.onAfterInsert(users, mockUow);
		Test.stopTest();

		((ApplicationLogger) MockUtility.Mocks.verify(mockLogger, 1))
			.logException(
				(ApplicationLogger.ExceptionWrapper) fflib_Match.anyObject(),
				fflib_Match.anyString(),
				fflib_Match.anyString(),
				fflib_Match.anyString(),
				fflib_Match.anyString(),
				(ApplicationLogger.LoggingLevel) fflib_Match.anyObject()
			);
	}

	@IsTest
	private static void testOnAfterUpdateException() {
		// Disable trigger execution
		MockUtility.disableTriggerExecution();

		// =====================================
		// Data Preparation
		// =====================================
		// Generate Consumer Account - Person Account
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Map<Id, Contact> contacts = new Map<Id, Contact>(ApplicationTestDataFactory.getContacts(2, acc.Id, true));
		Id profileId = [SELECT Id FROM Profile WHERE Profile.Name = 'DDC Consumer Community User'][0].Id;

		// Generate 2 community users having valid profile
		List<User> users = ApplicationTestDataFactory.getCommunityUsers(2, new List<Id>(contacts.keySet()), true);
		users[0].ProfileId = profileId;
		users[0].Opt_In_For_Marketing__c = false;
		users[1].ProfileId = profileId;
		users[1].Opt_In_For_Marketing__c = true;
		List<User> oldUsers = new List<User>{ users[0].clone(true), users[1].clone(true) };
		// User updated to Opt In
		users[0].Opt_In_For_Marketing__c = true; // positive scenario - which requires a contact update
		users[1].Opt_In_For_Marketing__c = false; // This user's contact doesn't need a update

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ApplicationLogger mockLogger = (ApplicationLogger) MockUtility.mockUtility(ApplicationLogger.class);
		MockUtility.Mocks.startStubbing();
		((ApplicationUnitOfWork) MockUtility.Mocks.doThrowWhen(new MockException(), mockUow))
			.registerAsyncWork(
				new ApplicationUnitOfWork.AsyncStagingWorker(
					ConsumerUserContactAutomationModule.AsyncUpdateContactDetailsWorker.class,
					(Map<String, Object>) fflib_Match.anyObject()
				)
			);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ConsumerUserContactAutomationModule module = ConsumerUserContactAutomationModule.newInstance();
		module.onAfterUpdate(users, new Map<Id, User>(oldUsers), mockUow);
		Test.stopTest();

		((ApplicationLogger) MockUtility.Mocks.verify(mockLogger, 1))
			.logException(
				(ApplicationLogger.ExceptionWrapper) fflib_Match.anyObject(),
				fflib_Match.anyString(),
				fflib_Match.anyString(),
				fflib_Match.anyString(),
				fflib_Match.anyString(),
				(ApplicationLogger.LoggingLevel) fflib_Match.anyObject()
			);
	}
}