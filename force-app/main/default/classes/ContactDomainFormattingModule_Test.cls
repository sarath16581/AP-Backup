/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactDomainFormattingModule 
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class ContactDomainFormattingModule_Test {
    
    @IsTest
    static void onBeforeInsert() {

        ContactService mockService = (ContactService)MockUtility.mockUtility(ContactService.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.stopStubbing();

        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());
        ContactDomainFormattingModule module = ContactDomainFormattingModule.newInstance();
        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
        List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);

        Test.startTest();

        module.onBeforeInsert(contacts, uow);
        ((ContactService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).applyPhoneNumberFormatting((List<Contact>)fflib_Match.eq(contacts), (Map<Id, Contact>)fflib_Match.isNull());

        // PMD warning
        System.assert(true);

        Test.stopTest();
    }

    @IsTest
    static void onBeforeUpdate() {
        
        ContactService mockService = (ContactService)MockUtility.mockUtility(ContactService.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.stopStubbing();

        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactDomainTriggerHandler.getUnitOfWorkSObjectTypes());
        ContactDomainFormattingModule module = ContactDomainFormattingModule.newInstance();
        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
        List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
        Contact ct1 = contacts[0];
        Contact oldCt1 = ct1.clone(true, true, false, false);
        Map<Id, Contact> existingRecords = new Map<Id, Contact>{oldCt1.Id => oldCt1};

        Test.startTest();

        module.onBeforeUpdate(contacts, existingRecords, uow);
        ((ContactService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).applyPhoneNumberFormatting((List<Contact>)fflib_Match.eq(contacts), (Map<Id, Contact>)fflib_Match.eq(existingRecords));

        // PMD warning
        System.assert(true);
        
        Test.stopTest();
    }
}