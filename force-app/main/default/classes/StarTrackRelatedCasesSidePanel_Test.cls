/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture, Inc.
Description:   Test Class for StarTrackRelatedCasesSidePanelController
History
January 25, 2016 - David Catindoy - Created
------------------------------------------------------------*/
@isTest
private class StarTrackRelatedCasesSidePanel_Test {

    @testSetup static void testSetup(){
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        Database.insert(testAccount);
        
        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);
        
        Billing_Account__c testBillingAcc = TestDataProvider.createBillingAccount('', 1, new List<Account>{testAccount})[0];
        Database.insert(testBillingAcc);
        
        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.Call_Purpose__c = 'Other';
        testCase.Enquiry_Type__c = 'POD';
        testCase.AccountId = testAccount.Id;
        testCase.Related_Billing_Account__c = testBillingAcc.Id;
        testCase.Origin = 'Phone';
        Database.insert(testCase);
    }
    
    //Need to create this another test setup to avoid this error: "DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)"
    @testSetup static void createUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='StarTrack Support']; 
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
        User u = new User(Alias = 'newUser', Email='user@testorg.a', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        Database.insert(u);
    }
    
	static testMethod void testRelBillingAccount() {
	    
	    Case caseRec = [SELECT Id, Related_Billing_Account__c, AccountId FROM Case LIMIT 1];
	    User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
        
        CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = caseRec.Id, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(cs);
        
        AccountShare accShare = new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', AccountId = caseRec.AccountId, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(accShare);
        
        System.runAs(supportUser) {
            Test.setCurrentPage(Page.StarTrackRelatedCasesSidePanel);
            Test.startTest();
    	        ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
                StarTrackRelatedCasesSidePanelController ctrl = new StarTrackRelatedCasesSidePanelController(sc);
            Test.stopTest();
        }
	}
}