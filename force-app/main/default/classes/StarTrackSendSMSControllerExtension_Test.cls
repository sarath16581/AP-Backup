/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test Class for StarTrackSendSMSControllerExtension
History
May 16, 2016 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class StarTrackSendSMSControllerExtension_Test {

    @testSetup
    static void testSetup(){
        
        StarTrack_Settings__c cusSetting = StarTrack_Settings__c.getOrgDefaults();
        cusSetting.StarTrack_SMS_Suffix__c = 'Please don\'t reply.';
        insert cusSetting;
        
        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.Call_Purpose__c = 'Card Left';
        testCase.Enquiry_Type__c = 'Depot Collection';
        testCase.Recent_Contact_Mobile_Number__c = '0453647829';
        INSERT testCase;
    }

    @isTest static void testSendSMS() {
        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case queryCase = [SELECT CaseNumber, Id FROM Case LIMIT 1];
        Test.setCurrentPage(Page.StarTrackSendSMS);
        Integer totalCount = 160 - (StarTrack_Settings__c.getOrgDefaults().StarTrack_SMS_Suffix__c != null ? StarTrack_Settings__c.getOrgDefaults().StarTrack_SMS_Suffix__c.length()+2 : 0);
         
        Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(queryCase);
            StarTrackSendSMSControllerExtension ctrl = new StarTrackSendSMSControllerExtension(sc);
            ctrl.txtMessage = 'Sample';
            ctrl.setValidationToTrue();
            String greaterThan60 = 'This is testing. Greater than 160 characters. This is testing. Greater than 160 characters. This is testing. Greater than 160 characters. This is testing. Greater than 160 characters.';
            System.assertEquals('Error: Mobile Number not specified.', StarTrackSendSMSControllerExtension.sendSMS(queryCase.Id, queryCase.CaseNumber, '', 'This is testing.', totalCount));
            System.assertEquals('Error: Invalid Mobile Number.', StarTrackSendSMSControllerExtension.sendSMS(queryCase.Id, queryCase.CaseNumber, '12375869', 'This is testing.', totalCount));
            System.assertEquals('Error: Invalid Mobile Number.', StarTrackSendSMSControllerExtension.sendSMS(queryCase.Id, queryCase.CaseNumber, '1237586xyz', 'This is testing.', totalCount));
            System.assertEquals('Error: Max number characters allowed is 160', StarTrackSendSMSControllerExtension.sendSMS(queryCase.Id, queryCase.CaseNumber, '1237586934', greaterThan60, totalCount));
            System.assert(String.isNotEmpty(StarTrackSendSMSControllerExtension.sendSMS(delEnquiryRecTypeId, queryCase.CaseNumber, '1237586934', 'This is testing.', totalCount)));
            System.assertEquals('Success!', StarTrackSendSMSControllerExtension.sendSMS(queryCase.Id, queryCase.CaseNumber, '1237586934', 'This is testing.', totalCount));
        Test.stopTest();
        
        Task queryTask = [SELECT Id, Status, SMSError__c FROM Task WHERE WhatId =: queryCase.Id LIMIT 1];
        System.assertNotEquals(null, queryTask);
    }

}