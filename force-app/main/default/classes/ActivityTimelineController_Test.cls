/**
 * This apex class is test class for ActivityTimelineController
 *
 *
 * @changelog:
 * 2022-10-05 Steve L - Created
*/

@IsTest
private class ActivityTimelineController_Test {
    /**
     * test getAllActivities method from ActivityTimelineController, expect to result a list of ActivityTimelineController.RecordActivity that is made up of the Tasks and Event selected
     */
    @IsTest
    private static void testGetAllActivities() {
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
        List<User> users = ApplicationTestDataFactory.getUsers(1,true);
        List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
        accounts[0].OwnerId = users[0].Id;

        List<Task> tasks = new List<Task>{ApplicationTestDataFactory.getTasks(1, accounts[0].Id,  true)[0]};
        tasks[0].OwnerId = users[0].Id;
        tasks[0].Subject = 'test sub';
        tasks[0].Status = 'Acknowledged';
        tasks[0].Type = 'Phone Call';

        List<Event> events = new List<Event>{ApplicationTestDataFactory.getEvents(1, accounts[0].Id,  true)[0]};
        events[0].OwnerId = users[0].Id;
        events[0].Subject = 'test event sub';

        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
        AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
        TasksSelector tasksSelector = (TasksSelector)MockUtility.mockSelector(TasksSelector.class);
        EventsSelector eventsSelector = (EventsSelector)MockUtility.mockSelector(EventsSelector.class);
        // set up our responses
        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(accountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>(accounts));
        MockUtility.Mocks.when(tasksSelector.selectByWhatId((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id,Task>(tasks));
        MockUtility.Mocks.when(eventsSelector.selectByWhatId((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,Event>(events));
        MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        String recordId = accounts[0].Id;
        String sObjectName = 'Account';
        Integer recordLimit = 3;
        Integer offsetLimit = 0;
        List<ActivityTimelineController.RecordActivity> results = ActivityTimelineController.getAllActivities(recordId, sObjectName, recordLimit, offsetLimit);
        System.assertEquals(2, results.size(), 'Expected to return 2 results');
        Boolean assertResult = false;
        for (ActivityTimelineController.RecordActivity result : results) {
            if (!String.isEmpty(result.type) && result.type.containsIgnoreCase(ActivityTimelineController.CALL_SUBTYPE)) {
                System.assertEquals(tasks[0].Id,result.actId);
                System.assertEquals('Acknowledged',result.status);
                System.assertEquals('test sub',result.title);
                assertResult = true;
            } else if (!String.isEmpty(result.subType) && result.subType.containsIgnoreCase(ActivityTimelineController.EVENT_SUBTYPE)) {
                System.assertEquals(events[0].Id,result.actId);
                System.assertEquals('test event sub',result.title);
                assertResult = true;
            }
        }
        System.assert(assertResult, 'Expected the result to be generated from the Task and Event lists');
        Test.stopTest();

    }
}