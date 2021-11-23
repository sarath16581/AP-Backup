/*------------------------------------------------------------------------------
Author:         Kenny Liew
Company:        Salesforce.com
Description:    A test class created to validate the
                MyPostBusinessLeadConvert utility class

                Tests executed:

                1 - testPositiveSingular().  Successful lead conversion for a
                    single Contact created with duplicate Leads by email
                    address.

                2 - testPositiveSingularPersonAccount().  Successful lead
                    conversion for a single Person Account created with
                    duplicate Leads by email address.

                3 - testEmailChangedNoAction().  Negative test for Lead
                    Conversion, where email between Lead and Contact don't
                    match, even when the Campaign Member Id does.  Simulates
                    forwarding of registration / activation emails to others.

                4 - testNegativeSingular().  Negative test for Lead
                    Conversion, with intentional use of invalid Campaign
                    Member Id.  Purpose is to test error handling in try / catch
                    block.

                5 - testNegativeSingularPersonAccount().  Negative test for Lead
                    Conversion, with intentional use of invalid Campaign
                    Member Id.  Purpose is to test error handling in try / catch
                    block.

                6 - testPositiveBulkified().  Positive test, bulkified scenario.

History
<Date>      <Authors Name>      <Brief Description of Change>
6-June-16   Kenny Liew          Initial creation.
30-NOV-16   Davey Yu            Update all methods to remove data dependency on actual data 
------------------------------------------------------------------------------*/

@istest
public class MyPostBusinessLeadConvert_Test {
        
   @isTest static void testPositiveSingular() {

        //  create test data for the following scenario:
        //  -   single Contact record being created and fires trigger, with valid Business Account and Campaign Member Id - positive testing,
        //      single record.
        //  -   with duplicate Leads, same email address.

        RecordType leadRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'Standard' LIMIT 1];
        
        Campaign testCampaign1 = new Campaign();
        testCampaign1.Name = 'MyPost Business';
        insert testCampaign1;

        Lead testLead1 = new Lead();
        testLead1.Company = 'MyPost Business Test Account 1';
        testLead1.FirstName = 'MyPost Business';
        testLead1.LastName = 'Test Lead 1';
        testLead1.Email = 'test.lead@auspost.com.au';
        testLead1.LeadSource = 'SBSub_Online';
        testLead1.Status = 'MyPost Business';
        testLead1.Legal_Marketing_Opt_In__c = true;
        testLead1.Email_Electronic_Opt_In__c = 'YES';
        testLead1.RecordTypeId = leadRecordType.Id;
        insert testLead1;

        Lead testLead2 = new Lead();
        testLead2.Company = 'MyPost Business Test Account 2';
        testLead2.FirstName = 'MyPost Business';
        testLead2.LastName = 'Test Lead 2';
        testLead2.Email = 'test.lead@auspost.com.au';
        testLead2.LeadSource = 'SBSub_Retail';
        testLead2.Status = 'MyPost Business';
        testLead2.Legal_Marketing_Opt_In__c = true;
        testLead2.Email_Electronic_Opt_In__c = 'YES';
        testLead2.RecordTypeId = leadRecordType.Id;
        insert testLead2;

        CampaignMember testCampaignMember1 = [SELECT Id FROM CampaignMember WHERE CampaignId = :testCampaign1.Id AND LeadId = :testLead1.Id LIMIT 1];
        RecordType accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Business_Account' LIMIT 1];

        Account testAccount1 = new Account();
        testAccount1.Name = 'MyPost Business Test Account';
        testAccount1.RecordTypeId = accountRecordType.Id;
        insert testAccount1;

        Contact testContact1 = new Contact();
        testContact1.AccountId = testAccount1.Id;
        testContact1.FirstName = 'MPB';
        testContact1.LastName = 'Test Lead';
        testContact1.Email = 'test.lead@auspost.com.au';
        testContact1.MPB_Campaign_Member_Id__c = testCampaignMember1.Id;
        
        Test.startTest();
        insert testContact1;
        Test.stopTest();        

        Lead updatedLeadRecord = [SELECT Id, FirstName, LastName, Company, IsConverted FROM Lead WHERE Id = :testLead1.Id LIMIT 1];
        Lead updatedLead2Record = [SELECT Id, Status FROM Lead WHERE Id = :testLead2.Id LIMIT 1];
        Contact updatedContactRecord = [SELECT Id, FirstName, LastName, MPB_Campaign_Member_Id__c FROM Contact WHERE Id = :testContact1.Id LIMIT 1];
        
        System.assertEquals(testAccount1.Name, updatedLeadRecord.Company);              //  Lead's Company value updated per Account's
        System.assertEquals(testContact1.FirstName, updatedLeadRecord.FirstName);       //  Lead's First Name value updated per Contact's
        System.assertEquals(testContact1.LastName, updatedLeadRecord.LastName);         //  Lead's Last Name value updated per Contact's
        System.assertEquals(true, updatedLeadRecord.IsConverted);                       //  Lead gets converted
        System.assertEquals('Duplicate lead', updatedLead2Record.Status);               //  Duplicate Lead's status gets set to 'Duplicate lead'
        System.assertEquals(null, updatedContactRecord.MPB_Campaign_Member_Id__c);      //  Contact.MPB_Campaign_Member_Id__c should be nullified

    }


    @isTest static void testPositiveSingularPersonAccount() {

        //  create test data for the following scenario:
        //  -   single Person Account record being created and fires trigger, with valid Person Account and Campaign Member Id - positive testing,
        //      single record.
        //  -   with duplicate Leads, same email address.
        
        RecordType leadRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'Standard' LIMIT 1];
        
        Campaign testCampaign1 = new Campaign();
        testCampaign1.Name = 'MyPost Business';
        insert testCampaign1;
        
        Lead testLead5 = new Lead();
        testLead5.FirstName = 'MyPost Business';
        testLead5.LastName = 'Test Lead 5';
        testLead5.Email = 'test.person.account@auspost.com.au';
        testLead5.LeadSource = 'SBSub_Online';
        testLead5.Status = 'MyPost Business';
        testLead5.Legal_Marketing_Opt_In__c = true;
        testLead5.Email_Electronic_Opt_In__c = 'YES';
        testLead5.RecordTypeId = leadRecordType.Id;
        insert testLead5;

        Lead testLead6 = new Lead();
        testLead6.FirstName = 'MyPost Business';
        testLead6.LastName = 'Test Lead 6';
        testLead6.Email = 'test.person.account@auspost.com.au';
        testLead6.LeadSource = 'SBSub_Online';
        testLead6.Status = 'MyPost Business';
        testLead6.Legal_Marketing_Opt_In__c = true;
        testLead6.Email_Electronic_Opt_In__c = 'YES';
        testLead6.RecordTypeId = leadRecordType.Id;
        insert testLead6;
        
        CampaignMember testCampaignMember1 = [SELECT Id FROM CampaignMember WHERE CampaignId = :testCampaign1.Id AND LeadId = :testLead5.Id LIMIT 1];
        CampaignMember testCampaignMember2 = [SELECT Id FROM CampaignMember WHERE CampaignId = :testCampaign1.Id AND LeadId = :testLead6.Id LIMIT 1];
    
        RecordType accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];

        Account testPersonAccount = new Account();
        testPersonAccount.FirstName = 'MyPost Business';
        testPersonAccount.LastName = 'Test Person Account';
        testPersonAccount.PersonEmail = 'test.person.account@auspost.com.au';
        testPersonAccount.PersonLeadSource = 'SBSub_Online';
        testPersonAccount.Email_Electronic_Opt_In__pc = 'YES';
        testPersonAccount.Legal_Marketing_Opt_In__pc = true;
        testPersonAccount.MPB_Campaign_Member_Id__pc = testCampaignMember1.Id;
        testPersonAccount.RecordTypeId = accountRecordType.Id;

        Test.startTest();
        insert testPersonAccount;
        Test.stopTest();        

        Lead updatedLeadRecord = [SELECT Id, FirstName, LastName, IsConverted FROM Lead WHERE Id = :testLead5.Id LIMIT 1];
        Lead updatedDuplicateLeadRecord = [SELECT Id, IsConverted, Status FROM Lead WHERE Id = :testLead6.Id LIMIT 1];
        Account updatedPersonAccount = [SELECT Id, MPB_Campaign_Member_Id__pc FROM Account WHERE Id = :testPersonAccount.Id LIMIT 1];
        CampaignMember updatedCampaignMember = [SELECT Status FROM CampaignMember WHERE Id = :testCampaignMember1.Id LIMIT 1];

        System.assertEquals(testPersonAccount.FirstName, updatedLeadRecord.FirstName);      //  Lead's FirstName value updated per Person Account's
        System.assertEquals(testPersonAccount.LastName, updatedLeadRecord.LastName);        //  Lead's LastName value updated per Person Account's
        System.assertEquals(true, updatedLeadRecord.IsConverted);                           //  1st lead's converted
        System.assertEquals(false, updatedDuplicateLeadRecord.IsConverted);                 //  2nd lead's NOT converted
        System.assertEquals('Duplicate lead', updatedDuplicateLeadRecord.Status);           //  2nd lead's status updated to 'Duplicate lead'
        System.assertEquals(null, updatedPersonAccount.MPB_Campaign_Member_Id__pc);         //  Person Account's MPB_Campaign_Member_Id__pc field set to null post conversion
        System.assertEquals('Responded', updatedCampaignMember.Status);                     //  Campaign Member record's status set to 'Responded'.

    }


    @isTest static void testEmailChangedNoAction() {

        //  create test data for the following scenario:
        //  -   single Contact record being created and fires trigger, with valid Business Account and Campaign Member Id but change of email
        //      address when Account + Contact's created, hence being ignored by logic.

        RecordType leadRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'Standard' LIMIT 1];
        
        Campaign testCampaign4 = new Campaign();
        testCampaign4.Name = 'MyPost Business';
        insert testCampaign4;
        
        Lead testLead4 = new Lead();
        testLead4.Company = 'MyPost Business Test Account 4';
        testLead4.FirstName = 'MyPost Business';
        testLead4.LastName = 'Test Lead 4';
        testLead4.Email = 'test.lead.4@auspost.com.au';
        testLead4.LeadSource = 'SBSub_Online';
        testLead4.Status = 'MyPost Business';
        testLead4.Legal_Marketing_Opt_In__c = true;
        testLead4.Email_Electronic_Opt_In__c = 'YES';
        testLead4.RecordTypeId = leadRecordType.Id;
        insert testLead4;

        CampaignMember testCampaignMember4 = [SELECT Id FROM CampaignMember WHERE CampaignId = :testCampaign4.Id AND LeadId = :testLead4.Id LIMIT 1];
      
        RecordType accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Business_Account' LIMIT 1];

        Account testAccount4 = new Account();
        testAccount4.Name = 'MyPost Business Test Account';
        testAccount4.RecordTypeId = accountRecordType.Id;
        insert testAccount4;

        Contact testContact4 = new Contact();
        testContact4.AccountId = testAccount4.Id;
        testContact4.FirstName = 'MPB';
        testContact4.LastName = 'Test Lead';
        testContact4.Email = 'test.lead.changed@auspost.com.au';
        testContact4.MPB_Campaign_Member_Id__c = testCampaignMember4.Id;
        
        Test.startTest();
        insert testContact4;
        Test.stopTest();

        Lead updatedLeadRecord = [SELECT Id, Company, IsConverted FROM Lead WHERE Id = :testLead4.Id LIMIT 1];
        Contact updatedContactRecord = [SELECT Id, FirstName, LastName, MPB_Campaign_Member_Id__c FROM Contact WHERE Id = :testContact4.Id LIMIT 1];

        System.assertEquals(false, updatedLeadRecord.IsConverted);                                      //  Lead does not get converted
        System.assertEquals(testCampaignMember4.Id, updatedContactRecord.MPB_Campaign_Member_Id__c);    //  Contact.MPB_Campaign_Member_Id__c should be nullified, value untouched

    }

    @isTest static void testNegativeSingular() {

        //  create test data for the following scenario:
        //  -   single Contact record being created and fires trigger, with INVALID Campaign Member Id - negative testing, single record
        //  -   purpose is to test that error handling logic works

        RecordType leadRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'Standard' LIMIT 1];
        
        Campaign testCampaign1 = new Campaign();
        testCampaign1.Name = 'MyPost Business';
        insert testCampaign1;
        
        Lead testLead3 = new Lead();
        testLead3.Company = 'MyPost Business Test Account 3';
        testLead3.FirstName = 'MyPost Business';
        testLead3.LastName = 'Test Lead 1';
        testLead3.Email = 'test.lead@auspost.com.au';
        testLead3.LeadSource = 'SBSub_Online';
        testLead3.Status = 'Not Verified';
        testLead3.Legal_Marketing_Opt_In__c = true;
        testLead3.Email_Electronic_Opt_In__c = 'YES';
        testLead3.RecordTypeId = leadRecordType.Id;
        insert testLead3;

        RecordType accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Business_Account' LIMIT 1];
        Account testAccount2 = new Account();
        testAccount2.Name = 'MyPost Business Test Account';
        testAccount2.RecordTypeId = accountRecordType.Id;
        insert testAccount2;

        Contact testContact2 = new Contact();
        testContact2.AccountId = testAccount2.Id;
        testContact2.FirstName = 'MPB';
        testContact2.LastName = 'Test Lead';
        testContact2.Email = 'test.lead@auspost.com.au';
        testContact2.MPB_Campaign_Member_Id__c = testLead3.Id;  // intentional use of invalid Campaign Member Id.
        
        Test.startTest();
        insert testContact2;
        Test.stopTest();        

        Lead updatedLeadRecord = [SELECT Id, Company, IsConverted FROM Lead WHERE Id = :testLead3.Id LIMIT 1];
        System.assertEquals(false, updatedLeadRecord.IsConverted);  //  Lead does not get converted

    }

    @isTest static void testNegativeSingularPersonAccount() {

        //  create test data for the following scenario:
        //  -   single Person Account record being created and fires trigger, with valid Person Account and Campaign Member Id - positive testing,
        //      single record.
        //  -   with duplicate Leads, same email address.
        
        RecordType leadRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Lead' AND DeveloperName = 'Standard' LIMIT 1];
        
        Campaign testCampaign1 = new Campaign();
        testCampaign1.Name = 'MyPost Business';
        insert testCampaign1;
        
        Lead testLead7 = new Lead();
        testLead7.FirstName = 'MyPost Business';
        testLead7.LastName = 'Test Lead 7';
        testLead7.Email = 'test.person.account@auspost.com.au';
        testLead7.LeadSource = 'SBSub_Online';
        testLead7.Status = 'MyPost Business';
        testLead7.Legal_Marketing_Opt_In__c = true;
        testLead7.Email_Electronic_Opt_In__c = 'YES';
        testLead7.RecordTypeId = leadRecordType.Id;
        insert testLead7;

        Lead testLead8 = new Lead();
        testLead8.FirstName = 'MyPost Business';
        testLead8.LastName = 'Test Lead 8';
        testLead8.Email = 'test.person.account@auspost.com.au';
        testLead8.LeadSource = 'SBSub_Online';
        testLead8.Status = 'MyPost Business';
        testLead8.Legal_Marketing_Opt_In__c = true;
        testLead8.Email_Electronic_Opt_In__c = 'YES';
        testLead8.RecordTypeId = leadRecordType.Id;
        insert testLead8;

       
        CampaignMember testCampaignMember1 = [SELECT Id FROM CampaignMember WHERE CampaignId = :testCampaign1.Id AND LeadId = :testLead7.Id LIMIT 1];
       
        RecordType accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1];

        Account testPersonAccount = new Account();
        testPersonAccount.FirstName = 'MyPost Business';
        testPersonAccount.LastName = 'Test Person Account';
        testPersonAccount.PersonEmail = 'test.person.account@auspost.com.au';
        testPersonAccount.PersonLeadSource = 'SBSub_Online';
        testPersonAccount.Email_Electronic_Opt_In__pc = 'YES';
        testPersonAccount.Legal_Marketing_Opt_In__pc = true;
        testPersonAccount.MPB_Campaign_Member_Id__pc = testLead7.Id;
        testPersonAccount.RecordTypeId = accountRecordType.Id;

        Test.startTest();
        insert testPersonAccount;
        Test.stopTest();        

        Lead updatedLeadRecord = [SELECT Id, FirstName, LastName, IsConverted FROM Lead WHERE Id = :testLead7.Id LIMIT 1];
        System.assertEquals(false, updatedLeadRecord.IsConverted);                          //  1st lead's converted

    }
    
    @isTest static void testPositiveBulkified() {

        //  create test data for the following scenario:
        //  -   25 Contact records being created and fired trigger, with valid Business Account Campaign Member Id - positive testing,
        //      bulkified scenario.
        
        RecordType accountRecordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Business_Account' LIMIT 1];
        
        Campaign testCampaign1 = new Campaign();
        testCampaign1.Name = 'MyPost Business';
        insert testCampaign1;
        
        List<Account> listofAccounts = new List<Account>();
        
        for (Integer i = 0; i<5; i++) {
            Account newAccount = new Account(Name='MyPost Business Test Account ' + i, RecordTypeId=accountRecordType.Id);
            listofAccounts.add(newAccount);
        }
        insert listofAccounts;
        
        List<Contact> listofContacts = new List<Contact>();
        List<Lead> listofLeads = new List<Lead>();
        for (Account currentAccountRec : listofAccounts) {
            
          
            
            Lead newLead = new Lead();
            newLead.Company = 'MyPost Business Test Account ' + currentAccountRec.Id;
            newLead.FirstName = 'MyPost Business';
            newLead.LastName = 'Test Lead ' + currentAccountRec.Id;
            newLead.Email = 'test.lead.' + currentAccountRec.Id + '@auspost.com.au';
            newLead.LeadSource = 'SBSub_Online';
            newLead.Status = 'MyPost Business';
            newLead.Legal_Marketing_Opt_In__c = true;
            newLead.Email_Electronic_Opt_In__c = 'YES';
            newLead.RecordTypeId = '01290000000X7uAAAS';
            insert newLead;
            listofLeads.add(newLead);

          
            CampaignMember testCampaignMember1 = [SELECT Id FROM CampaignMember WHERE CampaignId = :testCampaign1.Id AND LeadId = :newLead.Id LIMIT 1];
            

          
            
            Contact newContact = new Contact();
            newContact.AccountId = currentAccountRec.Id;
            newContact.FirstName = 'MPB';
            newContact.LastName = 'Test Lead';
            newContact.Email = 'test.lead.' + currentAccountRec.Id + '@auspost.com.au';
            newContact.MPB_Campaign_Member_Id__c = testCampaignMember1.Id;
            listofContacts.add(newContact);
        }
        
        Test.startTest();
        insert listofContacts;
        Test.stopTest();        

        //  add system.asserts.  is it possible with bulkified scenario?
        for (Lead currentLeadInLoop : listofLeads) {
            Lead updatedLeadRecord = [SELECT Id, Company, IsConverted FROM Lead WHERE Id = :currentLeadInLoop.Id LIMIT 1];
            System.assertEquals(true, updatedLeadRecord.IsConverted);   //  Lead is successfully converted
        }
        
    }

}