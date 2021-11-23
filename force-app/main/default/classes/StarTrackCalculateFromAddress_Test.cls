/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test Class for StarTrackCalculateFromAddress
History
June 9, 2016 - David Catindoy - Created
------------------------------------------------------------*/
@isTest
private class StarTrackCalculateFromAddress_Test {

    @testSetup
    static void testSetup(){
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.Business_Solutions_From_Email__c = 'bsc@gmail.com';
        customSetting.Investigators_From_Email__c = 'csc@gmail.com';
        customSetting.Duplicate_Email_Check_Interval_Minutes__c = 2;
        customSetting.Check_for_Duplicate_Email__c = true;
        customSetting.ST_Duplicate_Inbound_Email_Prefix__c = StarTrack_Constants.DUPLICATE_EMAIL;
        customSetting.ST_Credit_Claim_Inbound_Email_Prefix__c = 'INVALID CREDIT CLAIM -';
        customSetting.Credit_Dispute_From_Email__c = 'credit@gmail.com';
        insert customSetting;
        
        List<StarTrackDefaultEmailAddresses__c> defaultAddressList = new List<StarTrackDefaultEmailAddresses__c>();
        defaultAddressList.add(new StarTrackDefaultEmailAddresses__c(Name = 'apple@gmail.com', Description__c = 'BSC - Apple', From_Email_Address__c = 'apple-reply@gmail.com'));
        insert defaultAddressList;
        
        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(StarTrack_Constants.CASE_DELIVERY_RT).getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.StarTrack_Calc_Email_Address__c = 'bsc@gmail.com; apple@gmail.com';
        testCase.Subject = 'Sample Duplicate';
        testCase.Send_Auto_Response_Email__c = false;
        testCase.SuppliedEmail = 'te@st.test';
        testCase.Call_Purpose__c = 'Late Delivery';
        INSERT testCase;
        
        EmailMessage oldEmailMsg = new EmailMessage(ParentId = testCase.Id, Subject = 'Sample Duplicate', FromAddress = 'te@st.test');
        insert oldEmailMsg;
        
        Case cloneCase = testCase.clone(false, true, false, false);
        insert cloneCase;
        EmailMessage newEmailMsg = new EmailMessage(ParentId = cloneCase.Id, Subject = 'Sample Duplicate', FromAddress = 'te@st.test');
        insert newEmailMsg;
    }

    @isTest
    static void testDuplicate() {
        Case caseRec = [SELECT Id, Subject FROM Case ORDER BY CreatedDate DESC LIMIT 1];
        EmailMessage emailMsg = [SELECT Id, ParentId, Subject, FromAddress FROM EmailMessage ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
            StarTrackCalculateFromAddress.calculateFromAddress(new List<String>{caseRec.Id +'-'+ emailMsg.Id});
        Test.stopTest();
        caseRec = [SELECT Id, Subject, ResolutionCode__c, Status, Enquiry_Type__c FROM Case WHERE Id =: caseRec.Id];
        System.assertEquals(StarTrack_Constants.DUPLICATE_EMAIL + 'Sample Duplicate', caseRec.Subject);
        System.assertEquals(StarTrack_Constants.CASE_RESOLUTION_DUPLICATE, caseRec.ResolutionCode__c);
        System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSED, caseRec.Status);
        System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_DEF, caseRec.Enquiry_Type__c);
    }
    
    @isTest
    static void testMultipleToAddress() {
        Case caseRec = [SELECT Id, Subject FROM Case ORDER BY CreatedDate DESC LIMIT 1];
        EmailMessage emailMsg = new EmailMessage(ParentId = caseRec.Id, Subject = 'Not Duplicate', FromAddress = 'te@st.test');
        insert emailMsg;
        
        Test.startTest();
            StarTrackCalculateFromAddress.calculateFromAddress(new List<String>{caseRec.Id +'-'+ emailMsg.Id});
        Test.stopTest();
        caseRec = [SELECT Id, Send_Auto_Response_Email__c FROM Case WHERE Id =: caseRec.Id];
        System.assertEquals(true, caseRec.Send_Auto_Response_Email__c);
    }
    
    @isTest
    static void testSingleToAddress() {
        Case caseRec = [SELECT Id, StarTrack_Calc_Email_Address__c FROM Case ORDER BY CreatedDate DESC LIMIT 1];
        caseRec.StarTrack_Calc_Email_Address__c= 'apple@gmail.com';
        update caseRec;
        EmailMessage emailMsg = new EmailMessage(ParentId = caseRec.Id, Subject = 'Not Duplicate', FromAddress = 'te@st.test');
        insert emailMsg;
        
        Test.startTest();
            StarTrackCalculateFromAddress.calculateFromAddress(new List<String>{caseRec.Id +'-'+ emailMsg.Id});
        Test.stopTest();
        caseRec = [SELECT Id, StarTrack_Calc_Email_Address__c FROM Case WHERE Id =: caseRec.Id];
        System.assertEquals('apple-reply@gmail.com', caseRec.StarTrack_Calc_Email_Address__c);
    }
    
    @isTest
    static void testCreditCase() {
        Test.startTest();
        Case creditCase = new Case(Subject = 'Sample Credit', SuppliedEmail = 'te@st.test', StarTrack_Calc_Email_Address__c = 'credit@gmail.com');
        creditCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(StarTrack_Constants.CASE_CREDIT_RT).getRecordTypeId();
        insert creditCase;
        
        EmailMessage emailMsg = new EmailMessage(ParentId = creditCase.Id, Subject = 'Not Duplicate', FromAddress = 'te@st.test');
        insert emailMsg;
            StarTrackCalculateFromAddress.calculateFromAddress(new List<String>{creditCase.Id +'-'+ emailMsg.Id});
        Test.stopTest();
        creditCase = [SELECT Id, Send_Auto_Response_Email__c FROM Case WHERE Id =: creditCase.Id];
        System.assertEquals(true, creditCase.Send_Auto_Response_Email__c);
    }
    
    @isTest
    static void testDuplicateNotCheck() {
        StarTrack_Settings__c customSettingRec = [SELECT Check_for_Duplicate_Email__c FROM StarTrack_Settings__c LIMIT 1];
        customSettingRec.Check_for_Duplicate_Email__c = false;
        update customSettingRec;
        
        Case caseRec = [SELECT Id, Subject FROM Case ORDER BY CreatedDate DESC LIMIT 1];
        EmailMessage emailMsg = [SELECT Id, ParentId, Subject, FromAddress FROM EmailMessage ORDER BY CreatedDate DESC LIMIT 1];
        
        Test.startTest();
            StarTrackCalculateFromAddress.calculateFromAddress(new List<String>{caseRec.Id +'-'+ emailMsg.Id});
        Test.stopTest();
        caseRec = [SELECT Id, Subject, Send_Auto_Response_Email__c FROM Case WHERE Id =: caseRec.Id];
        System.assertNotEquals(StarTrack_Constants.DUPLICATE_EMAIL + 'Sample Duplicate', caseRec.Subject);
        System.assertEquals(true, caseRec.Send_Auto_Response_Email__c);
    }
    
    @isTest
    static void testInvalidCreditDispute() {
        
        Test.startTest();
            Case creditCase = new Case(Subject = 'Credit ' + StarTrack_Constants.CREDITCLAIM_INVSUBJECT, SuppliedEmail = 'te@st.test', StarTrack_Calc_Email_Address__c = 'credit@gmail.com');
            creditCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(StarTrack_Constants.CASE_CREDIT_RT).getRecordTypeId();
            insert creditCase;
            
            EmailMessage emailMsg = new EmailMessage(ParentId = creditCase.Id, Subject = 'Credit ' + StarTrack_Constants.CREDITCLAIM_INVSUBJECT, FromAddress = 'te@st.test', ToAddress = 'credit@gmail.com');
            insert emailMsg;
            StarTrackCalculateFromAddress.calculateFromAddress(new List<String>{creditCase.Id +'-'+ emailMsg.Id});
        Test.stopTest();
        creditCase = [SELECT Id, Subject, Status FROM Case WHERE Id =: creditCase.Id];
        System.assertEquals(StarTrack_Settings__c.getOrgDefaults().ST_Credit_Claim_Inbound_Email_Prefix__c + 'Credit ' + StarTrack_Constants.CREDITCLAIM_INVSUBJECT, creditCase.Subject);
        System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSED, creditCase.Status);
    }
}