/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test class for StarTrack Card Left Controller
History
September 3, 2015 - Patrick James Franco - Created
Oct. 16, 2015 - David Catindoy - Modified
November 26, 2015 - Patrick James Franco - Updated based changes regarding StarTrackQuickAction component
------------------------------------------------------------*/
@isTest
private class StarTrackCreateAutomatedSWMYTask_Test {

	@testSetup static void testSetup(){

        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        Database.insert(testAccount);
        
        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);

        Billing_Account__c testBillingAcc = TestDataProvider.createBillingAccount('', 1,new List<Account>{testAccount})[0];
        testBillingAcc.Depot_Collection__c = 'Yes';
        testBillingAcc.Redirection__c = 'No';
        testBillingAcc.Redelivery__c = 'No';
        Database.insert(testBillingAcc);

        Network__c testNetwork = TestDataProvider.createTestNetwork();
        testNetwork.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId(); 
        testNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL;
        testNetwork.ST_Email__c = true;
        testNetwork.Email__c = 'te@st.comz';
        testNetwork.State__c = 'ACT';
        testNetwork.Facility__c = 'Express';
        testNetwork.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        testNetwork.Email__c = 'te@st.zzz';
        Database.insert(testNetwork);

        Depot_Area__c testDepotArea = new Depot_Area__c();
        testDepotArea.Name = 'Test Depot Area';
        testDepotArea.Depot__c = testNetwork.Id;
        testDepotArea.Area__c = StarTrack_Constants.DEPOTAREA_AREA_BRANCHMANAGEMENT;
        Database.insert(testDepotArea);

        Depot_Area_User__c testDepotAreaUser = new Depot_Area_User__c();
        testDepotAreaUser.Name = 'Test Depot Area User';
        testDepotAreaUser.Depot_Role__c = testDepotArea.Id;
        testDepotAreaUser.User__c = UserInfo.getUserId();
        Database.insert(testDepotAreaUser);

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.STServiceType__c = 'Airlock';
        testArticle.Network__c = testNetwork.Id;
        testArticle.Billing_Account__c = testBillingAcc.Id;
        Database.insert(testArticle);

        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.Call_Purpose__c = 'Card Left';
        testCase.Enquiry_Type__c = 'Depot Collection';
        testCase.ArticleTest__c = testArticle.Id;
        testCase.Phone__c ='+639126783645';
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }
        testCase.Delivery_Collection_Date__c = validDate;
        testCase.Related_Billing_Account__c = testBillingAcc.Id;
        testCase.AccountId = testAccount.Id;
        testCase.Network__c = testNetwork.Id;
        testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        Database.insert(testCase);
	}
	
	//Need to create this another test setup to avoid this error: "DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)"
    @testSetup static void createUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='StarTrack Support']; 
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
        User u = new User(Alias = 'newUser', Email='user@testorg.a', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        Database.insert(u);
    }
    
    static testMethod void testAutomatedSWMYTask() {
	    
	    Case caseRec = [SELECT Id, Related_Billing_Account__c, AccountId, Network__c FROM Case LIMIT 1];
	    User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
        
        CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = caseRec.Id, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(cs);
        
        AccountShare accShare = new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', AccountId = [SELECT Id FROM Account WHERE Id =: caseRec.AccountId].Id, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(accShare);
        
        System.runAs(supportUser) {
            Test.setCurrentPage(Page.StarTrackCardLeftPA);
            ApexPages.currentPage().getParameters().put('Id', caseRec.Id);
            Test.startTest();
                StarTrackCreateAutomatedSWMYTask.createAutomatedTask(new List<Id>{caseRec.Id});
                
                caseRec = [SELECT Id, Related_Billing_Account__c, AccountId, Network__c, ArticleTest__c FROM Case WHERE Id =: caseRec.Id];
                caseRec.Related_Billing_Account__c = null;
                Database.update(caseRec);
                
                Article__c consignment = [SELECT Id, Billing_Account__c FROM Article__c WHERE Id =: caseRec.ArticleTest__c];
                consignment.Billing_Account__c = null;
                Database.update(consignment);
                StarTrackCardLeft_ControllerX cardLeft = new StarTrackCardLeft_ControllerX();
                StarTrackCreateAutomatedSWMYTask.createAutomatedTask(new List<Id>{caseRec.Id});
                
                caseRec.Network__c = null;
                Database.update(caseRec);
                StarTrackCreateAutomatedSWMYTask.createAutomatedTask(new List<Id>{caseRec.Id});
                
            Test.stopTest();
            
            System.assertEquals(false, [SELECT Id, Case__c FROM workflow_Email__c WHERE Case__c = :caseRec.Id].isEmpty());
        }
	}

}