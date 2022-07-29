/***
 * @description
 * Test class for ApplicationUnitOfWorkAsyncEventHandler
 *
 * @author Nathan Franklin
 * @date 2020-09-01
 * @group Tests
 * @domain Core
 * @changelog
 */
@IsTest
private class ApplicationUnitOfWorkAsyncEvent_Test {

	/**
	 * Scenario:
	 * When the platform event handler fires, this will ensure the our worker is enqueued and executed
	 */
	@IsTest
	private static void testDispatchEnqueuesAndExecutesAsyncWorker() {

		// =====================================
		// Data Preparation
		// =====================================
		List<AsyncWorkerEvent__e> asyncWorkerEvents = ApplicationTestDataFactoryUOW.getAsyncWorkerEvents(4, 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1');

		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[0].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		//asyncWorkerEvents[0].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 1});

		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[1].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[1].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[1].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		//asyncWorkerEvents[1].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 2});

		asyncWorkerEvents[2].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[2].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[2].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[2].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[2].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		//asyncWorkerEvents[2].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 3});

		asyncWorkerEvents[3].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[3].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[3].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[3].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[3].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		//asyncWorkerEvents[3].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 4});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationDatabase.getInstance().eventPublish(asyncWorkerEvents);

		Test.getEventBus().deliver();

		Test.stopTest();

		System.assertEquals(new List<String>{'MyAsyncWorker1', 'MyAsyncWorker1', 'MyAsyncWorker1', 'MyAsyncWorker1'}, ApplicationUnitOfWorkTestUtility.asyncStack, 'MyAsyncWorker1 was not invoked as expected');
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected only 1 group');

		List<ExceptionLog__c> logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

		Integer remainingWorkerCount = [SELECT COUNT() FROM AsyncWorker__c];
		System.assertEquals(0, remainingWorkerCount, 'Expected all worker records to be deleted');
	}

	/**
	 * Scenario:
	 * When the platform event handler fires, this will ensure the our workers are queued in the correct number of groups and are executed accordingly
	 * NOTE: Execution may not be sequential
	 */
	@IsTest
	private static void testDispatchCorrectlyGroupsAndBreaksFlowOnceMaximumsAreReachedIntegration() {

		// =====================================
		// Data Preparation
		// =====================================

		// maximum number of workers allowed in each group
		ApplicationUnitOfWorkAsyncEventHandler.testClassMaxGroupedWorkers = 3;

		// setup our maximum number of queueables that can be invoked in a single transaction
		ApplicationUnitOfWorkAsyncEventHandler.testClassMaxAsyncQueueableOverride = 3;

		List<AsyncWorkerEvent__e> asyncWorkerEvents = ApplicationTestDataFactoryUOW.getAsyncWorkerEvents(10, 'ApplicationUnitOfWorkTestUtility.AsyncWorker1');

		// ================
		// Group 1
		// ================
		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[0].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		asyncWorkerEvents[0].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 1});

		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[1].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[1].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[1].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker2';
		asyncWorkerEvents[1].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 2});

		// ================
		// Group 2
		// ================
		asyncWorkerEvents[2].SObjectTypeGroup__c = 'Contact';
		asyncWorkerEvents[2].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[2].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[2].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker3';
		asyncWorkerEvents[2].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 3});

		// ================
		// Group 3
		// ================
		asyncWorkerEvents[3].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[3].UserId__c = '005000000000001';
		asyncWorkerEvents[3].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[3].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[3].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		asyncWorkerEvents[3].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 4});

		asyncWorkerEvents[4].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[4].UserId__c = '005000000000001';
		asyncWorkerEvents[4].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[4].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[4].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1a';
		asyncWorkerEvents[4].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 5});

		asyncWorkerEvents[5].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[5].UserId__c = '005000000000001';
		asyncWorkerEvents[5].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[5].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[5].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		asyncWorkerEvents[5].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 6});
		//Note with ApplicationUnitOfWorkAsyncEventHandler.testClassMaxGroupedWorkers being 3, the next worker will start a new group
		// ================
		// Group 4
		// ================
		asyncWorkerEvents[6].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[6].UserId__c = '005000000000001';
		asyncWorkerEvents[6].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[6].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[6].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		asyncWorkerEvents[6].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 7});

		// ================
		// Group 5
		// ================
		asyncWorkerEvents[7].SObjectTypeGroup__c = 'Contact';
		asyncWorkerEvents[7].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[7].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[7].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[7].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker3';
		asyncWorkerEvents[7].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 8});

		asyncWorkerEvents[8].SObjectTypeGroup__c = 'Contact';
		asyncWorkerEvents[8].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[8].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[8].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[8].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker3';
		asyncWorkerEvents[8].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 9});

		// ================
		// Group 6
		// ================
		asyncWorkerEvents[9].SObjectTypeGroup__c = 'Account';
		asyncWorkerEvents[9].UserId__c = UserInfo.getUserId();
		asyncWorkerEvents[9].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerEvents[9].CurrentStack__c = 'TheStack';
		asyncWorkerEvents[9].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		asyncWorkerEvents[9].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 10});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationDatabase.getInstance().eventPublish(asyncWorkerEvents);

		Test.getEventBus().deliver();

		// A total of 3 queueables should have been queued given the value of ApplicationUnitOfWorkAsyncEventHandler.testClassMaxAsyncQueueableOverride above
		// NOTE: there will be 3 queueables worth of work left over that wasn't queued in this
		System.assertEquals(3, [SELECT COUNT() FROM AsyncApexJob], 'The groups were not successfully sliced');

		// The above should result in 6 out of 10 platform event deliveries
		// this is because of the the ApplicationUnitOfWorkAsyncEventHandler.testClassMaxGroupedWorkers ApplicationUnitOfWorkAsyncEventHandler.testClassMaxAsyncQueueableOverride settings
		System.assertEquals(6, [SELECT Position FROM EventBusSubscriber WHERE Topic='AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position, 'Expected tip to be at position 6');

		List<ExceptionLog__c> logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

		// make sure the created async workers have been created correctly
		Integer asyncWorkerRecordCount = [SELECT COUNT() FROM AsyncWorker__c];
		System.assertEquals(6, asyncWorkerRecordCount, 'Expect transaction boundry');

		Test.getEventBus().deliver();

		// all 10 workers should exist now
		asyncWorkerRecordCount = [SELECT COUNT() FROM AsyncWorker__c];
		System.assertEquals(10, asyncWorkerRecordCount, 'Expected all worker records to be created');

		// process the queueables on the buffer
		Test.stopTest();

		// make sure no error occurs during the execution
		logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

		// make sure only 6 workers were processed
		System.assertEquals(10, ApplicationUnitOfWorkTestUtility.asyncWorkerCount, 'Incorrect number of asyncWorkersInvoked');

		// check workers were called correct number of times
		List<String> executionFlow = new List<String>{
				'MyAsyncWorker1',
				'MyAsyncWorker2',
				'MyAsyncWorker3',
				'MyAsyncWorker1',
				'MyAsyncWorker1a',
				'MyAsyncWorker1',
				'MyAsyncWorker1',
				'MyAsyncWorker3',
				'MyAsyncWorker3',
				'MyAsyncWorker1'
		};

		System.assertEquals(executionFlow, ApplicationUnitOfWorkTestUtility.asyncStack, 'Execution stack not correct');

		asyncWorkerRecordCount = [SELECT COUNT() FROM AsyncWorker__c];
		System.assertEquals(0, asyncWorkerRecordCount, 'Expected all worker records to be deleted');

	}

//	/**
//	 * Scenario:
//	 * This ensures that logical groups are detected.
//	 * When events are published, they are processed in groups where possible
//	 */
//	@IsTest
//	private static void testAsyncEventGrouping() {
//
//		// =====================================
//		// Data Preparation
//		// =====================================
//		List<AsyncWorkerEvent__e> asyncWorkerEvents = ApplicationTestDataFactoryUOW.getAsyncWorkerEvents(2, 'ApplicationUnitOfWorkTestUtility.AsyncWorker1');
//
//		// =====================================
//		// Stubbing
//		// =====================================
//		// None!
//
//		// =====================================
//		// Testing
//		// =====================================
//		Test.startTest();
//
//		ApplicationUnitOfWorkAsyncEventHandler handler = ApplicationUnitOfWorkAsyncEventHandler.getInstance();
//
//		// is group
//		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
//
//		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[1].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[1].CurrentStack__c = 'TheStack';
//
//		System.assert(handler.isLogicalGroup(asyncWorkerEvents[0], asyncWorkerEvents[1]), 'Expected logical group');
//
//		// is not group
//		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
//
//		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Account';
//		asyncWorkerEvents[1].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[1].CurrentStack__c = 'TheStack';
//
//		System.assertEquals(false, handler.isLogicalGroup(asyncWorkerEvents[0], asyncWorkerEvents[1]), 'Did not expect logical group');
//
//		// is not group
//		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact'});
//		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
//
//		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[1].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[1].CurrentStack__c = 'TheStack';
//
//		System.assertEquals(false, handler.isLogicalGroup(asyncWorkerEvents[0], asyncWorkerEvents[1]), 'Did not expect logical group');
//
//		// is not group
//		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
//
//		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[1].UserId__c = '005000000000000';
//		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[1].CurrentStack__c = 'TheStack';
//
//		System.assertEquals(false, handler.isLogicalGroup(asyncWorkerEvents[0], asyncWorkerEvents[1]), 'Did not expect logical group');
//
//		// is not group
//		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
//
//		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[1].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[1].CurrentStack__c = 'TheStack22222';
//
//		System.assertEquals(false, handler.isLogicalGroup(asyncWorkerEvents[0], asyncWorkerEvents[1]), 'Did not expect logical group');
//
//		// is not group
//		asyncWorkerEvents[0].RequiresCallouts__c = true;
//		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
//
//		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[1].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[1].CurrentStack__c = 'TheStack22222';
//
//		System.assertEquals(false, handler.isLogicalGroup(asyncWorkerEvents[0], asyncWorkerEvents[1]), 'Did not expect logical group');
//
//		// is not group
//		asyncWorkerEvents[0].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[0].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[0].CurrentStack__c = 'TheStack';
//
//		asyncWorkerEvents[1].RequiresCallouts__c = true;
//		asyncWorkerEvents[1].SObjectTypeGroup__c = 'Contact';
//		asyncWorkerEvents[1].UserId__c = UserInfo.getUserId();
//		asyncWorkerEvents[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
//		asyncWorkerEvents[1].CurrentStack__c = 'TheStack22222';
//
//		System.assertEquals(false, handler.isLogicalGroup(asyncWorkerEvents[0], asyncWorkerEvents[1]), 'Did not expect logical group');
//
//		Test.stopTest();
//
//	}

	/**
	 * Scenario:
	 * Makes sure that when an async worker is executed that the stack depth is increased
	 */
	@IsTest
	private static void testEnsureStackDepthIncreasesWhenAsyncWorkerIsExecutedIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		List<AsyncWorker__c> asyncWorkerRecords = ApplicationTestDataFactoryUOW.getAsyncWorkerRecords(1, 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1', null, false);

		// Group 1
		asyncWorkerRecords[0].SObjectTypeGroup__c = 'Contact';
		asyncWorkerRecords[0].UserId__c = UserInfo.getUserId();
		asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerRecords[0].CurrentStack__c = 'TheStack';
		asyncWorkerRecords[0].ClassType__c = 'ApplicationUnitOfWorkTestUtility.AsyncWorker1';
		asyncWorkerRecords[0].Parameters1__c = JSON.serialize(new Map<String, Object>{'event' => 1});
		asyncWorkerRecords[0].CurrentStackDepth__c = 1;

		insert asyncWorkerRecords;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWorkAsyncEventHandler handler = ApplicationUnitOfWorkAsyncEventHandler.getInstance();

		handler.processAsyncWorkerQueue(new List<List<AsyncWorker__c>>{asyncWorkerRecords});

		// trigger the queueable execution
		Test.stopTest();

		System.assertEquals(2, ApplicationUnitOfWork.currentAsyncStackDepth, 'Expected stack depth to increase');

	}

	/**
	 * Scenario:
	 * Makes sure that when an async worker is executed that the stack depth is increased
	 */
	@IsTest
	private static void testEnsureParametersArePassedIntoAsyncWorkerIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		List<AsyncWorker__c> asyncWorkerRecords = ApplicationTestDataFactoryUOW.getAsyncWorkerRecords(1, 'ApplicationUnitOfWorkTestUtility.AsyncWorkerCheckParameters', null, false);

		// Group 1
		asyncWorkerRecords[0].SObjectTypeGroup__c = 'Contact';
		asyncWorkerRecords[0].UserId__c = UserInfo.getUserId();
		asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerRecords[0].CurrentStack__c = 'TheStack';
		asyncWorkerRecords[0].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorkerDeserialisesParams';
		asyncWorkerRecords[0].Parameters1__c = JSON.serialize(new Map<String, Object>{'MyParam1' => 'This', 'MyParam2' => 'Deserialised', 'MyParam3' => 'Correctly'});
		asyncWorkerRecords[0].CurrentStackDepth__c = 1;

		insert asyncWorkerRecords;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWorkAsyncEventHandler handler = ApplicationUnitOfWorkAsyncEventHandler.getInstance();

		handler.processAsyncWorkerQueue(new List<List<AsyncWorker__c>>{asyncWorkerRecords});

		// trigger the queueable execution
		// this will execute MyAsyncWorkerDeserialisesParams which calls System.assert on the params are passed in
		Test.stopTest();

		// PMD warning
		System.assert(true);

	}

	/**
	 * Scenario:
	 * Ensures that a queueable with callout capability is enqueued
	 */
	@IsTest
	private static void testQueueableCanInvokeCalloutWhenQueuedCorrectlyIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		List<AsyncWorker__c> asyncWorkerRecords = ApplicationTestDataFactoryUOW.getAsyncWorkerRecords(1, 'ApplicationUnitOfWorkTestUtility.AsyncWorkerThatDoesCallout', null, false);
		asyncWorkerRecords[0].RequiresCallouts__c = true;
		asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		insert asyncWorkerRecords;

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new ApplicationUnitOfWorkTestUtility.QueueableWorkerDummyCalloutHttpMock());

		// =====================================
		// Testing
		// =====================================

		ApplicationUnitOfWorkAsyncEventHandler handler = ApplicationUnitOfWorkAsyncEventHandler.getInstance();

		Test.startTest();

		// this should enqueue AsyncQueueableWithCallout
		handler.processAsyncWorkerQueue(new List<List<AsyncWorker__c>>{asyncWorkerRecords});

		// this should execute our queuable which executes our async worker which tries a dummy callout
		// would generate an exception if the async worker with AllowCallouts was not invoked
		// this exception would be stored against the AsyncWorker__c record (not thrown)
		Test.stopTest();

		List<String> expectedAsyncWorkersInvoked = new List<String>{'AsyncWorkerThatDoesCallout'};
		System.assertEquals(expectedAsyncWorkersInvoked, ApplicationUnitOfWorkTestUtility.asyncStack);

		// normally an AsyncWorker__c record is delete after successful execution
		// since this should have succeeded, there should be no records
		System.assertEquals(0, [SELECT COUNT() FROM AsyncWorker__c], 'Expected successful execution which should have deleted AsyncWorker__c record');

		List<ExceptionLog__c> logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

	}

	/**
	 * Scenario:
	 * When an async worker requires a callout and the callout is successfully made, but an exception is thrown after the callout
	 * Test to make sure the database transactions are rolled back and an error is logged against the AsyncWorker__c record
	 */
	@IsTest
	private static void testQueueableExceptionIsCaughtAfterCalloutIsMadeIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<AsyncWorker__c> asyncWorkerRecords = ApplicationTestDataFactoryUOW.getAsyncWorkerRecords(1, 'ApplicationUnitOfWorkTestUtility.MyAsyncWorkerFailsAfterSuccessfulCallout', null, false);
		asyncWorkerRecords[0].RequiresCallouts__c = true;
		asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		insert asyncWorkerRecords;

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new ApplicationUnitOfWorkTestUtility.QueueableWorkerDummyCalloutHttpMock());

		// =====================================
		// Testing
		// =====================================

		ApplicationUnitOfWorkAsyncEventHandler handler = ApplicationUnitOfWorkAsyncEventHandler.getInstance();

		Test.startTest();

		// this should enqueue AsyncQueueableWithCallout
		handler.processAsyncWorkerQueue(new List<List<AsyncWorker__c>>{asyncWorkerRecords});

		// this should execute our queuable which executes our async worker which tries a dummy callout
		// MyAsyncWorkerFailsAfterSuccessfulCallout worker throws an exception which should be caught and handled by the async orchestrator
		// this exception would be stored against the AsyncWorker__c record (not thrown)
		Test.stopTest();

		List<String> expectedAsyncWorkersInvoked = new List<String>{'MyAsyncWorkerFailsAfterSuccessfulCallout'};
		System.assertEquals(expectedAsyncWorkersInvoked, ApplicationUnitOfWorkTestUtility.asyncStack);

		// normally an AsyncWorker__c record is delete after successful execution
		// since this should have failed, our record should still exist
		List<AsyncWorker__c> workers = [SELECT IsError__c, LastError__c FROM AsyncWorker__c];
		System.assertEquals(1, workers.size(), 'Expected a failure to not delete AsyncWorker__c records');
		System.assertEquals(true, workers[0].IsError__c, 'Expected an error to be marked on AsyncWorker__c record');
		System.assertEquals(true, workers[0].LastError__c.contains('WorkerThrowsException'), 'Expected a WorkerThrowsException to be generated when Async Worker failed');

		// inside MyAsyncWorkerFailsAfterSuccessfulCallout, an account record is inserted which should have been rolled back when the exception is thrown
		System.assertEquals(0, [SELECT COUNT() FROM Account], 'Account record inserted in MyAsyncWorkerFailsAfterSuccessfulCallout should have been rolled back');
	}

	/**
	 * Scenario:
	 * When more than 1 async workers a grouped together and one fails, only the one that fails should be rolled back
	 * This makes sure that when async workers fail they don't impede on other workers
	 */
	@IsTest
	private static void testAsyncWorkerErrorOnlyRollsbackItself() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<AsyncWorker__c> asyncWorkerRecords = ApplicationTestDataFactoryUOW.getAsyncWorkerRecords(2, '', null, false);
		asyncWorkerRecords[0].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorkerInsertsAnAccount';
		asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});

		asyncWorkerRecords[1].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorkerInsertsAnAccountThenThrowsAnError';
		asyncWorkerRecords[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});

		insert asyncWorkerRecords;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		// execute both workers in the same context
		// executing ApplicationUnitOfWorkAsyncEventHandler.handleExecution ensures we are processing them in the same group without worrying about 'grouping'
		ApplicationUnitOfWorkAsyncEventHandler.handleExecution(new List<AsyncWorker__c>{asyncWorkerRecords[0], asyncWorkerRecords[1]});

		Test.stopTest();

		List<String> expectedAsyncWorkersInvoked = new List<String>{'MyAsyncWorkerInsertsAnAccount', 'MyAsyncWorkerInsertsAnAccountThenThrowsAnError'};
		System.assertEquals(expectedAsyncWorkersInvoked, ApplicationUnitOfWorkTestUtility.asyncStack);

		// normally an AsyncWorker__c record is delete after successful execution
		// since this should have failed, our record should still exist
		List<AsyncWorker__c> workers = [SELECT IsError__c, LastError__c, ClassType__c FROM AsyncWorker__c];
		System.assertEquals(1, workers.size(), 'Succesful worker record should have been deleted and the failed worker record retained. Got: ' + workers);
		System.assertEquals(true, workers[0].IsError__c, 'Expected an error to be marked on AsyncWorker__c record');
		System.assertEquals('ApplicationUnitOfWorkTestUtility.MyAsyncWorkerInsertsAnAccountThenThrowsAnError', workers[0].ClassType__c, 'Expected MyAsyncWorkerInsertsAnAccountThenThrowsAnError record');
		System.assertEquals(true, workers[0].LastError__c.contains('WorkerThrowsException'), 'Expected a WorkerThrowsException to be generated when Async Worker failed');

		// make sure the account record inserted in MyAsyncWorkerInsertsAnAccountThenThrowsAnError worker is rolled back
		System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Name = 'MyAsyncWorkerInsertsAnAccountThenThrowsAnError'], 'Account record inserted in MyAsyncWorkerInsertsAnAccountThenThrowsAnError should have been rolled back');

		// make sure the account record inserted in MyAsyncWorkerInsertsAnAccount worker is NOT rolled back
		System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Name = 'MyAsyncWorkerInsertsAnAccount'], 'Account record inserted in MyAsyncWorkerInsertsAnAccount should have been retained');
	}


	/**
	 * Scenario:
	 * Ensures that a queueable with callout capability is not allowed to execute when it's grouped with other workers
	 */
	@IsTest
	private static void testQueueableCanNotInvokeCalloutWhenRequiresCalloutsIsNotSet() {

		// =====================================
		// Data Preparation
		// =====================================
		List<AsyncWorker__c> asyncWorkerRecords = ApplicationTestDataFactoryUOW.getAsyncWorkerRecords(2, 'ApplicationUnitOfWorkTestUtility.MyAsyncWorkerDoesCalloutsButIsntConfiguredTo', null, false);
		asyncWorkerRecords[0].SObjectTypeGroup__c = 'Contact';
		asyncWorkerRecords[0].UserId__c = UserInfo.getUserId();
		asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerRecords[1].SObjectTypeGroup__c = 'Contact';
		asyncWorkerRecords[1].UserId__c = UserInfo.getUserId();
		asyncWorkerRecords[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerRecords[1].ClassType__c = 'ApplicationUnitOfWorkTestUtility.MyAsyncWorker1';
		insert asyncWorkerRecords;

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new ApplicationUnitOfWorkTestUtility.QueueableWorkerDummyCalloutHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationUnitOfWorkAsyncEventHandler handler = ApplicationUnitOfWorkAsyncEventHandler.getInstance();

		// add a queueable to process both workers
		handler.processAsyncWorkerQueue(new List<List<AsyncWorker__c>>{asyncWorkerRecords});

		// a single queueable should be executed for both workers
		Test.stopTest();

		List<String> expectedAsyncWorkersInvoked = new List<String>{'MyAsyncWorkerDoesCalloutsButIsntConfiguredTo', 'MyAsyncWorker1'};
		System.assertEquals(expectedAsyncWorkersInvoked, ApplicationUnitOfWorkTestUtility.asyncStack);

		// check that 1 worker record was deleted and the other one remains
		List<AsyncWorker__c> workers = [SELECT IsError__c, LastError__c, ClassType__c FROM AsyncWorker__c];
		System.assertEquals(1, workers.size(), 'Succesful worker record should have been deleted and the failed worker record retained. Got: ' + workers);
		System.assertEquals(true, workers[0].IsError__c, 'Expected an error to be marked on AsyncWorker__c record');
		System.assertEquals('ApplicationUnitOfWorkTestUtility.MyAsyncWorkerDoesCalloutsButIsntConfiguredTo', workers[0].ClassType__c, 'Expected MyAsyncWorkerDoesCalloutsButIsntConfiguredTo record');
		System.assertEquals(true, workers[0].LastError__c.contains('CalloutException'), 'Expected a WorkerThrowsException to be generated when Async Worker failed');

		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Both workers should have been grouped into a single queueable');
	}

	/**
	 * Scenario:
	 * Ensures that when a lock error occurs, it triggers a process to reenqueue
	 */
	@IsTest
	private static void testAsyncWorkerIsRetriedOnLockFailureIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		List<AsyncWorker__c> asyncWorkerRecords = ApplicationTestDataFactoryUOW.getAsyncWorkerRecords(2, 'ApplicationUnitOfWorkTestUtility.MyAsyncWorkerThrowsLockErrors', null, false);
		asyncWorkerRecords[0].CurrentLockRetryAttempts__c = 0;
		asyncWorkerRecords[0].SObjectTypeGroup__c = 'Contact';
		asyncWorkerRecords[0].UserId__c = UserInfo.getUserId();
		asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerRecords[1].CurrentLockRetryAttempts__c = 0;
		asyncWorkerRecords[1].SObjectTypeGroup__c = 'Contact';
		asyncWorkerRecords[1].UserId__c = UserInfo.getUserId();
		asyncWorkerRecords[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		insert asyncWorkerRecords;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		ApplicationUnitOfWorkAsyncEventHandler handler = ApplicationUnitOfWorkAsyncEventHandler.getInstance();

		Test.startTest();

		// this should enqueue AsyncQueueable
		handler.processAsyncWorkerQueue(new List<List<AsyncWorker__c>>{asyncWorkerRecords});

		// this should execute our queuable which throws a lock error
		// we should see a new platform event added to the queue and processed after this since there was a lock error
		Test.stopTest();

		// NOTE: only 1 worker would have executed before the lock error caused the whole group to be aborted
		List<String> expectedAsyncWorkersInvoked = new List<String>{'MyAsyncWorkerThrowsLockErrors'};
		System.assertEquals(expectedAsyncWorkersInvoked, ApplicationUnitOfWorkTestUtility.asyncStack, 'Only 1 worker should have executed before aborting the entire execution');

		// make sure the original asyncworker was deleted
		// (Original asyncworker records are deleted when lock errors occur)
		List<AsyncWorker__c> workers = [SELECT Id, CurrentLockRetryAttempts__c FROM AsyncWorker__c];
		System.assertEquals(2, workers.size(), workers);

		// make sure the only record in the asyncworker table is not the original one since we delete the original and cause another one to be created
		System.assertNotEquals(asyncWorkerRecords[0].Id, workers[0].Id, workers);
		System.assertNotEquals(asyncWorkerRecords[1].Id, workers[0].Id, workers);
		System.assertNotEquals(asyncWorkerRecords[0].Id, workers[1].Id, workers);
		System.assertNotEquals(asyncWorkerRecords[1].Id, workers[1].Id, workers);

		// make sure the retry count has increased
		System.assertEquals(1, workers[0].CurrentLockRetryAttempts__c, 'Expected this to be the second attempt at processing worker');
		System.assertEquals(1, workers[1].CurrentLockRetryAttempts__c, 'Expected this to be the second attempt at processing worker');

		// 2 new platform event should be added
		System.assertEquals(2, [SELECT Position FROM EventBusSubscriber WHERE Topic='AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position, 'Expected tip to be at position 1');

		// delivering the platform event should enqueue a new job to execute the API
		// this one is in addition to the original one that was queued
		System.assertEquals(2, [SELECT COUNT() FROM AsyncApexJob], 'Expected handler to invoke a second queueable to call async API');

	}
	/**
	 * Ensures that when a lock error occurs too many times, it should fail permanently
	 */
	@IsTest
	private static void testAsyncWorkerFailsPermanentlyWhenTooManyLockFailuresOccur() {

		// =====================================
		// Data Preparation
		// =====================================
		List<AsyncWorker__c> asyncWorkerRecords = ApplicationTestDataFactoryUOW.getAsyncWorkerRecords(2, 'ApplicationUnitOfWorkTestUtility.MyAsyncWorkerThrowsLockErrors', null, false);
		asyncWorkerRecords[0].MaxNumberRetries__c = 1;
		asyncWorkerRecords[0].CurrentLockRetryAttempts__c = 1;
		asyncWorkerRecords[0].SObjectTypeGroup__c = 'Contact';
		asyncWorkerRecords[0].UserId__c = UserInfo.getUserId();
		asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		asyncWorkerRecords[1].MaxNumberRetries__c = 1;
		asyncWorkerRecords[1].CurrentLockRetryAttempts__c = 1;
		asyncWorkerRecords[1].SObjectTypeGroup__c = 'Contact';
		asyncWorkerRecords[1].UserId__c = UserInfo.getUserId();
		asyncWorkerRecords[1].UnitOfWorkSObjectTypes__c = JSON.serialize(new List<String>{'Contact', 'Account'});
		insert asyncWorkerRecords;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		ApplicationUnitOfWorkAsyncEventHandler handler = ApplicationUnitOfWorkAsyncEventHandler.getInstance();

		Test.startTest();

		// this should enqueue AsyncQueueable
		handler.processAsyncWorkerQueue(new List<List<AsyncWorker__c>>{asyncWorkerRecords});

		// this should execute our queuable which throws a lock error
		// since the maximum number of retries will be exceeded, no further platform events would be reenqueued
		Test.stopTest();

		// NOTE: only 1 worker would have executed before the lock error caused the whole group to be aborted
		List<String> expectedAsyncWorkersInvoked = new List<String>{'MyAsyncWorkerThrowsLockErrors'};
		System.assertEquals(expectedAsyncWorkersInvoked, ApplicationUnitOfWorkTestUtility.asyncStack, 'Only 1 worker should have executed before aborting the entire execution');

		// make sure the original asyncworkers are still intact since we are no longer renqueuing any additional workers
		List<AsyncWorker__c> workers = [SELECT Id, CurrentLockRetryAttempts__c, IsError__c FROM AsyncWorker__c];
		System.assertEquals(2, workers.size(), workers);

		Set<Id> existingWorkerIds = new Set<Id>{workers[0].Id, workers[1].Id};
		System.assert(existingWorkerIds.contains(asyncWorkerRecords[0].Id), 'Original woker records were deleted');
		System.assert(existingWorkerIds.contains(asyncWorkerRecords[1].Id), 'Original woker records were deleted');

		System.assertEquals(true, workers[0].IsError__c, workers);
		System.assertEquals(true, workers[1].IsError__c, workers);

		// no platform events should have been published
		System.assertEquals(0, [SELECT Position FROM EventBusSubscriber WHERE Topic='AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position, 'Expected tip to be at position 1');

		// only the original queueable to process the workers should exist
		// The workers shouldn't be reenqueued since the maximum number of attempts have been exceeded
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Did not expect more queueables');

	}

	/**
	 * Scenario:
	 * Make sure the kill switch works if we ever need to kill the event processing
	 */
	@IsTest
	private static void testEnsureAsyncKillSwitchWorksIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		SystemSettings__c settings = new SystemSettings__c(DisableUOWExclusiveAsyncEvents__c = true);
		insert settings;

		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker1.class);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker1);
		uow.commitWork();

		Test.getEventBus().deliver();

		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob], 'Expected no queueables');

		List<ExceptionLog__c> logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

	}

}