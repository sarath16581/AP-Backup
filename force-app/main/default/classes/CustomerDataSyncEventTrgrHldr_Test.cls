/**
 * @description       : This is a test class for the CustomerDataSyncEventTriggerHandler Class
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-13-2022
 * @last modified by  : Sreenish Krishnan
 **/
@isTest
public with sharing class CustomerDataSyncEventTrgrHldr_Test {
	private static void entry() {
		// =====================================
		// Data Preparation
		// =====================================
		//Prepare the Platform Events published from the ESB
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
		// Testing
		// =====================================
		Test.startTest();

		List<Database.SaveResult> srList = EventBus.publish(events);

		Test.stopTest();

		// =====================================
		// Assertion
		// =====================================
		System.assertEquals(true, srList[0].isSuccess(), 'event published');
	}
}