/**********************************************************************************
Description: Test class to cover ActivityUtil functionality.
History:
-----------------------------------------------------------------------------------
2016-06-01  Eric.Shen@auspost.com.au Updated to incorporate SMS sending out for case
            and lead creation for SNAP IT process.
2017-12-09  Adrian Recio Included test coverage for work day adjustment method
2018-06-14  TDO-45 : rahul.kapoor@coroma.com.au Refactored comments and indentation,
            added assertEquals and assertNotEquals, added new tests to handle
            send SMS for Star Track Tasks, tests to sendSMS using Mock class.
20.04.2022    SaiSwetha Pingali   Removed snapIt logic as it is no longer required.

***********************************************************************************/
@isTest
private class ActivityUtil_Test {

    @testSetup
    static void setupTestData() {
        //create AusPostSettings__c
        AusPostSettings__c testSettings = TestDataProvider.createAndSaveAusPostSettings('SMS', 'TIBCOSMS');

    }

    /**********************************************************************
    *  Scenario:
    *      Determine the matching workday record based on assigned to field
    ***********************************************************************/
    public static testMethod void workDayAdjustmentTest(){
        //Create test FY
        Fiscal_Year__c testFiscalYear = new Fiscal_Year__c();
        testFiscalYear.Name = '2017';
        insert testFiscalYear;

        //Create test public holiday
        Public_Holiday__c testPublicHoliday = new Public_Holiday__c();
        testPublicHoliday.July__c = 1;
        testPublicHoliday.August__c = 1;
        testPublicHoliday.September__c = 1;
        testPublicHoliday.October__c = 1;
        testPublicHoliday.November__c = 1;
        testPublicHoliday.December__c = 1;
        testPublicHoliday.January__c = 1;
        testPublicHoliday.February__c = 1;
        testPublicHoliday.March__c = 1;
        testPublicHoliday.April__c = 1;
        testPublicHoliday.May__c = 1;
        testPublicHoliday.June__c = 1;
        testPublicHoliday.Fiscal_Year__c = testFiscalYear.Id;
        insert testPublicHoliday;

        //Create test work day adjustment for Inside Sales
        List<Work_Day_Adjustments__c> workDayList = new List<Work_Day_Adjustments__c>();

        Work_Day_Adjustments__c testWorkDay = new Work_Day_Adjustments__c();
        testWorkDay.Sales_Team__c = 'Holding Sales Team';
        testWorkDay.Role__c = 'Inside Sales';
        testWorkDay.fiscalYear__c = testFiscalYear.Id;
        testWorkDay.holiday__c = testPublicHoliday.Id;
        testWorkDay.OwnerId = UserInfo.getUserId();
        testWorkDay.Current_Role__c = true;
        workDayList.add(testWorkDay);

        //Create test work day adjustment for Key Accounts
        Work_Day_Adjustments__c testWorkDay2 = new Work_Day_Adjustments__c();
        testWorkDay2.Sales_Team__c = 'Holding Sales Team';
        testWorkDay2.Role__c = 'Key Accounts';
        testWorkDay2.fiscalYear__c = testFiscalYear.Id;
        testWorkDay2.holiday__c = testPublicHoliday.Id;
        testWorkDay2.OwnerId = UserInfo.getUserId();
        testWorkDay2.Current_Role__c = true;
        workDayList.add(testWorkDay2);

        //Create test sales segment reference with Business Hubs
        List<Sales_Segment_Reference__c> salesSegRefList = new List<Sales_Segment_Reference__c>();

        Sales_Segment_Reference__c testSalesSegRef = new Sales_Segment_Reference__c();
        testSalesSegRef.Sales_Segment__c = 'Business Hubs';
        testSalesSegRef.Sales_Director__c = UserInfo.getUserId();
        salesSegRefList.add(testSalesSegRef);

        //Create test sales segment reference with Business Sales NSW 1
        Sales_Segment_Reference__c testSalesSegRef2 = new Sales_Segment_Reference__c();
        testSalesSegRef2.Sales_Segment__c = 'Business Sales NSW 1';
        testSalesSegRef2.Sales_Director__c = UserInfo.getUserId();
        salesSegRefList.add(testSalesSegRef2);

        insert salesSegRefList;

        //Create an Account
        List<Account> accList = TestDataProvider.createAccount('AccountName',1);
        insert accList;

        //Create a Task
        Task testTask = TestDataProvider.createTask(accList[0].Id, null, 'StarTrack Task');
        testTask.RecordTypeId = ActivityUtil.tRecTypeMap.get('Sales Task').getRecordTypeId();
        testTask.Subject = 'Test1';
        testTask.Type = 'Phone Call';
        testTask.Status = 'Completed';
        testTask.Category__c = 'Sales';
        testTask.OwnerId = Userinfo.getUserId();

        //Create a Event
        Event testEvent = new Event();
        testEvent.RecordtypeId = ActivityUtil.eRecTypeMap.get('Sales Event').getRecordTypeId();
        testEvent.Type = 'Face to Face Meeting';
        testEvent.Status__c = 'Completed';
        testEvent.Category__c = 'Sales';
        testEvent.WhatId = testWorkDay.Id;
        testEvent.ActivityDate = Date.today();
        testEvent.DurationInMinutes = 10;
        testEvent.ActivityDateTime = Date.today();

        test.startTest();
            insert workDayList;
            insert testTask;
            insert testEvent;
        test.stopTest();
        
    }

    /**********************************************************************
    *  Scenario:
    *      Test to check if the last activity date from event is updated.
    ***********************************************************************/
    @isTest
    static void testUpdateLastActivityFromEvent() {
        //Create Accounts.
        List<Account> accounts = TestDataProvider.createAccount('AccountName',1);
        insert accounts;

        //Create an Event.
        Event e = new Event(WhatId = accounts[0].Id, ActivityDate = Date.today(), DurationInMinutes = 10, ActivityDateTime = Date.today());
        insert e;

        //Create a Task.
        Task testTask = TestDataProvider.createTask(accounts[0].Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        insert testTask;

        List<Event> events = new List<Event>();
        events.add(e);

        Test.startTest();
            ActivityUtil.updateLastActivityFromEvent(events);
        Test.stopTest();

        Event retrievedEvent = [SELECT Id, ActivityDate
                                FROM Event
                                WHERE Id =: e.Id];
        Account retrievedAcc = [SELECT Id, Last_Activity_Date__c
                                FROM Account
                                WHERE Id =: accounts[0].Id];

        System.assertEquals(retrievedEvent.ActivityDate, retrievedAcc.Last_Activity_Date__c,
                'ActivityUtil_Test_testUpdateLastActivityFromEvent : Last Activity From Event is updated.');

    }

    /***********************************************************************
    *  Scenario:
    *      Test to set date time when Task is updated to Acknowledged Status.
    ************************************************************************/
    @isTest
    static void testSetStatusDate_acknowledged() {

        List<Account> accounts = TestDataProvider.createAccount('AccountName',1);
        insert accounts;

        Event e = new Event(WhatId = accounts[0].Id, ActivityDate = Date.today(), DurationInMinutes = 10, ActivityDateTime = Date.today());
        insert e;

        Task testTask = TestDataProvider.createTask(accounts[0].Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        insert testTask;

        List<Id> tasks = new List<Id>();
        tasks.add(testTask.Id);

        Test.startTest();
            ActivityUtil.setStatusDate(tasks);
        Test.stopTest();

        Task t = [SELECT Id, Acknowledged_Date__c
                  FROM Task
                  WHERE Id =: testTask.Id];

        System.assertNotEquals(null,t.Acknowledged_Date__c,
                'ActivityUtil_Test_testSetStatusDate_acknowledged : Acknowledged Date is updated.');

    }

    /*******************************************************************
    *  Scenario:
    *      Test to set date time when Task is updated to Waiting Status.
    ********************************************************************/
    @isTest
    static void testSetStatusDate_waiting() {

        List<Account> accounts = TestDataProvider.createAccount('AccountName',1);
        insert accounts;

        Event e = new Event(WhatId = accounts[0].Id, ActivityDate = Date.today(), DurationInMinutes = 10, ActivityDateTime = Date.today());
        insert e;

        Task testTask = TestDataProvider.createTask(accounts[0].Id, null, 'StarTrack Task');
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_WAITING;
        insert testTask;

        List<Id> tasks = new List<Id>();
        tasks.add(testTask.Id);

        Test.startTest();
            ActivityUtil.setStatusDate(tasks);
        Test.stopTest();

        Task t = [SELECT Id, Waiting_for_Operations_Date__c
                  FROM Task
                  WHERE Id =: testTask.Id];

        System.assertNotEquals(null,t.Waiting_for_Operations_Date__c,
                'ActivityUtil_Test_testSetStatusDate_acknowledged : Waiting for Operations Date is updated.');

    }

    /*******************************************************************
    *  Scenario:
    *      Test to set date time when Task is updated to finished Status.
    ********************************************************************/
    @isTest
    static void testSetStatusDate_finished() {
        BusinessHours bh = [SELECT id
                            FROM businesshours
                            WHERE IsDefault=true];

        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();
        //Create a Case.
        Case testCase = TestDataProvider.createCase();
        testCase.RecordTypeId = pbenquiryRecType;
        testCase.SuppliedEmail = 'a@q.c';
        testCase.BusinessHoursId = bh.Id;

        insert testCase;

        ID recordTypeID = [SELECT Id
                           FROM RecordType
                           WHERE SObjectType = 'Task'
                           AND DeveloperName = 'SSSWSMS'
                           LIMIT 1].Id;

        //Create a Task.
        Task testTask = TestDataProvider.createTask(testCase.Id, null, 'StarTrack Task');
        testTask.RecordTypeID = recordTypeID;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.CaseObject__c = testCase.Id;
        // testTask.CreatedDate = Date.today();
        testTask.Finished_Date__c = Date.today();

        insert testTask;

        List<Id> tasks = new List<Id>();
        tasks.add(testTask.Id);

        Test.startTest();
            ActivityUtil.setStatusDate(tasks);
        Test.stopTest();

        Task t = [SELECT Id, Finished_Date__c
                  FROM Task
                  WHERE Id =: testTask.Id];

        System.assertNotEquals(null,t.Finished_Date__c,
                'ActivityUtil_Test_testSetStatusDate_finished : Finished Date is updated.');
    }

    /*******************************************************************
    *  Scenario:
    *      Test to prepare SMS for tasks.
    ********************************************************************/
    @isTest
    static void testPrepareSMSForTasks() {
        Id pbenquiryRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Pickup Booking Enquiry').getRecordTypeId();

        //Create a Case.
        Case testCase = TestDataProvider.createCase();
        testCase.RecordTypeId = pbenquiryRecType;
        testCase.SuppliedEmail = 'a@q.c';

        INSERT testCase;

        ID recordTypeID = [SELECT Id
                           FROM RecordType
                           WHERE SObjectType = 'Task'
                           AND DeveloperName = 'SSSWSMS'
                           LIMIT 1].Id;

        //Create a Task.
        Task testTask = TestDataProvider.createTask(testCase.Id, null, 'StarTrack Task');
        testTask.RecordTypeID = recordTypeID;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.CaseObject__c = testCase.Id;

        INSERT testTask;

        List<Task> tasks = new List<Task>();
        tasks.add(testTask);

        Test.startTest();
            ActivityUtil.prepareSMSForTasks(tasks);
        Test.stopTest();

        Task t = [SELECT Id, SMSDateSent__c,SMSError__c
                  FROM Task
                  WHERE Id =: testTask.Id];

        System.assertEquals(null,t.SMSDateSent__c,
                'ActivityUtil_Test_testSetStatusDate_finished : SMS Date Sent is not updated.');
    }

    /*******************************************************************
    *  Scenario:
    *      Test to send SMS for tasks in future.
    ********************************************************************/
    @isTest
    static void testFutureSendSMSForTasks() {
        //Create an Account.
        List<Account> accounts = TestDataProvider.createAccount('AccountName',1);
        insert accounts;

        //Create a Contact.
        Contact cont = TestDataProvider.createTestContact();
        cont.MobilePhone = '1234';
        insert cont;

        ID recordTypeID = [SELECT Id
                           FROM RecordType
                           WHERE SObjectType = 'Task'
                           AND DeveloperName = 'SSSWSMS'
                           LIMIT 1].Id;

        //Create a Task.
        Task testTask = TestDataProvider.createTask(accounts[0].Id, cont.Id, 'StarTrack Task');
        testTask.RecordTypeID = recordTypeID;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;

        INSERT testTask;

        List<Task> tasks = new List<Task>();
        tasks.add(testTask);

        Test.startTest();
            ActivityUtil.sendSMSForTasks(tasks);
        Test.stopTest();

        Task t = [SELECT Id, SMSDateSent__c,SMSError__c
                  FROM Task
                  WHERE Id =: testTask.Id];

        System.assertEquals(null,t.SMSDateSent__c,
                'ActivityUtil_Test_testSetStatusDate_finished : SMS Date Sent is not updated.');
    }

    /**************************************************************************************
    *  Scenario:
    *      Test to send SMS for tasks in future using WebServiceCalloutMockTest.
    *      TDO_TODO: Test.isRunningTest() if condition in TIBCOSMSActivityEvent
    *      do not allow the WebServiceCalloutMockTest class to return a response
    *      with code='ESB-SMS-10000' to test the Success result code. Removing
    *      Test.isRunningTest() can be high risk as may be referred by related code.
    *      sendSMS callout can be tested for Success in future scope using thia Mock class.
    ***************************************************************************************/
    @isTest
    static void testFutureSendSMSForTasksWithMock() {
        //Create an Account.
        List<Account> accounts = TestDataProvider.createAccount('AccountName',1);
        insert accounts;

        //Create a Contact.
        Contact cont = TestDataProvider.createTestContact();
        cont.MobilePhone = '1234';
        insert cont;

        ID recordTypeID = [SELECT Id
                           FROM RecordType
                           WHERE SObjectType = 'Task'
                           AND DeveloperName = 'SSSWSMS'
                           LIMIT 1].Id;

        //Create a Task.
        Task testTask = TestDataProvider.createTask(accounts[0].Id, cont.Id, 'StarTrack Task');
        testTask.RecordTypeID = recordTypeID;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;

        INSERT testTask;

        List<Task> tasks = new List<Task>();
        tasks.add(testTask);

        Test.startTest();
        //Set mock callout class. This causes a fake response to be generated
            //Test.setMock(WebServiceMock.class, new WebServiceCalloutMockTest());
            ActivityUtil.sendSMSForTasks(tasks);
        Test.stopTest();
    }

    /*******************************************************************
    *  Scenario:
    *      Test to send SMS Star Track tasks in future.
    ********************************************************************/
    @isTest
    static void testFutureSendSMSForStarTrackTasks() {
        //Create an Account.
        List<Account> accounts = TestDataProvider.createAccount('AccountName',1);
        insert accounts;

        //Create a Contact.
        Contact cont = TestDataProvider.createTestContact();
        cont.MobilePhone = '1234';
        insert cont;

        ID recordTypeID = [SELECT Id
                           FROM RecordType
                           WHERE SObjectType = 'Task'
                           AND DeveloperName = 'StarTrack_SMS'
                           LIMIT 1].Id;

        //Create a Task.
        Task testTask = TestDataProvider.createTask(accounts[0].Id, cont.Id, 'StarTrack Task');
        testTask.RecordTypeID = recordTypeID;
        testTask.Subject = 'Test';
        testTask.Status = StarTrack_Constants.TASK_STATUS_ACKNOWLEDGED;
        testTask.Case_Phone__c='123456789';

        INSERT testTask;

        List<Task> tasks = new List<Task>();
        tasks.add(testTask);

        Test.startTest();
            ActivityUtil.sendSMSForStarTrackTasks(tasks);
        Test.stopTest();

        Task t = [SELECT Id, SMSDateSent__c,SMSError__c
                  FROM Task
                  WHERE Id =: testTask.Id];

        System.assertEquals(null,t.SMSDateSent__c,
                'ActivityUtil_Test_testSetStatusDate_finished : SMS Date Sent is not updated.');
    }

    /*******************************************************************
    *  Scenario:
    *      Test for the Last Activity Date maintenance code.
    ********************************************************************/
    private static testMethod void testUpdateLastActivity(){
        //Test against Organisation
        Id testOrg = [SELECT id
                      FROM RecordType
                      WHERE Name='Organisation'
                      LIMIT 1].id;

        //Set Last activity to 10 days ago
        Date testDate = Date.today().addDays(-10);

        //Create an Organisation
        Account testAccount = new Account(Name='testorg', RecordTypeId = testOrg, Last_Activity_Date__c = testDate);
        insert testAccount;

        //First test task scenarios

        //Add an open task for today
        Task testTask = new Task(ActivityDate = date.today().addDays(-5), WhatId = testAccount.Id, Subject = 'test', Status='Not Started');
        insert testTask;

        //Check account last activity date field
        Date lastDate = [SELECT id, Last_Activity_Date__c
                         FROM Account
                         WHERE id =:testAccount.Id
                         LIMIT 1].Last_Activity_Date__c;

        System.assertEquals(testDate,lastDate,
                'ActivityUtil_Test_testUpdateLastActivity : Both Dates are equal.');

        //Close task and trigger should set last activity date field to equal the variable
        testTask.Status = 'Completed';
        update testTask;

        lastDate = [SELECT id, Last_Activity_Date__c
                    FROM Account
                    WHERE id =:testAccount.Id
                    LIMIT 1].Last_Activity_Date__c;

        System.assertNotEquals(testDate,lastDate,
                'ActivityUtil_Test_testUpdateLastActivity : Both Dates are not equal.');

        //Now test event scenarios.

        //Current last activity is 5 days ago. add an event for more than 5 days ago
        Event testEvent = new Event(ActivityDateTime = datetime.now().addDays(-10), DurationInMinutes = 60, WhatId = testAccount.Id, Subject='test event');
        insert testEvent;

        lastDate = [SELECT id, Last_Activity_Date__c
                    FROM Account
                    WHERE id =:testAccount.Id
                    LIMIT 1].Last_Activity_Date__c;

        System.assertEquals(date.today().addDays(-5),lastDate,
                'ActivityUtil_Test_testUpdateLastActivity : Last Activity Date is not changed.');

        //Move the event date to more recent than the current Last Activity Date
        testEvent.ActivityDateTime = datetime.now();
        update testEvent;

        lastDate = [SELECT id, Last_Activity_Date__c
                    FROM Account
                    WHERE id =:testAccount.Id
                    LIMIT 1].Last_Activity_Date__c;

        System.assertEquals(date.today(),lastDate,
                'ActivityUtil_Test_testUpdateLastActivity : Last Activity Date is updated to event date.');
    }

    /*******************************************************************
     *  Scenario:
     *      Test to prepare and send Sms for Tasks.
     ********************************************************************/
    private static testmethod void testPrepareAndSendSms () {
        //Test against Organisation
        Id testOrg = [SELECT id
                      FROM RecordType
                      WHERE Name='Organisation'
                      LIMIT 1].id;

        //Set Last activity to 10 days ago
        Date testDate = Date.today().addDays(-10);

        //Create an Organisation
        Account testAccount = new Account(Name='testorg', RecordTypeId = testOrg, Last_Activity_Date__c = testDate);
        insert testAccount;

        //Create a contact
        Contact testContact = new Contact();
        testContact.FirstName = 'First';
        testContact.LastName = 'Last';
        testContact.MailingCity = 'Melbourne';
        testContact.MailingState = 'VIC';
        testContact.MailingStreet = '673 bourke street';
        testContact.MailingPostalCode = '3000';
        testContact.Email = 'example@email.com';
        testContact.AccountId = testAccount.Id;
        insert testContact;

        ID recordTypeID;
        for(RecordType rt : [SELECT Id
                             FROM RecordType
                             WHERE SObjectType = 'Task'
                             AND DeveloperName = 'SSSWSMS'
                             LIMIT 1]){
            recordTypeID = rt.Id;
        }

        //Add an open task for today
        Task testTask = new Task(ActivityDate = date.today().addDays(-5), WhatId = testAccount.Id, WhoId = testContact.Id, Subject = 'test', Status='Not Started');
        if (recordTypeID != null) testTask.RecordTypeId = recordTypeID;
        insert testTask;

        ActivityUtil.prepareSMSForTasks(new List<Task>{testTask});
        ActivityUtil.sendSMSForTasks(new List<Task>{testTask});
    }

    /*****************************************************
    *  Scenario:
    *      Method to test populates lead first activity of sales person
    ******************************************************/
    @isTest
    static void testupdateLeadFirstActivityFromTask(){
        Profile bgBaseProfile = [SELECT Id FROM Profile WHERE Name = 'BG Base'];

        User bgSalesUser = new User(
            Alias = 'bgcore', Email = 'bgsale9009@auspost.com.au',
            EmailEncodingKey = 'UTF-8', LastName = 'bgsalesLname', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = bgBaseProfile.Id, isActive = true,
            TimeZoneSidKey = 'America/Los_Angeles', UserName = 'bgsale9009@auspost.com.au',
            EmployeeNumber = '12009'
        );
        insert bgSalesUser;

        String bgcorePermissionSetId = [SELECT Id FROM PermissionSet WHERE Name='BG_Core' LIMIT 1].Id ;
        System.runAs(new User(Id = Userinfo.getUserId())) {
            PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = bgcorePermissionSetId, AssigneeId = bgSalesUser.Id);
            insert psa;
            Group amGroup = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName = 'Account_Managers' LIMIT 1];
            GroupMember grpMember = new GroupMember(GroupId = amGroup.id,UserOrGroupId = bgSalesUser.id);
            insert grpMember;
        }

        Lead l = new Lead();
        l.firstName = 'testFirstName';
        l.lastName = 'testLastName';
        l.email = 'test@example.com';
        l.phone = '0400809987';
        l.leadsource = 'email';
        l.status = 'In Progress';
        l.recordTypeId = Schema.sObjectType.lead.getRecordTypeInfosByName().get('BG_Standard').getRecordTypeId();
        l.ownerid = bgSalesUser.Id;
        insert l;
        Test.startTest();
        system.runAs(bgSalesUser){
            Task testTask = TestDataProvider.createTask(null, l.id, 'Sales_Task');
            testTask.Type = 'Phone Call';
            testTask.Status = 'Completed';
            insert testTask;
        }
        Test.stopTest();
        system.assert([SELECT First_Activity_of_Sales__c From Lead WHERE ID = :l.Id].First_Activity_of_Sales__c != Null, 'First Activity of Sales should be populated');
    }
}