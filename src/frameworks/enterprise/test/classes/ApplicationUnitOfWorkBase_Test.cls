/***
 * @description
 * Test class for ApplicationUnitOfWorkBase_Test
 *
 * @author Nathan Franklin
 * @date 2020-07-27
 * @group Tests
 * @domain Core
 * @changelog
 */
@IsTest
private class ApplicationUnitOfWorkBase_Test {

	/**
	 * Scenario:
	 * Make sure that records are inserted in the correct order.
	 * Also registers relationships so when a new record is inserted that is linked to another new record, the relationships will resolve correctly.
	 */
	@IsTest
	private static void testEnsureNewRecordsAreInsertedCorrectly() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		List<Contact> contactRecords = ApplicationTestDataFactory.getContacts(2, (Id)null, false);
		Case caseRecord = ApplicationTestDataFactory.getCases(1, false)[0];
		Article__c articleRecord = ApplicationTestDataFactory.getArticles(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();
		fflib_InOrder inOrder1 = new fflib_InOrder(MockUtility.Mocks, new List<Object>{ mockDatabase });

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Article__c.SObjectType,
				Account.SObjectType,
				Contact.SObjectType,
				Case.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(caseRecord, true, '');
		uow.registerNew(accountRecord, true, '');
		uow.registerNew(contactRecords[0], Contact.AccountId, accountRecord);
		uow.registerNew(contactRecords[1], Contact.AccountId, accountRecord, true, '');
		uow.registerNew(articleRecord);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{articleRecord}, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{accountRecord}, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{caseRecord}, false);

		// make sure the dmlInsert was executed in the specific order that they were added in
		((ApplicationDatabase)inOrder1.verify(mockDatabase, MockUtility.Mocks.calls(1))).dmlInsert(new List<SObject>{articleRecord}, false);
		((ApplicationDatabase)inOrder1.verify(mockDatabase, MockUtility.Mocks.calls(1))).dmlInsert(new List<SObject>{accountRecord}, false);
		((ApplicationDatabase)inOrder1.verify(mockDatabase, MockUtility.Mocks.calls(1))).dmlInsert(new List<SObject>{caseRecord}, false);

		System.assertNotEquals(null, accountRecord.Id, 'Expected Account Id to be set.');
		System.assertEquals(accountRecord.Id, contactRecords[0].AccountId, 'Expected Account Id to be set.');
		System.assertEquals(accountRecord.Id, contactRecords[1].AccountId, 'Expected Account Id to be set.');
	}

	/**
	 * Scenario:
	 *
	 * 1. New account record to be created
	 * 2. Existing billing account updated and will link newly create account record (Organisation__c)
	 * 3. 1 article to be updated with it's entire dataset
	 */
	@IsTest
	private static void testEnsureDirtyRecordsContainAllFieldsRegistered() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		Billing_Account__c billingAccountRecord = ApplicationTestDataFactory.getBillingAccounts(1, (Id)null, 'SAP ERP', true)[0];
		Article__c articleRecord = ApplicationTestDataFactory.getArticles(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Billing_Account__c.SObjectType,
				Article__c.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accountRecord);
		uow.registerDirty(new List<SObject>{billingAccountRecord}, true, '');
		uow.registerRelationship(billingAccountRecord, Billing_Account__c.Organisation__c, accountRecord);
		uow.registerDirty(new List<SObject>{articleRecord});

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{accountRecord}, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{billingAccountRecord}, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{articleRecord}, false);

		System.assertEquals(accountRecord.Id, billingAccountRecord.Organisation__c, 'Expected Account Id to be set.');
	}

	/**
	 * Scenario:
	 *
	 * 1. New account record to be created
	 * 2. New billing account to be created and will link newly create account record (Organisation__c)
	 * 3. Existing billing account updated and will link newly create account record (Organisation__c)
	 * 4. 1 article to be updated with it's entire dataset
	 */
	@IsTest
	private static void testEnsureDirtyRecordsCanBePartiallyRegisteredAndConcatenatedWithRelationships() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Billing_Account__c newBillingAccountRecord = ApplicationTestDataFactory.getBillingAccounts(1, accountRecord.Id, 'SAP ERP', false)[0];
		Article__c articleRecord = ApplicationTestDataFactory.getArticles(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Billing_Account__c.SObjectType,
				Article__c.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(newBillingAccountRecord);

		// the whole record will be registered
		uow.registerDirty(new Article__c(Id = articleRecord.Id, Name = articleRecord.Name, TrackingID__c = 'TEST', ProductCategory__c = 'eParcel', Source_System__c = 'SAP ERP'));

		// the selected fields will be appended to the existing registered record
		uow.registerDirty(new Article__c(Id = articleRecord.Id, ArticleID__c = 'TEST'), new List<SObjectField>{Article__c.ArticleID__c});

		// the selected fields will be appended to the existing registered record
		// note the exclusion of the SubProduct__c field
		uow.registerDirty(new Article__c(Id = articleRecord.Id, Source_System__c = 'TEAM', SubProduct__c = 'IMNOTUSED'), new List<SObjectField>{Article__c.Source_System__c});

		// all fields will be appended to the existing registered record
		// note the return value will be a reference to the entire registered record
		Article__c registeredArticle = (Article__c)uow.registerDirty(new Article__c(Id = articleRecord.Id, Service__c = 'Service'));

		// register the billing account relationship to the article
		uow.registerRelationship(registeredArticle, Article__c.Billing_Account__c, newBillingAccountRecord);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{newBillingAccountRecord}, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{registeredArticle}, false);

		// verify the expected fields were included in the dmlUpdate
		// thse are progressivly built as the same record is
		Set<String> populatedArticleFields = registeredArticle.getPopulatedFieldsAsMap().keySet();
		System.assert(populatedArticleFields.contains(String.valueOf(Article__c.Name)), 'Partial Article should have included field');
		System.assert(populatedArticleFields.contains(String.valueOf(Article__c.TrackingID__c)), 'Partial Article should have included field');
		System.assert(populatedArticleFields.contains(String.valueOf(Article__c.ProductCategory__c)), 'Partial Article should have included field');
		System.assert(populatedArticleFields.contains(String.valueOf(Article__c.ArticleID__c)), 'Partial Article should have included field');
		System.assert(populatedArticleFields.contains(String.valueOf(Article__c.Source_System__c)), 'Partial Article should have included field');
		System.assert(populatedArticleFields.contains(String.valueOf(Article__c.Source_System__c)), 'Partial Article should have included field');
		System.assert(populatedArticleFields.contains(String.valueOf(Article__c.Billing_Account__c)), 'Partial Article should have included field');
		System.assertEquals(false, populatedArticleFields.contains(String.valueOf(Article__c.SubProduct__c)), 'Partial Article should not have included field');
		System.assertEquals('TEAM', registeredArticle.Source_System__c, 'Value should have been overwritten');

		// ensure billing account was populated on Article record
		System.assertNotEquals(null, newBillingAccountRecord.Id, 'Expected Billing Account Id to not be null');
		System.assertEquals(newBillingAccountRecord.Id, registeredArticle.Billing_Account__c, 'Expected Billing Account Id to be set');
	}

	/**
	 * Scenario
	 * Ensures that registered relationships in UOW are resolved correctly
	 */
	@IsTest
	private static void testRelationshipMapping() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accountRecords = ApplicationTestDataFactory.getAccounts(2, false);
		List<Billing_Account__c> billingAccountRecords = ApplicationTestDataFactory.getBillingAccounts(2, (Id)null, 'SAP ERP', false);
		List<Contact> contactRecords = ApplicationTestDataFactory.getContacts(2, (Id)null, false);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Billing_Account__c.SObjectType,
				Contact.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		// make sure that all the relationships are registered correctly
		uow.registerRelationship(billingAccountRecords[0], Billing_Account__c.Organisation__c, accountRecords[0]);
		uow.registerRelationship(contactRecords[0], Contact.BillingAccount__c, billingAccountRecords[0]);
		uow.registerRelationship(contactRecords[0], Contact.AccountId, accountRecords[0]);

		uow.registerRelationship(billingAccountRecords[1], Billing_Account__c.Organisation__c, accountRecords[1]);
		uow.registerRelationship(contactRecords[1], Contact.BillingAccount__c, billingAccountRecords[1]);
		uow.registerRelationship(contactRecords[1], Contact.AccountId, accountRecords[1]);

		uow.registerNew(accountRecords);
		uow.registerNew(billingAccountRecords);
		uow.registerNew(contactRecords);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(accountRecords, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(billingAccountRecords, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(contactRecords, false);

		System.assertNotEquals(null, accountRecords[0].Id);
		System.assertNotEquals(null, billingAccountRecords[0].Id);
		System.assertNotEquals(null, contactRecords[0].Id);

		System.assertNotEquals(null, accountRecords[1].Id);
		System.assertNotEquals(null, billingAccountRecords[1].Id);
		System.assertNotEquals(null, contactRecords[1].Id);

		System.assertEquals(accountRecords[0].Id, billingAccountRecords[0].Organisation__c, 'Expected Account Id to be set.');
		System.assertEquals(billingAccountRecords[0].Id, contactRecords[0].BillingAccount__c, 'Expected Billing Account Id to be set.');
		System.assertEquals(accountRecords[0].Id, contactRecords[0].AccountId, 'Expected Account Id to be set.');

		System.assertEquals(accountRecords[1].Id, billingAccountRecords[1].Organisation__c, 'Expected Account Id to be set.');
		System.assertEquals(billingAccountRecords[1].Id, contactRecords[1].BillingAccount__c, 'Expected Billing Account Id to be set.');
		System.assertEquals(accountRecords[1].Id, contactRecords[1].AccountId, 'Expected Account Id to be set.');
	}

	/**
	 * Scenario:
	 * Make sure that when calling upsert it routes the records to either an insert or an update
	 */
	@IsTest
	private static void testEnsureUpsertingRecordsDoesInsertsAndUpdates() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
		accounts[0].Id = fflib_IDGenerator.generate(Account.getSObjectType());
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(2, (Id)null, false);
		contacts[0].Id = fflib_IDGenerator.generate(Contact.getSObjectType());

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Contact.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerUpsert(accounts);
		uow.registerUpsert(contacts, true, '');

		// make sure relationships are registered correctly
		uow.registerRelationship(contacts[0], Contact.AccountId, accounts[0]);
		uow.registerRelationship(contacts[1], Contact.AccountId, accounts[1]);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{accounts[1]}, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate(new List<SObject>{accounts[0]}, false);

		// make sure that the relationships were resolved correctly in the context of upserting
		System.assertNotEquals(null, accounts[1].Id, 'Expected Account Id to be set.');
		System.assertEquals(accounts[0].Id, contacts[0].AccountId, 'Expected Account Id to be set.');
		System.assertEquals(accounts[1].Id, contacts[1].AccountId, 'Expected Account Id to be set.');
	}

	/**
	 * Scenario:
	 * Ensures that a platform event is published on the successful completion of a transaction.
	 */
	@IsTest
	private static void testEnsurePlatformEventIsPublishedOnSuccessfulTransaction() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);

		// this is the event that Camunda would send to communicate the an app was provisioned successfully
		List<ExternalOnboardingEvent__e> events = new List<ExternalOnboardingEvent__e>{
				new ExternalOnboardingEvent__e(Application__c = 'Application__c', IsBam__c = true, RequestNumber__c = 'RequestNumber__c', Status__c = 'Status__c', Type__c = 'Type__c'),
				new ExternalOnboardingEvent__e(Application__c = 'Application__c', IsBam__c = true, RequestNumber__c = 'RequestNumber__c', Status__c = 'Status__c', Type__c = 'Type__c')
		};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				ExternalOnboardingEvent__e.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accounts);
		uow.registerPublishAfterSuccessTransaction(events);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).eventPublish(events);

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Ensures that dmlDelete is called when a record is queued for deletion in UOW.
	 * This also verifies that the deletes are done in reverse order of the way they are added
	 */
	@IsTest
	private static void testEnsureRecordsDeletion() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Article__c articleRecord = ApplicationTestDataFactory.getArticles(1, true)[0];
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(2, accountRecord.Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
		MockUtility.Mocks.stopStubbing();
		fflib_InOrder inOrder1 = new fflib_InOrder(MockUtility.Mocks, new List<Object>{ mockDatabase });

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Contact.SObjectType,
				Article__c.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDeleted(accountRecord);
		uow.registerDeleted(contacts);
		uow.registerDeleted(articleRecord, true, '');

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete(new List<Account>{accountRecord}, false);
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete(contacts, false);

		// make sure the dmlDelete was executed in the specific order that they were added in
		((ApplicationDatabase)inOrder1.verify(mockDatabase, MockUtility.Mocks.calls(1))).dmlDelete(contacts, false);
		((ApplicationDatabase)inOrder1.verify(mockDatabase, MockUtility.Mocks.calls(1))).dmlDelete(new List<SObject>{accountRecord}, false);

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Make sure an exception is thrown if an SObject is added to a UOW that does not support it
	 */
	@IsTest
	private static void testSObjectInvalidForUnitOfWork() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Contact.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerNew(accountRecord);

			// make sure committing the work is done in the correct order
			uow.commitWork();

			System.assert(false);
		} catch(Exception e) {
			// Make sure that an exception is thrown when the sobject type is not registered in the uow
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * End-to-end integration flow
	 */
	@IsTest
	private static void testEnsureRecordsAreInsertedAndUpdatedIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		accountRecord.LEGACY_ID__c = '60000000';
		insert accountRecord;

		Billing_Account__c billingAccountRecord = ApplicationTestDataFactory.getBillingAccounts(1, accountRecord.Id, 'SAP ERP', false)[0];
		Article__c articleRecord = ApplicationTestDataFactory.getArticles(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Billing_Account__c.SObjectType,
				Article__c.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDirty(accountRecord);
		uow.registerNew(articleRecord);
		uow.registerNew(billingAccountRecord);
		uow.registerRelationship(articleRecord, Article__c.Billing_Account__c, billingAccountRecord);

		// make sure committing the work is done in the correct order
		uow.commitWork();

		System.assertNotEquals(null, billingAccountRecord.Id, 'Expected a record to be created');
		System.assertNotEquals(null, articleRecord.Id, 'Expected a record to be created');
		System.assertEquals(billingAccountRecord.Id, articleRecord.Billing_Account__c, 'Expected billing account to be assigned');
	}

	/**
	 * Scenario:
	 * Make sure that a record is created in ExceptionLog__c when an DML error occurs and the UOW is not configured to throw an exception for that record
	 */
	@IsTest
	private static void testEnsureErrorsAreCorrectlyLoggedIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		accountRecord.LEGACY_ID__c = '60000000';
		insert accountRecord;

		// do not parent it to account (we only create an account because of a data error in billing account trigger that hasn't been fixed)
		Billing_Account__c billingAccountRecord = ApplicationTestDataFactory.getBillingAccounts(1, (Id)null, 'SAP ERP', false)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Billing_Account__c.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		// should throw an exception since it's in a master-detail with Account and the Organisation__c field is not set
		uow.registerNew(billingAccountRecord, false, 'ApplicationUnitOfWork_Test.testEnsureErrorsAreCorrectlyLoggedIntegration');

		uow.commitWork();

		Test.stopTest();

		System.assertEquals(0, [Select Count() From Billing_Account__c]);

		ExceptionLog__c log = [Select Id From ExceptionLog__c];
		System.assertNotEquals(null, log.Id);

	}

	/**
	 * Scenario:
	 * Make sure an insert operation occurs (additional insert) after the record insert is attempted.
	 * The second insert operation would be ExceptionLog__c.
	 * The mock AnswerGenericDMLFailed forces an error to be returned so the error can be simulated
	 */
	@IsTest
	private static void testEnsureErrorsAreLoggedOnInsertFailureWhenNoExceptionIsGenerated() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accountRecord, false, 'RandomClass.RandomMethod');

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Make sure an exception is thrown after the record insert is attempted where the UOW is configured to throw an exception for that specific record
	 * The mock AnswerGenericDMLFailed simulates an error
	 */
	@IsTest
	private static void testEnsureExceptionIsThrownOnInsertFailure() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerNew(accountRecord, true, 'RandomClass.RandomMethod');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * Make sure an insert operation occurs after the record update is attempted.
	 * The insert operation to listen for would be ExceptionLog__c.
	 * The mock AnswerGenericDMLFailed forces an error to be returned so the error can be simulated
	 */
	@IsTest
	private static void testEnsureErrorsAreLoggedOnUpdateFailureWhenNoExceptionIsGenerated() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDirty(accountRecord, false, 'RandomClass.RandomMethod');

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Make sure an exception is thrown after the record update is attempted where the UOW is configured to throw an exception for that specific record
	 * The mock AnswerGenericDMLFailed simulates an error
	 */
	@IsTest
	private static void testEnsureExceptionIsThrownOnUpdateFailure() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDirty(accountRecord, true, 'RandomClass.RandomMethod');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * Make sure an insert operation occurs after the record dekete is attempted.
	 * The insert operation to listen for would be ExceptionLog__c.
	 * The mock AnswerGenericDMLDeleteFailed forces an error to be returned so the error can be simulated
	 */
	@IsTest
	private static void testEnsureErrorsAreLoggedOnDeleteFailureWhenNoExceptionIsGenerated() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleteFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDeleted(accountRecord, false, 'RandomClass.RandomMethod');

		// make sure committing the work is done in the correct order
		uow.commitWork();

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logMessage((List<String>)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

		// PMD warning
		System.assert(true);
	}

	/**
	 * Scenario:
	 * Make sure an exception is thrown after the record delete is attempted where the UOW is configured to throw an exception for that specific record
	 * The mock AnswerGenericDMLDeleteFailed simulates an error
	 */
	@IsTest
	private static void testEnsureExceptionIsThrownOnDeleteFailure() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleteFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerDeleted(accountRecord, true, 'RandomClass.RandomMethod');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This tests an insert operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideGeneratesExceptionOnInsert() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailedLockError());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerNew(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This tests an update operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideGeneratesExceptionOnUpdate() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailedLockError());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerDirty(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This ensures when an error occurs that is not an UNABLE_TO_LOCK_ROW error, no exception is thrown
	 * This tests an update operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideDoesNotGenerateExceptionOnUpdate() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerDirty(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// make sure no exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// an exception was thrown but not expected
			System.assert(false, 'Did not expect an exception to be thrown');
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This ensures when an error occurs that is not an UNABLE_TO_LOCK_ROW error, no exception is thrown
	 * This tests an insert operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideDoesNotGenerateExceptionOnInsert() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerNew(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// make sure no exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// an exception was thrown but not expected
			System.assert(false, 'Did not expect an exception to be thrown');
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This ensures when an error occurs that is not an UNABLE_TO_LOCK_ROW error, no exception is thrown
	 * This tests a delete operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideDoesNotGenerateExceptionOnDelete() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleteFailed());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerDeleted(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// make sure no exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// an exception was thrown but not expected
			System.assert(false, 'Did not expect an exception to be thrown');
		}
	}

	/**
	 * Scenario:
	 * When throwLockErrors is set to true, an exception should be generated when an UNABLE_TO_LOCK_ROW error occurs
	 * This tests a delete operation
	 */
	@IsTest
	private static void ensureLockFailureOverrideGeneratesExceptionOnDelete() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLDeleteFailedLockError());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		// this allows the uow to throw an exception when work is being commited and an UNABLE_TO_LOCK_ROW error is returned
		uow.throwLockErrors = true;

		// even though throwOnError is false, the global throwLockErrors being set to true should still cause an exception to be thrown
		uow.registerDeleted(accountRecord, false, 'My Error');

		try {
			uow.commitWork();

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(Exception ex) {
			// make sure the exception is thrown
			System.assert(true);
		}
	}

	/**
	 * Scenario:
	 * Make sure a new record can not be updated with unit of work
	 */
	@IsTest
	private static void ensureNewRecordsCanNotBeRegisteredDirty() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerDirty(accountRecord, false, 'My Error');

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(ApplicationUnitOfWorkBase.UnitOfWorkException ex) {
			// make sure the exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// not sure what this exception is?
			System.assert(false, 'Incorrect exception type');
		}
	}

	/**
	 * Scenario:
	 * Make sure an existing record can not be inserted with unit of work
	 */
	@IsTest
	private static void ensureExistingRecordsCanNotBeRegisteredNew() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerNew(accountRecord, false, 'My Error');

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(ApplicationUnitOfWorkBase.UnitOfWorkException ex) {
			// make sure the exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// not sure what this exception is?
			System.assert(false, 'Incorrect exception type');
		}
	}

	/**
	 * Scenario:
	 * Make sure an new record can not be deleted with unit of work
	 */
	@IsTest
	private static void ensureNewRecordsCanNotBeRegisterDeleted() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		try {
			uow.registerDeleted(accountRecord, false, 'My Error');

			// this will fail the test if no exception is thrown
			System.assert(false, 'Expected an exception to be thrown');
		} catch(ApplicationUnitOfWorkBase.UnitOfWorkException ex) {
			// make sure the exception is thrown
			System.assert(true);
		} catch(Exception ex) {
			// not sure what this exception is?
			System.assert(false, 'Incorrect exception type');
		}
	}
}