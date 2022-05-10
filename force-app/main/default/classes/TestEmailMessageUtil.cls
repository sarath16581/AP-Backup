/**************************************************
Description:    Test class to cover EmailMessageUtil
History:
--------------------------------------------------
2022-03-25  naveen.rajanna@auspost.com.au   Update API version to 52 and fix failing test class
**************************************************/@isTest
private class TestEmailMessageUtil {
    //Added by David Catindoy - Nov 29, 2016
    @testSetup 
    static void testDataCreate() {
        StarTrack_Settings__c customSetting = StarTrack_Settings__c.getOrgDefaults();
        customSetting.Email2Case_Check_Last_X_Days__c = 2;
        customSetting.ST_Duplicate_Inbound_Email_Prefix__c = 'DUPLICATE EMAIL - ';
        customSetting.Number_of_Hours_per_Business_Days__c = 8;
        customSetting.Number_of_Business_Days__c = 10;
        customSetting.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
        insert customSetting;
        
        BusinessHours stdBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Id vocEnqRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Voice of Customer Enquiry').getRecordTypeId();
        
        List<Case> listOfCases = new List<Case>();
        listOfCases.add(new Case(RecordTypeId = deliveryRecType, Subject = 'Update Consignment Details', Origin = 'Direct Email', SuppliedEmail='test@test.com'));
        listOfCases.add(new Case(Status = 'New', Subject = 'Test VOC Enquiry', Origin = 'Email', Classification__c = 'Complaint', Priority = 'Normal', BusinessHoursId = stdBusinessHours.Id, RecordTypeId = vocEnqRecType));
        Database.insert(listOfCases);

        AusPostSettings__c setting = new AusPostSettings__c(Name = 'Spam Email Settings', Number1__c = 30);
        insert setting;

        SecurePost__c securePostSetting = new SecurePost__c(CaseType__c = 'SecurePost Onboarding', Email_to_Case_address__c = 'disha.kariya@auspost.com.au', ProductName__c = 'Parcel Post Secure RF');
        insert securePostSetting;
        System.debug('securePostSetting--->'+securePostSetting);
        String prodName = securePostSetting.ProductName__c;
        Product2 prod = new Product2(name = prodName);
        insert Prod;

        EmailMessage newEmail = new EmailMessage(ParentId = listOfCases[0].Id, FromAddress = 'test@test.com', Incoming = true, Subject = 'RE: FWD: FW: Update Consignment Details', HTMLBody = 'Sample', ToAddress = 'support@test.com', Headers = 'Return-Path: Testing header');
        insert newEmail;
    }
    
    @isTest
    private static void testCloningPermanentlyClosedCases() {
        Case c = TestDataProvider.createCase('subject', 'description', 'SSSWDelivery');
        c.Status = 'Closed';
        c.ResolutionCode__c = 'Network resolution';
        c.Permanent_Close__c  = true;
        c.SuppliedEmail = 'test@test.com';
        c.origin = 'Direct Email';
        insert c;
        
        QM__c q = new QM__c();
        q.Customer_Status__c = 'Awaiting customer response';
        q.Network_Status__c = 'Awaiting network response';
        q.CusEmail__c = [select address from orgwideemailaddress where displayname='Australia Post' limit 1].address;
        q.NetworkEmail__c = [select address from orgwideemailaddress where displayname='Customer Enquiry' limit 1].address;
        insert q;

        Test.startTest();
            SpamEmail__c spam = TestUtility.createSpamEmail('test@test.com');
            Database.insert(spam);

            EmailMessage email = new EmailMessage();
            email.ParentId = c.Id;
            email.Incoming = true;
            email.Subject = 'subject SNAPIT';
            email.TextBody = 'text body';
            email.FromAddress = 'test@test.com';
            email.FromName = 'from name';
            email.Headers = 'Return-Path: Testing header';
            email.ToAddress = [select address from orgwideemailaddress where displayname='Customer Enquiry' limit 1].address;
            email.MessageDate = Datetime.now();
            insert email;
        Test.stopTest();        
    }
    
    @isTest
    private static void testStarTrackDuplicateInboundEmail(){        
        Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case newCase = new Case(RecordTypeId = deliveryRecType, Subject = 'RE: FWD: FW: Update Consignment Details', Origin = StarTrack_Constants.CASE_ORIGIN_BSC);
        insert newCase;
        
        EmailMessage newEmail = new EmailMessage(ParentId = newCase.Id, FromAddress = 'test@test.com', Incoming = true, Subject = 'RE: FWD: FW: Update Consignment Details', HTMLBody = 'Sample', ToAddress = 'support@test.com', Headers = 'Return-Path: Testing header');
        Test.startTest();
            insert newEmail;
        Test.stopTest();
        
        newCase = [SELECT Id, Subject, ResolutionCode__c, Status, Enquiry_Type__c, Call_Purpose__c FROM Case WHERE Id =: newCase.Id];
        System.assertEquals(StarTrack_Constants.CASE_RESOLUTION_DUPLICATE, newCase.ResolutionCode__c);
        System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSED, newCase.Status);
        System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_DEF, newCase.Enquiry_Type__c);
        System.assertEquals(StarTrack_Constants.CASE_PURPOSE_DEF, newCase.Call_Purpose__c);
    }
    
    @isTest
    private static void testVOCInboundEmail(){
        Case caseRec = [SELECT Id FROM Case WHERE Subject = 'Test VOC Enquiry' LIMIT 1];
        Id incidentRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Voice of Customer Incident').getRecordTypeId();
        Case vocIncident = new Case(Subject = 'Test VOC 1', Description = 'Sample VOC 1', ParentId = caseRec.Id, Recent_Caller_First_Name__c = 'David', Recent_Caller_Last_Name__c = 'Catindoy', Parent_Status__c = 'New', Status = 'New', Business_Unit__c = 'Commercial', Nominated_Advocate_Email__c = 'david.catindoy@cloudsherpas.com', Nominated_Advocate__c = 'David', CallBackRequired__c = true, RecordTypeId = incidentRecType);
        vocIncident.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        
        Test.startTest();            
            Database.insert(vocIncident); 
            EmailMessage newEmail = new EmailMessage(ParentId = vocIncident.Id, FromAddress = 'test@test.com', Incoming = true, Subject = 'VOC Incident Inbound Email SNAPIT', HTMLBody = 'Sample', ToAddress = 'support@test.com');
            Database.insert(newEmail);
        Test.stopTest();
        
        System.assertEquals([SELECT Id, Status FROM Case WHERE Id =: caseRec.Id].Status, StarTrack_Constants.CASE_STAT_AWAITINGREVIEW);
    }

    // Added below method for Secure Post
    @isTest
    private static void testSecurePost(){
        Id onboardRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Onboarding').getRecordTypeId();
        Case newCase = new Case(RecordTypeId = onboardRecType, Subject = 'Registration for test user', Origin = 'Email');
        Database.insert(newCase);
        String previousCaseSubject = newCase.Subject;
        SecurePost__c securePostSetting = SecurePost__c.getInstance();
        EmailMessage newEmail = new EmailMessage(ParentId = newCase.Id, FromAddress = 'test@test.com', Incoming = true, Subject = 'RE: FWD: FW: Update Consignment Details', HTMLBody = 'Sample', ToAddress = securePostSetting.Email_to_Case_address__c);

        Test.startTest();
            Database.insert(newEmail);
        Test.stopTest();

        newCase = [SELECT Id, Subject, ResolutionCode__c, Status, Enquiry_Type__c, Call_Purpose__c FROM Case WHERE Id =: newCase.Id];
    }
}