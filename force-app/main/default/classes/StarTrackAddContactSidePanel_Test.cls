/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture, Inc.
Description:   Test Class for StarTrackAddContactSidePanel_ControllerX
History
September 15, 2016 - David Catindoy - Created
------------------------------------------------------------*/
@isTest
private class StarTrackAddContactSidePanel_Test {

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
        
        AuthorisedContacts__c relCont = new AuthorisedContacts__c(Related_Contact__c = newCon.Id, Case__c = testCase.Id, Contact_Type__c = 'Sender', Initial_Contact__c = true, Notification_Required__c = true, Pref_Method_of_Contact__c = 'Email');
        Database.insert(relCont);
    }
    
    //Need to create this another test setup to avoid this error: "DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)"
    @testSetup static void createUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='StarTrack Support']; 
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
        User u = new User(Alias = 'newUser', Email='user@testorg.a', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        Database.insert(u);
    }
    
	static testMethod void testContactPanel() {
	    
	    Case caseRec = [SELECT Id, AccountId FROM Case LIMIT 1];
	    User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
        
        CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = caseRec.Id, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(cs);
        
        AccountShare accShare = new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', AccountId = caseRec.AccountId, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(accShare);
        
        System.runAs(supportUser) {
            Test.setCurrentPage(Page.StarTrackAddContactSidePanel);
            Test.startTest();
    	        ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
                StarTrackAddContactSidePanel_ControllerX ctrl = new StarTrackAddContactSidePanel_ControllerX(sc);
                ctrl.getContacts();
                ctrl.changeEditFlag();
                List<AuthorisedContacts__c> relConts = new List<AuthorisedContacts__c>(ctrl.relatedContacts.values());
                ctrl.selectedConId = relConts.get(0).Id;
                ctrl.autoPopulateFields();
                ctrl.caseRec.Recent_Caller_Pref_Method_of_Contact__c = '';
                ctrl.saveContactDetails();
                ctrl.caseRec.Notification_Required__c = false;
                ctrl.saveContactDetails();
                ctrl.cancelEdit();
                ctrl.selectedConId = relConts.get(0).Id;
                ctrl.caseRec.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.CASE_ORIGIN_EMAIL;
                ctrl.caseRec.Recent_Caller_Email__c = null;
                ctrl.saveContactDetails();
                ctrl.caseRec.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.CASE_ORIGIN_PHONE;
                ctrl.saveContactDetails();
                ctrl.caseRec.Recent_Caller_Phone_Number__c = '04125465365';
                ctrl.saveContactDetails();
                ctrl.caseRec.Recent_Caller_Phone_Number__c = '041254';
                ctrl.saveContactDetails();
                ctrl.caseRec.Recent_Caller_Pref_Method_of_Contact__c = StarTrack_Constants.MOBILE_PREFCONTACT_METHOD;
                ctrl.caseRec.Recent_Contact_Mobile_Number__c = null;
                ctrl.saveContactDetails();
                ctrl.caseRec.Recent_Contact_Mobile_Number__c = '04125465365';
                ctrl.saveContactDetails();
                
                ctrl.cancelEdit();
                relConts = new List<AuthorisedContacts__c>(ctrl.relatedContacts.values());
                ctrl.selectedConId = '';
                ctrl.autoPopulateFields();
                ctrl.selectedConId = StarTrack_Constants.ADD_CONTACT;
                ctrl.autoPopulateFields();
                ctrl.selectedConId = relConts.get(0).Id;
                ctrl.autoPopulateFields();
                ctrl.caseRec.Notification_Required__c = false;
                ctrl.caseRec.Recent_Caller_Pref_Method_of_Contact__c = '';
                ctrl.caseRec.Recent_Caller_Email__c = '';
                ctrl.saveContactDetails();
                ctrl.selectedConId = relConts.get(0).Id;
                ctrl.autoPopulateFields();
                ctrl.caseRec.Callers_Data_Change__c = false;
                ctrl.saveContactDetails();
                ctrl.caseRec.Recent_Caller_Type__c = '' ;
                ctrl.saveContactDetails();
            Test.stopTest();
            
            
            caseRec = [SELECT Id, Recent_Caller_Type__c, Recent_Caller_Pref_Method_of_Contact__c, Recent_Caller_First_Name__c, Recent_Caller_Last_Name__c, Recent_Contact_Mobile_Number__c, Recent_Caller_Email__c, Number_of_Callers__c FROM Case WHERE Id = :caseRec.Id];
            
            AuthorisedContacts__c relCont = [SELECT Calc_Contact_Email__c, Calc_Contact_Mobile_Number__c, Calc_Contact_Phone_Number__c, Contact_Type__c, Calc_First_Name__c, Calc_Last_Name__c,
                                             Notification_Required__c, Pref_Method_of_Contact__c, Related_Contact__c, Initial_Contact__c, Notified_on_Status__c FROM AuthorisedContacts__c WHERE Case__c = :caseRec.Id];
            System.assertEquals(relCont.Calc_Contact_Mobile_Number__c, caseRec.Recent_Contact_Mobile_Number__c);
            System.assertEquals('Mobile', relCont.Pref_Method_of_Contact__c);
            System.assertEquals(false, relCont.Notification_Required__c);
        }
	}
	
	static testMethod void testContactList() {
	    
	    Case caseRec = [SELECT Id, AccountId FROM Case LIMIT 1];
	    User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
        
        AuthorisedContacts__c existingRelCont = [SELECT Id, Initial_Contact__c, Related_Contact__c FROM AuthorisedContacts__c LIMIT 1];
        existingRelCont.First_Name__c = 'David';
        existingRelCont.Last_Name__c = 'Catindoy';
        existingRelCont.Related_Contact__c = null;
        existingRelCont.Notification_Required__c = true;
        Database.update(existingRelCont);
        
        CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = caseRec.Id, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(cs);
        
        AccountShare accShare = new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', AccountId = caseRec.AccountId, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(accShare);
        
        System.runAs(supportUser) {
            Test.setCurrentPage(Page.StarTrackAddContactSidePanel);
            Test.startTest();
    	        ApexPages.StandardController sc = new ApexPages.StandardController(caseRec);
                StarTrackAddContactSidePanel_ControllerX ctrl = new StarTrackAddContactSidePanel_ControllerX(sc);
                ctrl.getContacts();
                List<Contact> contList = new List<Contact>(ctrl.contactList.values());
                ctrl.selectedConId = contList.get(0).Id;
                ctrl.autoPopulateFields();
                ctrl.selectedConId = StarTrack_Constants.ADD_CONTACT;
                ctrl.autoPopulateFields();
                ctrl.caseRec.Recent_Caller_First_Name__c = 'Sample';
                ctrl.caseRec.Recent_Caller_Last_Name__c = 'User';
                ctrl.caseRec.Recent_Contact_Mobile_Number__c = '0412546525';
                ctrl.caseRec.Recent_Caller_Pref_Method_of_Contact__c = '';
                ctrl.caseRec.Recent_Caller_Type__c = 'Sender' ;
                ctrl.saveContactDetails();
                ctrl.cancelEdit();
                ctrl.selectedConId = StarTrack_Constants.ADD_CONTACT;
                ctrl.autoPopulateFields();
                ctrl.caseRec.Recent_Caller_First_Name__c = 'Howie';
                ctrl.caseRec.Recent_Caller_Last_Name__c = 'Boy';
                ctrl.caseRec.Recent_Contact_Mobile_Number__c = '0412546525';
                ctrl.caseRec.Recent_Caller_Pref_Method_of_Contact__c = '';
                ctrl.caseRec.Notification_Required__c = true;
                ctrl.saveContactDetails();
            Test.stopTest();
            
            
            System.assert(![SELECT Id FROM AuthorisedContacts__c WHERE Case__c = :caseRec.Id].isEmpty());
        }
	}

}