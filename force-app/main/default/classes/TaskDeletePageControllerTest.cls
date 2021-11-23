/**
   * Created by: Shashwat Nath
   * Description: Test class for TaskDeletePageController class
   * Date: 01/10/2019
   */

@istest
public with sharing class TaskDeletePageControllerTest {
    @testSetup static void setup() {
        Task taskRecord = new Task();
        taskRecord.subject = 'Test';
        //taskRecord.DurationInMinutes = 60;
        //taskRecord.ActivityDateTime = System.now();
        insert taskRecord;
    }
    public static testmethod void deleteTaskTest() {
        Task taskRecord = [SELECT id from Task LIMIT 1];
        Test.StartTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(taskRecord);
            TaskDeletePageController taskDel = new TaskDeletePageController(sc);
            TaskDeletePageController.deleteTask(taskRecord.id);
        Test.StopTest();
        List<Task> tasklist = [SELECT id from Task LIMIT 1];
        system.assertEquals(tasklist.size(),0);
    }
}