/**
 * Created by shashwat.a.nath on 25/09/2019.
 */

public with sharing class TaskDeletePageController {
    // Constructor
    public TaskDeletePageController(ApexPages.StandardController controller)
    {

    }
    /**
    *  This Method is called When user clicks on Delete Button on Event Detail Page
    *  Method Receives the event Id from the Page after the multiple checks before visualforce remoting is called.
    */
    @remoteaction
    public static void deleteTask(String recordId){
        system.debug('Event Record ID =>' +recordId);
        List<Task> taskList = new List<Task>();
        taskList = [SELECT Id FROM Task WHERE ID=:recordId LIMIT 1];
        if(!taskList.isEmpty()){
            database.delete(taskList);
        }
    }
}