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
    
    /*
    * this test will verify the following method was called:
    * ApplicationUnitOfWork.registerDirty - with the valid records to update with valid values using the specified fields only
    */
    @IsTest
    static void onAfterInsert() {
        ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
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

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct1.Id}))).thenReturn(new List<ContactPointAddress>(ct1Addresses));
        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct2.Id}))).thenReturn(new List<ContactPointAddress>());

        MockUtility.Mocks.stopStubbing();

        Test.startTest();

        ContactPointAddressDomainModule.newInstance().onAfterInsert(ct1Addresses, uow);

        ((ApplicationUnitOfWork)MockUtility.Mocks.verify(uow, MockUtility.Mocks.times(1))).registerDirty((List<Contact>)fflib_Match.eq(new List<Contact>{
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
        }), 
        (List<SObjectField>)fflib_Match.eq(new List<SObjectField>{
			Contact.MailingStreet,
			Contact.MailingStreet2__c,
			Contact.MailingCity,
			Contact.MailingPostalCode,
			Contact.MailingState,
			Contact.MailingCountry,

			Contact.OtherStreet,
			Contact.OtherStreet2__c,
			Contact.OtherCity,
			Contact.OtherPostalCode,
			Contact.OtherState,
			Contact.OtherCountry
		}),
        (String)fflib_Match.eq('ContactPointAddressDomainModule'));

        // PMD Warning
        System.assert(true);

        Test.stopTest();
    }

    /*
    * this test will verify the following method was called:
    * ApplicationUnitOfWork.registerDirty - with the valid records to update with valid values using the specified fields only
    */
    @IsTest
    static void onAfterUpdate() {
        ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
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

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct1.Id}))).thenReturn(new List<ContactPointAddress>(ct1Addresses));
        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct2.Id}))).thenReturn(new List<ContactPointAddress>());

        MockUtility.Mocks.stopStubbing();

        Test.startTest();

        ContactPointAddressDomainModule.newInstance().onAfterUpdate(ct1Addresses, new Map<Id, ContactPointAddress>(ct2Addresses), uow);

        ((ApplicationUnitOfWork)MockUtility.Mocks.verify(uow, MockUtility.Mocks.times(1))).registerDirty((List<Contact>)fflib_Match.eq(new List<Contact>{
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
        }), 
        (List<SObjectField>)fflib_Match.eq(new List<SObjectField>{
			Contact.MailingStreet,
			Contact.MailingStreet2__c,
			Contact.MailingCity,
			Contact.MailingPostalCode,
			Contact.MailingState,
			Contact.MailingCountry,

			Contact.OtherStreet,
			Contact.OtherStreet2__c,
			Contact.OtherCity,
			Contact.OtherPostalCode,
			Contact.OtherState,
			Contact.OtherCountry
		}),
        (String)fflib_Match.eq('ContactPointAddressDomainModule'));

        // PMD Warning
        System.assert(true);

        Test.stopTest();
    }

    /*
    * this test will verify the following method was called:
    * ApplicationUnitOfWork.registerDirty - with the valid records to update with valid values using the specified fields only
    */
    @IsTest
    static void onAfterDelete() {
        ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
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

        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct1.Id}))).thenReturn(new List<ContactPointAddress>(ct1Addresses));
        MockUtility.Mocks.when(cpAddressSelector.selectByContactWithOtherOrMailingAddressType((Set<Id>)fflib_Match.eq(new Set<Id>{ct2.Id}))).thenReturn(new List<ContactPointAddress>());

        MockUtility.Mocks.stopStubbing();

        Test.startTest();

        ContactPointAddressDomainModule.newInstance().onAfterDelete(ct2Addresses, uow);

        ((ApplicationUnitOfWork)MockUtility.Mocks.verify(uow, MockUtility.Mocks.times(1))).registerDirty((List<Contact>)fflib_Match.eq(new List<Contact>{
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
        }), 
        (List<SObjectField>)fflib_Match.eq(new List<SObjectField>{
			Contact.MailingStreet,
			Contact.MailingStreet2__c,
			Contact.MailingCity,
			Contact.MailingPostalCode,
			Contact.MailingState,
			Contact.MailingCountry,

			Contact.OtherStreet,
			Contact.OtherStreet2__c,
			Contact.OtherCity,
			Contact.OtherPostalCode,
			Contact.OtherState,
			Contact.OtherCountry
		}),
        (String)fflib_Match.eq('ContactPointAddressDomainModule'));

        // PMD Warning
        System.assert(true);

        Test.stopTest();
    }

	//test exceptions in module class
	@isTest
	static void testExceptionOnUpdate(){
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;
		Test.startTest();
		ContactPointAddressDomainModule module = ContactPointAddressDomainModule.newInstance();
		module.onAfterUpdate(new List<SObject>{},new Map<Id,SObject>{},null);
		Test.stopTest();
		//an exception should be created when thre are invalid parameters in the onAfterUpdate
		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
		System.assertEquals(true, logResult.size() > 0, 'Exception created');
	}

	//test exceptions in module class
	//@isTest
	// static void testExceptionOnInsert(){
	// 	LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
	// 	logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
	// 	insert logLevel;
	// 	Test.startTest();
	// 	ContactPointAddressDomainModule module = ContactPointAddressDomainModule.newInstance();
	// 	module.onAfterInsert(null,null);
	// 	Test.stopTest();
	// 	//an exception should be created when thre are invalid parameters in the onAfterInsert
	// 	List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
	// 	System.assertEquals(true, logResult.size() > 0, 'Exception created');
	// }

	// //test exceptions in module class
	// 	@isTest
	// 	static void testExceptionOnDelete(){
	// 		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
	// 		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
	// 		insert logLevel;
	// 		Test.startTest();
	// 		ContactPointAddressDomainModule module = ContactPointAddressDomainModule.newInstance();
	// 		module.onAfterDelete(new List<SObject>{},null);
	// 		Test.stopTest();
	// 		//an exception should be created when thre are invalid parameters in the onAfterDelete
	// 		List<ExceptionLog__c> logResult = [SELECT id FROM ExceptionLog__c];
	// 		System.assertEquals(true, logResult.size() > 0, 'Exception created');
	// 	}
    
}
