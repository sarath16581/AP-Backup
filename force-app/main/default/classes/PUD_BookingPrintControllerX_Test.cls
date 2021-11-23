/**
* @author Dheeraj Mandavilli
* @date 2020-08-05
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Test class for PUD_BookingPrintControllerX class.
* NOTE: This test class is used to test the PUD_JobPrintFromBooking VF Page upon clicking "Print Today's Jobs" from Routes Detail Page. 
* 2020-08-05 - Dheeraj Mandavilli - Created
*/
@isTest
public with sharing class PUD_BookingPrintControllerX_Test {
    static testmethod void validateBookingPrintControllerXMethodOne(){
        
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        
        //Create a Route
        PUD_Route__c route = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route;
        
        Map<String, Id> recordIdMap = new Map<String,Id>();
        
        //Create Test Data
        recordIdMap = PUDTestUtility.createPUDBasicRecords();
        
        //Create a booking
        PUD_Booking__c booking = PUDTestUtility.createBooking('AP_Permanent_Pickup', recordIdMap.get('blCust'),null, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));
        insert booking;
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.PUD_JobPrintFromBooking; 
        pageRef.getParameters().put('Id', String.valueOf(booking.Id));
        Test.setCurrentPage(pageRef);
        
        PUD_BookingPrintControllerX testDTPrint = new PUD_BookingPrintControllerX(new ApexPages.StandardController(booking));
        
        Test.StopTest(); 
        system.assertNotEquals(null,testDTPrint,'Test Passed');
    } 
}