/**
 ** Description: Test Class for StarTrackCardLeftCalculation_ControllerX class
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: JAN.7.2016
 ** History:--------------------------------------------
 **         JAN.7.2016 David Catindoy - Created
 **/
@isTest
private class StarTrackCardLeftCalculation_ConX_Test {

    @testSetup static void testSetup(){
        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;
        
        Article__c testCon = TestDataProvider.createTestArticle();
        testCon.Network__c = testNetwork.Id;
        testCon.Name = 'Sample Article';
        testCon.ReceiverPostcode__c = '1234';
        testCon.Receiver_Suburb__c = 'TestSuburb';
        INSERT testCon;
        
        Postcode__c testPostCode = new Postcode__c();
        testPostCode.Name = '1234';
        testPostCode.Suburb__c = 'TestSuburb';
        INSERT testPostCode;

        PostcodeMapping__c testPostCodeMap = new PostcodeMapping__c();
        testPostCodeMap.Postcode__c = testPostCode.Id;
        testPostCodeMap.Network__c = testNetwork.Id;
        testPostCodeMap.Run_Dock__c = '637349';
        INSERT testPostCodeMap;
        
        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.Origin = 'Email';
        testCase.Call_Purpose__c = 'Other';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        testCase.Network__c = testNetwork.Id;
        testCase.ArticleTest__c = testCon.Id;
        INSERT testCase;
        
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('StarTrack Task').getRecordTypeId();
        Task newTask = new Task(WhatId = testCase.Id, Depot_Role__c = null, Run_Dock__c = null, Subject = 'Sample Task', RecordTypeId = taskRecTypeId);
        INSERT newTask;
        
    }
    
	@isTest static void testRunDockAndDepotCalculationPositive() {
        Task taskRec = [SELECT Id, WhatId, Depot_Role__c, Run_Dock__c FROM Task WHERE Subject = 'Sample Task'];
        
        Test.startTest();
            StarTrackCardLeftCalculation_ControllerX.RunDockANDDepotAreaCalculation(new List<Id>{taskRec.Id});
        Test.stopTest();
        
        taskRec = [SELECT Id, WhatId, Depot_Role__c, Run_Dock__c FROM Task WHERE Id =:taskRec.Id];
        System.assert(taskRec.Run_Dock__c == '637349');
	}
	
	@isTest static void testRunDockAndDepotCalculationNegative() {
	    Article__c conRec = [SELECT Id, ReceiverPostcode__c, Receiver_Suburb__c FROM Article__c WHERE Name = 'Sample Article'];
	    conRec.ReceiverPostcode__c = null;
        conRec.Receiver_Suburb__c = null;
        update conRec;
        Task taskRec = [SELECT Id, WhatId, Depot_Role__c, Run_Dock__c FROM Task WHERE Subject = 'Sample Task'];
        
        Test.startTest();
            StarTrackCardLeftCalculation_ControllerX.RunDockANDDepotAreaCalculation(new List<Id>{taskRec.Id});
        Test.stopTest();
        
        taskRec = [SELECT Id, WhatId, Depot_Role__c, Run_Dock__c FROM Task WHERE Id =:taskRec.Id];
        System.assert(taskRec.Run_Dock__c == null);
	}

}