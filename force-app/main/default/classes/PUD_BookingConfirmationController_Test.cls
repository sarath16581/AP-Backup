/* @author       : Arjun Singh
* @date         : 
* @description  : Test Class for BookingConfirmationController
*/
/*******************************  History ************************************************
01/31/2020  : Created
*******************************  History ************************************************/
@isTest
public class PUD_BookingConfirmationController_Test {
    static testMethod void MPBBookingRecordEmailTest() {
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
         Account acc =TestUtility.createBusinessAccount('Test Org','01290000000VkR9AAK');
        insert acc;
        acc.LEGACY_ID__c='60000000';
        update acc;
        Id accid=acc.id;
        
        Map<String, Id> recordIdMap = new Map<String,Id>();        
        recordIdMap = PUDTestUtility.createPUDBasicRecords();
        
        //Create a Booking
        PUD_Booking__c booking1= PUDTestUtility.createBooking('MPB_Pickup', null,accid, null, recordIdMap.get('netDepot'), recordIdMap.get('route'));        
        insert booking1;
        booking1.Confidence__c = 'High';
        update booking1;
        
        Test.startTest();
            PUD_BookingConfirmationController con = new PUD_BookingConfirmationController();
             con.bookingRecordId = booking1.id;
        Test.stopTest();
        System.assert(booking1.Confidence__c != null);
    }
}