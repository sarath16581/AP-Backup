/**
 * @description
 * Test class for StarTrackSupportCasePriorityModule
 * @author Madhusudhan
 * @date 2021-06-17
 * @group Tests
 * @domain StarTrack
 * @changelog
 */
@IsTest
private class StarTrackSupportCasePriorityModule_Test {
    /**
     * Test:
     * When a case inserted set the priority to High if it is Consignment Next Flight.
     */
    @IsTest
    private static void testEnsureBeforeInsertUpdatesCasePriority() {
        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);

        Set<Id> articlesIds = new Set<Id>{ articles[0].Id };

        // next flight Consignment
        articles[0].Product_Group__c = 'Next Flight';

        // article and recordType on case
        cases[0].ArticleTest__c = articles[0].Id;
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

        // =====================================
        // Stubbing
        // =====================================
        ArticlesSelector mockArticleSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockArticleSelector.selectById((Set<Id>) articlesIds))
            .thenReturn(new Map<Id, Article__c>(articles));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        StarTrackSupportCasePriorityModule module = StarTrackSupportCasePriorityModule.newInstance();

        module.onBeforeInsert(cases, uow);

        Test.stopTest();

        // make sure the method behaved
        ((ArticlesSelector) MockUtility.Mocks.verify(mockArticleSelector, 1)).selectById(articlesIds);

        // make sure fields were updated correctly
        System.assertEquals('High', cases[0].Priority, 'Expected Priority to be set High on case');
    }

    /**
     * Test:
     * When a case updated, set the priority to High if it is Consignment Next Flight.
     */
    @IsTest
    private static void testEnsureBeforeUpdateUpdatesCasePriority() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        List<Case> oldCases = new List<Case>{ cases[0].clone(true) };
        Set<Id> articlesIds = new Set<Id>{ articles[0].Id };

        // next flight Consignment
        articles[0].Product_Group__c = 'Next Flight';

        // article and recordType on case
        cases[0].ArticleTest__c = articles[0].Id;
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

        // =====================================
        // Stubbing
        // =====================================
        ArticlesSelector mockArticleSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockArticleSelector.selectById((Set<Id>) articlesIds))
            .thenReturn(new Map<Id, Article__c>(articles));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        StarTrackSupportCasePriorityModule module = StarTrackSupportCasePriorityModule.newInstance();

        module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);
        Test.stopTest();

        // make sure the method behaved
        ((ArticlesSelector) MockUtility.Mocks.verify(mockArticleSelector, 1)).selectById(articlesIds);

        // make sure fields were updated correctly
        System.assertEquals('High', cases[0].Priority, 'Expected Priority to be set High on case');
    }

    /**
     * Test:
     * When a Delivery Enquiry case is inserted, set the priority on related tasks
     */
    @IsTest
    private static void testEnsureAfterInsertUpdatesDeliveryCaseTaskPriority() {
        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);

        Set<Id> articlesIds = new Set<Id>{ articles[0].Id };

        // next flight Consignment
        articles[0].Product_Group__c = 'Next Flight';

        // article and recordType on case
        cases[0].ArticleTest__c = articles[0].Id;
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

        // =====================================
        // Stubbing
        // =====================================
        ArticlesSelector mockArticleSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockArticleSelector.selectById((Set<Id>) articlesIds))
            .thenReturn(new Map<Id, Article__c>(articles));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        StarTrackSupportCasePriorityModule module = StarTrackSupportCasePriorityModule.newInstance();

        module.onAfterInsert(cases, uow);

        Test.stopTest();

        // make sure the method behaved
        ((ArticlesSelector) MockUtility.Mocks.verify(mockArticleSelector, 1)).selectById(articlesIds);
    }

    /**
     * Test:
     * When case priority is updated, set the priority on related tasks
     */
    @IsTest
    private static void testEnsureAfterUpdateUpdatesTaskPriority() {
        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        List<Case> oldCases = new List<Case>{ cases[0].clone(true) };
        List<Task> tasks = ApplicationTestDataFactory.getTasks(1, cases[0].Id, true);

        // next flight Consignment
        articles[0].Product_Group__c = 'Next Flight';

        // article and recordType on case
        cases[0].ArticleTest__c = articles[0].Id;
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
        oldCases[0].Priority = 'Normal';
        cases[0].Priority = 'Critical';

        // =====================================
        // Stubbing
        // =====================================
        TasksSelector mockTaskSelector = (TasksSelector) MockUtility.mockSelector(TasksSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockTaskSelector.selectByWhatId(new Set<Id>{ cases[0].Id }))
            .thenReturn(new Map<Id, Task>(tasks));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        StarTrackSupportCasePriorityModule module = StarTrackSupportCasePriorityModule.newInstance();

        module.onAfterUpdate(cases, new Map<Id, Case>(oldCases), uow);

        Test.stopTest();

        // make sure the method behaved
        ((TasksSelector) MockUtility.Mocks.verify(mockTaskSelector, 1)).selectByWhatId(new Set<Id>{ cases[0].Id });
        // make sure field updated correctly
        System.assertEquals(cases[0].Priority, tasks[0].Priority, 'Expected Priority to be set Task');
    }

    /**
     * Test:
     * When a priority is updated on a Delivery Enquiry case, set the priority on related tasks
     */
    @IsTest
    private static void testEnsureAfterUpdateUpdatesDeliveryCaseTaskPriority() {
        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseTriggerHandler2.getUnitOfWorkSObjectTypes());
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);
        Set<Id> articlesIds = new Set<Id>{ articles[0].Id };
        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        List<Case> oldCases = new List<Case>{ cases[0].clone(true) };
        List<Task> tasks = ApplicationTestDataFactory.getTasks(1, cases[0].Id, true);

        // next flight Consignment
        articles[0].Product_Group__c = 'Next Flight';

        // article and recordType on case
        cases[0].ArticleTest__c = articles[0].Id;
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
        oldCases[0].Priority = 'Critical';
        cases[0].Priority = 'Critical';

        // =====================================
        // Stubbing
        // =====================================
        ArticlesSelector mockArticleSelector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);
        TasksSelector mockTaskSelector = (TasksSelector) MockUtility.mockSelector(TasksSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockArticleSelector.selectById((Set<Id>) articlesIds))
            .thenReturn(new Map<Id, Article__c>(articles));
        MockUtility.Mocks.when(mockTaskSelector.selectByWhatId(new Set<Id>{ cases[0].Id }))
            .thenReturn(new Map<Id, Task>(tasks));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        StarTrackSupportCasePriorityModule module = StarTrackSupportCasePriorityModule.newInstance();

        module.onAfterUpdate(cases, new Map<Id, Case>(oldCases), uow);

        Test.stopTest();

        // make sure the method behaved
        ((ArticlesSelector) MockUtility.Mocks.verify(mockArticleSelector, 1)).selectById(articlesIds);
        ((TasksSelector) MockUtility.Mocks.verify(mockTaskSelector, 1)).selectByWhatId(new Set<Id>{ cases[0].Id });
        // make sure field updated correctly
        System.assertEquals(cases[0].Priority, tasks[0].Priority, 'Expected Priority to be set Task');
    }

    /**
     * Test: Integration Scenario
     * When a priority is updated on a Delivery Enquiry case, set the priority on related tasks
     */
    @IsTest
    private static void testEnsureAfterUpdateUpdatesDeliveryCaseTaskPriorityIntegration() {
        // =====================================
        // Data Preparation
        // =====================================
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, false);
        // next flight Consignment
        articles[0].Product_Group__c = 'Next Flight';
        insert articles;

        List<Case> cases = ApplicationTestDataFactory.getCases(2, false);
        cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
        cases[0].Priority = 'High';
        cases[1].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;
        cases[1].Priority = 'High';
        insert cases;
        List<Task> tasks = ApplicationTestDataFactory.getTasks(1, cases[0].Id, false);
        List<Task> normalTasks = ApplicationTestDataFactory.getTasks(1, cases[1].Id, false);
        insert tasks;
        insert normalTasks;

        // update article and priority on case
        cases[0].ArticleTest__c = articles[0].Id;
        cases[0].Priority = 'High';
        cases[1].ArticleTest__c = articles[1].Id;
        cases[1].Priority = 'High';

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        update cases;

        Test.stopTest();

        // make sure field updated correctly
        List<Task> updatedTasks = [SELECT Id, Priority FROM Task WHERE Id = :tasks[0].Id];
        System.assertEquals('High', updatedTasks[0].Priority, 'Expected Priority to be set Task');
    }
}