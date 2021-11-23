/**
* @author Dheeraj Mandavilli
* @date 2019-11-19
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Test class for PUD_AdhocJobsPrintfromRouteControllerX class.
* NOTE: This test class is used to test the PUD_AdhocJobsPrint VF Page upon clicking "Print Adhoc and Perm with variations" from Routes Detail Page. 
* 2019-11-19 - Dheeraj Mandavilli - Created
*/
@isTest
public with sharing class PUD_AdhocJobsPrintfromRouteCtrlX_Test {
	static testmethod void validateBookingPrintControllerXMethodOne(){
        
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        
        //Create a Route
        PUD_Route__c route = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route;
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.PUD_BookingPrint; 
        pageRef.getParameters().put('Id', String.valueOf(route.Id));
        Test.setCurrentPage(pageRef);
        
        PUD_AdhocJobsPrintfromRouteControllerX testDTPrint = new PUD_AdhocJobsPrintfromRouteControllerX(new ApexPages.StandardController(route));
        
        Test.StopTest(); 
        system.assertNotEquals(null,testDTPrint,'Test Passed');
    } 
}