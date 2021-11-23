/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test class for StarTrack Send Email Extension
History
May 16, 2016 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class StarTrackSendEmailExt_Test {
    
    @isTest static void testDummy() {
        Case dummyCase = TestDataProvider.createTestCase();
        dummyCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        INSERT dummyCase;

        ApexPages.StandardController ctrl = new ApexPages.StandardController(dummyCase);
        StarTrackSendEmailExt ext = new StarTrackSendEmailExt(ctrl);

        Test.setCurrentPage(Page.StarTrackSendEmail);
    }

    /*@testSetup static void testSetup() {
        
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
        insert customSetting;
        
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        INSERT testAccount;

        testAccount.Legacy_Id__c = '60000000';
        UPDATE testAccount;

        Billing_Account__c testBillingAcc = TestDataProvider.createBillingAccount('', 1,new List<Account>{testAccount})[0];
        testBillingAcc.Depot_Collection__c = 'No';
        testBillingAcc.Redirection__c = 'No';
        testBillingAcc.Redelivery__c = 'No';
        INSERT testBillingAcc;
        
        Id pudEnquiryId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testPUDCase = TestDataProvider.createTestCase();
        testPUDCase.RecordTypeId = pudEnquiryId;
        testPUDCase.Call_Purpose__c = 'Card Left';
        testPUDCase.Recent_Caller_Email__c = 't@e.st';
        INSERT testPUDCase;

        Id salesEnquiryId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        Case testSalesCase = TestDataProvider.createTestCase();
        testSalesCase.RecordTypeId = salesEnquiryId;
        testSalesCase.Call_Purpose__c = 'Other';
        testSalesCase.Recent_Caller_Email__c = 't@e.st';
        testSalesCase.Recent_Caller_First_Name__c = 'First';
        testSalesCase.Recent_Caller_Last_Name__c = 'Last';
        testSalesCase.Recent_Caller_Phone_Number__c = '1';
        testSalesCase.Related_Billing_Account__c = testBillingAcc.Id;
        INSERT testSalesCase;

        Id tacticalId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('StarTrack Business Solutions Communications').getRecordTypeId();
        Case testTacticalCase = TestDataProvider.createTestCase();
        testTacticalCase.RecordTypeId = tacticalId;
        testTacticalCase.SuppliedEmail = 't@e.st';
        INSERT testTacticalCase;
    }

    @isTest static void testSalesAddressPositive() {
        Id salesEnquiryId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Sales Enquiry').getRecordTypeId();
        Case queryCase = [SELECT RecordTypeId, Recent_Caller_Email__c FROM Case WHERE RecordTypeId = :salesEnquiryId LIMIT 1];

        ApexPages.StandardController ctrl = new ApexPages.StandardController(queryCase);
        StarTrackSendEmailExt ext = new StarTrackSendEmailExt(ctrl);

        Test.setCurrentPage(Page.StarTrackSendEmail);
        Test.startTest();
            System.assert(String.isNotBlank(ext.toAddress));
        Test.stopTest();
    }

    @isTest static void testTacticalAddressPositive() {
        Id tacticalId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('StarTrack Business Solutions Communications').getRecordTypeId();
        Case queryCase = [SELECT RecordTypeId, SuppliedEmail FROM Case WHERE RecordTypeId = :tacticalId LIMIT 1];

        ApexPages.StandardController ctrl = new ApexPages.StandardController(queryCase);
        StarTrackSendEmailExt ext = new StarTrackSendEmailExt(ctrl);

        Test.setCurrentPage(Page.StarTrackSendEmail);
        Test.startTest();
            System.assert(String.isNotBlank(ext.toAddress));
        Test.stopTest();
    }

    @isTest static void testSalesAddressNegative() {
        Id pudEnquiryId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case queryCase = [SELECT RecordTypeId, Recent_Caller_Email__c FROM Case WHERE RecordTypeId = :pudEnquiryId LIMIT 1];

        ApexPages.StandardController ctrl = new ApexPages.StandardController(queryCase);
        StarTrackSendEmailExt ext = new StarTrackSendEmailExt(ctrl);

        Test.setCurrentPage(Page.StarTrackSendEmail);
        Test.startTest();
            System.assert(String.isBlank(ext.toAddress));
        Test.stopTest();
    }*/
}