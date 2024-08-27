/**
 * @author Seth Heang
 * @group Tests
 * @tag Contact, Account, PersonAccount
 * @domain Core
 * @description Test class for UnifiedCustomerCreationController
 * @changelog
 * 2024-08-16 - Seth Heang - Created
 */
@IsTest(IsParallel=true)
private class UnifiedCustomerCreationControllerTest {

	/**
	 * Test buildPersonAccountDataForInsert() and verify the PersonAccount(Consumer) data mapping
	 */
	@IsTest
	static void testBuildPersonAccountDataMapping() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest personAccountReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		personAccountReq.firstName = 'Seth';
		personAccountReq.lastName = 'Test';
		personAccountReq.preferredName = 'Sam';
		personAccountReq.emailAddress = 'seth@test.com';
		personAccountReq.phoneNumber = '0300123456';
		personAccountReq.addressStreet = '111 Bourke St';
		personAccountReq.addressCity = 'Melbourne';
		personAccountReq.addressState = 'VIC';
		personAccountReq.addressPostalCode = '3000';
		personAccountReq.addressDPID = '12345';
		personAccountReq.addressLongitude = 10.23;
		personAccountReq.addressLatitude = 20.34;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Account result = UnifiedCustomerCreationController.buildPersonAccountDataForInsert(personAccountReq);
		Test.stopTest();

		Assert.areEqual(ApplicationTestDataFactory.personAccountRecordType, result.RecordTypeId, 'record type Id should be Consumer but instead got: ' + result.RecordTypeId);
		Assert.areEqual(personAccountReq.firstName, result.FirstName, 'first name should match but instead got: ' + result.FirstName);
		Assert.areEqual(personAccountReq.lastName, result.LastName, 'last name should match but instead got: ' + result.LastName);
		Assert.areEqual(personAccountReq.preferredName, result.Preferred_Name__pc, 'preferred name should match but instead got: ' + result.Preferred_Name__pc);
		Assert.areEqual(personAccountReq.emailAddress, result.PersonEmail, 'email should match but instead got: ' + result.PersonEmail);
		Assert.areEqual(personAccountReq.phoneNumber, result.Phone, 'phone number should match but instead got: ' + result.Phone);
		Assert.areEqual(personAccountReq.addressStreet, result.PersonMailingStreet, 'street should match but instead got: ' + result.PersonMailingStreet);
		Assert.areEqual(personAccountReq.addressCity, result.PersonMailingCity, 'city should match but instead got: ' + result.PersonMailingCity);
		Assert.areEqual(personAccountReq.addressState, result.PersonMailingState, 'state should match but instead got: ' + result.PersonMailingState);
		Assert.areEqual(personAccountReq.addressPostalCode, result.PersonMailingPostalCode, 'postcode should match but instead got: ' + result.PersonMailingPostalCode);
		Assert.areEqual(personAccountReq.addressDPID, result.MailingDPID__pc, 'mailing dpid should match but instead got: ' + result.MailingDPID__pc);
		Assert.areEqual(personAccountReq.addressLongitude, result.PersonMailingLongitude, 'longitude should match but instead got: ' + result.PersonMailingLongitude);
		Assert.areEqual(personAccountReq.addressLatitude, result.PersonMailingLatitude, 'latitude should match but instead got: ' + result.PersonMailingLatitude);
	}

	/**
	 * Test buildOrganisationDataForInsert() and verify the Account(Organisation) data mapping
	 */
	@IsTest
	static void testBuildOrganisationDataMapping() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest organisationReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		organisationReq.organisationName = 'Seth Org';
		organisationReq.addressStreet = '111 Bourke St';
		organisationReq.addressCity = 'Melbourne';
		organisationReq.addressState = 'VIC';
		organisationReq.addressPostalCode = '3000';
		organisationReq.addressDPID = '12345';
		organisationReq.addressLongitude = 10.23;
		organisationReq.addressLatitude = 20.34;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Account result = UnifiedCustomerCreationController.buildOrganisationDataForInsert(organisationReq);
		Test.stopTest();

		Assert.areEqual(ApplicationTestDataFactory.accountRecordType, result.RecordTypeId, 'record type Id should be Organisation but instead got: ' + result.RecordTypeId);
		Assert.areEqual(organisationReq.organisationName, result.Name, 'organisation name should match but instead got: ' + result.Name);
		Assert.areEqual(organisationReq.addressStreet, result.ShippingStreet, 'street should match but instead got: ' + result.ShippingStreet);
		Assert.areEqual(organisationReq.addressCity, result.ShippingCity, 'city should match but instead got: ' + result.ShippingCity);
		Assert.areEqual(organisationReq.addressState, result.ShippingState, 'state should match but instead got: ' + result.ShippingState);
		Assert.areEqual(organisationReq.addressPostalCode, result.ShippingPostalCode, 'postcode should match but instead got: ' + result.ShippingPostalCode);
		Assert.areEqual(organisationReq.addressDPID, result.Shipping_DPID__c, 'shipping dpid should match but instead got: ' + result.Shipping_DPID__c);
		Assert.areEqual(organisationReq.addressLongitude, result.ShippingLongitude, 'longitude should match but instead got: ' + result.ShippingLongitude);
		Assert.areEqual(organisationReq.addressLatitude, result.ShippingLatitude, 'latitude should match but instead got: ' + result.ShippingLatitude);

	}

	/**
	 * Test buildContactDataForInsert() and verify the Contact data mapping
	 */
	@IsTest
	static void testBuildContactDataMapping() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest contactReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		contactReq.firstName = 'Seth';
		contactReq.lastName = 'Test';
		contactReq.preferredName = 'Sam';
		contactReq.emailAddress = 'seth@test.com';
		contactReq.phoneNumber = '0400123456';
		contactReq.addressStreet = '111 Bourke St';
		contactReq.addressCity = 'Melbourne';
		contactReq.addressState = 'VIC';
		contactReq.addressPostalCode = '3000';
		contactReq.addressDPID = '12345';
		contactReq.addressLongitude = 10.23;
		contactReq.addressLatitude = 20.34;
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Contact result = UnifiedCustomerCreationController.buildContactDataForInsert(contactReq);
		Test.stopTest();

		Assert.areEqual(contactReq.firstName, result.FirstName, 'first name should match but instead got: ' + result.FirstName);
		Assert.areEqual(contactReq.lastName, result.LastName, 'last name should match but instead got: ' + result.LastName);
		Assert.areEqual(contactReq.preferredName, result.Preferred_Name__c, 'preferred name should match but instead got: ' + result.Preferred_Name__c);
		Assert.areEqual(contactReq.emailAddress, result.Email, 'email should match but instead got: ' + result.Email);
		Assert.areEqual(contactReq.phoneNumber, result.MobilePhone, 'mobile number should match but instead got: ' + result.MobilePhone);
		Assert.areEqual(contactReq.addressStreet, result.MailingStreet, 'street should match but instead got: ' + result.MailingStreet);
		Assert.areEqual(contactReq.addressCity, result.MailingCity, 'city should match but instead got: ' + result.MailingCity);
		Assert.areEqual(contactReq.addressState, result.MailingState, 'state should match but instead got: ' + result.MailingState);
		Assert.areEqual(contactReq.addressPostalCode, result.MailingPostalCode, 'postcode should match but instead got: ' + result.MailingPostalCode);
		Assert.areEqual(contactReq.addressDPID, result.MailingDPID__c, 'mailing dpid should match but instead got: ' + result.MailingDPID__c);
		Assert.areEqual(contactReq.addressLongitude, result.MailingLongitude, 'longitude should match but instead got: ' + result.MailingLongitude);
		Assert.areEqual(contactReq.addressLatitude, result.MailingLatitude, 'latitude should match but instead got: ' + result.MailingLatitude);
		Assert.areEqual(contactReq.organisationAccountId, result.AccountId, 'accountId should match but instead got: ' + result.AccountId);
	}

	/**
	 * Test buildConsumerDataForInsert() and verify that it accepts either Account or Contact and insert new Organisation and link to Contact if neccessary
	 */
	@IsTest
	static void testBuildConsumerData() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest consumerReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		consumerReq.firstName = 'Seth';
		consumerReq.lastName = 'Test';
		consumerReq.preferredName = 'Sam';
		consumerReq.emailAddress = 'seth@test.com';
		consumerReq.phoneNumber = '0400123456';
		consumerReq.addressStreet = '111 Bourke St';
		consumerReq.addressCity = 'Melbourne';
		consumerReq.addressState = 'VIC';
		consumerReq.addressPostalCode = '3000';
		consumerReq.addressDPID = '12345';
		consumerReq.addressLongitude = 10.23;
		consumerReq.addressLatitude = 20.34;
		consumerReq.customerType = UnifiedCustomerCreationController.CUSTOMER_TYPE_CONSUMER;

		UnifiedCustomerCreationController.CustomerCreationRequest contactReq = consumerReq.clone();
		contactReq.customerType = UnifiedCustomerCreationController.CUSTOMER_TYPE_ORGANISATION;
		contactReq.organisationName = 'Seth Org';
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SObject personAccountObj = UnifiedCustomerCreationController.buildConsumerDataForInsert(consumerReq);
		SObject contactObj = UnifiedCustomerCreationController.buildConsumerDataForInsert(contactReq);
		Test.stopTest();

		Assert.isTrue(personAccountObj instanceof Account, 'SObject should be instance of PersonAccount but was not');
		Assert.isTrue(contactObj instanceof Contact, 'SObject should be instance of Contact but was not');

		fflib_ArgumentCaptor insertableAccountCaptor = fflib_ArgumentCaptor.forClass(List<Account>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<Account>) insertableAccountCaptor.capture(), fflib_Match.anyBoolean());
		List<Account> insertableAccounts = (List<Account>) insertableAccountCaptor.getValue();

		Assert.isNotNull(insertableAccounts[0].Id, 'Organisation Id should not be null but instead got null');
		Assert.isNotNull(((Contact) contactObj).AccountId, 'AccountId should be populated but instead was null');
		Assert.areEqual(((Contact) contactObj).AccountId, insertableAccounts[0].Id, 'Organisation Id should match but instead got: ' + insertableAccounts[0].Id);
		Assert.areEqual(contactReq.organisationName, insertableAccounts[0].Name, 'Organisation Name should match but instead got: ' + insertableAccounts[0].Name);
	}

	/**
	 * Scenario: Test creation of new contact and link it to an existing organisation
	 *			And verify the operation is successful
	 */
	@IsTest
	static void testCreateNewContactAndLinkedExistingOrganisationWithSuccess() {
		// =====================================
		// Data Preparation
		// =====================================
		Account testOrg = ApplicationTestDataFactory.getAccounts(1, true)[0];

		UnifiedCustomerCreationController.CustomerCreationRequest contactReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		contactReq.firstName = 'Seth';
		contactReq.lastName = 'Test';
		contactReq.preferredName = 'Sam';
		contactReq.emailAddress = 'seth@test.com';
		contactReq.phoneNumber = '0400123456';
		contactReq.addressStreet = '111 Bourke St';
		contactReq.addressCity = 'Melbourne';
		contactReq.addressState = 'VIC';
		contactReq.addressPostalCode = '3000';
		contactReq.addressDPID = '12345';
		contactReq.addressLongitude = 10.23;
		contactReq.addressLatitude = 20.34;
		contactReq.organisationAccountId = testOrg.Id;
		contactReq.customerType = UnifiedCustomerCreationController.CUSTOMER_TYPE_ORGANISATION;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Id customerId = UnifiedCustomerCreationController.createNewCustomer(contactReq);
		Test.stopTest();

		fflib_ArgumentCaptor insertableContactCaptor = fflib_ArgumentCaptor.forClass(List<Contact>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<Contact>) insertableContactCaptor.capture(), fflib_Match.anyBoolean());
		List<Contact> insertableContacts = (List<Contact>) insertableContactCaptor.getValue();

		Assert.isNotNull(insertableContacts[0].Id, 'Contact Id should not be null but instead got null');
		Assert.areEqual(customerId, insertableContacts[0].Id, 'Contact Id should match but instead got: ' + insertableContacts[0].Id);

		fflib_ArgumentCaptor updatableContactCaptor = fflib_ArgumentCaptor.forClass(List<Contact>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Contact>) updatableContactCaptor.capture());
		List<Contact> updatableContacts = (List<Contact>) updatableContactCaptor.getValue();
		Assert.isNotNull(updatableContacts[0].AccountId, 'AccountId should be populated but instead was null');
		Assert.areEqual(testOrg.Id, updatableContacts[0].AccountId, 'Organisation Id should match but instead got: ' + updatableContacts[0].AccountId);
	}

	/**
	 * Scenario: Test creation of a new contact, a new organisation and linking the contact to organisation
	 *			And verify the operation is successful
	 */
	@IsTest
	static void testCreateNewContactAndNewOrganisationWithSuccess() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest contactReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		contactReq.firstName = 'Seth';
		contactReq.lastName = 'Test';
		contactReq.preferredName = 'Sam';
		contactReq.emailAddress = 'seth@test.com';
		contactReq.phoneNumber = '0400123456';
		contactReq.addressStreet = '111 Bourke St';
		contactReq.addressCity = 'Melbourne';
		contactReq.addressState = 'VIC';
		contactReq.addressPostalCode = '3000';
		contactReq.addressDPID = '12345';
		contactReq.addressLongitude = 10.23;
		contactReq.addressLatitude = 20.34;
		contactReq.organisationName = 'Seth New Org';
		contactReq.customerType = UnifiedCustomerCreationController.CUSTOMER_TYPE_ORGANISATION;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Id customerId = UnifiedCustomerCreationController.createNewCustomer(contactReq);
		Test.stopTest();

		fflib_ArgumentCaptor insertableSObjectCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) insertableSObjectCaptor.capture(), fflib_Match.anyBoolean());
		List<SObject> insertableSObjects = new List<SObject>();
		for (Object objList : (List<Object>) insertableSObjectCaptor.getAllValues()){
			insertableSObjects.addAll((List<SObject>) objList);
		}

		Account newAccount;
		Contact newContact;
		for (SObject obj : insertableSObjects){
			if (obj instanceof Account){
				newAccount = (Account) obj;
			} else if (obj instanceof Contact) {
				newContact = (Contact) obj;
			}
		}
		Assert.isNotNull(newAccount?.Id, 'Organisation Id should not be null but instead got null');
		Assert.isNotNull(newContact?.Id, 'Contact Id should not be null but instead got null');
		Assert.areEqual(customerId, newContact?.Id, 'Contact Id should match but instead got: ' + newContact?.Id);

		fflib_ArgumentCaptor updatableContactCaptor = fflib_ArgumentCaptor.forClass(List<Contact>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Contact>) updatableContactCaptor.capture());
		List<Contact> updatableContacts = (List<Contact>) updatableContactCaptor.getValue();
		Assert.isNotNull(updatableContacts[0].AccountId, 'AccountId should be populated but instead was null');
		Assert.areEqual(newAccount.Id, updatableContacts[0].AccountId, 'Organisation Id should match but instead got: ' + updatableContacts[0].AccountId);
	}

	/**
	 * Scenario: Test creation of a new consumer(PersonAccount)
	 *			And verify the operation is successful
	 */
	@IsTest
	static void testCreateNewPersonAccountWithSuccess() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest consumerReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		consumerReq.firstName = 'Seth';
		consumerReq.lastName = 'Test';
		consumerReq.preferredName = 'Sam';
		consumerReq.emailAddress = 'seth@test.com';
		consumerReq.phoneNumber = '0400123456';
		consumerReq.addressStreet = '111 Bourke St';
		consumerReq.addressCity = 'Melbourne';
		consumerReq.addressState = 'VIC';
		consumerReq.addressPostalCode = '3000';
		consumerReq.addressDPID = '12345';
		consumerReq.addressLongitude = 10.23;
		consumerReq.addressLatitude = 20.34;
		consumerReq.customerType = UnifiedCustomerCreationController.CUSTOMER_TYPE_CONSUMER;

		// setup PersonAccount Selector response
		Account resultConsumer = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact resultPersonContact = ApplicationTestDataFactory.getContacts(1, resultConsumer.Id, true)[0]; // the purpose is to get a random contact Id, as practically, PersonContactId is not a separate contact from PersonAccount
		resultConsumer = (Account)ApplicationTestDataFactory.setUnwritableFields(resultConsumer, new Map<String, Object>{ 'PersonContactId' => resultPersonContact.Id });
		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(
				AccountsSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(
				mockAccountsSelector.selectById(
						(Set<Id>) fflib_Match.anyObject()
				)
		).thenReturn(new Map<Id, Account>{resultConsumer.Id => resultConsumer});
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Id customerId = UnifiedCustomerCreationController.createNewCustomer(consumerReq);
		Test.stopTest();

		fflib_ArgumentCaptor insertableConsumerCaptor = fflib_ArgumentCaptor.forClass(List<Account>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<Account>) insertableConsumerCaptor.capture(), fflib_Match.anyBoolean());
		List<Account> insertableConsumers = (List<Account>) insertableConsumerCaptor.getValue();

		// verify PersonAccount.Id is not null
		Assert.isNotNull(insertableConsumers[0].Id, 'Consumer Id should not be null but instead got null');

		// verify the method return PersonAccount.PersonContactId and it matches
		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{insertableConsumers[0].Id}));

		Assert.isNotNull(customerId, 'Consumer Id should not be null but instead got null');
		Assert.areEqual(resultPersonContact.Id, customerId, 'Consumer Id should match PersonContactId but instead got: ' + customerId);
	}

	/**
	 * Scenario: Test creation of a new consumer(PersonAccount)
	 *			And verify the operation is failed due to duplicate and the error message is appropriate
	 */
	@IsTest
	static void testCreateNewPersonAccountWithFailureDueToDuplicateError() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest consumerReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		consumerReq.firstName = 'Seth';
		consumerReq.lastName = 'Test';
		consumerReq.preferredName = 'Sam';
		consumerReq.emailAddress = 'seth@test.com';
		consumerReq.phoneNumber = '0400123456';
		consumerReq.addressStreet = '111 Bourke St';
		consumerReq.addressCity = 'Melbourne';
		consumerReq.addressState = 'VIC';
		consumerReq.addressPostalCode = '3000';
		consumerReq.addressDPID = '12345';
		consumerReq.addressLongitude = 10.23;
		consumerReq.addressLatitude = 20.34;
		consumerReq.customerType = UnifiedCustomerCreationController.CUSTOMER_TYPE_CONSUMER;

		Account dupPersonAccount = ApplicationTestDataFactory.getPersonAccounts(1, false)[0];
		dupPersonAccount.FirstName = 'Seth';
		dupPersonAccount.LastName = 'Test';
		dupPersonAccount.PersonMobilePhone = '0400123456';

		// insert PersonAccount so that DuplicateRule can be tested below
		insert dupPersonAccount;
		// =====================================
		// Testing
		// =====================================

		Id customerId;
		try {
			Test.startTest();
			customerId = UnifiedCustomerCreationController.createNewCustomer(consumerReq);
			Test.stopTest();
		}
		catch(AuraHandledException ex) {
			Assert.areEqual(UnifiedCustomerCreationController.DUPLICATE_CONTACT_MESSAGE, ex.getMessage(), 'Duplicate rule message should match but instead got: ' + ex.getMessage());
		}
	}

	/**
	 * Scenario: Test creation of a new contact
	 *			And verify the operation is failed due to duplicate and the error message is appropriate
	 */
	@IsTest
	static void testCreateNewContactWithFailureDueToDuplicateError() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest contactReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		contactReq.firstName = 'Seth';
		contactReq.lastName = 'Test';
		contactReq.preferredName = 'Sam';
		contactReq.emailAddress = 'seth@dup.com';
		contactReq.phoneNumber = '0400123456';
		contactReq.addressStreet = '111 Bourke St';
		contactReq.addressCity = 'Melbourne';
		contactReq.addressState = 'VIC';
		contactReq.addressPostalCode = '3000';
		contactReq.addressDPID = '12345';
		contactReq.addressLongitude = 10.23;
		contactReq.addressLatitude = 20.34;
		contactReq.customerType = UnifiedCustomerCreationController.CUSTOMER_TYPE_ORGANISATION;

		Account testOrg = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert testOrg;

		Contact dupContact = ApplicationTestDataFactory.getContacts(1, testOrg.Id, false)[0];
		dupContact.FirstName = 'Seth';
		dupContact.LastName = 'Test';
		dupContact.Email = 'seth@dup.com';

		// insert PersonAccount so that DuplicateRule can be tested below
		insert dupContact;
		// =====================================
		// Testing
		// =====================================

		Id customerId;
		try {
			Test.startTest();
			customerId = UnifiedCustomerCreationController.createNewCustomer(contactReq);
			Test.stopTest();
		}
		catch(AuraHandledException ex) {
			Assert.areEqual(UnifiedCustomerCreationController.DUPLICATE_CONTACT_MESSAGE, ex.getMessage(), 'Duplicate rule message should match but instead got: ' + ex.getMessage());
		}
	}

	/**
	 * Scenario: Test creation of a new contact and a new organisation
	 *			And verify the operation has a partial failure where organisation creation is successful but contact creation has failure
	 *			And verify the organisation change is rolled back
	 */
	@IsTest
	static void testCreateNewContactAndNewOrganisationWithPartialFailureThenRollBackChange() {
		// =====================================
		// Data Preparation
		// =====================================
		UnifiedCustomerCreationController.CustomerCreationRequest contactReq = new UnifiedCustomerCreationController.CustomerCreationRequest();
		contactReq.firstName = 'Seth';
		contactReq.lastName = 'Test';
		contactReq.preferredName = 'Sam';
		contactReq.emailAddress = 'seth@dup.com';
		contactReq.phoneNumber = '0400123456';
		contactReq.addressStreet = '111 Bourke St';
		contactReq.addressCity = 'Melbourne';
		contactReq.addressState = 'VIC';
		contactReq.addressPostalCode = '3000';
		contactReq.addressDPID = '12345';
		contactReq.addressLongitude = 10.23;
		contactReq.addressLatitude = 20.34;
		contactReq.organisationName = 'Seth Test Org';
		contactReq.customerType = UnifiedCustomerCreationController.CUSTOMER_TYPE_ORGANISATION;

		Account newOrganisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		newOrganisation = UnifiedCustomerCreationController.buildOrganisationDataForInsert(contactReq);
		Contact newContact = UnifiedCustomerCreationController.buildContactDataForInsert(contactReq);
		newContact.AccountId = newOrganisation.Id;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.eqList(new List<Account>{newOrganisation}), (Boolean) fflib_Match.anyBoolean())).thenAnswer(new InsertedSObjectAnswer(newOrganisation, true, null));
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.eqList(new List<Contact>{newContact}), (Boolean) fflib_Match.anyBoolean())).thenAnswer(new InsertedSObjectAnswer(null, false, UnifiedCustomerCreationController.GENERIC_ERROR_MESSAGE));
		MockUtility.Mocks.when(mockDatabase.dmlRollback((Savepoint)fflib_Match.anyObject())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================

		Id customerId;
		try {
			Test.startTest();
			customerId = UnifiedCustomerCreationController.createNewCustomer(contactReq);
			Test.stopTest();
		}
		catch(AuraHandledException ex) {
			Assert.areEqual(UnifiedCustomerCreationController.GENERIC_ERROR_MESSAGE, ex.getMessage(), 'Error Message should match but instead got: ' + ex.getMessage());
		}

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>) fflib_Match.eqList(new List<Account>{newOrganisation}), (Boolean) fflib_Match.anyBoolean());
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>) fflib_Match.eqList(new List<Contact>{newContact}), (Boolean) fflib_Match.anyBoolean());
		//Make sure Roll back was called once
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlRollback((Savepoint)fflib_Match.anyObject());

	}

	/**
	 * Note: Due to implementation of List<Database.SaveResult> in the main controller, encounters "Invalid conversion from runtime from SObject to List<Database.SaveResult>
	 *		when trying to use thenReturn(SObject) in the dmlInsert MockUtility, thus implement fflib_Answer below.
	 */
	public class InsertedSObjectAnswer implements fflib_Answer {
		private SObject record;
		private Boolean successStatus;
		private String errorMessage;

		public InsertedSObjectAnswer(SObject record, Boolean successStatus, String errorMessage){
			this.record = record;
			this.successStatus = successStatus;
			this.errorMessage = errorMessage;
		}

		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();

			Map<String, Object> result = new Map<String, Object>();
			if(this.successStatus){
				result.put('success',true);
				result.put('id',this.record.Id);

				MockUtility.mockDMLInsertedRecords.addAll(new List<SObject>{this.record});
			}else{
				result.put('success',false);
				result.put('id',null);
				result.put('errors',new List<Map<String, Object>>{
						new Map<String, Object>{
								'message' => this.errorMessage
						}
				});
			}

			saveResults.add(result);
			return (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
		}
	}
}