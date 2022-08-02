/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for PersonAccountDomainCtPointSyncModule 
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class PersonAccountDomainCtPointSyncMod_Test {
    
    @IsTest
    static void onBeforeInsert() {
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PersonAccountDomainTriggerHandler.getUnitOfWorkSObjectTypes());

        ContactService mockService = (ContactService)MockUtility.mockUtility(ContactService.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.stopStubbing();

        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);

        Test.startTest();

        PersonAccountDomainCtPointSyncModule.newInstance().onBeforeInsert(accounts, uow);
        ((ContactService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).applyPhoneNumberFormatting((List<Account>)fflib_Match.eq(accounts), (Map<Id, Account>)fflib_Match.isNull());

        Test.stopTest();

        // PMD Warning
        System.assert(true);
    }

    @IsTest
    static void onBeforeUpdate() {
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PersonAccountDomainTriggerHandler.getUnitOfWorkSObjectTypes());

        ContactService mockService = (ContactService)MockUtility.mockUtility(ContactService.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.stopStubbing();

        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
        Account acc1 = accounts[0];
        Account oldAcc1 = acc1.clone(true, true, false, false);
        Map<Id, Account> existingRecords = new Map<Id, Account>{oldAcc1.Id => oldAcc1};

        Test.startTest();

        PersonAccountDomainCtPointSyncModule.newInstance().onBeforeUpdate(accounts, existingRecords, uow);
        ((ContactService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).applyPhoneNumberFormatting((List<Account>)fflib_Match.eq(accounts), (Map<Id, Account>)fflib_Match.eq(existingRecords));

        Test.stopTest();

        // PMD Warning
        System.assert(true);
    }

    @IsTest
    static void onAfterUpdate() {
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(PersonAccountDomainTriggerHandler.getUnitOfWorkSObjectTypes());
        
        List<Account> accounts = new List<Account>();
        Map<Id, Account> existingAccounts = new Map<Id, Account>();
        Map<Id, String> contactIdsVsHomePhones = new Map<Id, String>();
        Map<Id, String> contactIdsVsMobilePhones = new Map<Id, String>();
        Map<Id, String> contactIdsVsEmails = new Map<Id, String>();

        Account personAccount1 = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact1 = ApplicationTestDataFactory.getContacts(1, personAccount1.Id, true)[0];
        personContact1.HomePhone = '111111';
        personContact1.MobilePhone = '+614111111';
        personContact1.Email = 'test111111@test.com';
        contactIdsVsEmails.put(personContact1.Id, personContact1.Email);
        contactIdsVsHomePhones.put(personContact1.Id, personContact1.HomePhone);
        contactIdsVsMobilePhones.put(personContact1.Id, personContact1.MobilePhone);
		personAccount1 = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount1, new Map<String, Object>{
                                                                                    'PersonContactId' => personContact1.Id,
                                                                                    'PersonHomePhone' => personContact1.HomePhone,
                                                                                    'PersonMobilePhone' => personContact1.MobilePhone,
                                                                                    'PersonEmail' => personContact1.Email,
                                                                                    'isPersonAccount' => true
                                                                                });
        accounts.add(personAccount1);
        List<ContactPointPhone> existingCpps =  ApplicationTestDataFactory.getContactPointPhones(2, personAccount1.id, true);
        ContactPointPhone existingCppHomePhone1 = existingCpps[0];
        existingCppHomePhone1.Contact__c = personContact1.Id;
        existingCppHomePhone1.PhoneType = 'Home';
        existingCppHomePhone1.TelephoneNumber = personContact1.HomePhone;
        existingCppHomePhone1.Verified__c = false;

        ContactPointPhone existingCppMobilePhone1 = existingCpps[1];
        existingCppMobilePhone1.Contact__c = personContact1.Id;
        existingCppMobilePhone1.PhoneType = 'Mobile';
        existingCppMobilePhone1.TelephoneNumber = personContact1.MobilePhone;
        existingCppMobilePhone1.Verified__c = false;

        ContactPointEmail existingCppEmail1 = ApplicationTestDataFactory.getContactPointEmails(1, personAccount1.id, true)[0];
        existingCppEmail1.Contact__c = personContact1.Id;
        existingCppEmail1.EmailAddress = personContact1.Email;
        existingCppEmail1.Verified__c = false;

        Account existingPersonAccount1 = personAccount1.clone(true, true, false, false);

        existingPersonAccount1 = (Account)ApplicationTestDataFactory.setUnwritableFields(existingPersonAccount1, new Map<String, Object>{
                                                                                    'PersonContactId' => personContact1.Id,
                                                                                    'PersonHomePhone' => '22222',
                                                                                    'PersonMobilePhone' => '040422222',
                                                                                    'PersonEmail' => 'test22222@test.com',
                                                                                    'isPersonAccount' => true
                                                                                });
        existingAccounts.put(existingPersonAccount1.id, existingPersonAccount1);      
        
        Account personAccount2 = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		Contact personContact2 = ApplicationTestDataFactory.getContacts(1, personAccount2.Id, true)[0];
        personContact2.HomePhone = '3333333';
        personContact2.MobilePhone = '+6143333333';
        personContact2.Email = 'test333333@test.com';
        contactIdsVsEmails.put(personContact2.Id, personContact2.Email);
        contactIdsVsHomePhones.put(personContact2.Id, personContact2.HomePhone);
        contactIdsVsMobilePhones.put(personContact2.Id, personContact2.MobilePhone);
		personAccount2 = (Account)ApplicationTestDataFactory.setUnwritableFields(personAccount2, new Map<String, Object>{
                                                                                    'PersonContactId' => personContact2.Id,
                                                                                    'PersonHomePhone' => personContact2.HomePhone,
                                                                                    'PersonMobilePhone' => personContact2.MobilePhone,
                                                                                    'PersonEmail' => personContact2.Email,
                                                                                    'isPersonAccount' => true
                                                                                });
        accounts.add(personAccount2);
        existingCpps =  ApplicationTestDataFactory.getContactPointPhones(2, personAccount2.id, true);
        ContactPointPhone existingCppHomePhone2 = existingCpps[0];
        existingCppHomePhone2.Contact__c = personContact2.Id;
        existingCppHomePhone2.PhoneType = 'Home';
        existingCppHomePhone2.TelephoneNumber = personContact2.HomePhone;
        existingCppHomePhone2.Verified__c = false;

        ContactPointPhone existingCppMobilePhone2 = existingCpps[1];
        existingCppMobilePhone2.Contact__c = personContact2.Id;
        existingCppMobilePhone2.PhoneType = 'Mobile';
        existingCppMobilePhone2.TelephoneNumber = personContact2.HomePhone;
        existingCppMobilePhone2.Verified__c = false;

        ContactPointEmail existingCppEmail2 = ApplicationTestDataFactory.getContactPointEmails(1, personAccount2.id, true)[0];
        existingCppEmail2.Contact__c = personContact2.Id;
        existingCppEmail2.EmailAddress = personContact2.Email;
        existingCppEmail2.Verified__c = false;

        Account existingPersonAccount2 = personAccount2.clone(true, true, false, false);

        existingPersonAccount2 = (Account)ApplicationTestDataFactory.setUnwritableFields(existingPersonAccount2, new Map<String, Object>{
                                                                                    'PersonContactId' => personContact2.Id,
                                                                                    'PersonHomePhone' => '444444',
                                                                                    'PersonMobilePhone' => '040444444',
                                                                                    'PersonEmail' => 'test44444@test.com',
                                                                                    'isPersonAccount' => true
                                                                                });
        existingAccounts.put(existingPersonAccount2.id, existingPersonAccount2);   
        
        ContactPointPhoneSelector cpPhoneSelector = (ContactPointPhoneSelector)MockUtility.mockSelector(ContactPointPhoneSelector.class);
        ContactPointEmailSelector cpEmailSelector = (ContactPointEmailSelector)MockUtility.mockSelector(ContactPointEmailSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(cpPhoneSelector.selectByContactAndPhoneNumber((Set<Id>)fflib_Match.eq(contactIdsVsHomePhones.keySet()), 
                                                                         (List<String>)fflib_Match.eq(contactIdsVsHomePhones.values()), 
                                                                         (Set<Object>)fflib_Match.eq(new Set<Object>{ContactPointPhoneSelector.Options.FILTER_HOMEPHONE})
                                )).thenReturn(new List<ContactPointPhone>{existingCppHomePhone1});


        MockUtility.Mocks.when(cpPhoneSelector.selectByContact((Set<Id>)fflib_Match.eq(new Set<Id>{existingCppHomePhone2.Contact__c}), 
                                                           (Set<Object>)fflib_Match.eq(new Set<Object>{ContactPointPhoneSelector.Options.FILTER_HOMEPHONE, ContactPointPhoneSelector.Options.FILTER_VERIFIED_FALSE})
                                )).thenReturn(new List<ContactPointPhone>{existingCppHomePhone2});

        
        MockUtility.Mocks.when(cpPhoneSelector.selectByContactAndPhoneNumber((Set<Id>)fflib_Match.eq(contactIdsVsMobilePhones.keySet()), 
                                                                         (List<String>)fflib_Match.eq(contactIdsVsMobilePhones.values()), 
                                                                         (Set<Object>)fflib_Match.eq(new Set<Object>{ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE})
                                )).thenReturn(new List<ContactPointPhone>{existingCppMobilePhone1});


        MockUtility.Mocks.when(cpPhoneSelector.selectByContact((Set<Id>)fflib_Match.eq(new Set<Id>{existingCppMobilePhone2.Contact__c}), 
                                                           (Set<Object>)fflib_Match.eq(new Set<Object>{ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE, ContactPointPhoneSelector.Options.FILTER_VERIFIED_FALSE})
                                )).thenReturn(new List<ContactPointPhone>{existingCppMobilePhone2});

        
        MockUtility.Mocks.when(cpEmailSelector.selectByContactAndEmail((Set<Id>)fflib_Match.eq(contactIdsVsEmails.keySet()), 
                                                                        (List<String>)fflib_Match.eq(contactIdsVsEmails.values()),
                                                                        (Set<Object>)fflib_Match.eq(new Set<Object>())
                                )).thenReturn(new List<ContactPointEmail>{existingCppEmail1});


        MockUtility.Mocks.when(cpEmailSelector.selectByContact((Set<Id>)fflib_Match.eq(new Set<Id>{existingCppEmail2.Contact__c}), 
                                                           (Set<Object>)fflib_Match.eq(new Set<Object>{ContactPointEmailSelector.Options.FILTER_VERIFIED_FALSE})
                                )).thenReturn(new List<ContactPointEmail>{existingCppEmail2});

        MockUtility.Mocks.stopStubbing();

        Test.startTest();

        PersonAccountDomainCtPointSyncModule.newInstance().onAfterUpdate(accounts, existingAccounts, uow);

        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete(
                                                                                                    (List<ContactPointPhone>)fflib_Match.eq(new List<ContactPointPhone>{existingCppHomePhone2})
                                                                                                );

        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete(
                                                                                                    (List<ContactPointEmail>)fflib_Match.eq(new List<ContactPointEmail>{existingCppEmail2})
                                                                                                );

        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete(
                                                                                                (List<ContactPointPhone>)fflib_Match.eq(new List<ContactPointPhone>{existingCppMobilePhone2})
                                                                                            );

        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(
                                                                                            (List<SObject>)fflib_Match.eq(new List<SObject>{
                                                                                                new ContactPointPhone(
                                                                                                    ParentId = personContact2.accountId,
                                                                                                    Contact__c = personContact2.Id,
                                                                                                    PhoneType = 'Home',
                                                                                                    TelephoneNumber = personContact2.HomePhone,
                                                                                                    Verified__c = FALSE,
                                                                                                    Preferred__c = FALSE,
                                                                                                    UniqueMobile__c = FALSE
                                                                                                ),
                                                                                                new ContactPointPhone(
                                                                                                    ParentId = personContact2.accountId,
                                                                                                    Contact__c = personContact2.Id,
                                                                                                    PhoneType = 'Mobile',
                                                                                                    TelephoneNumber = personContact2.MobilePhone,
                                                                                                    Verified__c = FALSE,
                                                                                                    Preferred__c = FALSE,
                                                                                                    UniqueMobile__c = FALSE
                                                                                                ),
                                                                                                new ContactPointEmail(
                                                                                                    ParentId = personContact2.accountId,
                                                                                                    Contact__c = personContact2.Id,
                                                                                                    EmailAddress = personContact2.Email,
                                                                                                    Verified__c = FALSE,
                                                                                                    Preferred__c = FALSE,
                                                                                                    AuthenticationEmail__c = FALSE,
                                                                                                    Communication_Email__c = TRUE
                                                                                                )
                                                                                            }));

        Test.stopTest();

        // PMD Warning
        System.assert(true);
    }

}