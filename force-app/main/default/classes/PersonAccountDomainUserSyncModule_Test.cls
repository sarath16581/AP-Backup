/***
 * @author George Nguyen
 * @date 2022-08-01
 * @domain Core
 * @description Test class for PersonAccountDomainUserSyncModule 
 * @changelog
 * 2022-08-01 - George Nguyen - Created
 */
@IsTest
public class PersonAccountDomainUserSyncModule_Test {

    @IsTest
    static void syncUpdatedFieldsToUserRecord() {
        Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
        personAccount.OID_ID__pc = 'new value';
        personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'IsPersonAccount' => true});

		Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];
        personContact.OID_ID__c = 'new value';
        User usr = ApplicationTestDataFactory.getCommunityUsers(1, new List<Id> {personContact.id}, true)[0];

        Account existingPersonAccount = personAccount.clone(true, false, false, false);
        existingPersonAccount.OID_ID__pc = 'old value';

        ContactsSelector ctSelector = (ContactsSelector)MockUtility.mockSelector(ContactsSelector.class);
        UsersSelector uSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(ctSelector.selectByAccount((Set<Id>)fflib_Match.eq(new Set<Id>{personAccount.id}))).thenReturn(new Map<Id, Contact>{personContact.Id => personContact});
        MockUtility.Mocks.when(uSelector.selectByContactId((Set<Id>)fflib_Match.eq(new Set<Id>{personContact.id}))).thenReturn(new Map<Id, User>{usr.Id => usr});

        MockUtility.Mocks.stopStubbing();

        List<Account> records = new List<Account>{ personAccount };
        Map<Id, Account> existingRecords = new Map<Id, Account>{ existingPersonAccount.id => existingPersonAccount };

        Test.startTest();
        PersonAccountDomainUserSyncModule.newInstance().onAfterUpdate(records, existingRecords, mockUow);

        Test.stopTest();

        usr.OID_ID__c = personContact.OID_ID__c;

        ((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
            (List<User>) fflib_Match.eq(new List<User>{usr}), 
            (List<SObjectField>)fflib_Match.eq(new List<SObjectField>{User.OID_ID__c}),
            (String) fflib_Match.eq('PersonAccountDomainUserSyncModule')
        );

        // PMD Warning
		System.assert(true);
    }

    @IsTest
    private static void testSyncDeactivatedUserRecords() {
        Account personAccount = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
        personAccount.Status__pc = APT_Constants.INACTIVE;

        Contact personContact = ApplicationTestDataFactory.getContacts(1, personAccount.Id, true)[0];

        personAccount = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount, new Map<String, Object>{'IsPersonAccount' => true, 'PersonContactId' => personContact.Id});

        Account existingPersonAccount = personAccount.clone(true, false, false, false);
        existingPersonAccount.Status__pc = 'Active';

        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

        List<Account> records = new List<Account>{ personAccount };
        Map<Id, Account> existingRecords = new Map<Id, Account>{ existingPersonAccount.Id => existingPersonAccount };

        Test.startTest();
        PersonAccountDomainUserSyncModule.newInstance().onAfterUpdate(records, existingRecords, mockUow);
        Test.stopTest();

        List<AsyncApexJob> asyncApexJobs = [SELECT Id, Status , JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(1, asyncApexJobs.size(), 'Queueable job failed to start');
    }
}