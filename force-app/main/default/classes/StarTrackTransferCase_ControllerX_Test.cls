/*------------------------------------------------------------
Author:        Fahad Akhtar
Company:       Cloud Sherpas
Description:   Test class for StarTrack Transfer Case Controller
Oct. 16, 2015 - David Catindoy - Modified
Nov. 04, 2015 - Patrick James Franco - Added testOnLoadPickupBooking method
Sept. 20, 2016 - David Catindoy - Modified to get inline with the new implemented transfer case rules
Jul. 22, 2021 - Madhusudhan - Production test class failure fix
------------------------------------------------------------*/
@isTest
private class StarTrackTransferCase_ControllerX_Test{

    @testSetup static void testSetup(){
        List<sobject> ls = TestDataProvider.createStartrackErrorMessagesData();
        
        List<StarTrack_Transfer_Case_Rule__c> transferCaseRules = new List<StarTrack_Transfer_Case_Rule__c>();
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = 'StarTrack Next Flight Queue', Product_Group__c = 'Next Flight', Order__c = 1, Business_Solutions_Customer__c = true));
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = StarTrack_Constants.TRANSFER_QUEUE, Business_Solutions_Customer__c = true, Order__c = 2));
        transferCaseRules.add(new StarTrack_Transfer_Case_Rule__c(Queue_Name__c = 'ETA Queue', Case_RecordType__c = 'Pickup Booking Enquiry', Case_Purpose__c = 'Pickup ETA', Order__c = 4));
        Database.insert(transferCaseRules); 

        // Verify all custom settings are created
        System.assertEquals(ls.size(),[SELECT Id FROM StarTrack_Error_Messages__c].size());

        List<Account> lst_account = TestDataProvider.createAccount('test', 8);

        for(Integer i = 0; i < 2; i++){
            lst_account[i].Transfer_Case_Queue__c = 'Delivery Queue';
            lst_account[i].Business_Solutions_Customer__c = true;
        }

        for(Integer i = 2; i < 4; i++){
            lst_account[i].Business_Solutions_Customer__c = true;
            lst_account[i].Transfer_Case_Queue__c = '';
        }

        for(Integer i = 4; i < 6; i++){
            lst_account[i].Business_Solutions_Customer__c = true;
            lst_account[i].Transfer_Case_Queue__c = 'WRONG_QUEUE_NAME';
        }

        for(Integer i = 6; i < 8; i++){
            lst_account[i].Business_Solutions_Customer__c = false;
        }

        Database.insert(lst_account);
        System.debug('** List of Account ** ' + lst_account);
        System.assertEquals(lst_account[0].Legacy_Id__c,'60000000');
        lst_account[0].Legacy_Id__c = '60000000';
        Database.Update(lst_account[0]);

        List<Network__c> lst_network = TestDataProvider.createNetwork('Test network', 8);

        User u = TestDataProvider.createTestUsers();
        Database.insert(u);
        for(Network__c n : lst_network){
            n.ownerid = u.id;
        }

        Database.insert(lst_network);

        List<Billing_Account__c> lst_billingAccount = TestDataProvider.createBillingAccount('', 8,lst_account);
        Database.insert(lst_billingAccount);

        List<Article__c> lst_article = TestDataProvider.createArticle('Subject', 8,lst_billingAccount);
        for(Integer i = 0; i < 8; i++){
            lst_article[i].Network__c = lst_network[i].Id;
            lst_article[i].Billing_Account__c = lst_billingAccount[i].Id;
        }

        Database.insert(lst_article);

        List<case> lst_cases = TestDataProvider.createCases('Subject', 8,lst_article);
        for(Integer i = 0; i < 8; i++){
            lst_cases[i].AccountId = lst_account[i].id;
            lst_cases[i].Related_Billing_Account__c = lst_billingAccount[i].id;
            lst_cases[i].RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;
        }
        Database.insert(lst_cases);

        User usr = [Select id from User where Id = :UserInfo.getUserId()];

        System.runAs(usr) {

            List<Group> testQueues = new List<Group>();
            testQueues.add(new Group(Name='StarTrack Next Flight Queue',  Type='Queue'));
            testQueues.add(new Group(Name='ETA Queue',  Type='Queue'));
            testQueues.add(new Group(Name='Web Bookings Queue',  Type='Queue'));
            testQueues.add(new Group(Name='Controlled Returns Queue',  Type='Queue'));
            testQueues.add(new Group(Name='Sorry We Missed You',  Type='Queue'));
            testQueues.add(new Group(Name='Delivery Queue',  Type='Queue'));
            Database.insert(testQueues);
            
            
            List<QueuesObject> queueAssignments = new List<QueueSObject>();
            queueAssignments.add(new QueuesObject(QueueID = testQueues[0].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[1].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[2].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[3].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[4].Id, SObjectType = 'Case'));
            queueAssignments.add(new QueuesObject(QueueID = testQueues[5].Id, SObjectType = 'Case'));
            Database.insert(queueAssignments);
        }
        
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.Next_Flight_Case_Consignment__c = 'StarTrack Next Flight Queue';
        customSetting.PBE_ETA_Enquiry__c = 'ETA Queue';
        customSetting.PBE_Missed_Futile_Enquiry__c = 'Web Bookings Queue';
        customSetting.PBE_Controlled_Returns__c = 'Controlled Returns Queue';
        customSetting.Redelivery_Redirection_Enquiry__c = 'Sorry We Missed You';
        Database.insert(customSetting);
        

    }
    
    //Need to create this another test setup to avoid this error: "DML operation on setup object is not permitted after you have updated a non-setup object (or vice versa)"
    @testSetup static void createUser(){
        Profile p = [SELECT Id FROM Profile WHERE Name='StarTrack Support']; 
        UserRole r = [SELECT Id FROM UserRole WHERE Name = 'CEO/Reporting'];
        User u = new User(Alias = 'newUser', Email='user@testorg.a', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id, TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        Database.insert(u);
    }

    @isTest static void testCaseTransferForBusinessSolutionsPositiveNetworkOwner() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c,
                                Transfer_Override_Reason__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = false
                        LIMIT 1
                        ];

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.c.Transfer_Override_Reason__c = 'Test value';
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
            System.assert(ApexPages.getMessages().size()>0);
        Test.stopTest();
    }

    @isTest static void testCaseTransferForBusinessSolutionsPositive() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c,
                                Transfer_Override_Reason__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = true
                        AND
                                Account.Transfer_Case_Queue__c =  'Delivery Queue'
                        LIMIT 1
                        ];

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.c.Transfer_Override_Reason__c = 'Test value';
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
            System.assertEquals(false, ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testCaseTransferForBusinessSolutionsNoQueueNegative() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = true
                        AND
                                Account.Transfer_Case_Queue__c = 'WRONG_QUEUE_NAME'
                                LIMIT 1
                        ];

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
            System.assertEquals(false, ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testCaseTransferForBusinessSolutionsInCorrectQueueNegative() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = true
                        AND
                                Account.Transfer_Case_Queue__c = ''
                                LIMIT 1
                        ];

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
            System.assertEquals(false, ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testCaseTransferForBusinessSolutionsNoTransferReasonNegative() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c,
                                Transfer_Override_Reason__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = false
                        LIMIT 1
                        ];

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
        Test.stopTest();
    }

    @isTest static void testCatchError() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c,
                                Transfer_Override_Reason__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = false
                        LIMIT 1
                        ];
        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.onChangeOfOwner();
            ext.validate();
            ext.saveOverride();
            System.assertEquals(false, ext.validation);
        Test.stopTest();
    }

    @isTest static void testSaveOverrideFalse() {
        Case testCase = [
                        SELECT
                                Id,
                                CaseNumber,
                                OwnerId,
                                ArticleTest__r.Network__r.Ownerid,
                                Account.Business_Solutions_Customer__c,
                                Account.Transfer_Case_Queue__c,
                                Network__c,
                                Transfer_Override_Reason__c
                        FROM
                                Case
                        WHERE
                                Account.Business_Solutions_Customer__c = false
                        LIMIT 1
                        ];

        User testUser = [SELECT Id FROM User where Alias='newUser' and UserType = 'Standard'];
        testCase.Type = 'Fraud';
        testCase.OwnerId = testUser.Id;
        update testCase;
        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            ext.c.Ownerid = UserInfo.getUserId();
            ext.onChangeOfOwner();
            ext.c.Transfer_Override_Reason__c = 'Reason';
            ext.showOwnershipReason = true;
            ext.validate();
            ext.saveOverride();
            System.assertEquals(ext.validation,true);
        Test.stopTest();
    }

    static testMethod void testOnLoadPickupBooking(){
        Case testCase = [SELECT Id, RecordTypeId FROM Case LIMIT 1];
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        testCase.Call_Purpose__c = 'Pickup';
        //testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_PICKUPETA;
        testCase.Enquiry_Type__c = 'Driver ETA - Pickup';        
        UPDATE testCase;

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            System.assertNotEquals(UserInfo.getUserId(), testCase.OwnerId);

            //testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_MISSEDPICKUP;
            testCase.Enquiry_Type__c = 'Missed Pickup';            
            UPDATE testCase;

            ext.onload();
            System.assertNotEquals(UserInfo.getUserId(), testCase.OwnerId);

            //testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_FUTILE;
            testCase.Enquiry_Type__c = 'Futile';
            UPDATE testCase;

            ext.onload();
            System.assertNotEquals(UserInfo.getUserId(), testCase.OwnerId);

            //testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_CONTROLLEDRETURN;
            testCase.Enquiry_Type__c = 'Controlled Returns';
            UPDATE testCase;

            ext.onload();
            System.assertNotEquals(UserInfo.getUserId(), testCase.OwnerId);
        Test.stopTest();
    }


    static testMethod void testOnLoadPickupBooking1(){


        Case testCase = [SELECT Id, RecordTypeId FROM Case WHERE Account.Business_Solutions_Customer__c = false LIMIT 1];
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        testCase.Call_Purpose__c = 'Pickup';
        //testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_PICKUPETA;
        testCase.Enquiry_Type__c = 'Driver ETA - Pickup';        
        UPDATE testCase;

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        Test.startTest();
            StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
            ext.onload();
            System.assertNotEquals(UserInfo.getUserId(), testCase.OwnerId);

            //testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_MISSEDPICKUP;
            testCase.Enquiry_Type__c = 'Missed Pickup';            
            UPDATE testCase;

            ext.onload();
            System.assertNotEquals(UserInfo.getUserId(), testCase.OwnerId);

            //testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_FUTILE;
            testCase.Enquiry_Type__c = 'Futile';
            UPDATE testCase;

            ext.onload();
            System.assertNotEquals(UserInfo.getUserId(), testCase.OwnerId);

            //testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_CONTROLLEDRETURN;
            testCase.Enquiry_Type__c = 'Controlled Returns';
            UPDATE testCase;

            ext.onload();
            System.assertNotEquals(UserInfo.getUserId(), testCase.OwnerId);
        Test.stopTest();
    }
    
    static testMethod void testRemainingScenarios(){


        Case testCase = [SELECT Id, RecordTypeId, ArticleTest__c, AccountId FROM Case WHERE Account.Business_Solutions_Customer__c = true AND ArticleTest__c != null LIMIT 1];
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        testCase.Call_Purpose__c = 'Pickup';
        testCase.Enquiry_Type__c = 'Driver ETA - Pickup';    
        testCase.Business_Solutions_Customer__c = true;
        UPDATE testCase;
        System.debug('Test Case: '+ testCase);
        
        Article__c consignment = [SELECT Id, Product_Group__c, Network__c FROM Article__c WHERE Id =: testCase.ArticleTest__c];
        consignment.Product_Group__c = 'Next Flight';
        update consignment;
        
        Account legalEntity = [SELECT Id, Transfer_Case_Queue__c FROM Account WHERE Id =: testCase.AccountId];

        Test.setCurrentPage(Page.StarTrackTransferCasePA);
        ApexPages.currentPage().getParameters().put('id', testCase.Id);
        
        StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
        ext.refreshPage();

        Test.startTest();
            
            consignment.Product_Group__c = 'Express';
            update consignment;
            legalEntity.Transfer_Case_Queue__c = '';
            update legalEntity;
            ext.refreshPage();
            System.assert(!ApexPages.getMessages().isEmpty());
            
            legalEntity.Transfer_Case_Queue__c = 'Delivery Queue';
            update legalEntity;
            ext.refreshPage();
            
            testCase.Business_Solutions_Customer__c = false;
            testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
            testCase.Call_Purpose__c = StarTrack_Constants.CASE_PURPOSE_PICKUPETA;
            update testCase;
            ext.refreshPage();
            
            testCase.Call_Purpose__c = StarTrack_Constants.CASE_PURPOSE_MISSEDPICKUP;
            update testCase;
            ext.refreshPage();
            
            testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
            testCase.Call_Purpose__c = StarTrack_Constants.CASE_PURPOSE_CONTROLLEDRETURN;
            update testCase;
            ext.refreshPage();
                
            testCase.Call_Purpose__c = 'Card Left';
            testCase.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_REDELIVERY;
            update testCase;
            ext.refreshPage();
            
            testCase.Enquiry_Type__c = 'Depot Calculation';
            testCase.Status = StarTrack_Constants.CASE_STATUS_WAITINGOPERATIONS;
            testCase.Network__c = consignment.Network__c;
            update testCase;
            ext.refreshPage();
            ext.onChangeOfOwner();
        Test.stopTest();
        
        ext.showOwnershipReason = true;
        ext.c.Transfer_Override_Reason__c = '';
        ext.saveOverride();
        System.assert(!ext.validation);
        ext.showOwnershipReason = true;        
        ext.c.Transfer_Override_Reason__c = 'Sample Override Reason';
        ext.saveOverride();
        testCase = [SELECT Id, OwnerId, Transfer_Override_Reason__c FROM Case WHERE Id =: testCase.Id];
        System.assertEquals([SELECT Id, OwnerId FROM Network__c WHERE Id =: consignment.Network__c].OwnerId, testCase.OwnerId);
        System.assertEquals('Sample Override Reason', testCase.Transfer_Override_Reason__c);
    }
    
    static testMethod void testTransferRules(){

        Case caseRec = [SELECT Id, RecordTypeId, ArticleTest__c, AccountId, Related_Billing_Account__c, Business_Solutions_Customer__c, Network__c FROM Case WHERE Account.Business_Solutions_Customer__c = true AND ArticleTest__c != null LIMIT 1];
        Article__c consignment = [SELECT Id, Product_Group__c, Network__c FROM Article__c WHERE Id =: caseRec.ArticleTest__c];
        caseRec.Network__c = consignment.Network__c;
        caseRec.Business_Solutions_Customer__c = true;
        caseRec.Type = 'Fraud';
        Database.update(caseRec);
        
        User supportUser = [SELECT Id, Alias, Email, LastName, ProfileId, UserRoleId, UserName FROM User WHERE Alias = 'newUser' LIMIT 1];
        
        CaseShare cs = new CaseShare(CaseAccessLevel = 'Edit', CaseId = caseRec.Id, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(cs);
        
        AccountShare accShare = new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', AccountId = caseRec.AccountId, UserOrGroupId = supportUser.Id, RowCause = 'Manual');
        Database.insert(accShare);
        System.runAs(supportUser){
            Test.setCurrentPage(Page.StarTrackTransferCasePA);
            ApexPages.currentPage().getParameters().put('Id', caseRec.Id);
            
            Test.startTest();
                StarTrackTransferCase_ControllerX ext = new StarTrackTransferCase_ControllerX();
                ext.refreshPage();
                
                Account acc = [SELECT Id, Transfer_Case_Queue__c FROM Account WHERE Id =: caseRec.AccountId];
                acc.Transfer_Case_Queue__c = '';
                Database.update(acc);
                ext.refreshPage();
                
                consignment.Product_Group__c = 'Next Flight';
                Database.update(consignment);
                
                ext.refreshPage();
                
                caseRec.ArticleTest__c = null;
                caseRec.Business_Solutions_Customer__c = false;
                Database.update(caseRec);
                
                ext.refreshPage();
                
            Test.stopTest();
            
            }
    }
}