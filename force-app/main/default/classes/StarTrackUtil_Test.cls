/**************************************************
Description:    Test class to cover StarTrackUtil
History:
--------------------------------------------------
2019-02-10  nathan.franklin@auspost.com.au  Added additional test methods for refactored functionality testCalculateResolutionTime and testFCR
**************************************************/
@isTest
private class StarTrackUtil_Test {

    @isTest static void testCreateLDCEmail() {

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        //testArticle.Network__c = testNetwork.Id;
        INSERT testArticle;

        Case c = TestDataProvider.createCase();
        c.ArticleTest__c = testArticle.Id;
        c.SuppliedEmail = 'a@q.c';
        INSERT c;


        Test.startTest();
        StarTrackUtil.createLDCEmail(c.Id);
        Test.stopTest();

        Workflow_Email__c wfe = [SELECT Id, Case__c FROM Workflow_Email__c WHERE Case__c =: c.Id];

        System.assert(wfe != null);
        System.assertEquals(wfe.Case__c, c.Id);

    }

    @isTest static void testCreateLDCApprovedEmail() {

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        //testArticle.Network__c = testNetwork.Id;
        INSERT testArticle;

        Case c = TestDataProvider.createCase();
        c.ArticleTest__c = testArticle.Id;
        c.SuppliedEmail = 'a@q.c';
        INSERT c;


        Test.startTest();
        StarTrackUtil.createLDCApprovedEmail(c.Id);
        Test.stopTest();

        Workflow_Email__c wfe = [SELECT Id, Case__c FROM Workflow_Email__c WHERE Case__c =: c.Id];

        System.assert(wfe != null);
        System.assertEquals(wfe.Case__c, c.Id);

    }

    @isTest static void testValidateLDCNetwork() {

        List<Network__c> networks = new List<Network__c>();
        Network__c network = TestDataProvider.createTestNetwork();
        network.Preferred_Method_of_Tasking__c = 'Email';
        network.ST_Email__c = true;
        network.Email__c = '1@1.c';
        networks.add(network);

        Network__c network1 = TestDataProvider.createTestNetwork();
        network1.Preferred_Method_of_Tasking__c = 'Email';
        network1.ST_Email__c = true;
        network1.Email__c = '1@1.c';
        networks.add(network1);

        Network__c network2 = TestDataProvider.createTestNetwork();
        network2.Preferred_Method_of_Tasking__c = 'Email';
        network2.ST_Email__c = true;
        network2.Email__c = '1@1.c';
        networks.add(network2);
        INSERT networks;

        networks[1].Parent_Network__c = networks[2].Id;
        networks[0].Parent_Network__c = networks[1].Id;

        UPDATE networks;

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.Network__c = networks[0].Id;
        INSERT testArticle;

        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Case c = TestDataProvider.createCase();
        c.RecordTypeId = pbenquiryRecType;
        c.SuppliedEmail = 'a@q.c';
        c.ArticleTest__c = testArticle.Id;
        INSERT c;

        Test.startTest();
        StarTrackUtil.validateLDCNetwork(c.Id);
        Test.stopTest();

        Case createdCase = [SELECT Id, OwnerId, Network__c FROM Case WHERE Id =: c.Id];

        System.assert(createdCase.Network__c != null);
    }

    @isTest static void testCreateLDCTask() {
        
/**
        List<Group> ldcQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'StarTrack Late Delivery Claims Queue'];
        delete ldcQueue;
        Group testGroup = new Group(Name='StarTrack Late Delivery Claims Queue', type='Queue');
        INSERT testGroup;
        QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
        INSERT testQueue;
**/
        User usr = [Select id from User where Id = :UserInfo.getUserId()];

        System.runAs(usr) {

            Test.startTest();
            Network__c network = TestDataProvider.createTestNetwork();
            network.Preferred_Method_of_Tasking__c = 'Email';
            network.ST_Email__c = true;
            network.Email__c = '1@1.c';
            INSERT network;

            Depot_Area__c depotArea = new Depot_Area__c(Depot__c = network.Id, Area__c = StarTrack_Constants.DEPOTAREA_AREA_OPERATIONS);
            INSERT depotArea;

            Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
            Case c = TestDataProvider.createCase();
            c.RecordTypeId = pbenquiryRecType;
            c.SuppliedEmail = 'a@q.c';
            c.Network__c = network.Id;
            INSERT c;

            StarTrackUtil.createLDCTask(c.Id);
            Test.stopTest();

            Case createdCase = [SELECT Id, OwnerId FROM Case WHERE Id =: c.Id];

            System.assert(createdCase.OwnerId != null);
        }
    }

    @isTest static void testCloseCaseTaskEmail() {

        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Case c = TestDataProvider.createCase();
        c.RecordTypeId = pbenquiryRecType;
        c.SuppliedEmail = 'a@q.c';
        INSERT c;

        Workflow_Email__c wfe = new Workflow_Email__c();
        wfe.Case__c = c.Id;
        wfe.Status__c = StarTrack_Constants.WFE_STATUS_OPEN;
        wfe.To_Address__c = c.SuppliedEmail;
        wfe.Task_Subject__c = 'Late Delivery Claim: ';
        wfe.Name = 'Late Delivery Claim: ';
        wfe.Email_Type__c = StarTrack_Constants.TASK_SUBTYPE_SINGLETASKING;
        INSERT wfe;
        
        Task testTask = TestDataProvider.createTask(c.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.CaseObject__c = c.Id;
        INSERT testTask;

        Test.startTest();
        StarTrackUtil.closeCaseTaskEmail(c.Id);
        Test.stopTest();

        Case createdCase = [SELECT Id, OwnerId, Network__c FROM Case WHERE Id =: c.Id];
        Workflow_Email__c retrievedWFE = [SELECT Status__c FROM Workflow_Email__c WHERE Case__c =: c.Id];
        Task retrievedTask = [SELECT Status FROM Task WHERE WhatId =: c.Id];

        System.assertEquals(StarTrack_Constants.TASK_STATUS_FINISHED, retrievedTask.Status);
        //System.assertEquals(StarTrack_Constants.WFE_STATUS_CLOSE, retrievedWFE.Status__c);

    }

    @isTest static void testCalculateDepot() {

        Network__c networkRec = TestDataProvider.createTestNetwork();
        networkRec.Preferred_Method_of_Tasking__c = 'Email';
        networkRec.ST_Email__c = true;
        networkRec.Email__c = '1@1.c';
        networkRec.Facility__c = 'Premium & Express';
        INSERT networkRec;
        
        Postcode__c postCode = new Postcode__c(Name = '1234', Suburb__c = 'TestSuburb');
        Database.insert(postCode);
        
        PostcodeMapping__c postCodeMapping = new PostcodeMapping__c(Network__c = networkRec.Id, Postcode__c = postCode.Id);
        Database.insert(postCodeMapping);

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.Source_System__c = 'TEAM';
        testArticle.RecordTypeId = Schema.SObjectType.Article__c.getRecordTypeInfosByName().get(StarTrack_Constants.CON_REC_TYPE).getRecordTypeId();
        INSERT testArticle;
        
        testArticle.Receiver_Suburb__c = '';
        Database.update(testArticle);
        
        Case newCase = new Case(Subject = 'Sample Case', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId(), ArticleTest__c = testArticle.Id);
        Database.insert(newCase);
        
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        Database.update(testArticle);

        List<Article__c> articles = new List<Article__c>();
        articles.add(testArticle);

        Test.startTest();
            StarTrackUtil.calculateDepot(articles);
        Test.stopTest();

        testArticle = [SELECT Id, Network__c, Service_Type__c FROM Article__c WHERE Id =: testArticle.Id];

        System.assertEquals(networkRec.Id, testArticle.Network__c);

    }

    @isTest static void testCalculateConsignmentServiceType() {

        Network__c network = TestDataProvider.createTestNetwork();
        network.Preferred_Method_of_Tasking__c = 'Email';
        network.ST_Email__c = true;
        network.Email__c = '1@1.c';
        INSERT network;

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.Network__c = network.Id;
        INSERT testArticle;

        List<Article__c> articles = new List<Article__c>();
        articles.add(testArticle);

        Test.startTest();
        StarTrackUtil.calculateConsignmentServiceType(articles);
        Test.stopTest();

        Article__c retrievedArticle = [SELECT Update_Related_Cases__c, Service_Type__c FROM Article__c WHERE Id =: testArticle.Id];

        System.assertEquals(testArticle.Service_Type__c, retrievedArticle.Service_Type__c);
    }

    /**
     * Scenario
     * Logic to calculate the total Case resolution time with regards to Business Hours
     */
    public static testMethod void testCalculateResolutionTime() {

        BusinessHours stdBusinessHours = [SELECT Id from BusinessHours WHERE Name = 'Default'];

        // calculateResolutionTime ensures that this value isn't update for the System support user which is the Deployment user...
        // it's not clear why this is a requirement
        // need to run this as another user to ensure the value calculates correctly.
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'StarTrack Support'];
        User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = prof.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com');

        Case c = TestDataProvider.createCase();

        System.runAs(testUser) {
            Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
            c.RecordTypeId = pbenquiryRecType;
            c.SuppliedEmail = 'a@q.c';
            c.Status = 'New';
            c.BusinessHoursId = stdBusinessHours.Id;
            insert c;

            // make sure the business hours has valid time to calculate
            Test.setCreatedDate(c.Id, DateTime.now().addDays(-50));

            Test.startTest();

            c.Status = 'Closed';
            c.ResolutionCode__c = 'Acknowledge Feedback';
            update c;

            Test.stopTest();
        }

        c = [Select Id, Case_Resolution_Time_in_Min__c From Case];

        // make sure the case resultion time was calculated in calculateResolutionTime
        System.assertEquals(false, String.isEmpty(String.valueOf(c.Case_Resolution_Time_in_Min__c)));
    }

    /**
     * Scenario
     * Logic to calculate the total Case resolution time with regards to Business Hours in the mapped Network
     */
    public static testMethod void testFCR() {

        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Case c = TestDataProvider.createCase();
        c.RecordTypeId = pbenquiryRecType;
        c.SuppliedEmail = 'a@q.c';
        c.Status = 'New';
        insert c;

        Test.startTest();

        c.Status = 'Closed';
        c.ResolutionCode__c = 'Acknowledge Feedback';
        update c;

        Test.stopTest();

        c = [Select Id, FCR__c From Case];

        // make sure the FCR flag is set to true inside processFCRFlag
        System.assertEquals(true, c.FCR__c);
    }
}