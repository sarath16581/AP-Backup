/**
* Date            Version          Owner               Desription
* 10-Apr-19       1.0              Anshul Goyal        This is the test class for the trigger handler class 'JobTriggerHandler' and  the trigger "JobTrigger"
*/

@IsTest(seeAllData=false)
private class JobTriggerHandler_Test {


    @testSetup static void testDataCreation() {
        //create case
        Case caseRec = TestDataProvider.createAndSaveCase('special services case','this is the special services case', 'Special_Services');


        //create network
        Network__c networkRecord = TestDataProvider.createTestNetwork();
        networkRecord.SSSE_Email__c='test@test.com';
        insert networkRecord;

        //create job
        Id RecordTypeIdJob = Schema.SObjectType.Job__C.getRecordTypeInfosByName().get('Special Services').getRecordTypeId();
        Job__c job = new Job__c(recordTypeId= RecordTypeIdJob , Job_Type__c='Special Services', Status__c='New',Case__c=caseRec.Id);
        insert job;
    }
    //this method test the triggerhandler method 'afterUpdateTriggerHandler' of class 'JobTriggerHandler' and trigger 'JobTrigger'
    static testMethod void testAfterUpdateTriggerHandler() {

        //query network record for the pickup and delivery depo for the job
        Network__c netwrk = [SELECT Id FROM Network__c LIMIT 1];
        Job__c job = [SELECT Id,Status__c FROM Job__c WHERE status__c='New' LIMIT 1];

        //update job status from 'New' to 'Allocated'
        job.Status__c = 'Allocated';
        job.Verified_Data__c =true;
        job.Pick_Up_Depot__c = netwrk.Id;
        job.Delivery_Depot__c=netwrk.Id;
        update job;
        
        Case caseRec = [SELECT Id,status FROM Case LIMIT 1];
        
        //verify the case status has been updated to 'In progress' or not
        System.assertEquals(caseRec.status, 'In Progress');

    }
}