/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Test Class for StarTrackCalculateCaseResolutionTime
Test Class:    StarTrackCalculateCaseResolutionTime_Test
History
October 7, 2015 - Patrick James Franco - Created
October 9, 2015 - Patrick James Franco - Updated test class due to changes in process builder
------------------------------------------------------------*/

@isTest
private class StarTrackCalculateCaseResolutionTimeTest {

    /*@testSetup
    static void testSetup(){
        Id orgAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organisation').getRecordTypeId();

        Account testAccount = new Account();
        testAccount.RecordTypeId = orgAccRecTypeId;
        testAccount.Name = 'Test Account A';
        testAccount.Type = 'Small Business';
        INSERT testAccount;
        
        Entitlement testEntitlement = new Entitlement();
        testEntitlement.Name = 'Test Entitlement';
        testEntitlement.AccountId = testAccount.Id;
        INSERT testEntitlement;
        
        StarTrack_Settings__c customSetting = new StarTrack_Settings__c();
        customSetting.Case_Entitlement__c = testEntitlement.Id;
        insert customSetting;

        List<Case> testCaseList = new List<Case>();
        Id pudCaseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        // Used 25 instead of 200 since Flow behavior is not bulkified in nature
        for(Integer ctr = 0; ctr < 25; ctr++){
            Case testCase = new Case();
            testCase.RecordTypeId = pudCaseRecTypeId;
            testCase.Call_Purpose__c = 'Other';
            testCase.Enquiry_Type__c = 'POD';
            testCase.Status = 'Closed';
            testCase.ResolutionCode__c = 'Other';
            testCaseList.add(testCase);
        }
        INSERT testCaseList;
    }*/

    /*------------------------------------------------------------
    Author:        Patrick James Franco
    Company:       Cloud Sherpas
    Description:   Method to test the setEntitlement on Update
    History:
    September 24, 2015 - Patrick James Franco - Created
    October 7, 2015 - Patrick James Franco - Refactored CaseUtility_Test
    ------------------------------------------------------------*/
    static testMethod void testCalculateResolutionTime(){
    	//dummy test class
    	//apex class no longer used
    	List<Id> dummyIds = new List<Id>();
        StarTrackCalculateCaseResolutionTime.calculateResolutionTime(dummyIds);

        /*List<Case> queryCaseList = [SELECT Id, Status, ResolutionCode__c FROM Case];
        List<Id> caseIds = new List<Id>();
        for(Case testCase : queryCaseList){
            caseIds.add(testCase.Id);
        }

        Test.startTest();
            StarTrackCalculateCaseResolutionTime.calculateResolutionTime(caseIds);
            Case queryCase = [SELECT Case_Resolution_Time_in_Min__c FROM Case LIMIT 1];
            System.assert(queryCase.Case_Resolution_Time_in_Min__c >= 0);
        Test.stopTest();*/
    }
}