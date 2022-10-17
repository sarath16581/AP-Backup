/**
 * @description       : This is a test class for the ContactPointEmailTrigger
 * @author            : George Nguyen
 * @domain            : Connected Customer
 * @last modified on  : 25-07-2022
 * @last modified by  : George Nguyen
**/
@IsTest
class ContactPointEmailTrigger_Test {
    
    @IsTest
    static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
        ContactPointEmailDomainTriggerHandler mock = (ContactPointEmailDomainTriggerHandler)MockUtility.mockUtility(ContactPointEmailDomainTriggerHandler.class);

        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
        insert accounts;
		List<SObject> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
        insert contacts;
        List<ContactPointEmail> cpEmails = ApplicationTestDataFactory.getContactPointEmails(1, accounts[0].id, false);
		cpEmails[0].Contact__c = contacts[0].Id;
		cpEmails[0].EmailAddress = 'test-sync-with-contact@sample.auspost.com.au';
        insert cpEmails;

        ((ContactPointEmailDomainTriggerHandler) MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())).dispatch();

        // PMD Warning
		System.assert(true);
    }
}