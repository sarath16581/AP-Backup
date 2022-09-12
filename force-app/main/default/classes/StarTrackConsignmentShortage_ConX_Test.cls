/**
 ** Description: Test Class for StarTrackConsignmentShortage_ControllerX class
 ** Author: David Catindoy(CloudSherpas)
 ** Date Created: JAN.8.2016
 ** History:--------------------------------------------
 **         JAN.8.2016 David Catindoy - Created
 **/
@isTest
private class StarTrackConsignmentShortage_ConX_Test {

    @testSetup static void testSetup(){
        Network__c testNetwork = TestDataProvider.createNetwork('Test Network', 1)[0];
        INSERT testNetwork;
        
        Article__c testCon = TestDataProvider.createTestArticle();
        testCon.Network__c = testNetwork.Id;
        testCon.Name = 'Sample Article';
        testCon.ReceiverPostcode__c = '1234';
        testCon.Receiver_Suburb__c = 'TestSuburb';
        INSERT testCon;
        
        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.Origin = 'Email';
        testCase.Call_Purpose__c = 'Other';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General Enquiry').getRecordTypeId();
        testCase.Network__c = testNetwork.Id;
        testCase.ArticleTest__c = testCon.Id;
        INSERT testCase;
        
    }
    
    @isTest static void testConsignmentShortage() {
        Case caseRec = [SELECT Id, Enquiry_Type__c, Approval_Status__c, Tier__c, Consignment_Shortage__c, Case_Age_Total_Hours__c FROM Case WHERE Subject = 'Test Case'];
        Case resultCase;
        
        Test.startTest();
            StarTrackConsignmentShortage_ControllerX controller = new StarTrackConsignmentShortage_ControllerX();
            System.assert(!controller.buttonHit);
            controller.setCaseRecord(caseRec);
            controller.searchUpdatedCase();
            System.assert(controller.buttonHit);
            caseRec.Enquiry_Type__c = 'Shortage';
            caseRec.Value_of_Goods__c = '$2,000 - $9,999'; //REQ2947669 - Changing to new picklist value since old value is inactivated
            update caseRec;
            System.assertEquals('Shortage', StarTrackConsignmentShortage_ControllerX.refreshCase(caseRec.Id).Enquiry_Type__c);
            controller.setCaseRecord(caseRec);
            controller.searchUpdatedCase();
            resultCase = controller.getCaseRecord();
        Test.stopTest();
        
        System.assert(resultCase.Enquiry_Type__c == 'Shortage');
            
    }

}