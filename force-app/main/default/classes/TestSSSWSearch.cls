/**
  * @author       : eric.shen@auspost.com.au 
  * @date         : 28/07/2015
  * @description  : Test class for SSSWsearch
  */


@isTest
private class TestSSSWSearch {
    /*
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
    }
    
    static testMethod void testGetCustomerTypes() {
        Case dummyCase = new Case();
        SearchContactComponentController controller = new SearchContactComponentController();   
        List<SelectOption> customerTypes = controller.getCustomerTypes();
        system.assert(customerTypes.get(0).getValue() == '');
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
        
        string result = SearchContactComponentController.addCustomer( strAccountName, strAccountNumber, 
                                              strFirstName, 
                                              strLastName, 
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
                                              strCountry);
        
        system.assert(result.startsWith('Error:'));
        
        strAddress = 'houdini address';
        strAddressLine1 = 'houdini address';
        strAddressLine2 = 'houdini address';
        strCity = 'wonderland';
        strState = 'far far away';
        strLastName = 'HoudiniG_isBobTheBuilder';
        
        result = SearchContactComponentController.addCustomer(strAccountName, strAccountNumber, 
                                              strFirstName, 
                                              strLastName, 
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
                                              strCountry);
        
        Contact ct = [select accountId from Contact where LastName =:strLastName limit 1];
        system.assert(result == ct.accountId);
        
        Account bizAccount = TestDataProvider.createAndSaveBusinessAccount('Business Bob the builder', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
        bizAccount = [select accountNumber from Account where id=:bizAccount.id limit 1];
        strAccountNumber = String.isblank(bizAccount.accountNumber) ? 'test' : bizAccount.accountNumber;
        strLastName = 'HoudiniG_isALegendXXXXXX';
        result = SearchContactComponentController.addCustomer(strAccountName, strAccountNumber, 
                                              strFirstName, 
                                              strLastName, 
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
                                              strCountry);
        
        //ct = [select accountId from Contact where LastName =:strLastName limit 1];
        //system.assert(ct.accountId == bizAccount.id);
    }
*/
}