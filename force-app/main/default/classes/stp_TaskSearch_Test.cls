/**
 * Created by hasantha on 7/01/2019.
 History:
--------------------------------------------------
2019-10-02  LJ Modified
 */
@IsTest
private class stp_TaskSearch_Test {

    @testSetup
    static void setup() {
        //Create Accounts.
        List < Account > accounts = TestDataProvider.createAccount('AccountName', 1);
        insert accounts;
        list < Article__c > articles = TestDataProvider.createArticle('sub1', 1, null);
        articles.get(0).Name = '000CONSI001';
        insert articles;
        //
        Case cse = TestDataProvider.createCase('test', 'test', 'Pickup Booking Enquiry');
        cse.ArticleTest__c = articles.get(0).id;
        insert cse;
        //Create a Task.
        Task testTask = TestDataProvider.createTask(accounts[0].Id, null, 'StarTrack Task');
        testTask.CaseObject__c = cse.id;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.TaskUpdate__c = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
        insert testTask;

        //Create Network
        Network__c MelNw = new Network__c(Name = 'MelbourneNetwork');
        insert MelNw;

        List<Depot_Area__c> das = new List<Depot_Area__c>();
        Depot_Area__c depArea1 = new Depot_Area__c( Depot__c = MelNw.Id , Name ='Operations', Area__c = 'Operations');
        DAS.add(depArea1);
        Depot_Area__c depArea2 = new Depot_Area__c( Depot__c = MelNw.Id , Name ='BookIns', Area__c = 'BookIns');
        DAS.add(depArea2);
        Depot_Area__c depArea3 = new Depot_Area__c( Depot__c = MelNw.Id , Name ='Damaged', Area__c = 'Damaged');
        DAS.add(depArea3);
        insert das;
    }

    /**
    * Acknowledge task successfully
    */
    @IsTest
    static void getDepotAreaSuccess() {
        // Parent network
        Network__c thisNetwork = [SELECT Id, Name FROM Network__c WHERE Name = 'MelbourneNetwork' LIMIT 1];
        List <stp_TaskSearch.PickListValue> pValues = stp_TaskSearch.getDepotArea(thisNetwork.Id);

        // null check would be enough
        system.assertEquals(3, pValues.size(),'stp_TaskSearch_Test.getDepotAreaSuccess()' );
    }

    /**
   * TAsk and attachments succesfully
   */
    @IsTest
    static void getContentDocsSuccess() {
        // Parent network
        String taskId = [SELECT Id, Status FROM Task LIMIT 1].id;

        // upload content
        ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
        );
        insert contentVersionInsert;

        // Test INSERT
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        ContentDocumentLink CDLs = new ContentDocumentLink(ContentDocumentId =documents[0].Id,Visibility ='AllUsers', LinkedEntityId = taskId, ShareType ='V');
        insert CDLs;

        List< ContentDocumentLink>  cdsLink = stp_TaskSearch.getContentDocs(taskId);

        system.assertEquals(1, cdsLink.size(),'stp_TaskSearch_Test.getContentDocsSuccess' );
    }

    /**
     * return the task if it is available
     */
    @IsTest
    static void getTaskAvailableSuccess() {
        // pull the task for id
        String taskId = [SELECT Id, Status FROM Task LIMIT 1].id;
        // test the method
        Task task = stp_TaskSearch.getTask(taskId);

        // null check would be enough
        system.assertNotEquals(null, task, 'stp_TaskSearch_Test.getTaskAvailableSuccess() : Task cannot be null');
    }

    /**
     * Search tasks by list type and the cosignment id
     */
    @IsTest
    static void searchTaskAvailableSuccess() {
        List < Task > tasks = stp_TaskSearch.searchTask('', '000CONSI001');
    }

    /**
     * read field set based on the passed object and the field set name
     */
    @IsTest
    static void readFieldSetSuccess() {
        Object fieldObj = stp_TaskSearch.readFieldSet('StarTrack_Consignment_Summary', 'Article__c');

        // null check would be enough
        system.assertNotEquals(null, fieldObj, 'StarTrackPortalTaskSearch.readFieldSetSuccess() : Field set cannot be null');
    }

    /**
     * read field set based on the passed object and the field set name, if failed should throw an exception
     */
    @IsTest
    static void readFieldSetFail() {
        Boolean isError = false;
        try {
            Object fieldObj = stp_TaskSearch.readFieldSet('No_such_fielset', 'nosuchobject__c');
        } catch (Exception e) {
            isError = true;
        }
        // error must be thrown
        system.assertEquals(true, isError, 'StarTrackPortalTaskSearch.readFieldSetFail() : error must be trown');
    }

    /**
     * get the task update picklist values
     */
    @IsTest
    static void getTaskUpdateSuccess() {
        Object fieldObj = stp_TaskSearch.getTaskUpdate();

        // null check would be enough
        system.assertNotEquals(null, fieldObj, 'StarTrackPortalTaskSearch.readFieldSetSuccess() : Field set cannot be null');
    }

    /**
     * get the task details
     */
    /* Commented and will need to be fixed 
    @IsTest
    static void getTaskDetailsSuccess() {
        Task task = [SELECT Id, Status, CaseObject__c FROM Task LIMIT 1];
        Task returnedTask = stp_TaskSearch.getTaskDetails(task.Id);

        // null check would be enough
        system.assertEquals(task.Id, returnedTask.Id, 'StarTrackPortalTaskSearch.getTaskDetailsSuccess() : Requested Task should be returned');
    } */


    /**
     * get the status picklist values
     */
    @IsTest
    static void getStatusSuccess() {
        Object fieldObj = stp_TaskSearch.getStatus();

        // null check would be enough
        system.assertNotEquals(null, fieldObj, 'StarTrackPortalTaskSearch.getStatusSuccess() : statuses cannot be null');
    }

    /**
     * Task update check
     */
    @IsTest
    static void saveTaskDetailsSuccess() {
        Task task = [SELECT Id, Status, CaseObject__c FROM Task LIMIT 1];
        Depot_Area__c dep = [SELECT Depot__c, Id, Name, Area__c FROM Depot_Area__c LIMIT 1];
        task.TaskUpdate__c = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
        stp_TaskSearch.saveTaskDetails(task.id, task,dep.Id );

        // check updated value for tasks
        task = [SELECT TaskUpdate__c, CaseObject__c FROM Task LIMIT 1];
        system.assertEquals(StarTrack_Constants.WAITING_ON_INVESTIGATOR, task.TaskUpdate__c,
                'stp_TaskSearch_Test.saveTaskDetailsSuccess() : Task update failed');

        // update case failed while updating the task
        Case cse = [SELECT Id, Case_Update__c FROM Case WHERE Id =: task.CaseObject__c LIMIT 1];
        system.assertEquals(StarTrack_Constants.WAITING_ON_INVESTIGATOR, cse.Case_Update__c,
                'stp_TaskSearch_Test.saveTaskDetailsSuccess() : Case update failed');


    }

    /**
     * check for the validation while task update
     */
    @IsTest
    static void saveTaskDetailsValidateCheck() {
        //create a case
        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Case c = TestDataProvider.createCase();
        c.RecordTypeId = pbenquiryRecType;
        c.SuppliedEmail = 'a@q.c';
        insert c;

        // create a task
        Task testTask = TestDataProvider.createTask(c.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.CaseObject__c = c.Id;
        insert testTask;

        // update it with status as Finished, some fields are required
        testTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
        testTask.Bulk_Close__c = StarTrack_Constants.ST_TRUE;
        if (String.isBlank(testTask.Resolution_Code__c)) {
            testTask.Resolution_Code__c = StarTrack_Constants.TASK_RESOLUTION_CODE;
        }
        testTask.Finished_Date__c = Datetime.now();
        update testTask;

        Task retrievedTask = [SELECT Status FROM Task WHERE WhatId =: c.Id];
        Depot_Area__c dep = [SELECT Depot__c, Id, Name, Area__c FROM Depot_Area__c LIMIT 1];

        System.assertEquals(StarTrack_Constants.TASK_STATUS_FINISHED, retrievedTask.Status);

        retrievedTask.status = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
        String msg = stp_TaskSearch.saveTaskDetails(retrievedTask.id, retrievedTask, dep.Id);

        // check for the error message
        system.assert(msg.contains('Task has already been'),
                'stp_TaskSearch_Test.saveTaskDetailsValidateCheck() : expected error message not displayed');

    }


    /**
     * Acknowledge task successfully
     */
    @IsTest
    static void acknowledgeTaskDetailsSuccess() {
        Task task = [SELECT Id, Status, CaseObject__c FROM Task LIMIT 1];
        String strMsg = stp_TaskSearch.acknowledgeTaskDetails(task.Id);

        // null check would be enough
        system.assertEquals('Record acknowledged successfully!', strMsg,
                'stp_TaskSearch_Test.acknowledgeTaskDetailsSuccess() : Record should be saved successfully : ' );
    }

    /**
     * Acknowledge task invalid
     */
    @IsTest
    static void acknowledgeTaskDetailsFail() {
        // create a case
        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Case c = TestDataProvider.createCase();
        c.RecordTypeId = pbenquiryRecType;
        c.SuppliedEmail = 'ab@q.c';
        insert c;

        // create a task
        Task testTask = TestDataProvider.createTask(c.Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.CaseObject__c = c.Id;
        insert testTask;

        // update it with status as Finished, some fields are required
        testTask.Status = StarTrack_Constants.TASK_STATUS_FINISHED;
        testTask.Bulk_Close__c = StarTrack_Constants.ST_TRUE;
        if (String.isBlank(testTask.Resolution_Code__c)) {
            testTask.Resolution_Code__c = StarTrack_Constants.TASK_RESOLUTION_CODE;
        }
        testTask.Finished_Date__c = Datetime.now();
        update testTask;

        Task retrievedTask = [SELECT Status FROM Task WHERE Id =: testTask.Id];
        // make sure the task is a finished one
        System.assertEquals(StarTrack_Constants.TASK_STATUS_FINISHED, retrievedTask.Status);


        boolean isError = false;
        try {
            stp_TaskSearch.acknowledgeTaskDetails(retrievedTask.Id);
        } catch (Exception e) {
            // should thrown error
            isError = true;
        }

        // trying to acknowledge a finished task
        system.assertEquals(true, isError,
                'stp_TaskSearch_Test.acknowledgeTaskDetailsFail() : trying to acknowladge a finished task ');
    }


    /**
     * Acknowledge list of tasks at once, this is the functionality of the Acknowledge button click once select more than once
     * tasks.
     */
    @IsTest
    static void acknowledgeTasksListSuccess() {

        // create a case
        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Case c = TestDataProvider.createCase();
        c.RecordTypeId = pbenquiryRecType;
        c.SuppliedEmail = 'ab@q.c';
        insert c;

        List < Task > tasks = new List < Task > ();
        for (Integer i = 0; i < 10; i++) {
            // create a task
            Task testTask = TestDataProvider.createTask(c.Id, null, 'StarTrack Task');
            testTask.Subject = 'Test' + i;
            testTask.Status = StarTrack_Constants.WAITING_ON_INVESTIGATOR;
            testTask.CaseObject__c = c.Id;
            tasks.add(testTask);
        }
        insert tasks;

        // mimmic as a string
        String tasksString = JSON.serialize(tasks);

        stp_TaskSearch.acknowledgeTasksList(tasksString);

        // retrieve the updated tasks to check the new status
        List < Task > updatedTasks = [SELECT Id, Status FROM Task WHERE CaseObject__c =: c.Id];

        for (Task task: updatedTasks) {
            system.assertEquals(StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED, task.Status,
                    'stp_TaskSearch_Test.acknowledgeTasksListSuccess() : Task must be in status : ' + StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED);
        }


    }

    /**
     * Acknowledge list of tasks at once, this is the functionality of the Acknowledge button click once select more than once
     * tasks. Check for already Acknowledged once
     */
    @IsTest
    static void acknowledgeTasksListFail() {

        // create a case
        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        Case c = TestDataProvider.createCase();
        c.RecordTypeId = pbenquiryRecType;
        c.SuppliedEmail = 'ab@q.c';
        insert c;

        // let's have a tasks list
        List < Task > tasks = new List < Task > ();
        for (Integer i = 0; i < 10; i++) {
            // create a task
            Task testTask = TestDataProvider.createTask(c.Id, null, 'StarTrack Task');
            testTask.Subject = 'Test' + i;
            testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
            testTask.CaseObject__c = c.Id;
            tasks.add(testTask);
        }
        insert tasks;
        // mimicking as string
        String tasksString = JSON.serialize(tasks);

        Boolean isError = false;
        // expected an exception
        try {
            stp_TaskSearch.acknowledgeTasksList(tasksString);
        } catch (Exception e) {
            isError = true;
        }

        // error message should be thrown
        system.assertEquals(true, isError,
                'stp_TaskSearch_Test.acknowledgeTasksListFail() : Error message should thrown as one or more tasks are already acknowledged');
    }


    /**
     * get the task details
     */
    @IsTest
    static void getPostToFeedSuccess() {
        Task task = [SELECT Id, Status, CaseObject__c FROM Task LIMIT 1];
        task.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        String message = stp_TaskSearch.postToFeed(task, 'here is the comment');

        system.assertEquals(true, message.contains('Record saved successfully'),
                'StarTrackPortalTaskSearch.getTaskDetailsSuccess() : Task should be saved');

        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId =: task.id];

        system.assertNotEquals(null, fi,
                'StarTrackPortalTaskSearch.getTaskDetailsSuccess() : Post feed should be successful');

    }



}