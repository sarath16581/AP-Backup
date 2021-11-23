/*------------------------------------------------------------
Author:        Jen Karen Tan
Description:   Test class for StarTrackTasksRenderPDF_ControllerX
History
August 8, 2016 - Jen Karen Tan - Created
------------------------------------------------------------*/

@isTest
private class StarTrackTasksRenderPDF_ControllerX_Test {
    @testSetup static void testSetup(){
        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;
        
        Depot_Area__c testDepotArea = new Depot_Area__c();
        testDepotArea.Name = 'Test Depot Area';
        testDepotArea.Depot__c = testNetwork.Id;
        INSERT testDepotArea;

        Depot_Area_User__c testDepotAreaUser = new Depot_Area_User__c();
        testDepotAreaUser.Name = 'Test Depot Area User';
        testDepotAreaUser.Depot_Role__c = testDepotArea.Id;
        testDepotAreaUser.User__c = UserInfo.getUserId();
        INSERT testDepotAreaUser;
        
        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.STServiceType__c = 'Airlock';
        testArticle.Network__c = testNetwork.Id;
        INSERT testArticle;
        
        Case testCase = new Case();
        testCase.Origin = 'Email';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General Enquiry').getRecordTypeId();
        testCase.ArticleTest__c = testArticle.Id;
        testCase.Network__c = testNetwork.Id;
        INSERT testCase;
    }

    @isTest static void testPDFRender(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='StarTrack Operations']; 
        User u = new User(Alias = 'newUser', Email='user@testorg.a', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = p.Id, 
             TimeZoneSidKey='America/Los_Angeles', UserName='user@testorg.a');
        insert u;
        
        Case queryCase = [SELECT Id FROM Case LIMIT 1];
        Depot_Area__c queryDepotArea = [SELECT Id, Depot__c FROM Depot_Area__c LIMIT 1];
        Network__c net = [SELECT Id FROM Network__c WHERE Id =: queryDepotArea.Depot__c];
        
        Task testTask = TestDataProvider.createTask(queryCase.Id, null, 'StarTrack Task');
        testTask.Depot_Role__c = queryDepotArea.Id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        testTask.CaseObject__c = queryCase.Id;
        testTask.Network__r = net;
        INSERT testTask;
        
        StarTrackTasksRenderPDF_ControllerX cont = null;
        
        System.runAs(u) {
            ApexPages.CurrentPage().getParameters().put('id', String.valueOf(testTask.Id));
            cont = new StarTrackTasksRenderPDF_ControllerX();
        }
        
        System.assert(cont.taskList != null);

    }
}