/**
 * @description       : This is a test class for Customer Data Sync Event handler
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @changelog
 * 2022-08-14 			Sreenish Krishnan - Created
 * 2023-08-24 			Boris Bachovski - Fix failing test method (testprocessCustomerDataEventSalesforceIDNotFound) due to changes in the actual class made in Oct '22
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
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
		personContact.APCN__c = '1242';

		personAccount = (Account) ApplicationTestDataFactory.setUnwritableFields(
			personAccount,
			new Map<String, Object>{ 'PersonContactId' => personContact.Id }
		);

		//upsert operartions
		List<Map<String, Object>> accUpsertResult = new List<Map<String, Object>>();
		Map<String, Object> uresultMap1 = new Map<String, Object>{ 'success' => true, 'id' => personAccount.Id };
		accUpsertResult.add(uresultMap1);
		List<Database.UpsertResult> mockResult1 = (List<Database.UpsertResult>) JSON.deserialize(
			JSON.serialize(accUpsertResult),
			List<Database.UpsertResult>.class
		);

		//personAccount.PersonContactId = personContact.Id;
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

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{ personAccount.Id => personAccount });

		Schema.SObjectType otAccount = Schema.getGlobalDescribe().get('Account');
		Schema.SObjectField fAPCN = otAccount.getDescribe().fields.getMap().get('APCN__c');

		MockUtility.Mocks.when(
				mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.eqSObjectField(fAPCN))
			)
			.thenReturn(mockResult1);

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

		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		personAccount = (Account) ApplicationTestDataFactory.setUnwritableFields(
			personAccount,
			new Map<String, Object>{ 'PersonContactId' => personContact.Id }
		);

		//upsert operartions
		List<Map<String, Object>> accUpsertResult = new List<Map<String, Object>>();
		Map<String, Object> uresultMap1 = new Map<String, Object>{ 'success' => true, 'id' => personAccount.Id };
		accUpsertResult.add(uresultMap1);
		List<Database.UpsertResult> mockResult1 = (List<Database.UpsertResult>) JSON.deserialize(
			JSON.serialize(accUpsertResult),
			List<Database.UpsertResult>.class
		);
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

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{ personAccount.Id => personAccount });
		Schema.SObjectType otAccount = Schema.getGlobalDescribe().get('Account');
		Schema.SObjectField fAPCN = otAccount.getDescribe().fields.getMap().get('APCN__c');

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject()))
			.thenReturn(accUpsertResult);

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

		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		personAccount = (Account) ApplicationTestDataFactory.setUnwritableFields(
			personAccount,
			new Map<String, Object>{ 'PersonContactId' => personContact.Id }
		);
		//upsert operartions
		List<Map<String, Object>> accUpsertResult = new List<Map<String, Object>>();
		Map<String, Object> uresultMap1 = new Map<String, Object>{ 'success' => true, 'id' => personAccount.Id };
		accUpsertResult.add(uresultMap1);
		List<Database.UpsertResult> mockResult1 = (List<Database.UpsertResult>) JSON.deserialize(
			JSON.serialize(accUpsertResult),
			List<Database.UpsertResult>.class
		);

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

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{ personAccount.Id => personAccount });

		Schema.SObjectType otAccount = Schema.getGlobalDescribe().get('Account');
		Schema.SObjectField fAPCN = otAccount.getDescribe().fields.getMap().get('APCN__c');
		MockUtility.Mocks.when(
				mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.eqSObjectField(fAPCN))
			)
			.thenReturn(mockResult1);

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
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);
		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

		personAccount = (Account) ApplicationTestDataFactory.setUnwritableFields(
			personAccount,
			new Map<String, Object>{ 'PersonContactId' => personContact.Id }
		);

		//upsert operartions
		List<Map<String, Object>> accUpsertResult = new List<Map<String, Object>>();
		Map<String, Object> uresultMap1 = new Map<String, Object>{ 'success' => true, 'id' => personAccount.Id };
		accUpsertResult.add(uresultMap1);
		List<Database.UpsertResult> mockResult1 = (List<Database.UpsertResult>) JSON.deserialize(
			JSON.serialize(accUpsertResult),
			List<Database.UpsertResult>.class
		);
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

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{ personAccount.Id => personAccount });

		Schema.SObjectType otAccount = Schema.getGlobalDescribe().get('Account');
		Schema.SObjectField fAPCN = otAccount.getDescribe().fields.getMap().get('APCN__c');

		MockUtility.Mocks.when(
				mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.eqSObjectField(fAPCN))
			)
			.thenReturn(mockResult1);

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
	static void testprocessCustomerDataEventAPCNNotFoundSalesforceIDFound() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';

		//upsert operartions
		List<Map<String, Object>> accUpsertResult = new List<Map<String, Object>>();
		Map<String, Object> uresultMap1 = new Map<String, Object>{ 'success' => true, 'id' => personAccount.Id };
		accUpsertResult.add(uresultMap1);
		List<Database.UpsertResult> mockResult1 = (List<Database.UpsertResult>) JSON.deserialize(
			JSON.serialize(accUpsertResult),
			List<Database.UpsertResult>.class
		);
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

		MockUtility.Mocks.when(mockAccountsSelector.selectById((Set<Id>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Account>{ personAccount.Id => personAccount });

		Schema.SObjectType otAccount = Schema.getGlobalDescribe().get('Account');
		Schema.SObjectField fAPCN = otAccount.getDescribe().fields.getMap().get('APCN__c');
		MockUtility.Mocks.when(
				mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.eqSObjectField(fAPCN))
			)
			.thenReturn(mockResult1);

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

	//cp phone and email create
	@isTest
	static void testsyncContactPointEmailAndContactPointPhoneCreateReal() {
		//Prepare the Platform Events published from the ESB
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, false)[0];
		personAccount.apcn__c = '873337950';
		personAccount.apcn__pc = '873337950';

		insert personAccount;

		Test.startTest();

		//check if the platform event has been published successfully
		/*	System.assertEquals(true, srList1[0].isSuccess(), 'event published');

		ContactPointEmailSelector selector = ContactPointEmailSelector.newInstance();
		List<ContactPointEmail> results = selector.selectByParentId(new Set<Id>{ personAccount.Id }, new Set<Object>{});
		System.debug('results are ' + results);
		System.assertEquals(true, results.size() > 0, 'ContactPointEmails inserted');*/

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
				emails__c = '[ \n {\n \"emailAddress\":\"Laurel_Mertz@hotmail.com\",\n \"isVerified\":\"true\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n }]',
				phones__c = '[ \n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		List<Database.SaveResult> srList = EventBus.publish(events);
		Test.stopTest();

		//check if the platform event has been published successfully
		System.assertEquals(true, srList[0].isSuccess(), 'existing customer event published');

		ContactPointEmailSelector selectorEmails = ContactPointEmailSelector.newInstance();
		ContactPointPhoneSelector selectorPhones = ContactPointPhoneSelector.newInstance();
		List<ContactPointEmail> resultCPE = selectorEmails.selectByParentId(
			new Set<Id>{ personAccount.Id },
			new Set<Object>{ ContactPointEmailSelector.Options.WITH_CONTACT }
		);
		List<ContactPointPhone> resultCPP = selectorPhones.selectByParentId(
			new Set<Id>{ personAccount.Id },
			new Set<Object>{ ContactPointPhoneSelector.Options.WITH_CONTACT }
		);
		System.debug('resultCPE are ' + resultCPE);
		System.debug('resultCPP are ' + resultCPP);
		System.assertEquals(1, resultCPE.size(), 'ContactPointEmail records after insert');
		System.assertEquals(2, resultCPP.size(), 'ContactPointPhone records after insert');
	}

	//cp email updates and delete sync
	@isTest
	static void testsyncContactPointEmailPhoneUpdateAndDeleteExistingReal() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		List<Account> personAccounts = ApplicationTestDataFactory.getPersonAccounts(2, false);
		personAccounts[0].apcn__c = '873337950';
		personAccounts[0].apcn__pc = '873337950';
		personAccounts[0].Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);

		personAccounts[1].apcn__c = '873337951';
		personAccounts[1].apcn__pc = '873337951';
		personAccounts[1].Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);

		insert personAccounts;

		ContactsSelector selectorContact = ContactsSelector.newInstance();
		List<Contact> contactList = selectorContact.selectByAccount(new Set<Id>{ personAccounts[0].Id,personAccounts[1].Id }).values();

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, personAccounts[0].Id, false);
		cpEmails[0].EmailAddress = 'emailone@sample.com.test';
		cpEmails[0].Contact__c = contactList[0].Id;
		cpEmails[0].Verified__c = false;
		cpEmails[0].Preferred__c = false;
		cpEmails[0].ParentId = personAccounts[0].Id;

		cpEmails[1].EmailAddress = 'emailtwo@sample.com.test';
		cpEmails[1].Contact__c = contactList[0].Id;
		cpEmails[1].Verified__c = false;
		cpEmails[1].Preferred__c = false;
		cpEmails[1].ParentId = personAccounts[0].Id;

		List<ContactPointEmail> cpEmailsDelete = ApplicationTestDataFactory.getContactPointEmails(1, personAccounts[1].Id, false);
		cpEmailsDelete[0].EmailAddress = 'emaildeleteone@sample.com.test';
		cpEmailsDelete[0].Contact__c = contactList[1].Id;
		cpEmailsDelete[0].Verified__c = false;
		cpEmailsDelete[0].Preferred__c = false;
		cpEmailsDelete[0].ParentId = personAccounts[1].Id;

		insert cpEmails;
		insert cpEmailsDelete;

		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, personAccounts[0].Id, false);
		cpPhones[0].Contact__c = contactList[0].Id;
		cpPhones[0].ParentId = personAccounts[0].Id;
		cpPhones[0].Preferred__c = false;
		cpPhones[0].TelephoneNumber = '0491570161';
		cpPhones[0].UniqueMobile__c = false;
		cpPhones[0].Verified__c = false;
		cpPhones[0].PhoneType = 'Mobile';

		cpPhones[1].Contact__c = contactList[0].Id;
		cpPhones[1].ParentId = personAccounts[0].Id;
		cpPhones[1].Preferred__c = false;
		cpPhones[1].TelephoneNumber = '0491570199';
		cpPhones[1].UniqueMobile__c = false;
		cpPhones[1].Verified__c = false;
		cpPhones[1].PhoneType = 'Mobile';
		
		List<ContactPointPhone> cpPhonesDelete = ApplicationTestDataFactory.getContactPointPhones(1, personAccounts[1].Id, false);
		cpPhonesDelete[0].Contact__c = contactList[1].Id;
		cpPhonesDelete[0].ParentId = personAccounts[1].Id;
		cpPhonesDelete[0].Preferred__c = false;
		cpPhonesDelete[0].TelephoneNumber = '0491570162';
		cpPhonesDelete[0].UniqueMobile__c = false;
		cpPhonesDelete[0].Verified__c = false;
		cpPhonesDelete[0].PhoneType = 'Mobile';

		insert cpPhones;
		insert cpPhonesDelete;
		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337950',
				salesforceRecordID__c = personAccounts[0].Id,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccounts[0].Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"emailone@sample.com.test\",\n \"isVerified\":\"true\",\n \"isPrimary\":\"true\",\n \"isCredentialEmail\":\"false\"\n }]',
				phones__c = '[ \n {\n \"phone\":\"0491570161\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"true\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"true\"\n },\n {\n \"phone\":\"0491570159\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"true\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n },\n {\n \"phone\":\"08 8888 8888\",\n \"type\":\"HOME\",\n \"isVerified\":\"false\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }\n ]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337951',
				salesforceRecordID__c = personAccounts[1].Id,
				legalFirstName__c = 'FName Scenario 2',
				legalLastName__c = 'LName Scenario 2',
				preferredName__c = 'FNameLNameScenario2',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccounts[1].Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[]',
				phones__c = '[]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		Test.startTest();
		List<Database.SaveResult> srList = EventBus.publish(events);
		Test.stopTest();

		//check if the platform event has been published successfully
		System.assertEquals(true, srList[0].isSuccess(), 'event published');

		ContactPointEmailSelector selectorCPE = ContactPointEmailSelector.newInstance();
		ContactPointPhoneSelector selectorCPP = ContactPointPhoneSelector.newInstance();
		List<ContactPointEmail> resultsCPE1 = selectorCPE.selectByParentId(
			new Set<Id>{ personAccounts[0].Id },
			new Set<Object>{ ContactPointEmailSelector.Options.WITH_CONTACT }
		);
		List<ContactPointEmail> resultsCPE2 = selectorCPE.selectByParentId(
			new Set<Id>{ personAccounts[1].Id },
			new Set<Object>{ ContactPointEmailSelector.Options.WITH_CONTACT }
		);
		List<ContactPointPhone> resultsCPP1 = selectorCPP.selectByParentId(
			new Set<Id>{ personAccounts[0].Id },
			new Set<Object>{ ContactPointPhoneSelector.Options.WITH_CONTACT }
		);
		List<ContactPointPhone> resultsCPP2 = selectorCPP.selectByParentId(
			new Set<Id>{ personAccounts[1].Id },
			new Set<Object>{ ContactPointPhoneSelector.Options.WITH_CONTACT }
		);
		System.assertEquals(1, resultsCPE1.size(), 'ContactPointEmails synced after update and delete');
		System.assertEquals(3, resultsCPP1.size(), 'ContactPointPhones synced after update and delete');
		System.assertEquals(0, resultsCPE2.size(), 'ContactPointEmails deleted');
		System.assertEquals(0, resultsCPP2.size(), 'ContactPointPhones deleted');
	}

	@isTest
	static void testPayloadParsingExceptionReal() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, false)[0];
		personAccount.apcn__c = '873337950';
		personAccount.apcn__pc = '873337950';
		personAccount.Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 5, 5, 2, 2, 3);

		insert personAccount;

		ContactsSelector selectorContact = ContactsSelector.newInstance();
		List<Contact> contactList = selectorContact.selectByAccount(new Set<Id>{ personAccount.Id }).values();

		List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(2, personAccount.Id, false);
		cpEmails[0].EmailAddress = 'emailone@sample.com.test';
		cpEmails[0].Contact__c = contactList[0].Id;
		cpEmails[0].Verified__c = false;
		cpEmails[0].Preferred__c = false;
		cpEmails[0].ParentId = personAccount.Id;

		cpEmails[1].EmailAddress = 'emailtwo@sample.com.test';
		cpEmails[1].Contact__c = contactList[0].Id;
		cpEmails[1].Verified__c = false;
		cpEmails[1].Preferred__c = false;
		cpEmails[1].ParentId = personAccount.Id;

		insert cpEmails;

		List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(2, personAccount.Id, false);

		cpPhones[0].Contact__c = contactList[0].Id;
		cpPhones[0].ParentId = personAccount.Id;
		cpPhones[0].Preferred__c = false;
		cpPhones[0].TelephoneNumber = '0491570161';
		cpPhones[0].UniqueMobile__c = false;
		cpPhones[0].Verified__c = false;
		cpPhones[0].PhoneType = 'Mobile';

		cpPhones[1].Contact__c = contactList[0].Id;
		cpPhones[1].ParentId = personAccount.Id;
		cpPhones[1].Preferred__c = false;
		cpPhones[1].TelephoneNumber = '0491570199';
		cpPhones[1].UniqueMobile__c = false;
		cpPhones[1].Verified__c = false;
		cpPhones[1].PhoneType = 'Mobile';

		insert cpPhones;

		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;

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
				emails__c = 'some issues with parsing [ \n {\n \"emailAddress\":\"emailone@sample.com.test\",\n \"isVerified\":\"true\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n }]',
				phones__c = '[ \n {\n \"phone\":\"0491570161\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"true\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);
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
				emails__c = '[ \n {\n \"emailAddress\":\"emailone@sample.com.test\",\n \"isVerified\":\"true\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n }]',
				phones__c = '[ \n {\n \"phone\":\"0491570161\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"true\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		Test.startTest();
		List<Database.SaveResult> srList = EventBus.publish(events);
		Test.stopTest();

		//check if the platform event has been published successfully
		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		ContactPointEmailSelector selectorCPE = ContactPointEmailSelector.newInstance();
		ContactPointPhoneSelector selectorCPP = ContactPointPhoneSelector.newInstance();
		List<ContactPointEmail> resultsCPE = selectorCPE.selectByParentId(
			new Set<Id>{ personAccount.Id },
			new Set<Object>{ ContactPointEmailSelector.Options.WITH_CONTACT }
		);
		List<ContactPointPhone> resultsCPP = selectorCPP.selectByParentId(
			new Set<Id>{ personAccount.Id },
			new Set<Object>{ ContactPointPhoneSelector.Options.WITH_CONTACT }
		);
		System.assertEquals(1, resultsCPE.size(), 'ContactPointEmails synced after update and delete');
		System.assertEquals(1, resultsCPP.size(), 'ContactPointPhones synced after update and delete');

		//assert exception that has been created for the validation error for CPE1
		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
		System.assertEquals(true, logResult.size() > 0, 'Exception has been created fro parsing issue');
	}

	@isTest
	static void testDMLExceptionsReal() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database and the a contact point email associated to the Account
		List<Account> personAccounts = ApplicationTestDataFactory.getPersonAccounts(2, false);
		personAccounts[0].apcn__c = '873337950';
		personAccounts[0].apcn__pc = '873337950';
		personAccounts[0].Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 2, 5, 2, 21, 3);

		personAccounts[1].apcn__c = '873337951';
		personAccounts[1].apcn__pc = '873337951';
		personAccounts[1].Integration_Service_Mod_Date__c = Datetime.newInstanceGmt(2021, 2, 5, 2, 22, 3);

		insert personAccounts;

		ContactsSelector selectorContact = ContactsSelector.newInstance();
		List<Contact> contactList = selectorContact.selectByAccount(new Set<Id>{ personAccounts[0].Id, personAccounts[1].Id }).values();

		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> events = new List<CustomerDataSync__e>();
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337950',
				salesforceRecordID__c = personAccounts[0].Id,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccounts[0].Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"invalidemail0211920921%$#$@$@$$$$@email\",\n \"isVerified\":\"true\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n }]',
				phones__c = '[ \n {\n \"phone\":\"0491570161\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"true\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);
		events.add(
			new CustomerDataSync__e(
				apcn__c = '873337951',
				salesforceRecordID__c = personAccounts[1].Id,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 1',
				preferredName__c = 'FNameLNameScenario1',
				birthDate__c = Date.newInstance(2022, 4, 5),
				loa__c = 100.23,
				legalMarketingOptIn__c = true,
				winningMasterAPCN__c = personAccounts[1].Id,
				isInactiveCustomer__c = false,
				integrationServiceModDate__c = Datetime.newInstanceGmt(2022, 5, 5, 2, 2, 3),
				emails__c = '[ \n {\n \"emailAddress\":\"emailone@sample.com.test\",\n \"isVerified\":\"true\",\n \"isPrimary\":\"false\",\n \"isCredentialEmail\":\"false\"\n }]',
				phones__c = '[ \n {\n \"phone\":\"0491570161\",\n \"type\":\"MOBILE\",\n \"isVerified\":\"true\",\n \"isUnique\":\"false\",\n \"isPrimary\":\"false\"\n }]',
				addresses__c = '[ \n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n },\n {\n \"type\":\"Other\",\n \"suburb\":\"CROYDON\",\n \"state\":\"NSW\",\n \"postCode\":\"3206\",\n \"country\":\"AU\"\n }\n ]'
			)
		);

		Test.startTest();
		List<Database.SaveResult> srList = EventBus.publish(events);
		Test.stopTest();

		//check if the platform event has been published successfully
		System.assertEquals(true, srList[0].isSuccess(), 'event published');
		ContactPointEmailSelector selectorCPE = ContactPointEmailSelector.newInstance();
		ContactPointPhoneSelector selectorCPP = ContactPointPhoneSelector.newInstance();
		List<ContactPointEmail> resultsCPE1 = selectorCPE.selectByParentId(
			new Set<Id>{ personAccounts[0].Id },
			new Set<Object>{ ContactPointEmailSelector.Options.WITH_CONTACT }
		);
		List<ContactPointEmail> resultsCPE2 = selectorCPE.selectByParentId(
			new Set<Id>{ personAccounts[1].Id },
			new Set<Object>{ ContactPointEmailSelector.Options.WITH_CONTACT }
		);
		List<ContactPointPhone> resultsCPP = selectorCPP.selectByParentId(
			new Set<Id>{ personAccounts[0].Id, personAccounts[1].Id },
			new Set<Object>{ ContactPointPhoneSelector.Options.WITH_CONTACT }
		);

		System.assertEquals(0, resultsCPE1.size(), 'ContactPointEmails 1 did not synced due to validation errors');
		System.assertEquals(1, resultsCPE2.size(), 'ContactPointEmails 2 synced after update and delete');
		System.assertEquals(2, resultsCPP.size(), 'ContactPointPhones synced after update and delete');

		//assert exception that has been created for the validation error for CPE1
		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
		System.assertEquals(true, logResult.size() > 0, 'Exception created for DML error');
	}
}