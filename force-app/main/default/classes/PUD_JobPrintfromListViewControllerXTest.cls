/**
* @author Dheeraj Mandavilli
* @date 2019-11-28
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Test class for PUD_JobPrintfromListViewControllerX class.
* NOTE: This test class is used to test the PUD_JobsPrint VF Page upon clicking "Print All Jobs" from Routes List View. 
* 2019-11-28 - Dheeraj Mandavilli - Created
*/
@IsTest
public with sharing class PUD_JobPrintfromListViewControllerXTest {
    
    static testmethod void validateJobPrintControllerXMethodOne(){
        
        
        //Create User
        User user1 = PUDTestUtility.createUser('AusPost Depot Supervisor');
        insert user1;
        
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        List<PUD_Route__c> routeList = new List<PUD_Route__c>();
        //Create a Route
        PUD_Route__c route1 = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route1;
        routeList.add(route1);
        PUD_Route__c route2 = PUDTestUtility.createRoute ('DT62', networkDepot.Id);
        insert route2;
        routeList.add(route2);
        
        Map<String,List<PUD_Job__c>> routeMap = new Map<String,List<PUD_Job__c>>();
        
        List<PUD_Job__c> jobsList = new List<PUD_Job__c> ();
        date reportdate;
        string depotname;
        Set<String> routeKeys = new Set<String>();
        List<PUD_Job__c> routeList1 = new List<PUD_Job__c>();
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.PUD_JobPrint; 
        Test.setCurrentPage(pageRef);
        
        PUD_JobPrintfromListViewControllerX testJobsPrint = new PUD_JobPrintfromListViewControllerX(new ApexPages.StandardSetController(routeList));
        testJobsPrint.depotName = networkDepot.Name;
        testJobsPrint.depotId = networkDepot.Id;
        jobsList = testJobsPrint.jobTemplateList;
        
        routeMap= testJobsPrint.routeJobMap;
        routeKeys = testJobsPrint.routeKeys;
        testJobsPrint.reportdate = String.valueOf(System.today());
        
        Test.StopTest(); 
        system.assertNotEquals(null,testJobsPrint,'Test Passed');
    } 
    
    static testmethod void validateJobPrintControllerXMethodCreateMap(){
        
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        List<PUD_Route__c> routeList = new List<PUD_Route__c>();
        //Create a Route
        PUD_Route__c route1 = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route1;
        routeList.add(route1);
        PUD_Route__c route2 = PUDTestUtility.createRoute ('DT62', networkDepot.Id);
        insert route2;
        routeList.add(route2);
        
        Map<String, Id> recordIdMap = new Map<String,Id>();
        
        recordIdMap = PUDTestUtility.createPUDBasicRecords();
        //Create a Booking
        PUD_Booking__c booking1= PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blNetLPO'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
        insert booking1;
        
        //Create jobs
        List<PUD_Job__c> jobsList = new List<PUD_Job__c> ();
        PUD_Job__c job1= new PUD_Job__c();
        job1.Booking__c = booking1.Id;
        job1.Bags_Quantity__c = 10;
        insert job1;
        jobsList.add(job1);
        PUD_Job__c job2= new PUD_Job__c();
        job2.Booking__c = booking1.Id;
        job2.Bags_Quantity__c = 20;
        insert job2;
        jobsList.add(job2);
        
        Map<String,List<PUD_Job__c>> routeMap = new Map<String,List<PUD_Job__c>>();
        
        Set<String> routeKeys = new Set<String>();
        List<PUD_Job__c> routeList1 = new List<PUD_Job__c>();
        
        Test.StartTest();        
        
        routeMap = PUD_JobPrintfromListViewControllerX.createMap(jobsList,routeMap);
        
        Test.StopTest();
        system.assertNotEquals(null,routeMap,'Test Passed');
    }
    
}