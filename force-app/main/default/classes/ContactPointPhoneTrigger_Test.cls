/**
 * @description       : This is a test class for the ContactPointPhoneTrigger
 * @author            : George Nguyen
 * @domain            : Connected Customer
 * @last modified on  : 25-07-2022
 * @last modified by  : George Nguyen
**/
@IsTest
class ContactPointPhoneTrigger_Test {
    
    @IsTest
    static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
        ContactPointPhoneTriggerHandler mock = (ContactPointPhoneTriggerHandler)MockUtility.mockUtility(ContactPointPhoneTriggerHandler.class);

        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
        insert accounts;
		List<SObject> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
        insert contacts;
        List<ContactPointPhone> cpPhones = ApplicationTestDataFactory.getContactPointPhones(1, accounts[0].id, false);
		cpPhones[0].Contact__c = contacts[0].Id;
		cpPhones[0].TelephoneNumber = '+61404123123';
        insert cpPhones;

        ((ContactPointPhoneTriggerHandler) MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())).dispatch();
        
        // PMD Warning
		System.assert(true);
    }
}

