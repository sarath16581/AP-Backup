/**
* @author Dheeraj Mandavilli
* @date 2020-06-11
* @group PUD Project
* @tag Controller
* @tag PUD_Booking_Location__c
* @domain Interoperability PUD Project
* @description Test class for PUD_LocationConfirmationController class.
* NOTE: This test class is used to test the location record retreival which is to be used in sending email to Account Manager, 
*        whenever a location gets created or updated successfully.
* 2020-06-11 - Dheeraj Mandavilli - Created
*/
@isTest
public without sharing class PUD_LocationConfirmationController_Test {
    static testMethod void pudLocationRecordEmailTest() {
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        List<PUD_Route__c> routeList = new List<PUD_Route__c>();
        //Create a Route
        PUD_Route__c route1 = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route1;
        Account acc =TestUtility.createBusinessAccount('Test Org','01290000000VkR9AAK');
        insert acc;
        acc.LEGACY_ID__c='60000000';
        update acc;
        Id accid=acc.id;
        
        Map<String, Id> recordIdMap = new Map<String,Id>();        
        recordIdMap = PUDTestUtility.createPUDBasicRecords();
        
        //Create a Location
        PUD_Booking_Location__c location1= PUDTestUtility.createBookingLocation('Test Location',accid, null);        
        insert location1;
        location1.Account_Manager_Email__c = 'dheeraj.mandavilli@auspost.com.au';
        update location1;
        
        Test.startTest();
        PUD_LocationConfirmationController con = new PUD_LocationConfirmationController();
        con.locationRecordId = location1.id;
        Test.stopTest();
        system.assertNotEquals(null,con.locationRecordId,'Test Passed');
    }
}