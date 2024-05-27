/**************************************************
Description:    Test Class for EmailMessageUtil
History:
--------------------------------------------------
// 2023-02-09  Swati.mogadala@auspost.com.au -REQ3045758 - Updated testStarTrackDuplicateInboundEmail()
// 2024-05-16  Boris Bachovski - Added test methods for Email to Case pattern matcher. 
**************************************************/

@isTest
private class TestEmailMessageUtil {
    //Added by David Catindoy - Nov 29, 2016
    @testSetup static void testDataCreate() {
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

    //Added by David Catindoy - Nov 29, 2016
    @testSetup static void createUser(){
       Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
       UserRole r = [SELECT Id FROM UserRole WHERE Name = 'User Support - Business Systems Consultant'];
       User systemSupport = new User(Alias = 'ssuppss', Email='systemsupport@testorg.a', EmailEncodingKey='UTF-8', FirstName = 'System', LastName='Support', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id, TimeZoneSidKey='America/Los_Angeles', UserName='systemsupport@testorg.a', Work_Center_Code__c='123456');
       Database.insert(systemSupport);
    }
    
    @isTest
    static void testCloningPermanentlyClosedCases() {
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
        email.Subject = 'subject ';
        email.TextBody = 'text body';
        email.FromAddress = 'test@test.com';
        email.FromName = 'from name';
        email.Headers = 'Return-Path: Testing header';
        email.ToAddress = [select address from orgwideemailaddress where displayname='Customer Enquiry' limit 1].address;
        email.MessageDate = Datetime.now();
        insert email;

        Test.stopTest();
        
    }
    
    static testmethod void testStarTrackDuplicateInboundEmail(){
        User systemSupport = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'ssuppss' LIMIT 1];
        
        System.runAs(systemSupport){
            Id deliveryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
            Case newCase1 = new Case(RecordTypeId = deliveryRecType, Subject = 'RE: FWD: FW: Update Consignment Details', Origin = StarTrack_Constants.CASE_ORIGIN_BSC);
			Case newCase2 = new Case(RecordTypeId = deliveryRecType, Subject = 'RE: FWD: FW: Update Consignment Details', Origin = StarTrack_Constants.CASE_ORIGIN_BSC);
            Database.insert(newCase1);
            Database.insert(newCase2);
           // String previousCaseSubject = newCase.Subject;
            
            Test.startTest();
                EmailMessage newEmail1 = new EmailMessage(ParentId = newCase1.Id, FromAddress = 'testAgain@test.com', Incoming = true, Subject = 'RE: FWD: FW: Update Consignment Details', HTMLBody = 'Sample', ToAddress = 'support@test.com', Headers = 'Return-Path: Testing header');
                EmailMessage newEmail2 = new EmailMessage(ParentId = newCase2.Id, FromAddress = 'test@test.com', Incoming = true, Subject = 'RE: FWD: FW: Update Consignment Details', HTMLBody = 'Sample', ToAddress = 'support@test.com', Headers = 'Return-Path: Testing header');
            	Database.insert(newEmail1);
            	Database.insert(newEmail2);
            Test.stopTest();
            
            newCase1 = [SELECT Id, Subject, ResolutionCode__c, Status, Enquiry_Type__c, Call_Purpose__c FROM Case WHERE Id =: newCase1.Id];
            newCase2 = [SELECT Id, Subject, ResolutionCode__c, Status, Enquiry_Type__c, Call_Purpose__c FROM Case WHERE Id =: newCase2.Id];

            System.assertEquals(null, newCase1.ResolutionCode__c);
            System.assertEquals(StarTrack_Constants.CASE_STATUS_NEW, newCase1.Status);
			System.assertEquals(StarTrack_Constants.CASE_RESOLUTION_DUPLICATE, newCase2.ResolutionCode__c);
            System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSED, newCase2.Status);
            System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_DEF, newCase2.Enquiry_Type__c);
            System.assertEquals(StarTrack_Constants.CASE_PURPOSE_DEF, newCase2.Call_Purpose__c);
        }
            
        }
    
    static testmethod void testVOCInboundEmail(){
        User systemSupport = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'ssuppss' LIMIT 1];
        
        System.runAs(systemSupport){
            Test.startTest();
                Case caseRec = [SELECT Id FROM Case WHERE Subject = 'Test VOC Enquiry' LIMIT 1];
                Id incidentRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Voice of Customer Incident').getRecordTypeId();
                Case vocIncident = new Case(Subject = 'Test VOC 1', Description = 'Sample VOC 1', ParentId = caseRec.Id, Recent_Caller_First_Name__c = 'David', Recent_Caller_Last_Name__c = 'Catindoy', Parent_Status__c = 'New', Status = 'New', Business_Unit__c = 'Commercial', Nominated_Advocate_Email__c = 'david.catindoy@cloudsherpas.com', Nominated_Advocate__c = 'David', CallBackRequired__c = true, RecordTypeId = incidentRecType);
                vocIncident.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
                Database.insert(vocIncident); 
                EmailMessage newEmail = new EmailMessage(ParentId = vocIncident.Id, FromAddress = 'test@test.com', Incoming = true, Subject = 'VOC Incident Inbound Email ', HTMLBody = 'Sample', ToAddress = 'support@test.com');
                Database.insert(newEmail);
            Test.stopTest();
            
            System.assertEquals([SELECT Id, Status FROM Case WHERE Id =: caseRec.Id].Status, StarTrack_Constants.CASE_STAT_AWAITINGREVIEW);
        }
    }

    // Added below method for Secure Post
    static testmethod void testSecurePost(){
        User systemSupport = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'ssuppss' LIMIT 1];

        System.runAs(systemSupport){
            Id onboardRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Onboarding').getRecordTypeId();
            Case newCase = new Case(RecordTypeId = onboardRecType, Subject = 'Registration for test user', Origin = 'Email');
            Database.insert(newCase);
            String previousCaseSubject = newCase.Subject;
            SecurePost__c securePostSetting = SecurePost__c.getInstance();
            Test.startTest();
            EmailMessage newEmail = new EmailMessage(ParentId = newCase.Id, FromAddress = 'test@test.com', Incoming = true, Subject = 'RE: FWD: FW: Update Consignment Details', HTMLBody = 'Sample', ToAddress = securePostSetting.Email_to_Case_address__c);
            Database.insert(newEmail);
            Test.stopTest();

            newCase = [SELECT Id, Subject, ResolutionCode__c, Status, Enquiry_Type__c, Call_Purpose__c FROM Case WHERE Id =: newCase.Id];
//            System.assertEquals(StarTrack_Constants.CASE_RESOLUTION_DUPLICATE, newCase.ResolutionCode__c);
//            System.assertEquals(StarTrack_Constants.CASE_STAT_CLOSED, newCase.Status);
//            System.assertEquals(StarTrack_Constants.CASE_ENQUIRY_DEF, newCase.Enquiry_Type__c);
//            System.assertEquals(StarTrack_Constants.CASE_PURPOSE_DEF, newCase.Call_Purpose__c);
        }
    }


	/**
	 * Scenario: Test to ensure the whole pattern match for email is returned from the string
	 */
	@IsTest
	static void testGetEmailFullMatch() {
		// =====================================
		// Data Preparation
		// =====================================
		String email1 = 'transportenquiry@auspost.com.au;5195231b-cd74-45a4-b576-9bc88ae35b48';
		String email2 = 'transportenquiry@auspost.com.au$5bsdfgedg ewrewt ewrtw4etert';
		String email3 = '$retert%transportenquiry@auspost.com.au$5bsdfgedg ewrewt ewrtw4etert';
		String email4 = '$retert%transportenquiryauspost.com.au$5bsdfgedg ewrewt ewrtw4etert';
		String result = 'transportenquiry@auspost.com.au';

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// make sure the email has been returned
		Assert.areEqual(result, EmailMessageUtil.getEmailFullMatch(email1), 'Expected valid email to be returned');
		Assert.areEqual(result, EmailMessageUtil.getEmailFullMatch(email2), 'Expected valid email to be returned');
		Assert.areEqual(result, EmailMessageUtil.getEmailFullMatch(email3), 'Expected valid email to be returned');
		Assert.areNotEqual(result, EmailMessageUtil.getEmailFullMatch(email4), 'Expected no email to be returned');
		Assert.areEqual(null, EmailMessageUtil.getEmailFullMatch(null), 'Expected no email to be returned');
		Assert.areEqual(null, EmailMessageUtil.getEmailFullMatch('12132445'), 'Expected no email to be returned');
		Assert.areEqual(null, EmailMessageUtil.getEmailFullMatch('1213$auspost.com2445'), 'Expected no email to be returned');
		Assert.areEqual(null, EmailMessageUtil.getEmailFullMatch(''), 'Expected no email to be returned');
		Assert.areEqual(null, EmailMessageUtil.getEmailFullMatch(' '), 'Expected no email to be returned');
		Assert.areEqual(null, EmailMessageUtil.getEmailFullMatch('$retert%transportenquiry$123'), 'Expected no email to be returned');

		Test.stopTest();
	}
}