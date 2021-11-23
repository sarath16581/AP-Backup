/**
   * Created by: Shashwat Nath
   * Description: Test class for EventDeletePageController class
   * Date: 01/10/2019
   */

@IsTest
public class EventDeletePageControllerTest {
    @testSetup static void setup() {
        Event eventRecord = new Event();
        eventRecord.subject = 'Test';
        eventRecord.DurationInMinutes = 60;
        eventRecord.ActivityDateTime = System.now();
        insert eventRecord;
    }
    public static testmethod void deleteEventTest() {
        Event eventRecord = [SELECT id from Event LIMIT 1];
        Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(eventRecord);
            EventDeletePageController evntDel = new EventDeletePageController(sc);
            EventDeletePageController.deleteEvent(eventRecord.id);
        Test.StopTest();
        List<Event> eventlist = [SELECT id from Event LIMIT 1];
        system.assertEquals(eventlist.size(),0);
    }
}