/*------------------------------------------------------------
Author:        David Catindoy
Company:       Accenture
Description:   Test Class for StarTrackCreateLDCTask
History
May 13, 2016 - David Catindoy - Created
------------------------------------------------------------*/

@isTest
private class StarTrackCreateLDCTask_Test {

    @testSetup
    static void testSetup(){
        
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.StarTrack_Related_Contact_RecType_Id__c = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get('StarTrack Related Contact').getRecordTypeId();
        insert customSetting;
        
        Id metroRecTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId();
        Network__c testNetwork = TestDataProvider.createTestNetwork();
        testNetwork.RecordTypeId = metroRecTypeId;
        testNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL;
        testNetwork.ST_Email__c = true;
        testNetwork.Email__c = 'te@st.comz';
        testNetwork.State__c = 'ACT';
        testNetwork.Facility__c = 'Express';
        testNetwork.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        testNetwork.Email__c = 'te@st.zzz';
        testNetwork.Depot_ID__c = 'Test';
        testNetwork.Name = 'Test Network';
        testNetwork.ORG_UNIT_ADDR_1__c = 'Address 1';
        testNetwork.ORG_UNIT_ADDR_2__c = 'Address 2';
        testNetwork.ORG_UNIT_ADDR_3__c = 'Address 3';
        testNetwork.State__c = 'NSW';
        testNetwork.Post_Code__c = 'Post Code';
        testNetwork.Mon__c = '1';
        testNetwork.Tue__c = '2';
        testNetwork.Wed__c = '3';
        testNetwork.Thu__c = '4';
        testNetwork.Fri__c = '5';
        testNetwork.Sat__c = '6';
        testNetwork.Sun__c = '7';
        testNetwork.Depot_Lodgement_Times_Monday__c = '1';
        testNetwork.Depot_Lodgement_Times_Tuesday__c = '2';
        testNetwork.Depot_Lodgement_Times_Wednesday__c = '3';
        testNetwork.Depot_Lodgement_Times_Thursday__c = '4';
        testNetwork.Depot_Lodgement_Times_Friday__c = '5';
        testNetwork.Depot_Lodgement_Times_Saturday__c = '6';
        testNetwork.Depot_Lodgement_Times_Sunday__c = '7';
        testNetwork.Depot_Collection_Times_Monday__c = '1';
        testNetwork.Depot_Collection_Times_Tuesday__c = '2';
        testNetwork.Depot_Collection_Times_Wednesday__c = '3';
        testNetwork.Depot_Collection_Times_Thursday__c = '4';
        testNetwork.Depot_Collection_Times_Friday__c = '5';
        testNetwork.Depot_Collection_Times_Saturday__c = '6';
        testNetwork.Depot_Collection_Times_Sunday__c = '7';
        INSERT testNetwork;

        Depot_Area__c testDepotArea = new Depot_Area__c();
        testDepotArea.Name = 'Test Depot Area';
        testDepotArea.Depot__c = testNetwork.Id;
        testDepotArea.Area__c = StarTrack_Constants.DEPOTAREA_AREA_BRANCHMANAGEMENT;
        INSERT testDepotArea;

        Depot_Area_User__c testDepotAreaUser = new Depot_Area_User__c();
        testDepotAreaUser.Name = 'david Catindoy';
        testDepotAreaUser.Depot_Role__c = testDepotArea.Id;
        testDepotAreaUser.User__c = UserInfo.getUserId();
        INSERT testDepotAreaUser;

        testNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;
        testNetwork.System__c = true;
        UPDATE testNetwork;

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.ExpectedDeliveryDate__c = Date.today();
        testArticle.Network__c = testNetwork.Id;
        INSERT testArticle;

        EventMessage__c testEventMsg = new EventMessage__c();
        testEventMsg.Article__c = testArticle.Id;
        testEventMsg.ActualDateTime__c = Datetime.now() + 1;
        INSERT testEventMsg;
    }

    @isTest static void testCreateLDCTask() {
        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.Call_Purpose__c = 'Late Delivery';
        testCase.Enquiry_Type__c = 'LDC';
        testCase.Recent_Caller_First_Name__c = 'David';
        testCase.Recent_Caller_Last_Name__c = 'Catindoy';
        testCase.Recent_Caller_Email__c = 'david.catindoy@cloudsherpas.com';
        testCase.Recent_Caller_Phone_Number__c = '09126893944';
        testCase.Claim_Date__c = Datetime.now() + 2;
        testCase.ArticleTest__c = [SELECT Id FROM Article__c LIMIT 1].Id;
        INSERT testCase;

        Test.startTest();
            StarTrackCreateLDCTask.createLDCTask(new List<Id>{testCase.Id});
            Task newTask = new Task(Subject = 'New Task', Type = StarTrack_Constants.TASK_TYPE_OPERATION);
            insert newTask;
        Test.stopTest();
        
        System.assert(![SELECT Id FROM Task WHERE Type =: StarTrack_Constants.TASK_TYPE_OPERATION].isEmpty());
    }

}