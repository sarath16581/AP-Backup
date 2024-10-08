/***
 * @description
 * Test class for ApplicationUnitOfWork
 *
 * @author Nathan Franklin
 * @date 2020-07-27
 * @group Tests
 * @domain Core
 * @changelog
 */
@IsTest
private class ApplicationUnitOfWork_Test {

	/**
	 * Scenario:
	 * Tests when registerAsyncWork is called that a new platform event is published
	 */
	@IsTest
	private static void testEndToEndEnsureAsyncWorkIsQueuedIntoAsyncContext() {

		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker1.class, new Map<String, Object>{'key1' => 'value1'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker);
		uow.commitWork();

		Test.startTest();

		System.Savepoint sp = Database.setSavepoint();

		// deliver our platform events which should enqueue a queueable that invokes the async API
		Test.getEventBus().deliver();

		System.assertEquals(1, [SELECT Position FROM EventBusSubscriber WHERE Topic='AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position, 'Expected platform event tip to be at 1');
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected handler to invoke queueable to call async API');

		// since we rolled everything back, this would no longer execute the queueable that calls the async API
		Test.stopTest();

		List<ExceptionLog__c> logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

		List<String> expectedStack = new List<String>{
				'MyAsyncWorker1'
		};

		System.assertEquals(expectedStack, ApplicationUnitOfWorkTestUtility.asyncStack, 'The workers were not executed correctly');

	}

	/**
	 * Scenario:
	 * Tests to ensure that when an asynchronous action is queued up in the UOW, that it will be pushed into a queueable context via the async platform event
	 * This ensures that workers are correctly grouped together
	 */
	@IsTest
	private static void testEnsureAsyncWorkGroupsAreQueuedIntoAsyncContextIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker1.class, new Map<String, Object>{'key1' => 'value1'});
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1a = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker1a.class, new Map<String, Object>{'key1' => 'value1'});
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker2.class, new Map<String, Object>{'key2' => 'value2'});
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker3 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker3.class, new Map<String, Object>{'key3' => 'value3'});
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker4 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker4.class, new Map<String, Object>{'key4' => 'value4'});
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker4a = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker4a.class, new Map<String, Object>{'key5' => 'value5'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Contact.SObjectType,
				Case.SObjectType
		};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker1);
		uow.registerAsyncWork(stagingWorker1a);
		uow.registerAsyncWork(stagingWorker2);
		uow.registerAsyncWork(stagingWorker3);
		uow.registerAsyncWork(stagingWorker4);
		uow.registerAsyncWork(stagingWorker4a);
		uow.commitWork();

		// deliver our platform events to see if a new queueable was added
		Test.getEventBus().deliver();

		System.assertEquals(6, [SELECT Position FROM EventBusSubscriber WHERE Topic='AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position);
		System.assertEquals(4, [SELECT COUNT() FROM AsyncApexJob], 'Expected handler to invoke 3 worker threads');

		Test.stopTest();

		List<ExceptionLog__c> logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

		List<String> expectedStack = new List<String>{
				'MyAsyncWorker1', // <-- group 1
				'MyAsyncWorker1a', // <-- group 1
				'MyAsyncWorker2', // <-- group 2
				'MyAsyncWorker3', // <-- group 3
				'MyAsyncWorker4', // <-- group 4
				'MyAsyncWorker4a' // <-- group 4
		};

		System.assertEquals(expectedStack, ApplicationUnitOfWorkTestUtility.asyncStack, 'The workers were not executed correctly');

	}

	/**
	 * Scenario:
	 * Test to make sure that async operations do not continue to be enqueued beyond the allowed maximum stack depth
	 */
	@IsTest
	private static void testEnsureAsyncWorkDoesNotExceedTheMaximumStackDepth() {

		// =====================================
		// Data Preparation
		// =====================================

		// only allow a single level of async workers
		ApplicationUnitOfWork.testClassMaxAsyncStackDepth = 1;


		// MyAsyncWorker5 will try and enqueue itself over and again
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker5 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker5.class, new Map<String, Object>{'key1' => 'value1'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{Account.SObjectType};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerAsyncWork(stagingWorker5);
		uow.commitWork();

		// force deliver the platform event generated by uow.commitWork();
		// this will queue a queueable to execute when Test.stopTest() is called
		Test.getEventBus().deliver();

		// this will execute the async worker which will try and enqueue another level of async worker
		// given this would exceed the stack depth, an exception would be thrown (which the framework will catch)
		Test.stopTest();

		// check the async worker error
		List<AsyncWorker__c> workerRecords = [SELECT ClassType__c, IsError__c, LastError__c FROM AsyncWorker__c];
		System.assertEquals(1, workerRecords.size(), 'Did not expect more than 1 worker record to be created');

		System.assert(workerRecords[0].IsError__c, 'Expected worker to be in error state since it tried to enqueue beyond the maximum stack depth');
		System.assert(workerRecords[0].LastError__c.contains('ApplicationUnitOfWork.AsyncUnitOfWorkException'), 'Expected ApplicationUnitOfWork.AsyncUnitOfWorkException exception, got: ' + workerRecords[0].LastError__c);

		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected same job count since an exception should prevent subsequent registration');
		List<String> expectedStack = new List<String>{
				'MyAsyncWorker5'
		};

		System.assertEquals(expectedStack, ApplicationUnitOfWorkTestUtility.asyncStack, 'The workers were not executed correctly');
	}

	/**
	 * Scenario:
	 * Test to make sure that grouped async operations continue to execute even when one of the workers fails
	 */
	@IsTest
	private static void testEnsureGroupedAsyncWorkContinuesEvenWhenOneWorkerFails() {

		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorkerThrowsExceptions = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorkerThrowsExceptions.class, new Map<String, Object>{'key1' => 'value1'});
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker1.class, new Map<String, Object>{'key1' => 'value1'});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{Account.SObjectType};
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);

		uow.registerAsyncWork(stagingWorkerThrowsExceptions);
		uow.registerAsyncWork(stagingWorker1);
		uow.commitWork();

		// force deliver the platform event generated by uow.commitWork();
		// this will queue a queueable to execute when Test.stopTest() is called
		Test.getEventBus().deliver();

		// this will execute the async workers into a single queueable
		// One should fail, the other should execute,
		// One asyncworker record should be deleted, the other should remain
		Test.stopTest();

		// check the async worker error
		List<AsyncWorker__c> workerRecords = [SELECT ClassType__c, IsError__c, LastError__c FROM AsyncWorker__c];
		System.assertEquals(1, workerRecords.size(), 'Did not expect more than 1 worker record to remain');

		System.assert(workerRecords[0].IsError__c, 'Expected worker to be in error state');
		System.assert(workerRecords[0].LastError__c.contains('ApplicationUnitOfWorkTestUtility.WorkerThrowsException'), 'Expected ApplicationUnitOfWorkTestUtility.WorkerThrowsException exception, got: ' + workerRecords[0].LastError__c);

		// make sure only 1 group
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected only 1 queueable with 2 workers');

		List<String> expectedStack = new List<String>{
				'MyAsyncWorkerThrowsExceptions', //<-- an entry is added here even though an exception is thrown after
				'MyAsyncWorker1'
		};
		System.assertEquals(expectedStack, ApplicationUnitOfWorkTestUtility.asyncStack, 'The workers were not executed correctly');
	}


	/**
	 * Scenario:
	 * Ensures that a log item is created when we need to discard an async worker due to max depth limitation
	 */
	@IsTest
	private static void testEnsureAsyncWorkIsDiscardedAndLoggedWhenMaxStackDepthIsReached() {

		// =====================================
		// Data Preparation
		// =====================================

		// only allow a single level of async workers
		ApplicationUnitOfWork.testClassMaxAsyncStackDepth = 1;
		ApplicationUnitOfWork.currentAsyncStackDepth = 1;

		// MyAsyncWorker5 will try and enqueue itself over and again
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorkerIsDiscarded.class);

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
		uow.registerAsyncWork(stagingWorker);
		uow.commitWork();

		Test.stopTest();

		List<ExceptionLog__c> logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(1, logs.size(), logs);

		System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob], 'Did not expect queueables since worker should have been discarded');

	}

	/**
	 * Scenario:
	 * Makes sure that all work is executed in the same container once the stack depth is reached
	 */
	@IsTest
	private static void testEnsureAsyncWorkIsChainProcessedInSyncWhenMaxStackDepthIsReached() {

		// =====================================
		// Data Preparation
		// =====================================

		// do not allow any level of asynchronous processing
		// should cause all operations to be processed in sync
		ApplicationUnitOfWork.testClassMaxAsyncStackDepth = 1;
		ApplicationUnitOfWork.currentAsyncStackDepth = 1;

		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorkerIsProcessedInSync1.class);
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorkerIsProcessedInSync2.class);

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
		uow.registerAsyncWork(stagingWorker2);
		uow.commitWork();

		Test.getEventBus().deliver();

		Test.stopTest();

		System.assertEquals(2, ApplicationUnitOfWorkTestUtility.asyncWorkerCount);
		System.assertEquals(new List<String>{'MyAsyncWorkerIsProcessedInSync1', 'MyAsyncWorkerIsProcessedInSync2'}, ApplicationUnitOfWorkTestUtility.asyncStack);
		System.assertEquals(0, [SELECT COUNT() FROM AsyncApexJob], 'All work should have been processed in the current container');
	}

	/**
	 * Scenario:
	 * Event when a max stack depth is reached, if the async worker is configured with FORCE ASYNC, then it should be queued into an async context
	 * NOTE: The async one would always process after the one that is processed in sync
	 */
	@IsTest
	private static void testEnsureAsyncWorkIsPushedIntoAsyncWithForceAsync() {

		// =====================================
		// Data Preparation
		// =====================================

		// should cause all operations to be processed in sync except the ones explicity configures with FORCE_ASYNC
		ApplicationUnitOfWork.testClassMaxAsyncStackDepth = 1;
		ApplicationUnitOfWork.currentAsyncStackDepth = 1;

		// trigger an asynchronous proesssing
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorkerForcedAsyncWorker.class);

		// trigger a synchronous processing
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker1a = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker1a.class);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
				Account.SObjectType,
				Contact.SObjectType,
				Case.SObjectType
		};

		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);
		uow.registerAsyncWork(stagingWorker1);
		uow.registerAsyncWork(stagingWorker1a);
		uow.commitWork();

		// deliver our platform events to see if a new queueable was added
		Test.getEventBus().deliver();

		// only the one that is forced into ASYNC would publish a platform event
		System.assertEquals(1, [SELECT Position FROM EventBusSubscriber WHERE Topic='AsyncWorkerEvent__e' AND Type='ApexTrigger'].Position);

		// only 1 job should be enqueued which would be stagingWorker1a
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected handler to invoke queueable to call async API for worker 1');

		Test.stopTest();


		System.assertEquals(2, ApplicationUnitOfWorkTestUtility.asyncWorkerCount, 'Still expected 2 workers to execute: 1 in current context, 1 in a forced async context');

		// NOTE that stagingWorker1a should be processed before the async worker (since a platform event would be published first which will eventually trigger a queueable)
		System.assertEquals(new List<String>{'MyAsyncWorker1a', 'MyAsyncWorkerForcedAsyncWorker'}, ApplicationUnitOfWorkTestUtility.asyncStack);

		List<ExceptionLog__c> logs = [SELECT Id, ExceptionDetails__c FROM ExceptionLog__c];
		System.assertEquals(0, logs.size(), 'Expected no errors to be logged: ' + logs);

	}

	/**
	 * Scenario:
	 * Ensures that an error will be generated when an invalid configuration is set for an async worker
	 */
	@IsTest
	private static void testEnsureExceptionIsGeneratedWithInvalidAsyncWorkerConfiguration() {

		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWork.class);
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker3 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorkerWithLargeRetryAttempts.class);

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

		try {
			uow.registerAsyncWork(stagingWorker2);

			System.assert(false, 'An error was expected for an invalid config. Invalid class type');
		} catch(ApplicationUnitOfWork.AsyncUnitOfWorkException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Generic error occurred: ' + ex);
		}

		try {
			uow.registerAsyncWork(stagingWorker3);

			System.assert(false, 'An error was expected for an invalid config. Invalid number of retry attempts specified');
		} catch(ApplicationUnitOfWork.AsyncUnitOfWorkException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false, 'Generic error occurred: ' + ex);
		}
	}

	/**
	 * Scenario:
	 * Ensure that parameters are correctly deserialised based on the custom override method defined in the worker.
	 */
	@IsTest
	private static void testEnsureAsyncWorkerDeserialisesParametersCorrectlyIntegration() {

		// =====================================
		// Data Preparation
		// =====================================

		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorkerDeserialisesParams.class, new Map<String, String>{'MyParam1' => 'This', 'MyParam2' => 'Deserialised', 'MyParam3' => 'Correctly'});

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
		uow.registerAsyncWork(stagingWorker);
		uow.commitWork();

		// deliver our platform events to see if a new queueable was added
		// this will only deliver 2 because of the queueable limit override
		Test.getEventBus().deliver();

		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'Expected 2 queueable jobs to be added when AsyncWorkerEvent__e event is published');

		System.assertEquals(new List<String>{'MyAsyncWorkerDeserialisesParams'}, ApplicationUnitOfWorkTestUtility.asyncStack);

	}

	/**
	 * Scenario:
	 * Ensures that when the platform event is invoked for an async queueable, it does not exceed the number of queueables allowed for that transaction
	 * The platform event should exit gracefully and kick off another transaction
	 */
	@IsTest
	private static void testEnsureAsyncQueueablesDoNotExceedTheQueueableLimitIntegration() {

		// =====================================
		// Data Preparation
		// =====================================

		// make sure the platform event handle only enqueues 2 queueables
		ApplicationUnitOfWorkAsyncEventHandler.testClassMaxAsyncQueueableOverride = 2;

		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker2 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker2.class, new Map<String, Object>{'key2' => 'value2'});
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker3 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker3.class, new Map<String, Object>{'key3' => 'value3'});
		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker4 = new ApplicationUnitOfWork.AsyncStagingWorker(ApplicationUnitOfWorkTestUtility.MyAsyncWorker4.class, new Map<String, Object>{'key4' => 'value4'});

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
		uow.registerAsyncWork(stagingWorker2);
		uow.registerAsyncWork(stagingWorker3);
		uow.registerAsyncWork(stagingWorker4);

		uow.commitWork();

		// deliver our platform events to see if a new queueable was added
		// this will only deliver 2 because of the queueable limit override
		Test.getEventBus().deliver();

		System.assertEquals(2, [SELECT COUNT() FROM AsyncApexJob], 'Expected 2 queueable jobs to be added when AsyncWorkerEvent__e event is published');

		// this will only deliver 2 because of the queueable limit override
		Test.getEventBus().deliver();

		Test.stopTest();

		System.assertEquals(3, [SELECT COUNT() FROM AsyncApexJob], 'Expected 1 additional queueable job (first 2 + this 1 = 3) to be added when AsyncWorkerEvent__e event is published');

		System.assertEquals(3, ApplicationUnitOfWorkTestUtility.asyncWorkerCount, 'MyAsyncWorker1 should have been invoked 4 times');

	}



	/**
	 * Scenario:
	 * Ensure the async and exclusive async work queues are populated
	 */
	@IsTest
	private static void testEnsureAsyncWorkersAreRegistered() {

		// =====================================
		// Data Preparation
		// =====================================

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
		uow.registerAsyncWork(stagingWorker1.clone());
		uow.registerAsyncWork(stagingWorker1.clone());
		uow.registerAsyncWork(stagingWorker1.clone());

		System.assertEquals(4, uow.getAsyncWorkCount());

		Test.stopTest();

	}

	@IsTest
	private static void testQueueingOfEmailNotifications() {

		// =====================================
		// Data Preparation
		// =====================================
		
		List<Case> testCases = ApplicationTestDataFactory.getCases(10, true);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<SObjectType> sObjectTypes = new List<SObjectType>{
			Case.SObjectType
		};
		
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(sObjectTypes);
		
		for (Case testCase : testCases) {
			uow.queueEmailNotification(testCase.Id, Case.sObjectType, 'Test_Case_Email');
		}

		// check the registered emails in ApplicationEmailService instance
		System.assertEquals(10, ApplicationEmailService.getInstance().getRegistrySize(), '10 entries in ApplicationEmailService registry should have been created via the unitOfWork');
	
		// commit the work to dispatch emails
		uow.commitWork();

		// kick off platform events
		Test.getEventBus().deliver();

		Test.stopTest();
		
		System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob], 'A single asyncWorker should have been queued to dispatch emails');

	}

}