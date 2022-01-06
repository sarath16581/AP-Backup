/**
  * @author       : eric.shen@auspost.com.au
  * @date         : 28/07/2015
  * @description  : Test class for SearchContactComponentController
  * Updates:
  *     30/05/2017 - Dion.gunn@auspost.com.au - Moved to new class that reflects what it's covering.
  *                                             Added coverage to handle Duplicate Checking methtods.
  *     18/08/2017 - Maumita Bandyopadhyay - Added coverage to customer search.
  *     15/11/2019 - snigdha.sahu@auspost.com.au - Added coverage for validation rule
  *     15/11/2019 - seth.p.heang@accenture.com - Added coverage for Contact Block Duplicate Rule
  *     20/07/2020 - Swati.Mogadala@auspost.com.au -Add EmailNotAvailable checkbox for Contacts and person accounts(REQ2065161)
  *     20/05/2021 - Madhuri.awasthi@auspost.com.au - Add PreferredName field for Contact and person accounts(REQ2476162)
  */


@isTest
public with sharing class SearchContactComponentControllerTest {
    
    @testSetup static void createTestData() {
        Profile prof = [select id from Profile where Name = 'SSSW - Service Agent' limit 1];
        String username = 't' + String.valueOf(System.now()).hashCode() + '@auspost.com.au';
        User pu = new User(profileId = prof.id, username = username, email = 'testSearchContact@auspost.com.au', 
          emailencodingkey = 'UTF-8', localesidkey = 'en_US', 
            languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles', 
            alias='sccct', lastname='lastname');
        insert pu;
        Account acc = APT_TestUtils.createOrganisation();
            acc.name = 'test org';
            acc.ACN__c = '123456789';
            insert acc;
        Contact con = APT_TestUtils.createContact();
            con.firstName = 'Maria';
            con.lastName = 'Tiffany';
            con.Email = 'exampleTest@email.com';
            con.Phone = '0412345678';
            con.AccountId = acc.id;
            insert con;
    }
    static testMethod void testOnLoad() {
        // Load the contact based on the entered search filters.

        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.SObjectType.Case.getRecordTypeInfosByName();     //Eric Shen 28/07/15 Add record type for SSSW

        Case myCase = TestDataProvider.CaseUtil.newCase('sample subject');

        ApexPages.currentPage().getParameters().put('ANI', '123456');
        ApexPages.currentPage().getParameters().put('aId', '12345');

        Account personAccount = TestDataProvider.createAndSavePersonAccount('BobTheBuilder', Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        SearchContactComponentController controller = new SearchContactComponentController();
        System.assert(controller.contacts4Page == null ||controller.contacts4Page.size() == 0);

        personAccount.Phone = '123456';
        update personAccount;
        controller = new SearchContactComponentController();
        //System.assert(controller.contacts.size() == 1);

        personAccount = [select personContactId from account where id =: personAccount.id limit 1];

        Case c = new Case();
        c.contactId = personAccount.personContactId;
        c.recordtypeID = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId(); //Eric Shen 28/07/15 Add record type for SSSW
        c.subject = 'G Test Open';
        c.status = 'Open';
        c.Type = 'General Enquiry';
        c.ReopenDate__c = system.today();
        insert c;

        c = new Case();
        c.recordtypeID = caseRecTypeMap.get('SSSW Delivery').getRecordTypeId(); //Eric Shen 28/07/15 Add record type for SSSW
        c.contactId = personAccount.personContactId;
        c.Type = 'General Enquiry';
        c.ReopenDate__c = system.today().addDays(15);
        c.subject = 'G Test Close';
        c.status = 'Closed';
        c.ResolutionCode__c = 'Other';
        insert c;

        controller = new SearchContactComponentController();
        //system.assert(controller.contacts[0].numberOfOpenCases == 1);
        //system.assert(controller.contacts[0].numberOfClosedCases == 1);
    }

    static testMethod void testSearchForContact() {
        // if a phone number is passed via the query string the load up the contact
        // if a ref id is passed via the query string then load the article/case

        Account personAccount = TestDataProvider.createAndSavePersonAccount('HoudiniG_BobTheBuilder', Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        SearchContactComponentController controller = new SearchContactComponentController();
        system.assert(controller.contacts4Page == null || controller.contacts4Page.size() == 0);

        controller.clearSearch();
        controller.strFirstName = 'HoudiniG_BobTheBuilder';
        controller.strLastName = '';
        controller.searchForContact();

        controller.clearSearch();
        controller.strFirstName = '';
        controller.strLastName = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();

        controller.clearSearch();
        controller.strPhone = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();

        controller.clearSearch();
        controller.strEmail = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();

        controller.clearSearch();
        controller.strCustomerType = 'Consumer';
        controller.searchForContact();

        controller.clearSearch();
        controller.strAccountNumber = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();

        controller.clearSearch();
        controller.strAccountName = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();
        /*
        controller.clearSearch();
        controller.strArticleId = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();
        */
        controller.clearSearch();
        controller.strAddress = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();

        controller.clearSearch();
        controller.strSocialKeys = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();

        controller.clearSearch();
        controller.strSocialKeys = 'HoudiniG_BobTheBuilder';
        controller.searchForContact();
        
    }

    /*static testMethod void testButtonClicks() {
        SearchContactComponentController controller = new SearchContactComponentController();
        controller.searchForContact();
    }*/

    static testMethod void testGetCustomerTypes() {
        Case dummyCase = new Case();
        SearchContactComponentController controller = new SearchContactComponentController();
        List<SelectOption> customerTypes = controller.getCustomerTypes();
        system.assert(customerTypes.get(0).getValue() == '');
    }

    public static testMethod void testAdvSearchCustomersREST(){
        Account acc = TestDataProvider.createAndSavePersonAccount('POBSearchCustomer', Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        acc.APCN__pc = '1123456789';
        acc.APCN__c = '1123456789';
        update acc;

        
        //System.debug('acc : '+acc.APCN__pc);
        insert new AusPostSettings__c(Name = 'SAP_SearchByProductParameters', Username__c = 'Username', Password__c = 'Password',URL__c = '');
        //Test.setMock(HttpCalloutMock.class, new POBSearchHttpCalloutMock());
        Test.startTest();
        AdvancedSearchContactComponentController con = new AdvancedSearchContactComponentController();
        Test.setMock(HttpCalloutMock.class, new POBSearchHttpCalloutMock());
        con.contacts4Page = AdvancedSearchContactComponentController.SearchCustomerREST('Parameter1', 'Parameter2','Parameter3');
        System.assertEquals('1123456789', con.contacts4Page[0].Contact.APCN__c);
        Test.stopTest();
    }
    static testMethod void testAddCustomer() {
        // assert that a new contact is created based on the account no.
        // 1. if a billing account is found, then the new contact will also be linked via the billing account's main account
        // 2. if the account number is the main account then the contact is added to that account.
        // 3. if there is not account number then the contact is added as a person account.
        string strAccountName = '';
        string strAccountNumber = '';
        string strFirstName = 'Test';
        string strLastName = '';
        string strPreferredName = '';
        string strAddress = '';
        string strEmail = 'example@email.com';
        string strPhone = '';
        string strSocialKeys = '';
        string strCustomerType = '';
        string strDPID = '';
        string strAddressLine1 = '';
        string strAddressLine2 = '';
        string strCity = '';
        string strState = '';
        string strPostcode = '';
        string strCountry = '';
        boolean ckbEmailNotAvailable =FALSE;

        //Test bad data error (missing last name)
        List<SearchContactComponentController.ContactListDisplay> result = SearchContactComponentController.addCustomer( strAccountName, strAccountNumber,
                strFirstName,
                strLastName,
                strPreferredName,                                                                                                       
                strAddress,
                strEmail,
                strPhone,
                strSocialKeys,
                strCustomerType,
                strDPID,
                strAddressLine1,
                strAddressLine2,
                strCity,
                strState,
                strPostcode,
                strCountry,
                ckbEmailNotAvailable );

        system.assert(result[0].result.startsWith('Error:'));

        strAddress = 'houdini address';
        strAddressLine1 = 'houdini address';
        strAddressLine2 = 'houdini address';
        strCity = 'wonderland';
        strState = 'far far away';
        strPostcode = '3000';
        strLastName = 'HoudiniG';
    
        //Test success
        List<SearchContactComponentController.ContactListDisplay> accResult = SearchContactComponentController.addCustomer(strAccountName, strAccountNumber,
                strFirstName,
                strLastName,
                strPreferredName,                                                                                                          
                strAddress,
                strEmail,
                strPhone,
                strSocialKeys,
                strCustomerType,
                strDPID,
                strAddressLine1,
                strAddressLine2,
                strCity,
                strState,
                strPostcode,
                strCountry,
                ckbEmailNotAvailable );

        Contact ct = [select accountId from Contact where LastName =:strLastName limit 1];
        system.assert(accResult[0].result == ct.accountId);
        
        //30/05/2017 - Dion Gunn - Test duplicate error result
        //27/08/2019 - Snigdha - Fix test failure due to new validation rule
        
        // Create a person account with record type consumer
        Account personAcc = new Account(
            firstName = 'Meruem',
            lastName = 'Light',
            PersonMobilePhone = '0400123456',
            PersonEmail = 'testDup@email.com',
            RecordTypeId = [Select Id, Name from recordType where Name = 'Consumer' LIMIT 1].id
        );  insert personAcc;
        
        // Add test data with identical firstName, lastName, mobile, email data to existing person account
        strFirstName = 'Meruem';
        strLastName = 'Light'; 
        strPreferredName = 'Merry';
        strEmail = 'testDup@email.com';
        strPhone = '0400123456';
        strAddress = '';
        strAddressLine1 = '';
        strAddressLine2 = '';
        strCity = '';
        strState = '';
        strPostcode = '';
        // Query and run as 'SSSW - Service Agent' user
        User ssswUser = [select id, ProfileId from User where email = 'testSearchContact@auspost.com.au' AND Alias = 'sccct' limit 1];
        System.runAs(ssswUser){
            accResult = SearchContactComponentController.addCustomer(strAccountName, strAccountNumber,
                    strFirstName,
                    strLastName,
                    strPreferredName,                                                 
                    strAddress,
                    strEmail,
                    strPhone,
                    strSocialKeys,
                    strCustomerType,
                    strDPID,
                    strAddressLine1,
                    strAddressLine2,
                    strCity,
                    strState,
                    strPostcode,
                    strCountry,
                    ckbEmailNotAvailable );
            // Duplicate Error should be triggered due inserting identical Contact data
            system.assert(accResult[0].result.startsWith('Error: DUPLICATES_DETECTED'));
        }

        Account bizAccount = TestDataProvider.createAndSaveBusinessAccount('Business Bob the builder', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
        bizAccount.ABN__c = '28864970579';
        bizAccount.accountNumber = bizAccount.ABN__c;
        update bizAccount;
        bizAccount = [select Name, accountNumber from Account where id=:bizAccount.id limit 1];
        strAccountNumber = String.isblank(bizAccount.accountNumber) ? 'test' : bizAccount.accountNumber;
        strAccountName = bizAccount.Name;
        
        result = SearchContactComponentController.addCustomer(strAccountName, strAccountNumber,
                strFirstName,
                strLastName,
                strPreferredName,                                              
                strAddress,
                strEmail,
                strPhone,
                strSocialKeys,
                strCustomerType,
                strDPID,
                strAddressLine1,
                strAddressLine2,
                strCity,
                strState,
                strPostcode,
                strCountry,
                ckbEmailNotAvailable );
        ct = [select accountId from Contact where LastName =:strLastName limit 1];
        List<Account> accToTest = new List<Account>([select Id from Account where Id =: ct.accountId limit 1]);
        system.assert(!accToTest.isEmpty());

        //17/10/2019 - Seth Heang - Test Block Business Contact from being created if duplicate contacts are under same Organisation
        // Add test data with identical firstName, lastName, mobile, email data to existing person account
        strFirstName = 'Maria';
        strLastName = 'Tiffany'; 
        strPreferredName = 'Maria';
        strEmail = 'exampleTest@email.com';
        strPhone = '0412345678';
        strAccountName =  'test org';
        strAccountNumber ='';
        strAddress = '';
        strAddressLine1 = '';
        strAddressLine2 = '';
        strCity = '';
        strState = '';
        strPostcode = '';
        // Query and run as 'SSSW - Service Agent' user
        System.debug('##### before test');
        System.runAs(ssswUser){
            List<SearchContactComponentController.ContactListDisplay> conResult = SearchContactComponentController.addCustomer(
                    strAccountName, 
                    strAccountNumber,
                    strFirstName,
                    strLastName,
                    strPreferredName,
                    strAddress,
                    strEmail,
                    strPhone,
                    strSocialKeys,
                    strCustomerType,
                    strDPID,
                    strAddressLine1,
                    strAddressLine2,
                    strCity,
                    strState,
                    strPostcode,
                    strCountry,
                    ckbEmailNotAvailable );
            // Duplicate Error should be triggered due inserting identical Contact data
            System.debug('#####conResult for dup Contact: '+ conResult );
            system.assert(conResult[0].result.startsWith('Error: DUPLICATES_DETECTED'));
        }
    } 
        
    //Maumita Starts
    static testMethod void searchCustomer() {
        string strCustomerType = '';
        string strEmail = '';
        string strFirstName = 'maumita';
        string strLastName = '';
        string strPreferredName = '';
        string strPhone = '';
        string strAccountNumber = '';
        string strAccountName = '';
        string strSocialKeys = '';
        string strAddress = '';
        string strAddress_line = '';
        string strAddress_city = '';
        string strAddress_state = '';
        string strCity = '';
        string strAddress_pc = '';
        string strAddress_country = '';
        boolean ignorePhone = FALSE;

        //Test 
        List<SearchContactComponentController.ContactListDisplay> result = SearchContactComponentController.searchCustomer( strCustomerType,
             strEmail,
             strFirstName,
             strLastName,
             strPreferredName,                                                                                                              
             strPhone,
             strAccountNumber,
             strAccountName,
             strSocialKeys,
             strAddress,                                                    
             strAddress_line,
             strAddress_city, 
             strAddress_state,
             strAddress_pc,   
             strAddress_country,                                          
             ignorePhone);
        
        System.assert(result != null);
    }
    //Maumita Ends
}