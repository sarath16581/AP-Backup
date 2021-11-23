/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test Class for StarTrackCreateCaseCommentController
History
May 13, 2016 - David Catindoy - Created
------------------------------------------------------------*/
@isTest
private class StarTrackCreateCaseComment_Test {

    @testSetup
    static void createUser(){
    	
    	User supportUser = new User(
     		ProfileId = [SELECT Id FROM Profile WHERE Name = 'StarTrack Support'].Id,
     		LastName = 'last',
     		Email = 'test@user.com',
     		Username = 'test@supportuser123.com',
     		CompanyName = 'TEST',
     		Title = 'title',
     		Alias = 'alias',
     		TimeZoneSidKey = 'America/Los_Angeles',
     		EmailEncodingKey = 'UTF-8',
     		LanguageLocaleKey = 'en_US',
     		LocaleSidKey = 'en_US');
     	insert supportUser;
        
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
        insert customSetting;
        
        Id deliveryEnquiryId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = new Case();
        testCase.RecordTypeId = deliveryEnquiryId;
        testCase.Subject = 'Sample Subject';
        testCase.Call_Purpose__c = 'Card Left';
        testCase.Status = 'New';
        testCase.Enquiry_Type__c = 'Depot Collection';
        testCase.Recent_Caller_First_Name__c = 'David';
        testCase.Recent_Caller_Last_Name__c = 'Catindoy';
        testCase.Recent_Caller_Phone_Number__c = '09126893944';
        testCase.Recent_Caller_Email__c = 'david.catindoy@cloudsherpas.com';
        INSERT testCase;
        
    }

    @isTest
    static void testRefreshMethod() {
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];
		User support = new List<User>([SELECT Id, UserName FROM User WHERE UserName = 'test@supportuser123.com'])[0];
	    
	    CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = testCase.Id, UserOrGroupId = support.Id, RowCause = 'Manual');
        Database.insert(cs);
        
        Test.startTest();
        	System.runAs(support) {
        		Test.setCurrentPage(Page.StarTrackCreateCaseComment);
	            ApexPages.currentPage().getParameters().put('Id', testCase.Id);
	            StarTrackCreateCaseCommentController ext = new StarTrackCreateCaseCommentController();
	            testCase.Status = StarTrack_Constants.CASE_STATUS_INVESTIGATION;
	            update testCase;
	            StarTrackCreateCaseCommentController.refreshCase(testCase.Id);
	            testCase = [SELECT Id, Status FROM Case WHERE Id =: testCase.Id];
        	}
        Test.stopTest();
       
       //test if Case is updated
       System.assertEquals(StarTrack_Constants.CASE_STATUS_INVESTIGATION, testCase.Status);
    }

}