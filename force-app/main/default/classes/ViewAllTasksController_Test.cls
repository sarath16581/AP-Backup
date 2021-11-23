/***
 * @author Steve W.
 * @date 2020-03-03
 * @group Tests
 * @description Test Class covering VIewAllTasksController
 * @changelog
 * 2020-03-03 - Steve W - Created
 */

@istest
class ViewAllTasksController_Test {

    @testSetup static void setup(){
        //Create an Account to link tasks to
        Account acct = TestDataProvider.createAccount('TestViewAllTaskAccount',1)[0];
        insert acct;

        //Create contact
        Contact con = TestDataProvider.createContact('TestView AllTasksContact', acct.Id, 'Contact');
        insert con;
    }

    private static List<Task> generateTasks(Id acct, Integer numberToCreate, String status){
        List<Task> tasks = new List<Task>();

        for(Integer i = 0; i < numberToCreate; i++){
            Task t = TestDataProvider.createTask(acct, null, 'Sales Task');
            t.Subject = 'Test' + i;
            t.Type = 'Phone Call';
            t.Status = status;
            t.Category__c = 'Sales';
            t.ActivityDate = System.today().addDays(i);
            tasks.add(t);
        }

        return tasks;
    }

    /**
     * @description: test that returning no tasks does not cause a failure
     */
    @isTest static void testNoTasks() {
        Account a = [Select Id, Name FROM Account WHERE Name = 'TestViewAllTaskAccount0' LIMIT 1];
        ViewAllTasksController.TaskWrapper taskWrapper;

        Test.startTest();
            taskWrapper = ViewAllTasksController.GetTasks(a.Id, 'open', null);
        Test.stopTest();
        
        System.assertEquals(0, taskWrapper.tasks.size(), 'The Task List should be empty');
        System.assertEquals(0, taskWrapper.total, 'The Task total should be 0');
    }

    /**
     * @description: test default functionality
     */
    @isTest static void testWithTasks() {
        Account a = [Select Id, Name FROM Account WHERE Name = 'TestViewAllTaskAccount0' LIMIT 1];
        List<Task> tasksToInsert = ViewAllTasksController_Test.generateTasks(a.Id, 5, 'Not Started');
        insert tasksToInsert;

        ViewAllTasksController.TaskWrapper taskWrapper;

        Test.startTest();
            taskWrapper = ViewAllTasksController.GetTasks(a.Id, 'open', null);
        Test.stopTest();
        
        System.assertEquals(5, taskWrapper.tasks.size(), 'There should be 5 tasks');
    }

    /**
     * @description: test the offset to ensure the 'View More' functionality works
     */
    @isTest static void testOffset() {
        Account a = [Select Id, Name FROM Account WHERE Name = 'TestViewAllTaskAccount0' LIMIT 1];
        List<Task> tasksToInsert = ViewAllTasksController_Test.generateTasks(a.Id, 15, 'Completed');
        for(Integer i = 0; i < tasksToInsert.size() ; i++){
            tasksToInsert[i].ActivityDate = System.today().addDays(-i);
        }
        insert tasksToInsert;

        ViewAllTasksController.TaskWrapper taskWrapper;

        Test.startTest();
            taskWrapper = ViewAllTasksController.GetTasks(a.Id, 'closed', 2);
        Test.stopTest();

        System.assertEquals(System.today().addDays(-2), taskWrapper.tasks[0].ActivityDate, 'The first task due date should be 2 days old from now based on the offset');
    }

    /**
     * @description: the oldest task to return should be 01/07/2019 so make sure an older task is not returned
     */
    @isTest static void testCutOffDate() {
        Account a = [Select Id, Name FROM Account WHERE Name = 'TestViewAllTaskAccount0' LIMIT 1];
        List<Task> tasksToInsert = ViewAllTasksController_Test.generateTasks(a.Id, 2, 'Not Started');
        tasksToInsert[0].ActivityDate = Date.newInstance(2018, 02, 10);
        insert tasksToInsert;

        ViewAllTasksController.TaskWrapper taskWrapper;

        Test.startTest();
            taskWrapper = ViewAllTasksController.GetTasks(a.Id, 'open', null);
        Test.stopTest();

        System.assertEquals(1, taskWrapper.tasks.size(), 'A Single Task should be returned');
    }
}