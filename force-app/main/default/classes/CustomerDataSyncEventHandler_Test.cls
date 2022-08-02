/**
 * @description       : This is a test class for Customer Data Sync Event handler
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-22-2022
 * @last modified by  : Sreenish Krishnan
 **/
@isTest
private class CustomerDataSyncEventHandler_Test {
	@isTest
	static void testprocessCustomerDataEventNewCustomer() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';

		//Prepare the Platform Events published from the ESB
		//Scenario #1: New Customer inserted from SAP
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '1243',
				salesforceRecordID__c = null,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = null,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		//Mock Responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });
		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}

	@isTest
	static void testprocessCustomerDataEventExistingCustomerAPCNFoundNewIntegrationServiceModDate() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 4, 5, 2, 2, 3);

		//Prepare the Platform Events published from the ESB
		//Scenario #2: Existing APCN found and so update the custmer information
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '1242',
				salesforceRecordID__c = personAccount.Id,
				legalFirstName__c = 'FName Scenario 2',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		//Mock Responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });
		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}

	@isTest
	static void testprocessCustomerDataEventExistingCustomerAPCNFoundOldIntegrationServiceModDate() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);

		//Prepare the Platform Events published from the ESB
		//Scenario #2: Existing APCN found and so update the custmer information
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '1242',
				salesforceRecordID__c = personAccount.Id,
				legalFirstName__c = 'FName Scenario 2',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		//Mock Responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });
		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}

	@isTest
	static void testprocessCustomerDataEventSalesforceIDNotFound() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';

		//Prepare the Platform Events published from the ESB
		//Scenario #2: Salesforce ID not found and the APCN is also not found
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '1243',
				salesforceRecordID__c = fflib_IDGenerator.generate(Account.SObjectType),
				legalFirstName__c = 'FName Scenario 2',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		//Mock Responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });
		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}

	@isTest
	static void testprocessCustomerDataEventAPCNNotFoundSalesforceIDFound() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';

		//Prepare the Platform Events published from the ESB
		//Scenario #2: Salesforce ID not found and the APCN is also not found
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '1243',
				salesforceRecordID__c = personAccount.Id,
				legalFirstName__c = 'FName Scenario 2',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		//Mock Responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });
		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}

	//cp email classes
	@isTest
	static void testsyncContactPointEmailCreateNewEmails() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '873337950';
		personAccount.apcn__pc = '873337950';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337950',
				salesforceRecordID__c = personAccount.Id,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContactPointEmailSelector mockCpEmailsSelector = (ContactPointEmailSelector) MockUtility.mockSelector(
			ContactPointEmailSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{ personAccount.id => personAccount });

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			//	.thenReturn(new Map<Id, Account>{ personAccount.Id => personAccount });
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.when(
				mockCpEmailsSelector.selectByParentId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(new Map<Id, ContactPointEmail>{});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}

	@isTest
	static void testsyncContactPointEmailUpdateExistingEmail() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '873337950';
		personAccount.apcn__pc = '873337950';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 4, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		ContactPointEmail cpEmail = ApplicationTestDataFactory.getContactPointEmails(1, personAccount.id, true)[0];
		cpEmail.EmailAddress = 'Laurel_Mertz@hotmail.com';
		cpEmail.Contact__c = personContact.Id;
		cpEmail.Verified__c=true;

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337950',
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContactPointEmailSelector mockCpEmailsSelector = (ContactPointEmailSelector) MockUtility.mockSelector(
			ContactPointEmailSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.when(
				mockCpEmailsSelector.selectByParentId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(new List<ContactPointEmail>{ cpEmail });

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}


	@isTest
	static void testsyncContactPointEmailUpsertExistingEmail() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '873337950';
		personAccount.apcn__pc = '873337950';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 4, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		ContactPointEmail cpEmail = ApplicationTestDataFactory.getContactPointEmails(1, personAccount.id, true)[0];
		cpEmail.EmailAddress = 'Laurel_Mertz@hotmail.com';
		cpEmail.Contact__c = personContact.Id;

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337950',
				salesforceRecordID__c = personAccount.Id,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"true\",\n \"isPrimary\":\"true\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContactPointEmailSelector mockCpEmailsSelector = (ContactPointEmailSelector) MockUtility.mockSelector(
			ContactPointEmailSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.when(
				mockCpEmailsSelector.selectByParentId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(new List<ContactPointEmail>{ cpEmail });

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}

	@isTest
	static void testsyncContactPointEmailDeleteExistingEmail() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '873337950';
		personAccount.apcn__pc = '873337950';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 4, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		ContactPointEmail cpEmail = ApplicationTestDataFactory.getContactPointEmails(1, personAccount.id, true)[0];
		cpEmail.EmailAddress = 'emailtobedeleted@hotmail.com';
		cpEmail.Contact__c = personContact.Id;

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337950',
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContactPointEmailSelector mockCpEmailsSelector = (ContactPointEmailSelector) MockUtility.mockSelector(
			ContactPointEmailSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });

		MockUtility.Mocks.when(
				mockCpEmailsSelector.selectByParentId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(new List<ContactPointEmail>{ cpEmail });

		MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLDeleted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlDelete((List<SObject>) fflib_Match.anyObject());
	}

	//cp phone classes
	@isTest
	static void testsyncContactPointPhoneCreateNewPhones() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '873337951';
		personAccount.apcn__pc = '873337951';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337952',
				salesforceRecordID__c = personAccount.Id,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContactPointPhoneSelector mockCpPhonesSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(
			ContactPointPhoneSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new List<Account>{ personAccount });

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			//	.thenReturn(new Map<Id, Account>{ personAccount.Id => personAccount });
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.when(
				mockCpPhonesSelector.selectByParentId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(new List<ContactPointPhone>{});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}

	@isTest
	static void testsyncContactPointPhoneUpdateExistingPhones() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '873337951';
		personAccount.apcn__pc = '873337951';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		ContactPointPhone cpPhone = ApplicationTestDataFactory.getContactPointPhones(1, personAccount.id, true)[0];
		cpPhone.TelephoneNumber = '+61491570156';
		cpPhone.Contact__c = personContact.Id;

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337952',
				salesforceRecordID__c = personAccount.Id,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[ \n {\n \"phone\":\"0491570156\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContactPointPhoneSelector mockCpPhonesSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(
			ContactPointPhoneSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{ personAccount.id => personAccount });

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.when(
				mockCpPhonesSelector.selectByParentId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(new List<ContactPointPhone>{ cpPhone });

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject());
	}
	@isTest
	static void testsyncContactPointPhoneDeleteExistingPhones() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '873337951';
		personAccount.apcn__pc = '873337951';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		ContactPointPhone cpPhone = ApplicationTestDataFactory.getContactPointPhones(1, personAccount.id, true)[0];
		cpPhone.TelephoneNumber = '+61491570156';
		cpPhone.Contact__c = personContact.Id;

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337952',
				salesforceRecordID__c = personAccount.Id,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccount.Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n },\n {\n \"emailAddress\":\"Dina_Heller@hotmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"true\"\n }\n,\n{\n \"emailAddress\":\"mary.test.cust@yopmail.com\",\n \"isVerified\":\"false\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n } ]',
				phones__c = '[]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		// =====================================
		// Stubbing (No stubbing required as its a platform event)
		// =====================================
		//Mock the Accounts Selector and Database
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContactPointPhoneSelector mockCpPhonesSelector = (ContactPointPhoneSelector) MockUtility.mockSelector(
			ContactPointPhoneSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
				mockAccountsSelector.selectByAPCNAndIdAndPersonAccount(
					(Map<String, Object>) fflib_Match.anyObject(),
					fflib_Match.anyString(),
					fflib_Match.anySObjectField()
				)
			)
			.thenReturn(new List<Account>{ personAccount });

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{ personAccount.id => personAccount });

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.when(
				mockCpPhonesSelector.selectByParentId((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())
			)
			.thenReturn(new List<ContactPointPhone>{ cpPhone });

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();
		System.assertEquals(true, srList[0].isSuccess(), 'event published');

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlDelete((List<SObject>) fflib_Match.anyObject());
	}
}