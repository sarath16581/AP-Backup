/**************************************************
Description:    Controller for the EventDelete Page
History:
--------------------------------------------------
2019-09-17  shashwat.a.nath@accenture.com  Created
**************************************************/

public with sharing class EventDeletePageController {
    // Constructor
    public EventDeletePageController(ApexPages.StandardController controller)
    {

    }
    /**
    *  This Method is called When user clicks on Delete Button on Event Detail Page
    *  Method Receives the event Id from the Page after the multiple checks before visualforce remoting is called.
    */
    @remoteaction
    public static void deleteEvent(String recordId){
        system.debug('Event Record ID =>' +recordId);
        List<Event> eventList = new List<Event>();
        eventList = [SELECT Id FROM Event WHERE ID=:recordId LIMIT 1];
        if(!eventList.isEmpty()){
            database.delete(eventList);
        }
    }
}