/**
* @author Dheeraj Mandavilli
* @date 2020-03-25
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Test class for PUD_JobsPrintFutureControllerX class.
* NOTE: This test class is used to test the PUD_FutureJobsPrintView VF Page upon clicking "Print Route" from Routes Detail Page. 
* 2020-03-25 - Dheeraj Mandavilli - Created
*/
@isTest
public with sharing class PUD_JobsPrintFutureControllerX_Test {
    
    static testmethod void validateJobsPrintFutureControllerXMethodwithAll(){
        
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        
        //Create a Route
        PUD_Route__c route = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route;
        
        string type = 'All';
        string datevalue = '2020-06-10';
        date dateVal = Date.valueOf(datevalue);
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.PUD_BookingPrint; 
        pageRef.getParameters().put('Id', String.valueOf(route.Id));
        pageRef.getParameters().put('type',type);
        pageRef.getParameters().put('date',datevalue); 
        Test.setCurrentPage(pageRef);
        
        PUD_JobsPrintFutureControllerX testDTPrint = new PUD_JobsPrintFutureControllerX(new ApexPages.StandardController(route));
        
        Test.StopTest();
        system.assertNotEquals(null,testDTPrint,'Test Passed');
    } 
    
    static testmethod void validateJobsPrintFutureControllerXMethodwithPerm(){
        
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        
        //Create a Route
        PUD_Route__c route = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route;
        
        string type = 'Perm';
        string datevalue = '2020-06-11';
        date dateVal = Date.valueOf(datevalue);
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.PUD_BookingPrint; 
        pageRef.getParameters().put('Id', String.valueOf(route.Id));
        pageRef.getParameters().put('type',type);
        pageRef.getParameters().put('date',datevalue); 
        Test.setCurrentPage(pageRef);
        
        PUD_JobsPrintFutureControllerX testDTPrint = new PUD_JobsPrintFutureControllerX(new ApexPages.StandardController(route));
        
        Test.StopTest();
        system.assertNotEquals(null,testDTPrint,'Test Passed');
    } 
    
    static testmethod void validateJobsPrintFutureControllerXMethodwithAdhoc(){
        
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        
        //Create a Route
        PUD_Route__c route = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route;
        
        string type = 'Adhoc';
        string datevalue = '2020-06-12';
        date dateVal = Date.valueOf(datevalue);
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.PUD_BookingPrint; 
        pageRef.getParameters().put('Id', String.valueOf(route.Id));
        pageRef.getParameters().put('type',type);
        pageRef.getParameters().put('date',datevalue); 
        Test.setCurrentPage(pageRef);
        
        PUD_JobsPrintFutureControllerX testDTPrint = new PUD_JobsPrintFutureControllerX(new ApexPages.StandardController(route));
        
        Test.StopTest();
        system.assertNotEquals(null,testDTPrint,'Test Passed');
    }
    
}