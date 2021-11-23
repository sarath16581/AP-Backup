/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture, Inc.
Description:   Test Class for StarTrackCreateRelatedContact
History
January 25, 2016 - David Catindoy - Created
------------------------------------------------------------*/
@isTest
private class StarTrackCreateRelatedContact_Test {

    @testSetup static void testSetup(){
        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        Database.insert(testAccount);
        
        Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Email = 'davidcatindoy@gmail.com', AccountId = testAccount.Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE);
        Database.insert(newCon);
        
        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.Call_Purpose__c = 'Other';
        testCase.Enquiry_Type__c = 'POD';
        testCase.AccountId = testAccount.Id;
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
    
	static testMethod void testRelContactNotEmpty() {
	    
	    Case caseRec = [SELECT Id, AccountId FROM Case LIMIT 1];
	    User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
	    
	    AuthorisedContacts__c relCont = new AuthorisedContacts__c(Related_Contact__c = [SELECT Id FROM Contact WHERE AccountId =: caseRec.AccountId].Id, Case__c = caseRec.Id, Contact_Type__c = 'Sender', Initial_Contact__c = true, Notification_Required__c = true, Pref_Method_of_Contact__c = 'Email');
        Database.insert(relCont);
        
        CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = caseRec.Id, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(cs);
        
        AccountShare accShare = new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', AccountId = caseRec.AccountId, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(accShare);
        
        System.runAs(supportUser) {
            Test.startTest();
                StarTrackCreateRelatedContact.createRelatedContact(new List<Id>{caseRec.Id});
            Test.stopTest();
            
            System.assertEquals(1, [SELECT Id, Case__c FROM AuthorisedContacts__c WHERE Case__c =: caseRec.Id].size());
        }
	}
	
	static testMethod void testRelContactIsEmpty() {
	    
	    Case caseRec = [SELECT Id, AccountId, Initial_Caller_Email__c FROM Case LIMIT 1];
	    User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
        
        CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = caseRec.Id, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(cs);
        
        AccountShare accShare = new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', AccountId = caseRec.AccountId, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(accShare);
        
        System.runAs(supportUser) {
            Test.startTest();
                StarTrackCreateRelatedContact.createRelatedContact(new List<Id>{caseRec.Id});
                System.assertEquals(1, [SELECT Id, Case__c FROM AuthorisedContacts__c WHERE Case__c =: caseRec.Id].size());
                caseRec.Initial_Caller_Email__c = 'davidcatindoy@gmail.com';
                Database.update(caseRec);
                StarTrackCreateRelatedContact.createRelatedContact(new List<Id>{caseRec.Id});
            Test.stopTest();
            
            System.assertEquals(2, [SELECT Id, Case__c FROM AuthorisedContacts__c WHERE Case__c =: caseRec.Id].size());
        }
	}

}