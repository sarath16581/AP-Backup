/**************************************************
Type:       Test class for the CaseContactSidepanelContExt class
Purpose:    Tests if the page works for both Contact and Person Account and gets the page settings from CaseContactSidePanelTabSettings__c 
       
History:
--------------------------------------------------
18.12.2013  Mohamed.Atheek@bluewolf.com  Created
15/06/2017   dion.gunn@auspost.com.au - modified to cover duplicate checker exceptions
20 Aug 2018 nanda.kothamasu@auspost.com.au	 Fix the FIND search string with special char as per INC1132653
**************************************************/

@isTest
private class TestCaseContactSidepanelContExt {
   

    
    @testSetup static void createTestData() {
        Profile prof = [select id from Profile where Name = 'SSSW - Service Agent' limit 1];
        String username = 't' + String.valueOf(System.now()).hashCode() + '@auspost.com.au';
        User pu = new User(profileId = prof.id, username = username, email = 'testSearchContact@auspost.com.au',
                emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                alias='sccct', lastname='lastname');
        insert pu;
    }

    static testMethod void testWithExistingContact() {
        Account acc = TestDataProvider.createAndSaveBusinessAccount('BusAcc', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
        Contact cont = TestDataProvider.createAndSaveContact('test', acc.Id, Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        Case cs = TestDataProvider.createCase('subject', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
        cs.ContactId = cont.Id;
        insert cs;

        setupCustSetting();

        Test.startTest();

        ApexPages.StandardController stdController = new ApexPages.StandardController(cs);
        CaseContactSidepanelContExt contr = new CaseContactSidepanelContExt(stdController);
        Component.Apex.OutputPanel output = contr.getTabs();
        System.assertEquals(contr.strAccountName, 'BusAcc' );
        System.assertEquals(contr.strCustomerType, null);
             System.assert(!output.childComponents.isEmpty());

        contr.caseContact.Email = 'test@test.com';
        contr.save();

        Contact savedCont = [SELECT Email FROM Contact WHERE Id = :contr.caseContact.Id];
        System.assertEquals(contr.caseContact.Email, savedCont.Email);

        contr.caseContact.Email = 'test2@test.com';
        contr.cancel();

        savedCont = [SELECT Email FROM Contact WHERE Id = :contr.caseContact.Id];
        System.assertNotEquals(contr.caseContact.Email, savedCont.Email);

        Test.stopTest();
    }

    static testMethod void testWithNewContact() {
        Case cs = TestDataProvider.createCase('subject', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
        insert cs;

        setupCustSetting();

        Test.startTest();

        ApexPages.StandardController stdController = new ApexPages.StandardController(cs);
        CaseContactSidepanelContExt contr = new CaseContactSidepanelContExt(stdController);
        Component.Apex.OutputPanel output = contr.getTabs();
        System.assert(!output.childComponents.isEmpty());
     
		 List<SelectOption> options = contr.getCustomerTypes();
        
		 string value = contr.mapURL;
		 Boolean ErrorPresent = contr.ErrorsPresent;
            
        Account newAccount = new Account(Name = 'test');
        insert newAccount;
		 System.assertEquals(contr.strAccountNumber, newAccount.AccountNumber);
        
        //Test first contact save
        contr.caseContact.FirstName = 'first';
        contr.caseContact.LastName = 'last';
        contr.caseContact.Email = 'test@test.com';
        contr.strAccountName = 'test';
        contr.save();

        Contact savedCont;
        for (Contact contact: [SELECT Email FROM Contact WHERE Id = :contr.caseContact.Id]) {
            savedCont = contact;
        }
        if (savedCont != null) {
        
            System.assertEquals(contr.caseContact.Email, savedCont.Email);
        }

        contr.caseContact = contr.caseContact.clone(false);
        contr.caseContact.FirstName = 'first';
        contr.caseContact.LastName = 'last';
        contr.caseContact.Email = 'test@test.com';
        contr.strAccountName = 'test';

        User ssswUser = [select id, ProfileId from User where email = 'testSearchContact@auspost.com.au' AND Alias = 'sccct' limit 1];
        System.runAs(ssswUser) {
            contr.save();
        }

        Contact savedCont2;
        for (Contact contact: [SELECT Email FROM Contact WHERE Id = :contr.caseContact.Id]) {
            savedCont2 = contact;
        }

        System.assert(contr.caseContact.Id == null);

        Test.stopTest();
    }

    static testMethod void testWithPersonAccount() {
        Account acc = TestDataProvider.createAndSavePersonAccount('PersAcc', Constants.RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT);
        Id personContId = [SELECT PersonContactId FROM Account WHERE Id = :acc.Id].PersonContactId;
        Case cs = TestDataProvider.createCase('subject', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
        cs.ContactId = personContId;
        insert cs;

        setupCustSetting();

        ApexPages.StandardController stdController = new ApexPages.StandardController(cs);
        CaseContactSidepanelContExt contr = new CaseContactSidepanelContExt(stdController);
        Component.Apex.OutputPanel output = contr.getTabs();
        System.assert(!output.childComponents.isEmpty());

        contr.caseContact.Email = 'test@test.com';
        contr.save();

        Account savedAcc = [SELECT PersonEmail FROM Account WHERE Id = :acc.Id];
        System.assertEquals(contr.caseContact.Email, savedAcc.PersonEmail);

    }

    static testMethod void testWithDupePersonAccount() {
        Case cs = TestDataProvider.createCase('subject', 'description', Constants.RECORDTYPE_NAME_CASE_SSSW_GENERAL);
        insert cs;

        setupCustSetting();

        ApexPages.StandardController stdController = new ApexPages.StandardController(cs);
        CaseContactSidepanelContExt contr = new CaseContactSidepanelContExt(stdController);

        //First successful save
        contr.caseContact.FirstName = 'Test';
        contr.caseContact.LastName = 'LastName';
        contr.caseContact.Email = 'test@test.com';
        contr.strAccountName = '';
        contr.save();

        //Test Duplicate Person Account with name Fuzzy Logic
        User ssswUser = [select id, ProfileId from User where email = 'testSearchContact@auspost.com.au' AND Alias = 'sccct' limit 1];
        System.runAs(ssswUser) {
            //Save with duplicates
            contr.caseContact = contr.caseContact.clone(false,false,false,false);
            contr.strAccountName = '';
            //contr.caseRec.ContactId = null;
            contr.save();
        }

        //Contact id should be null as prevented by Dupe Checker
        System.assert(contr.caseContact.Id == null);
    }

    static void setupCustSetting() {
        CaseContactSidePanelTabSettings__c setting = new CaseContactSidePanelTabSettings__c();
        setting.Name = 'test123';
        setting.RelationshipName__c = 'Cases';
        setting.FieldList__c = 'Subject,CaseNumber';
        setting.ObjectName__c = 'Case';
        setting.ParentFieldName__c = 'ContactId';
        setting.Filters__c = 'Status != \'Closed – Expired\'';
        setting.LinkableField__c = 'CaseNumber';
        setting.HideButtons__c = true;
        setting.DisplayOrder__c = 0;
        insert setting;
    }
}