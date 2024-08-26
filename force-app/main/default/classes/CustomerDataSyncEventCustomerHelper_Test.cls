/**
 * @description       : Test Class for CustomerDataSyncHelper
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 08-09-2022
 * @last modified by  : Sreenish Krishnan
 **/
@isTest
public with sharing class CustomerDataSyncEventCustomerHelper_Test {
	@isTest
	static void upsertCustomerData() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare Person Account that exist in database
		Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		personAccount.apcn__c = '1242';
		personAccount.apcn__pc = '1242';

		//Prepare the Platform Events published from the ESB
		List<CustomerDataSync__e> filteredEvents = new List<CustomerDataSync__e>();
		filteredEvents.add(
			new CustomerDataSync__e(
				apcn__c = '1242',
				salesforceRecordID__c = null,
				legalFirstName__c = 'FName Scenario 1',
				legalLastName__c = 'LName Scenario 2',
				preferredName__c = 'FNameLNameScenario2',
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

		Map<String, Map<String, Object>> refMaps = new Map<String, Map<String, Object>>{
			'APCN' => new Map<String, Datetime>{ '1242' => Datetime.newInstanceGmt(2022, 4, 5, 2, 2, 3) },
			'SFID' => new Map<String, Account>{ personAccount.Id => personAccount }
		};

		//Mock the Database
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		//Mock Responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockDatabase.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject(), (Boolean) fflib_Match.anyObject()))
			.thenAnswer(new MockUtility.AnswerGenericDMLUpserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CustomerDataSyncEventCustomerHelper customerHelper = new CustomerDataSyncEventCustomerHelper();
		Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult> upsertResult = new Map<String, CustomerDataSyncEventCustomerHelper.CustomerUpsertResult>();
		upsertResult = customerHelper.upsertCustomerData(filteredEvents, refMaps);
		Test.stopTest();
		
		// =====================================
		// Asssertion
		// =====================================
		System.assert(!upsertResult.isEmpty(), 'customer data upserted');
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1)))
			.dmlUpsert((List<SObject>) fflib_Match.anyObject(), (SObjectField) fflib_Match.anyObject(), (Boolean) fflib_Match.anyObject());
	}
}