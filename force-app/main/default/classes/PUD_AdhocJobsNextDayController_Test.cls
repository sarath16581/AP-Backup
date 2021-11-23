/**
* @author Dheeraj Mandavilli
* @date 2020-08-10
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Test class for PUD_AdhocJobsNextDayController class.
* NOTE: This test class is used to test the PUD_AdhocJobsNextDay VF Page upon clicking "Adhoc Jobs-Next Day" from Routes List View. 
* 2020-08-10 - Dheeraj Mandavilli - Created
*/
@isTest
public with sharing class PUD_AdhocJobsNextDayController_Test {
    static testmethod void validateAdhocJobPrintControllerXMethodOne(){
        
        
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
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.PUD_JobPrint; 
        Test.setCurrentPage(pageRef);
        
        PUD_AdhocJobsNextDayController testJobsPrint = new PUD_AdhocJobsNextDayController(new ApexPages.StandardSetController(routeList));
        testJobsPrint.depotName = networkDepot.Name;
        testJobsPrint.depotId = networkDepot.Id;
        jobsList = testJobsPrint.jobTemplateList;
        
        routeMap= testJobsPrint.routeJobMap;
        routeKeys = testJobsPrint.routeKeys;
        testJobsPrint.reportdate = String.valueOf(System.today());
        
        Test.StopTest();
        system.assertNotEquals(null,testJobsPrint,'Test Passed');
    } 
    
    static testmethod void validateAdhocJobPrintControllerXMethodCreateMap(){
        
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
        
        PUD_Booking__c booking2= PUDTestUtility.createBooking('AP_Adhoc_Pickup', recordIdMap.get('blNetLPO'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
        insert booking2;
        
        PUD_Booking__c booking3= PUDTestUtility.createBooking('Other', recordIdMap.get('blNetLPO'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
        booking3.Booking_Type__c = 'Meal Break';
        insert booking3;
        
        //Create jobs
        List<PUD_Job__c> jobsList = new List<PUD_Job__c> ();
        PUD_Job__c job1= new PUD_Job__c();
        job1.Booking__c = booking1.Id;
        job1.Bags_Quantity__c = 10;
        job1.Revenue_Check__c = true;
        insert job1;
        jobsList.add(job1);
        
        PUD_Job__c job2= new PUD_Job__c();
        job2.Booking__c = booking1.Id;
        job2.Bags_Quantity__c = 20;
        insert job2;
        jobsList.add(job2);
        
        PUD_Job__c job3= new PUD_Job__c();
        job3.Booking__c = booking2.Id;
        job3.Bags_Quantity__c = 15;
        insert job3;
        jobsList.add(job3);
        
        PUD_Job__c job4= new PUD_Job__c();
        job4.Booking__c = booking1.Id;
        job4.Bags_Quantity__c = 10;
        job4.Stop_Credit__c = true;
        insert job4;
        jobsList.add(job4);
        
        PUD_Job__c job5= new PUD_Job__c();
        job5.Booking__c = booking3.Id;	
        insert job5;
        jobsList.add(job5);
        
        PUD_Job__c job6= new PUD_Job__c();
        job6.Booking__c = booking1.Id;
        job6.Bags_Quantity__c = 10;
        job6.Revenue_Check__c = false;
        job6.Stop_Credit__c = false;
        insert job6;
        jobsList.add(job6);
        
        Map<String,List<PUD_Job__c>> routeMap = new Map<String,List<PUD_Job__c>>();
        
        
        Test.StartTest();        
        
        routeMap = PUD_AdhocJobsNextDayController.createMap(jobsList,routeMap);
        
        Test.StopTest(); 
        system.assertNotEquals(null,routeMap,'Test Passed');
    }
}