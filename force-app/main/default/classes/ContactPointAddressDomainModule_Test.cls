/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactPointAddressDomainModule 
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class ContactPointAddressDomainModule_Test {
    
    @IsTest
    static void onAfterInsert() {
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointAddressDomainTriggerHandler.getUnitOfWorkSObjectTypes());
        Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(3, acc.Id, true);

        Contact ct1 = contacts[0];
        List<ContactPointAddress> ct1Addresses =  ApplicationTestDataFactory.getContactPointAddresses(2, acc.id, true);
        ContactPointAddress cpa1 = ct1Addresses[0];
        cpa1.Contact__c = ct1.Id;
        cpa1.Street = 'mailing addr 1';
        cpa1.Street2__c = 'mailing addr 1';
        cpa1.City = 'mailing addr 1';
        cpa1.PostalCode = '1111';
        cpa1.State = 'mailing addr 1';
        cpa1.Country = 'mailing addr';
        cpa1.AddressType = 'Mailing';

        ContactPointAddress cpa2 = ct1Addresses[1];
        cpa2.Contact__c = ct1.Id;
        cpa2.Street = 'other addr 1';
        cpa2.Street2__c = 'other addr 1';
        cpa2.City = 'other addr 1';
        cpa2.PostalCode = '1111';
        cpa2.State = 'other addr 1';
        cpa2.Country = 'other addr';
        cpa2.AddressType = 'Other';

        Contact ct2 = contacts[1];
        List<ContactPointAddress> ct2Addresses =  ApplicationTestDataFactory.getContactPointAddresses(1, acc.id, true);
        ct2Addresses[0].Contact__c = ct2.Id;


        ContactPointAddressSelector cpAddressSelector = (ContactPointAddressSelector)MockUtility.mockSelector(ContactPointAddressSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct1.Id}))).thenReturn(new List<ContactPointAddress>(ct1Addresses));
        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct2.Id}))).thenReturn(new List<ContactPointAddress>());

        MockUtility.Mocks.stopStubbing();

        Test.startTest();

        ContactPointAddressDomainModule.newInstance().onAfterInsert(ct1Addresses, uow);

        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Contact>)fflib_Match.eq(new List<Contact>{
            new Contact(
                Id = ct1.Id,
                MailingStreet = cpa1.Street,
                MailingStreet2__c = cpa1.Street2__c,
                MailingCity = cpa1.City,
                MailingPostalCode = cpa1.PostalCode,
                MailingState = cpa1.State,
                MailingCountry = cpa1.Country,

                OtherStreet = cpa2.Street,
                OtherStreet2__c = cpa2.Street2__c,
                OtherCity = cpa2.City,
                OtherPostalCode = cpa2.PostalCode,
                OtherState = cpa2.State,
                OtherCountry = cpa2.Country
            )
        }));

        // PMD Warning
        System.assert(true);

        Test.stopTest();
    }

    @IsTest
    static void onAfterUpdate() {
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointAddressDomainTriggerHandler.getUnitOfWorkSObjectTypes());
        Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(3, acc.Id, true);

        Contact ct1 = contacts[0];
        List<ContactPointAddress> ct1Addresses =  ApplicationTestDataFactory.getContactPointAddresses(2, acc.id, true);
        ContactPointAddress cpa1 = ct1Addresses[0];
        cpa1.Contact__c = ct1.Id;
        cpa1.Street = 'mailing addr 1';
        cpa1.Street2__c = 'mailing addr 1';
        cpa1.City = 'mailing addr 1';
        cpa1.PostalCode = '1111';
        cpa1.State = 'mailing addr 1';
        cpa1.Country = 'mailing addr';
        cpa1.AddressType = 'Mailing';

        ContactPointAddress cpa2 = ct1Addresses[1];
        cpa2.Contact__c = ct1.Id;
        cpa2.Street = 'other addr 1';
        cpa2.Street2__c = 'other addr 1';
        cpa2.City = 'other addr 1';
        cpa2.PostalCode = '1111';
        cpa2.State = 'other addr 1';
        cpa2.Country = 'other addr';
        cpa2.AddressType = 'Other';

        Contact ct2 = contacts[1];
        List<ContactPointAddress> ct2Addresses =  ApplicationTestDataFactory.getContactPointAddresses(1, acc.id, true);
        ct2Addresses[0].Contact__c = ct2.Id;


        ContactPointAddressSelector cpAddressSelector = (ContactPointAddressSelector)MockUtility.mockSelector(ContactPointAddressSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct1.Id}))).thenReturn(new List<ContactPointAddress>(ct1Addresses));
        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct2.Id}))).thenReturn(new List<ContactPointAddress>());

        MockUtility.Mocks.stopStubbing();

        Test.startTest();

        ContactPointAddressDomainModule.newInstance().onAfterUpdate(ct1Addresses, new Map<Id, ContactPointAddress>(ct2Addresses), uow);

        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Contact>)fflib_Match.eq(new List<Contact>{
            new Contact(
                Id = ct1.Id,
                MailingStreet = cpa1.Street,
                MailingStreet2__c = cpa1.Street2__c,
                MailingCity = cpa1.City,
                MailingPostalCode = cpa1.PostalCode,
                MailingState = cpa1.State,
                MailingCountry = cpa1.Country,

                OtherStreet = cpa2.Street,
                OtherStreet2__c = cpa2.Street2__c,
                OtherCity = cpa2.City,
                OtherPostalCode = cpa2.PostalCode,
                OtherState = cpa2.State,
                OtherCountry = cpa2.Country
            )
        }));

        // PMD Warning
        System.assert(true);

        Test.stopTest();
    }

    @IsTest
    static void onAfterDelete() {
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(ContactPointAddressDomainTriggerHandler.getUnitOfWorkSObjectTypes());
        Account acc = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(3, acc.Id, true);

        Contact ct1 = contacts[0];
        List<ContactPointAddress> ct1Addresses =  ApplicationTestDataFactory.getContactPointAddresses(2, acc.id, true);
        ContactPointAddress cpa1 = ct1Addresses[0];
        cpa1.Contact__c = ct1.Id;
        cpa1.Street = 'mailing addr 1';
        cpa1.Street2__c = 'mailing addr 1';
        cpa1.City = 'mailing addr 1';
        cpa1.PostalCode = '1111';
        cpa1.State = 'mailing addr 1';
        cpa1.Country = 'mailing addr';
        cpa1.AddressType = 'Mailing';

        ContactPointAddress cpa2 = ct1Addresses[1];
        cpa2.Contact__c = ct1.Id;
        cpa2.Street = 'other addr 1';
        cpa2.Street2__c = 'other addr 1';
        cpa2.City = 'other addr 1';
        cpa2.PostalCode = '1111';
        cpa2.State = 'other addr 1';
        cpa2.Country = 'other addr';
        cpa2.AddressType = 'Other';

        Contact ct2 = contacts[1];
        List<ContactPointAddress> ct2Addresses =  ApplicationTestDataFactory.getContactPointAddresses(1, acc.id, true);
        ct2Addresses[0].Contact__c = ct2.Id;


        ContactPointAddressSelector cpAddressSelector = (ContactPointAddressSelector)MockUtility.mockSelector(ContactPointAddressSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct1.Id}))).thenReturn(new List<ContactPointAddress>(ct1Addresses));
        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct2.Id}))).thenReturn(new List<ContactPointAddress>());

        MockUtility.Mocks.stopStubbing();

        Test.startTest();

        ContactPointAddressDomainModule.newInstance().onAfterDelete(ct2Addresses, uow);

        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Contact>)fflib_Match.eq(new List<Contact>{
            new Contact(
                Id = ct2.Id,
                MailingStreet = NULL,
                MailingStreet2__c = NULL,
                MailingCity = NULL,
                MailingPostalCode = NULL,
                MailingState = NULL,
                MailingCountry = NULL,

                OtherStreet = NULL,
                OtherStreet2__c = NULL,
                OtherCity = NULL,
                OtherPostalCode = NULL,
                OtherState = NULL,
                OtherCountry = NULL
            )
        }));

        // PMD Warning
        System.assert(true);

        Test.stopTest();
    }

    
}