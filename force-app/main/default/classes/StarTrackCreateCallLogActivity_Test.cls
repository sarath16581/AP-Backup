/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test Class for StarTrackCreateCallLogActivity
History
August 12, 2016 - David Catindoy - Created
August 31, 2016 - David Catindoy - Modified to cover @future testing
------------------------------------------------------------*/
@isTest
private class StarTrackCreateCallLogActivity_Test {
    
    @testSetup static void testSetup(){
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.Create_Call_Log_using_Future__c = true;
        customSetting.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
        insert customSetting;
    }
    
    //Need to create this another test setup to avoid this error: "DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)"
    @testSetup static void createUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='StarTrack Support']; 
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
        User u = new User(Alias = 'newUser', Email='user@testorg.a', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
             TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        insert u;
    }
    
    @isTest static void testCreateCallLogAsync() {
        
        User u = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
        System.runAs(u) {
            Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
            Case testCase = TestDataProvider.createTestCase();
            testCase.RecordTypeId = delEnquiryRecTypeId;
            testCase.Add_Caller_Quick_Action__c = true;
            testCase.Callers_Data_Change__c = true;
            testCase.Recent_Caller_First_Name__c = 'David';
            testCase.Recent_Caller_Last_Name__c = 'Catindoy';
            testCase.Recent_Caller_Type__c = 'Sender';
            testCase.Priority = 'High';
            testCase.Status = 'New';
            testCase.Recent_Caller_Phone_Number__c = '+639506891923';
            testCase.Recent_Caller_Email__c = 'dcat@gmail.com';
            testCase.Number_of_Callers__c = 0;
            testCase.Direction__c = 'Inbound';
            testCase.Recent_Caller_Pref_Method_of_Contact__c = 'Phone';
            INSERT testCase;
             
            Test.startTest();
                StarTrackCreateCallLogActivity.createLogACallRecord(new List<Id>{testCase.Id});
            Test.stopTest();
            testCase = [SELECT Id, Number_of_Callers__c FROM Case WHERE Id =: testCase.Id];
            
            System.assert(![SELECT Id FROM Task WHERE RecordTypeId =: Schema.SObjectType.Task.getRecordTypeInfosByName().get('StarTrack Activity').getRecordTypeId()].isEmpty());
        }
    }
    
    @isTest static void testCreateCallLogSync() {
        
        StarTrack_Settings__c customSetting = StarTrack_Settings__c.getOrgDefaults();
        customSetting.Create_Call_Log_using_Future__c = false;
        update customSetting;
        
        User u = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
        System.runAs(u) {
            Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
            Case testCase = TestDataProvider.createTestCase();
            testCase.RecordTypeId = delEnquiryRecTypeId;
            testCase.Add_Caller_Quick_Action__c = true;
            testCase.Callers_Data_Change__c = true;
            testCase.Recent_Caller_First_Name__c = 'David';
            testCase.Recent_Caller_Last_Name__c = 'Catindoy';
            testCase.Recent_Caller_Type__c = 'Sender';
            testCase.Priority = 'High';
            testCase.Status = 'New';
            testCase.Recent_Caller_Phone_Number__c = '+639506891923';
            testCase.Recent_Caller_Email__c = 'dcat@gmail.com';
            testCase.Number_of_Callers__c = 0;
            testCase.Direction__c = 'Inbound';
            testCase.Recent_Caller_Pref_Method_of_Contact__c = 'Phone';
            INSERT testCase;
             
            Test.startTest();
                StarTrackCreateCallLogActivity.createLogACallRecord(new List<Id>{testCase.Id});
            Test.stopTest();
            testCase = [SELECT Id, Number_of_Callers__c FROM Case WHERE Id =: testCase.Id];
            
            System.assert(![SELECT Id FROM Task WHERE RecordTypeId =: Schema.SObjectType.Task.getRecordTypeInfosByName().get('StarTrack Activity').getRecordTypeId()].isEmpty());
        }
    }
}