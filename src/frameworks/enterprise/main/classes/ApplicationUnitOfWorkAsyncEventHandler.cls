/***
 * @description
 * Platform Event handler for pushing Async operations into Queueables
 *
 * @author Nathan Franklin
 * @date 2020-09-01
 * @group Core
 * @changelog
 */
public with sharing class ApplicationUnitOfWorkAsyncEventHandler {

	/**
	 * When an async container is forced (either by passing null in for SObject group or implementing Database.AllowsCallouts), we use an increment to break the group key generation up to force a new group to be created
	 */
	private static Integer exclusiveSObjectGroupIncrement = 0;
	private static Integer exclusiveCalloutGroupIncrement = 0;

	public static ApplicationUnitOfWorkAsyncEventHandler getInstance() {
		return (ApplicationUnitOfWorkAsyncEventHandler)Application.Utilities.getInstance(ApplicationUnitOfWorkAsyncEventHandler.class);
	}

	private static final Map<SObjectField, SObjectField> WORKER_RECORD_MAPPINGS = new Map<SObjectField, SObjectField>{
			AsyncWorkerEvent__e.ClassType__c => AsyncWorker__c.ClassType__c,
			AsyncWorkerEvent__e.CurrentLockRetryAttempts__c => AsyncWorker__c.CurrentLockRetryAttempts__c,
			AsyncWorkerEvent__e.CurrentStack__c => AsyncWorker__c.CurrentStack__c,
			AsyncWorkerEvent__e.CurrentStackDepth__c => AsyncWorker__c.CurrentStackDepth__c,
			AsyncWorkerEvent__e.MaxNumberRetries__c => AsyncWorker__c.MaxNumberRetries__c,
			AsyncWorkerEvent__e.Parameters1__c => AsyncWorker__c.Parameters1__c,
			AsyncWorkerEvent__e.Parameters2__c => AsyncWorker__c.Parameters2__c,
			AsyncWorkerEvent__e.Parameters3__c => AsyncWorker__c.Parameters3__c,
			AsyncWorkerEvent__e.Parameters4__c => AsyncWorker__c.Parameters4__c,
			AsyncWorkerEvent__e.SObjectTypeGroup__c => AsyncWorker__c.SObjectTypeGroup__c,
			AsyncWorkerEvent__e.UnitOfWorkSObjectTypes__c => AsyncWorker__c.UnitOfWorkSObjectTypes__c,
			AsyncWorkerEvent__e.UserId__c => AsyncWorker__c.UserId__c,
			AsyncWorkerEvent__e.RequiresCallouts__c => AsyncWorker__c.RequiresCallouts__c
	};

	/**
	 * A testing class hack to override the static MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION
	 */
	@TestVisible
	private static Integer testClassMaxAsyncQueueableOverride = 0;

	/**
	 * A testing class hack to override the static final MAX_GROUPED_ASYNC_WORKERS
	 */
	@TestVisible
	private static Integer testClassMaxGroupedWorkers = 0;

	/**
	 * The maximum hard stack depth (ignore the workers getMaxDepthAction instruction. This is to mitigate against infinit loop scenarios.
	 */
	private static final Integer MAX_HARD_STACK_DEPTH {
		get {
			if(MAX_HARD_STACK_DEPTH == null) {
				SystemSettings__c settings = SystemSettings__c.getInstance();
				MAX_HARD_STACK_DEPTH = Integer.valueOf((settings?.AsyncFrameworkNoExceptionMaxDepth__c == null ? 10 : settings.AsyncFrameworkNoExceptionMaxDepth__c));
			}
			return MAX_HARD_STACK_DEPTH;
		}
		private set;
	}


	/**
	 * The maximum allowed queueable jobs that can be created inside the exclusive async worker platform event (should be 50 as per documentation)
	 */
	@TestVisible
	private static final Integer MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION {
		get {
			if(MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION == null) {
				if(Test.isRunningTest() && testClassMaxAsyncQueueableOverride != 0) {
					MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION = testClassMaxAsyncQueueableOverride;
				} else {
					MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION = Limits.getLimitQueueableJobs();
				}
			}
			return MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION;
		}
		private set;
	}

	/**
	 * The maximum number of workers that can be grouped together before a new queueable will be triggered
	 */
	@TestVisible
	private static final Integer MAX_GROUPED_ASYNC_WORKERS {
		get {
			if(MAX_GROUPED_ASYNC_WORKERS == null) {
				if(Test.isRunningTest() && testClassMaxGroupedWorkers != 0) {
					MAX_GROUPED_ASYNC_WORKERS = testClassMaxGroupedWorkers;
				} else {
					SystemSettings__c settings = SystemSettings__c.getInstance();
					MAX_GROUPED_ASYNC_WORKERS = Integer.valueOf((settings?.AsyncFrameworkMaxGroupedWorkers__c == null ? 5 : settings.AsyncFrameworkMaxGroupedWorkers__c));
				}
			}
			return MAX_GROUPED_ASYNC_WORKERS;
		}
		private set;
	}

	public void dispatch(List<AsyncWorkerEvent__e> events) {
		System.debug('ApplicationUnitOfWorkAsyncEventHandler:dispatch');

		String lastReplayId = '';

		List<Exception> generatedExceptions = new List<Exception>();

		Map<String, List<AsyncWorker__c>> groupedProcessable = new Map<String, List<AsyncWorker__c>>();

		for(Integer i=0;i<events.size();i++) {

			// note the overarching try catch block
			// this is to ensure that any errors that exist with the data will not stop other events from being processed
			// on error, we discard the operation and log the error
			try {
				String groupKey = getNextAvailableGroupKey(events[i], groupedProcessable);

				// make sure there is still capacity to process more groups
				if(groupedProcessable.get(groupKey) == null && groupedProcessable.size() >= MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION) {
					// stop processing any more platform events since we wouldn't be able to enqueue any more platform events
					// we set the last successfully processed message below, so breaking from here will simply spawn a new transaction from the next unprocessed event message
					break;
				} else if(groupedProcessable.get(groupKey) == null) {
					// create the group
					groupedProcessable.put(groupKey, new List<AsyncWorker__c>());
				}

				// add this item into the group
				groupedProcessable.get(groupKey).add(convertAsyncEventToWorkerRecord(events[i]));

			} catch(Exception ex) {
				// log the error that prevented this async worker from running correctly.
				// it's important that we catch these errors to ensure that the queue never stops processing
				generatedExceptions.add(ex);

				System.debug('Exception: ' + ex);
				System.debug(ex.getStackTraceString());
			}

			lastReplayId = events[i].ReplayId;
		}

		// store a log for any events with conversion and grouping problems
		if(!generatedExceptions.isEmpty()) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(generatedExceptions), ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWorkAsyncEventHandler.class), 'dispatch', 'AsyncWorkerEventTrigger', ApplicationLogger.LoggingLevel.ERROR);
		}

		// insert records into AsyncWorker__c which will then be passed into the async API
		// we use this object as a way to track the pending async operations to be completed...
		if(!groupedProcessable.isEmpty()) {
			System.debug('Group Count: ' + groupedProcessable.size());

			List<AsyncWorker__c> insertable = new List<AsyncWorker__c>();
			for(String groupKey : groupedProcessable.keySet()) {
				System.debug('Group: ' + groupedProcessable.get(groupKey));
				insertable.addAll(groupedProcessable.get(groupKey));
			}

			List<Database.SaveResult> results = ApplicationDatabase.getInstance().dmlInsert(insertable, false);
			ApplicationLogger.getInstance().logFailedDatabaseResults(results, ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWorkAsyncEventHandler.class), 'dispatch', 'AsyncWorkerEventTrigger', ApplicationLogger.LoggingLevel.ERROR);

			// queue these workers up into their queueables
			processAsyncWorkerQueue(groupedProcessable.values());
		}

		// Set the Replay ID of the last successfully processed event message.
		// If a limit is hit, the trigger refires and processing starts with the
		// event after the last one processed (the set Replay ID)
		if(!String.isEmpty(lastReplayId)) {
			System.debug('Replay: ' + lastReplayId);
			EventBus.TriggerContext.currentContext().setResumeCheckpoint(lastReplayId);
		}

	}

	/**
	 * The group key is used to group workers together that have been received in the event bus
	 * This allows us to logically group workers together
	 */
	@TestVisible
	private String getNextAvailableGroupKey(AsyncWorkerEvent__e event, Map<String, List<AsyncWorker__c>> currentGroupingQueue) {

		// NOTE: we use integer increments to force a new group when the worker needs it
		// SObjectTypeGroup being null or RequiresCallouts being true force a unique group
		String key = '';
		key += event.UnitOfWorkSObjectTypes__c + '-';
		key += (String.isEmpty(event.SObjectTypeGroup__c) ? String.valueOf(++exclusiveSObjectGroupIncrement) : event.SObjectTypeGroup__c) + '-';
		key += event.UserId__c + '-';
		key += event.CurrentStackDepth__c + '-';
		key += (event.RequiresCallouts__c ? String.valueOf(++exclusiveCalloutGroupIncrement) : String.valueOf(event.RequiresCallouts__c));

		Integer increment = 1;
		while(true) {
			String checkKey = key + '-' + String.valueOf(increment);
			if(currentGroupingQueue.get(checkKey) == null || (currentGroupingQueue.get(checkKey) != null && currentGroupingQueue.get(checkKey).size() < MAX_GROUPED_ASYNC_WORKERS)) {
				key = checkKey;
				break;
			} else {
				increment++;
			}
		}

		System.debug('Found Group Key: ' + key);

		return key;
	}

	/**
	 * Spawn queueables based on the work provided in asyncWorkers variable. This is built from the platform event handler
	 * The exact number of ids will vary based on their group configuration and limits specified in
	 *      MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION and MAX_GROUPED_ASYNC_WORKERS
	 *
	 * NOTE:
	 * The method does not perform any grouping operations, it assumes the grouping is completed prior to calling this method, hence the List<List> input
	 * The number of groups passed in here MUST NOT exceed the available number of queueables since each group is queued into a separate enqueueable (max limit is 50 groups)
	 */
	public void processAsyncWorkerQueue(List<List<AsyncWorker__c>> groupedAsyncWorkers) {
		List<AsyncWorker__c> updateableAsyncWorkerRecords = new List<AsyncWorker__c>();
		System.debug('asyncWorkers: ' + groupedAsyncWorkers);

		List<Exception> failedQueueWorkers = new List<Exception>();

		for(List<AsyncWorker__c> asyncWorkers : groupedAsyncWorkers) {
			// ignore any empty groups
			if(asyncWorkers.isEmpty()) {
				continue;
			}

			// note the overarching try catch block
			// this is to ensure that any errors that exist with the data will not stop other events from being processed
			// on error, we discard the operation and log the error
			try {
				Id jobId;

				Set<Id> workerIds = new Map<Id, AsyncWorker__c>(asyncWorkers).keySet();

				if (!asyncWorkers[0].RequiresCallouts__c) {
					// the normal AsyncWorker interface is enqueued when the worker does not require callouts
					// this queueable is a queueable without callouts
					AsyncQueueable queueable = new AsyncQueueable(workerIds);
					jobId = ApplicationDatabase.getInstance().enqueueJob(queueable);
					System.debug('Queued: ' + queueable);
				} else {
					// for a scenario where an async worker requires to make callouts
					// we launch a special queueable that allows callouts
					AsyncQueueableWithCallout queueable = new AsyncQueueableWithCallout(workerIds);
					jobId = ApplicationDatabase.getInstance().enqueueJob(queueable);
					System.debug('Queued: ' + queueable);
				}

				for(Id workerId : workerIds) {
					updateableAsyncWorkerRecords.add(new AsyncWorker__c(Id = workerId, QueueableJobId__c = jobId));
				}
			} catch(Exception ex) {
				// log the error that prevented this async worker from running correctly.
				// it's important that we catch these errors to ensure that the queue never stops processing
				failedQueueWorkers.add(ex);

				System.debug('Exception: ' + ex);
				System.debug(ex.getStackTraceString());
			}
		}

		if(!updateableAsyncWorkerRecords.isEmpty()) {
			List<Database.SaveResult> saveResults = ApplicationDatabase.getInstance().dmlUpdate(updateableAsyncWorkerRecords, false);
			ApplicationLogger.getInstance().logFailedDatabaseResults(saveResults, ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWork.class), 'processAsyncWorkerQueue', '', ApplicationLogger.LoggingLevel.ERROR);
		}

		if(!failedQueueWorkers.isEmpty()) {
			// make sure we log and jobs that failed to be enqueued
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(failedQueueWorkers), ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWork.class), 'processAsyncWorkerQueue', '', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Handle the processing of our async workers
	 * Based on a specific criteria, some workers can be grouped together
	 * This is based on isGrouped() being true
	 */
	private with sharing class AsyncQueueable implements Queueable {
		Set<Id> groupedWorkerIds;

		public AsyncQueueable(Set<Id> groupedWorkerIds) {
			this.groupedWorkerIds = groupedWorkerIds;
		}

		public void execute(QueueableContext context) {
			handleExecution(groupedWorkerIds);
		}
	}

	/**
	 * Handle the processing of our async workers with an optional callout
	 * This queueable is automatically called when a single async worker is being enqueued (no grouping)
	 */
	private with sharing class AsyncQueueableWithCallout implements Queueable, Database.AllowsCallouts {
		Set<Id> groupedWorkerIds;

		public AsyncQueueableWithCallout(Set<Id> groupedWorkerIds) {
			this.groupedWorkerIds = groupedWorkerIds;
		}

		public void execute(QueueableContext context) {
			handleExecution(groupedWorkerIds);
		}
	}

	private static void handleExecution(Set<Id> groupedWorkerIds) {
		handleExecution(AsyncWorkerSelector.newInstance().selectById(groupedWorkerIds));
	}

	/**
	 * This is executed once we are inside a queueable context via AsyncQueueable / AsyncQueueableWithCallout
	 * There could be 1 or more workers grouped together
	 *
	 * Any workers grouped here will have gone through isLogicalGroup() method in order to be grouped.
	 * With this in mind, we can leverage the details of the first worker to get the current stack depth, stack and other key details
	 */
	public static void handleExecution(List<AsyncWorker__c> asyncWorkerRecords) {
		if(asyncWorkerRecords.isEmpty()) {
			return;
		}

		Integer currentStackDepth = (asyncWorkerRecords[0].CurrentStackDepth__c == null ? 0 : Integer.valueOf(asyncWorkerRecords[0].CurrentStackDepth__c));
		Integer maxNumberRetries = (asyncWorkerRecords[0].MaxNumberRetries__c == null ? 1 : Integer.valueOf(asyncWorkerRecords[0].MaxNumberRetries__c));
		Integer currentRetryCount = (asyncWorkerRecords[0].CurrentLockRetryAttempts__c == null ? 1 : Integer.valueOf(asyncWorkerRecords[0].CurrentLockRetryAttempts__c));
		String sObjectTypeGroup = (String.isEmpty(asyncWorkerRecords[0].SObjectTypeGroup__c) ? '' : asyncWorkerRecords[0].SObjectTypeGroup__c);
		String currentStack = (String.isEmpty(asyncWorkerRecords[0].CurrentStack__c) ? '' : asyncWorkerRecords[0].CurrentStack__c);
		String sObjectUnitOfWorkTypesJSON = asyncWorkerRecords[0].UnitOfWorkSObjectTypes__c;
		Id userId;

		// fail silently if incorrect data exists in this field
		try {
			userId = (Id)asyncWorkerRecords[0].UserId__c;
		} catch(Exception ex) {}

		// ==========================================================================================
		// THE MOST IMPORTANT STEP TO HELP MITIGATE INFINITE STACK DEPTH
		// ==========================================================================================
		// increase the current stack depth IMMEDIATELY!
		// track the stack depth and the stack so we can prevent an infinite loop
		// NOTE: We only increase the stack depth if the current worker was not forced into the current context due to the stack depth being exceeded
		//       ForcedIntoCurrentContext__c should only be populated when in ApplicationUnitOfWork.doAsyncWork()
		if(asyncWorkerRecords[0].ForcedIntoCurrentContext__c != true) {
			ApplicationUnitOfWork.currentAsyncStackDepth = currentStackDepth + 1;
		}

		// failsafe (hard coded to try and prevent infinite looping if other failsafes fail)
		if(ApplicationUnitOfWork.currentAsyncStackDepth > MAX_HARD_STACK_DEPTH) {
			throw new ApplicationUnitOfWork.AsyncUnitOfWorkException('Stack is too deep (failsafe)');
		}

		// set the current stack that led us to this async operation
		ApplicationUnitOfWork.currentAsyncStack = (String.isEmpty(currentStack) ? new List<String>() : currentStack.split('\n'));

		// set the user id here incase we go further down into the stack with subsequent exclusive async worker throughout the worker's execution cycle...
		ApplicationUnitOfWork.currentAsyncUserId = userId;

		System.debug('Stack information: ');
		System.debug('currentStackDepth: ' + ApplicationUnitOfWork.currentAsyncStackDepth);
		System.debug('currentStack: ' + ApplicationUnitOfWork.currentAsyncStack);
		System.debug('');
		System.debug('Handling queueable work: ');
		System.debug('sObjectUnitOfWorkTypesJSON: ' + sObjectUnitOfWorkTypesJSON);
		System.debug('userId: ' + userId);
		System.debug('maxNumberRetries: ' + maxNumberRetries);
		System.debug('currentRetryCount: ' + currentRetryCount);
		System.debug('sObjectTypeGroup: ' + sObjectTypeGroup);

		// stores a reference to the last used asyncWorker
		// we need this in the event of the worker requiring callouts and an exception is thrown
		// storing this reference allows us to call asyncWorker.getCalloutSavepoint();
		ApplicationUnitOfWork.IAsyncWorker asyncWorker;

		// create a savepoint to ensure that we can roll back the whole transaction if any lock errors occur
		// we only do this if the work does not require callouts since calling this prior to a callout, the callout would generate a CalloutException
		// if the work requires a callout, then it's the responsibility of the worker to call markCalloutSavepoint on IAsyncWorker (which would normally happen after a callout)
		System.Savepoint sp;
		if(!asyncWorkerRecords[0].RequiresCallouts__c) {
			sp = ApplicationDatabase.getInstance().dmlSetSavePoint();
		}

		try {

			List<AsyncWorker__c> deletableWorkerRecords = new List<AsyncWorker__c>();
			List<AsyncWorker__c> updatableWorkerRecords = new List<AsyncWorker__c>();

			// note, if this is configured incorrectly, then it will cause the execution of this queueable to fail without processing
			List<SObjectType> unitOfWorkSObjectTypes = new List<SObjectType>();
			if (!String.isEmpty(sObjectUnitOfWorkTypesJSON)) {
				for (String sObjectType : (List<String>) JSON.deserialize(sObjectUnitOfWorkTypesJSON, List<String>.class)) {
					unitOfWorkSObjectTypes.add(((SObject) Type.forName(sObjectType).newInstance()).getSObjectType());
				}
				if (unitOfWorkSObjectTypes == null) {
					unitOfWorkSObjectTypes = new List<SObjectType>();
				}
			}

			ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(unitOfWorkSObjectTypes);

			if(!asyncWorkerRecords[0].RequiresCallouts__c) {
				// tells the Unit of Work to throw an exception when it detects a lock error. This is irrespective of any row level configuration (throwOnError config with registerNew, registerDirty etc...)
				// we use this as a part of the retry capability in the 'catch' handler below
				// NOTE: This is only done in the event of an async worker not requiring a callout.
				//          Where a worker requires a callout, it's expected that the worker would manage this setting directly as needed!
				//          This is needed since committing the uow is done outside of the workers execution context
				//          REASONING: At times a worker performs a read callout which means it would be ok to re-run the worker, however in the event of a write, the retry logic may be undeseriable

				uow.throwLockErrors = true;
			}

			// execute all the workers grouped together in this queueable
			// co-ordinate any subsequent actions using a UOW
			for (AsyncWorker__c asyncWorkerRecord : asyncWorkerRecords) {
				// create a savepoint for the individual worker to rollback any database activity that occurs within that specific worker if an exception occurs
				// this is to allow any additional workers to continue their execution making any database changes necessary
				// NOTE: We do not do this for workers that require callouts as per above documentation
				System.Savepoint workerSavePoint;
				if(!asyncWorkerRecords[0].RequiresCallouts__c) {
					workerSavePoint = ApplicationDatabase.getInstance().dmlSetSavePoint();
				}

				// create an instance of the IAsyncWorker interface that will be used to process this transaction
				if (String.isEmpty(asyncWorkerRecord.ClassType__c)) {
					throw new ApplicationUnitOfWork.AsyncUnitOfWorkException('Class type can not be null, must be able to instantiate a worker');
				}

				// Add an entry to the stack so if registerAsyncWork is called it take a snap shot of the stack so it can copy it into a new AsyncWorker__e platform event
				// This helps keep track of the stack for debugging
				ApplicationUnitOfWork.currentAsyncStack.add('Worker: ' + asyncWorkerRecord.ClassType__c);
				Integer stackElement = ApplicationUnitOfWork.currentAsyncStack.size() - 1;

				// create an instance of the worker
				try {
					asyncWorker = (ApplicationUnitOfWork.IAsyncWorker)(Type.forName(asyncWorkerRecord.ClassType__c).newInstance());
					asyncWorker.setUserId(userId);

					// deserialise the parameters to allows the worker to use them in its execute method
					// NOTE: deserialise can be overridden by the worker if it needs to deserialise into a specific structure or if it wants to walk the json or whatever
					asyncWorker.deserialiseParams(String.join(new List<String>{asyncWorkerRecord.Parameters1__c, asyncWorkerRecord.Parameters2__c, asyncWorkerRecord.Parameters3__c, asyncWorkerRecord.Parameters4__c}, ''));

					asyncWorker.execute(uow);

					// since the worker execution completed successfully, we queue this record up for deletion (assuming uow.commitWork does not throw errors)
					deletableWorkerRecords.add(asyncWorkerRecord);
				} catch(Exception ex) {
					System.debug('Exception: ' + ex);
					// NOTE: the developer may choose to catch and handle errors directly which is ok

					// we need to check whether the exception thrown is a lock error or not
					if(isLockException(ex)) {
						// a lock error, we throw the error so the below catch block can handle and re-enqueue the entire group again (if the max number of attempts have not been exceeded)
						throw ex;
					} else if(asyncWorkerRecord.RequiresCallouts__c) {
						// this worker requires callouts, it will always be in it's own async container
						// if an exception occurs then we just throw the exception and let the main exception handler process this
						throw ex;
					} else {
						// since this worker threw an exception (thats not a lock exception), we don't want this to impede on the other workers that will run in this group
						// we rollback the database to the point before the worker ran and then continue to the next worker
						// A SPECIAL NOTE: if the worker is using UOW register* methods then database activity still might occur for this worker after all workers have been processed.
						ApplicationDatabase.getInstance().dmlRollback(workerSavePoint);

						// mark this worker as failed and then we can continue onto the next worker (if there is one)
						updatableWorkerRecords.addAll(attachErrorToAsyncWorkerRecords(new List<AsyncWorker__c>{asyncWorkerRecord}, ex));
					}
				} finally {
					// since the currentAsyncStack is a static, we need to remove the item we added above since we are finished that that processing
					ApplicationUnitOfWork.currentAsyncStack.remove(stackElement);
				}
			}

			// commit any work as a result of the executed workers
			// with throwLockErrors = true (set above), and lock errors will generate an UnitOfWorkDatabaseException (irrespective of any individual config at the async worker level)
			// NOTE: async workers that use callouts, must set throwLockErrors manually if needed to trigger a lock error
			uow.commitWork();

			// put this into it's own try catch block to ensure a lock error here doesn't result in all the workers being re-enqueued
			if(!deletableWorkerRecords.isEmpty()) {
				try {
					// remove the AsyncWorker__c records because we are now finished with them
					ApplicationDatabase.getInstance().dmlDelete(deletableWorkerRecords);
				} catch (Exception ex) {
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWork.class), 'handleExecution', '', ApplicationLogger.LoggingLevel.ERROR);
				}
			}

			// put this into it's own try catch block to ensure a lock error here doesn't result in all the workers being re-enqueued
			if(!updatableWorkerRecords.isEmpty()) {
				try {
					// remove the AsyncWorker__c records because we are now finished with them
					ApplicationDatabase.getInstance().dmlUpdate(updatableWorkerRecords);
				} catch (Exception ex) {
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWork.class), 'handleExecution', '', ApplicationLogger.LoggingLevel.ERROR);
				}
			}
		} catch(Exception ex) {

			// NOTE: We catch exceptions to log errors from the workers but also to check if there were lock errors which can be retried
			//          This catches errors thrown from the worker itself (incase the work is doing direct dmls for example), or, from the UOW (commitWork)
			// when an exception occurs, we need to rollback all the database activity from the last save point
			if(asyncWorker == null) {
				// for whatever reason we did not get to the point of even instantiating a new worker.
				// this means it's probably an error with the framework or with the data that was passed in.
				throw new ApplicationUnitOfWork.AsyncUnitOfWorkException('AsyncWorker was empty');
			} else if(asyncWorkerRecords[0].RequiresCallouts__c) {
				if(asyncWorker.getCalloutSavepoint() != null) {
					// if the async worker has marked a savepoint then we rollback the transaction to that point
					// marking a save point is optional as the rollback might need to NOT happen in some scenarios
					ApplicationDatabase.getInstance().dmlRollback(asyncWorker.getCalloutSavepoint());
				}
			} else {
				ApplicationDatabase.getInstance().dmlRollback(sp);
			}

			if(isLockException(ex) && currentRetryCount < maxNumberRetries) {
				// the transaction needs to be retried since it failed because of a lock error
				System.debug('UNABLE_TO_LOCK_ROW, queueing the work to be processed again');
				System.debug(ex);

				// build a list of platform events to republish since this transaction failed
				List<AsyncWorkerEvent__e> events = new List<AsyncWorkerEvent__e>();
				for(AsyncWorker__c asyncWorkerRecord : asyncWorkerRecords) {
					AsyncWorkerEvent__e ev = convertAsyncWorkerRecordToEvent(asyncWorkerRecord);
					ev.CurrentLockRetryAttempts__c = (ev.CurrentLockRetryAttempts__c == null ? 0 : Integer.valueOf(ev.CurrentLockRetryAttempts__c));
					ev.CurrentLockRetryAttempts__c++;
					events.add(ev);
				}

				// requeue the workers for reprocessing
				if(!events.isEmpty()) {
					ApplicationDatabase.getInstance().eventPublish(events);
				}

				// remove the records that will be retried (these will be added as new records)
				ApplicationDatabase.getInstance().dmlDelete(asyncWorkerRecords);
			} else {
				// Update for the main exception handler scenario which would cover framework exception errors or lock error retry attempts are exceeded
				// INdividual workers individual exceptions are handles as each worker is processed and would not be processed here
				try {
					ApplicationDatabase.getInstance().dmlUpdate(attachErrorToAsyncWorkerRecords(asyncWorkerRecords, ex));
				} catch (Exception exp) {
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(exp), ApplicationUnitOfWork.LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWork.class), 'handleExecution', '', ApplicationLogger.LoggingLevel.ERROR);
				}
			}
		}
	}

	private static List<AsyncWorker__c> attachErrorToAsyncWorkerRecords(List<AsyncWorker__c> asyncWorkerRecords, Exception ex) {
		List<AsyncWorker__c> output = new List<AsyncWorker__c>();

		String error = ex.getTypeName() + ': ' + ex.getMessage() + '\n' +
				ex.getStackTraceString();

		for (AsyncWorker__c asyncWorkerRecord : asyncWorkerRecords) {
			output.add(new AsyncWorker__c(Id = asyncWorkerRecord.Id, CurrentStack__c = String.join(ApplicationUnitOfWork.currentAsyncStack, '\n'), IsError__c = true, LastError__c = error));
		}

		return output;
	}

	/**
	 * A lock could present itself in 1 of 2 ways:
	 * 1. If the developer is calling DML's directly then a DmlException would be thrown
	 * 2. If the developer is using ApplicationUnitOfWork then it processes then inserts, updates, deletes that cause a lock error will be wrapped in UnitOfWorkDatabaseException
	 */
	private static Boolean isLockException(Exception ex) {
		Boolean isLock = (ex instanceof DmlException && ex.getMessage().contains('UNABLE_TO_LOCK_ROW'));
		if(!isLock) {
			isLock = (ex instanceof ApplicationUnitOfWorkBase.UnitOfWorkDatabaseException && ((ApplicationUnitOfWorkBase.UnitOfWorkDatabaseException)ex).containsLockError());
		}
		return isLock;
	}

	/**
	 * Will populate an AsyncWorker__c record from an AsyncWorkerEvent__e record
	 */
	private static AsyncWorker__c convertAsyncEventToWorkerRecord(AsyncWorkerEvent__e event) {
		AsyncWorker__c asyncWorker = new AsyncWorker__c();
		for(SObjectField field : WORKER_RECORD_MAPPINGS.keySet()) {
			asyncWorker.put(WORKER_RECORD_MAPPINGS.get(field), event.get(field));
		}
		return asyncWorker;
	}

	/**
	 * Will populate an AsyncWorkerEvent__e record from an AsyncWorker__c record
	 */
	private static AsyncWorkerEvent__e convertAsyncWorkerRecordToEvent(AsyncWorker__c workerRecord) {
		AsyncWorkerEvent__e asyncWorkerEvent = new AsyncWorkerEvent__e();
		for(SObjectField field : WORKER_RECORD_MAPPINGS.keySet()) {
			asyncWorkerEvent.put(field, workerRecord.get(WORKER_RECORD_MAPPINGS.get(field)));
		}
		return asyncWorkerEvent;
	}





























//	public class APICalloutException extends Exception {
//		public APICalloutException(Integer responseCode, String responseBody, Set<Id> workerRecordIds) {
//			setMessage('Callout Failure: ' + responseCode + ': ' + responseBody + '\n' + String.join(new List<Id>(workerRecordIds), ','));
//		}
//	}
//	public static void TEST_runCalloutExecute() {
////		AsyncWorker__c workerRecord = new AsyncWorker__c();
////		workerRecord.ClassType__c = 'ApplicationUnitOfWorkAsyncEventHandler.MyAsyncWorker1';
////		workerRecord.UserId__c = UserInfo.getUserId();
////		workerRecord.CurrentStack__c = '';
////		workerRecord.CurrentStackDepth__c = 0;
////		workerRecord.SObjectTypeGroup__c = '';
////		workerRecord.UnitOfWorkSObjectTypes__c = '["Contact"]';
////		workerRecord.CurrentLockRetryAttempts__c = 0;
////		workerRecord.MaxNumberRetries__c = 0;
////
////		ApplicationDatabase.getInstance().dmlInsert(new List<SObject>{workerRecord});
////		System.enqueueJob(new AsyncQueueableAPICallout(new Set<Id>{workerRecord.Id}));
//
//		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(new List<SObjectTYpe> {
//				Contact.getSObjectType()
//		});
//
//		ApplicationUnitOfWork.AsyncStagingWorker stagingWorker = new ApplicationUnitOfWork.AsyncStagingWorker();
//		stagingWorker.classType = MyAsyncWorker1.class;
//		stagingWorker.params = new Map<String, Object>{
//				'key1' => 'value1'
//		};
//		uow.registerAsyncWork(stagingWorker);
//
//
//		uow.commitWork();
//
//	}
//
//	public class MyAsyncWorker1 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker1');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//
////			Contact con = new Contact(Id = '0030l00000YFJCv', HomePhone = '133931');
////			uow.registerDirty(con);
//
//			ApplicationUnitOfWork.AsyncStagingWorker worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker2.class;
//			uow.registerAsyncWork(worker);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker1.class;
//		}
//	}
//
//	public class MyAsyncWorker2 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker2');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//
////			Contact con = new Contact(Id = '0030l00000YFJCv', HomePhone = '133932');
////			uow.registerDirty(con);
//
//			ApplicationUnitOfWork.AsyncStagingWorker worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker3.class;
//			uow.registerAsyncWork(worker);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker2.class;
//		}
//	}
//
//	public class MyAsyncWorker3 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker3');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//
////			Contact con = new Contact(Id = '0030l00000YFJCv', HomePhone = '133932');
////			uow.registerDirty(con);
//
//			ApplicationUnitOfWork.AsyncStagingWorker worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker4.class;
//			uow.registerAsyncWork(worker);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker3.class;
//		}
//	}
//
//	public class MyAsyncWorker4 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker4');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//
////			Contact con = new Contact(Id = '0030l00000YFJCv', HomePhone = '133932');
////			uow.registerDirty(con);
//
//			ApplicationUnitOfWork.AsyncStagingWorker worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker5.class;
//			worker.sObjectGroup = Contact.getSObjectType();
//			uow.registerAsyncWork(worker);
//
//			worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker6.class;
//			worker.sObjectGroup = Contact.getSObjectType();
//			uow.registerAsyncWork(worker);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker4.class;
//		}
//	}
//
//	public class MyAsyncWorker5 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker5');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//
//			ApplicationUnitOfWork.AsyncStagingWorker worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker7.class;
//			uow.registerAsyncWork(worker);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker5.class;
//		}
//	}
//
//	public class MyAsyncWorker6 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker6');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//
//			ApplicationUnitOfWork.AsyncStagingWorker worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker8.class;
//			uow.registerAsyncWork(worker);
//
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker6.class;
//		}
//	}
//
//	public class MyAsyncWorker7 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker7');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//
//			ApplicationUnitOfWork.AsyncStagingWorker worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker9.class;
//			uow.registerAsyncWork(worker);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker7.class;
//		}
//	}
//
//	public class MyAsyncWorker8 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker8');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//
//			ApplicationUnitOfWork.AsyncStagingWorker worker = new ApplicationUnitOfWork.AsyncStagingWorker();
//			worker.classType = MyAsyncWorker10.class;
//			uow.registerAsyncWork(worker);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker8.class;
//		}
//	}
//
//	public class MyAsyncWorker9 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker9');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker9.class;
//		}
//	}
//
//	public class MyAsyncWorker10 extends ApplicationUnitOfWork.AsyncWorker {
//		public override void execute(ApplicationUnitOfWork uow) {
//			System.debug('MyAsyncWorker10');
//			System.debug(ApplicationUnitOfWork.currentAsyncStack);
//			System.debug(ApplicationUnitOfWork.currentAsyncStackDepth);
//		}
//		public override Type getClassType() {
//			return MyAsyncWorker10.class;
//		}
//	}
}