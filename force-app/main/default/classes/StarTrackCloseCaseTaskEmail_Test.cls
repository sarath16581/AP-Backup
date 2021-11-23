/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Test Class for StarTrackCloseCaseTaskEmail
History
December 20, 2016 - Patrick James Franco - Created
------------------------------------------------------------*/

@isTest
private class StarTrackCloseCaseTaskEmail_Test {

    @testSetup
    static void testSetup(){
        
        StarTrack_Settings__c stSettings = StarTrack_Settings__c.getOrgDefaults();
        stSettings.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
        upsert stSettings;
        
        Id networkRec = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId();
        Network__c testNetwork = TestDataProvider.createTestNetwork();
        testNetwork.RecordTypeId = networkRec;
        testNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL;
        testNetwork.ST_Email__c = true;
        testNetwork.Email__c = 'te@st.comz';
        testNetwork.State__c = 'ACT';
        testNetwork.Facility__c = 'Express';
        testNetwork.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        INSERT testNetwork;
        
        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.ExpectedDeliveryDate__c = Date.today();
        testArticle.Network__c = testNetwork.Id;
        INSERT testArticle;
        System.debug(testArticle);

        Id deliveryEnquiryId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Id starTrackTaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('StarTrack Task').getRecordTypeId();
        Case testCase = new Case();
        testCase.RecordTypeId = deliveryEnquiryId;
        testCase.Call_Purpose__c = 'Card Left';
        testCase.Status = 'New';
        testCase.Enquiry_Type__c = 'Depot Collection';
        testCase.Claim_Date__c = Datetime.now();
        testCase.Recent_Caller_First_Name__c = 'First';
        testCase.Recent_Caller_Last_Name__c = 'First';
        testCase.Recent_Caller_Phone_Number__c = '000';
        testCase.Recent_Caller_Email__c = 't@t.zzz';
        testCase.ArticleTest__c = testArticle.Id;
        INSERT testCase;
        System.debug(testCase);
        
        List<Task> listOfTasks = new List<Task>();
        for(Integer i=0; i<10; i++){
            Task temp = new Task();
            temp.OwnerId = UserInfo.getUserId();
            temp.WhatId = testCase.Id;
            temp.RecordTypeId = starTrackTaskRecTypeId;
            temp.Type = StarTrack_Constants.TASK_TYPE_OPERATION;
            temp.CaseObject__c = testCase.Id;
            temp.Subject = 'Sample';
            temp.Status = 'Waiting for Operations';
            listOfTasks.add(temp);
        }
        insert listOfTasks;
    }

    @isTest static void testCloseCaseTaskEmail() {
        Case testCase = [SELECT Id, Status FROM Case LIMIT 1];

        Test.startTest();
            StarTrackCloseCaseTaskEmail.closeCaseTaskEmail(new List<Id>{testCase.Id});
        Test.stopTest();
        testCase = [SELECT Id, Status, (SELECT Id, Status FROM Tasks WHERE Type =: StarTrack_Constants.TASK_TYPE_OPERATION) FROM Case WHERE Id =: testCase.Id];
        for(Task taskRec : testCase.Tasks){
            System.assertEquals('Finished', taskRec.Status);
        }
    }
}