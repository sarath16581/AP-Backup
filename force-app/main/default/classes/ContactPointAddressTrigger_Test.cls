/**
 * @description       : This is a test class for the ContactPointAddressTrigger
 * @author            : George Nguyen
 * @domain            : Connected Customer
 * @last modified on  : 25-07-2022
 * @last modified by  : George Nguyen
**/
@IsTest
class ContactPointAddressTrigger_Test {
    
    @IsTest
    static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
        ContactPointAddressDomainTriggerHandler mock = (ContactPointAddressDomainTriggerHandler)MockUtility.mockUtility(ContactPointAddressDomainTriggerHandler.class);

        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
        insert accounts;
		List<SObject> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
        insert contacts;
        List<ContactPointAddress> cpAddresses = ApplicationTestDataFactory.getContactPointAddresses(1, accounts[0].id, false);
		cpAddresses[0].Contact__c = contacts[0].Id;
		cpAddresses[0].Name = 'test';
        cpAddresses[0].Street = 'test';
        insert cpAddresses;

        ((ContactPointAddressDomainTriggerHandler) MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())).dispatch();

        // PMD Warning
		System.assert(true);
    }
}