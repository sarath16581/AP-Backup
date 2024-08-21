/**
 * @description
 * Handles Async Operations
 *
 * The Async flow:
 * 1. UOW registers async work (ApplicationUnitOfWork)
 * 2. UOW triggers Platform Events on commit (ApplicationUnitOfWork)
 * 3. Platform Event handler (builds list of records that be enqueued in a single transaction) (ApplicationUnitOfWorkAsync)
 * 4. processAsyncWorkerQueue // << TODO update description
 *
 * @author Nathan Franklin
 * @date 2020-09-01
 * @changelog
 */
global virtual inherited sharing class ApplicationUnitOfWork extends ApplicationUnitOfWorkBase {


	public static String LOGGING_APP_NAME = 'ApplicationUnitOfWork';

	/**
	 * Instruction for processing an async action when already in an async context
	 */
	public enum ASYNC_MAX_DEPTH_ENQUEUE_ACTION {
		PROCESS_SYNC,
		FORCE_ASYNC, // This would only be used in scenarios that require a callout or mixed_dml operations and can't be processed in sync
		DISCARD_AND_LOG,
		THROW_EXECPTION
	}

	/**
	 * List of async actions that should be grouped together in a single async operation
	 * If the context is already an async context then these actions will be grouped into the same current context
	 * If the context is synchronous then these actions will be grouped together in a new queueable action
	 */
	private List<AsyncStagingWorker> m_asyncWorkList = new List<AsyncStagingWorker>();

	/**
	 * The maximum size of the platform event stack trace
	 */
	public static final Integer STACK_TRACE_MAXIMUM_SIZE_IN_BYTES = 131072;

	/**
	 * A testing class hack to override the static MAX_QUEUEABLES_PER_PLATFORM_EVENT_ITERATION
	 */
	@TestVisible
	private static Integer testClassMaxAsyncStackDepth = 0;

	/**
	 * The maximum stack depth that an async operation can kick off
	 * NOTE: This value should remain as low as possible, usually between 3-6
	 * NOTE: This value should never be reduced without THOROUGH analysis being completed. Reducing this value could cause many failures!
	 * NOTE: This value should never be increased without THOROUGH analysis being completed. Increasing this value could cause unintended consequences
	 */
	@TestVisible
	private static final Integer MAX_ASYNC_STACK_DEPTH {
		get {
			if(MAX_ASYNC_STACK_DEPTH == null) {
				if(Test.isRunningTest() && testClassMaxAsyncStackDepth != 0) {
					MAX_ASYNC_STACK_DEPTH = testClassMaxAsyncStackDepth;
				} else {
					SystemSettings__c settings = SystemSettings__c.getInstance();
					MAX_ASYNC_STACK_DEPTH = Integer.valueOf((settings?.AsyncFrameworkMaxStackDepth__c == null ? 4 : settings.AsyncFrameworkMaxStackDepth__c));
				}
			}
			return MAX_ASYNC_STACK_DEPTH;
		}
		private set;
	}

	/**
	 * The maximum number of attempts to retry an async work if it fails due to a lock error
	 */
	public static final Integer MAX_LOCK_FAIL_RETRY_ATTEMPTS = 3;

	@TestVisible
	private static final Integer MAX_ASYNC_WORKER_PARAMETER_FIELD_SIZE = 131072;

	private static final Integer MAX_MESSAGE_LOG_SIZE = 32768;

	/**
	 * The current depth of an async operation.
	 * Note, async operations can launch async operations which can launch async operations
	 * IMPORTANT: This should never be set directly EVER. The framework is responsible for maintaining this
	 */
	public static Integer currentAsyncStackDepth {
		get {
			if(currentAsyncStackDepth == null) {
				currentAsyncStackDepth = 0;
			}
			return currentAsyncStackDepth;
		}
		set;
	}

	/**
	 * A string representation of the current async stack
	 * This will contain 2 types of items:
	 * Triggers
	 * Workers
	 *
	 * Trigger will be based on the trigger handler's instantiates UOW directly before any async operation being enqueued (if any)
	 * Worker will be the parent async worker that trigger the enqueueing of a subsequent worker
	 *
	 * Example of of how this is populated:
	 * [Trigger - ContactTriger] -> [Register Worker in trigger UOW - MyWorker1] -> [Commit] -> [Execute Worker] = "Trigger: ContactTrigger"
	 * [Trigger - ContactTriger] -> [Register Worker in trigger UOW - MyWorker1] -> [Commit] -> [Execute Worker] -> [Trigger - AccountTrigger] -> [Register Worker in trigger UOW - MyWorker2] -> [Commit] -> [Execute Worker]
	 *              = Trigger: ContactTrigger
	 *                Worker: MyWorker1
	 *                Trigger: AccountTrigger
	 */
	public static List<String> currentAsyncStack {
		get {
			if(currentAsyncStack == null) {
				currentAsyncStack = new List<String>();
			}
			return currentAsyncStack;
		}
		set;
	}

	/**
	 * Stores the User Id when an exclusive async worker is queued.
	 * This is because we use Platform Events to queue exclusive workers up where the UserInfo.getUserId() is the Automated Process user
	 */
	public static Id currentAsyncUserId {
		get {
			if(currentAsyncUserId == null) {
				currentAsyncUserId = UserInfo.getUserId();
			}
			return currentAsyncUserId;
		}
		// will be set in our exclusive async worker queueable
		set;
	}

	/**
	 * Provides a mockable interface for unit testing
	 */
	public static ApplicationUnitOfWork newInstance(List<Schema.SObjectType> sObjectTypes) {
		ApplicationUnitOfWork unitOfWork = (ApplicationUnitOfWork)Application.Utilities.newInstance(ApplicationUnitOfWork.class);
		unitOfWork.registerSObjectTypes(sObjectTypes);
		return unitOfWork;
	}

	/**
	 * Register an async operation
	 **/
	public void registerAsyncWork(AsyncStagingWorker stagedWorker) {

		// test the worker to ensure it's ok
		try {
			IAsyncWorker worker = (IAsyncWorker) stagedWorker.classType.newInstance();

			// double check to make sure an async worker can not retry more than what it should
			if (worker.getRetryAttemptsOnLockFailure() > MAX_LOCK_FAIL_RETRY_ATTEMPTS) {
				throw new AsyncUnitOfWorkException('Can not register async worker. Retry attempts exceeds maximum allowed attempts');
			}

			// make sure the async worker will not exceed stack depth if it isn't allowed to
			if(currentAsyncStackDepth >= MAX_ASYNC_STACK_DEPTH && worker.getMaxDepthAction() == ASYNC_MAX_DEPTH_ENQUEUE_ACTION.THROW_EXECPTION) {
				throw new AsyncUnitOfWorkException('Can not register async worker. Max depth will be exceeded');
			}
		} catch(AsyncUnitOfWorkException ex) {
			throw ex;
		} catch(Exception ex) {
			throw new AsyncUnitOfWorkException('Can not register async worker. Type is invalid');
		}

		// make sure the the params serialise into less than 110k
		// if any of the objects in the params are references to SObjects, the resolve relationships calls in UOW should populate their corresponding field ids which could increase the size of the payload...
		// TODO... The performance impacts here would most likely be significant...
		//         This should possibly be removed and a failure should be logged in the asynchronous context
		//		if(stagedWorker.params != null && JSON.serialize(stagedWorker.params).length() > MAX_ASYNC_WORKER_PARAMETER_FIELD_SIZE) {
		//			throw new AsyncUnitOfWorkException('Can not register async worker. Parameter size exceeds allowed limit');
		//		}

		// store the async stack to be propagated to the platform event
		stagedWorker.currentStack = String.join(currentAsyncStack, '\n');

		m_asyncWorkList.add(stagedWorker);
	}

	public Integer getAsyncWorkCount() {
		return m_asyncWorkList.size();
	}

	protected override void onDMLFinished() {
		registerEmailAsyncWork();	
		doAsyncWork();
	}

	/**
	 * Register asyncworker for email notifications (if there are any)
	 */
	private void registerEmailAsyncWork() {
		// retrieve all pending email notifications from the ApplicationEmailService registry (and clear the registry at the some time)
		List<ApplicationFlowEmailType> flowEmailNotifications = ApplicationEmailService.getInstance().removeAllPendingEmailNotifications();
		
		// if there are any pending email notifications, register a worker to send the email notifications asynchronously
		if (!flowEmailNotifications.isEmpty()) {
			registerAsyncWork(new AsyncStagingWorker(FlowEmailAsyncWorker.class, flowEmailNotifications));
		}
	}

	/**
	 * Handle next steps for asynchronous actions.
	 */
	private void doAsyncWork() {
		if (!m_asyncWorkList.isEmpty()) {

			// serialise the SObjectTypes into a List<String> so we can
			List<String> sObjectTypes = new List<String>();
			String sObjectTypesJSON = '';
			for(SObjectType sObjectType : m_sObjectTypes) {
				sObjectTypes.add(String.valueOf(sObjectType));
			}
			sObjectTypesJSON = JSON.serialize(sObjectTypes);

			List<AsyncWorkerEvent__e> events = new List<AsyncWorkerEvent__e>();
			List<String> discardedMessages = new List<String>();
			List<String> discardedAdditionalInformation = new List<String>();

			// this is used for processing workers that can't be enqueued into a new transaction given their instruction is to process in sync when the max depth has been reached
			// this is a failsafe more than anything which hopefully shouldn't be needed
			List<AsyncWorker__c> workersToProcessInCurrentContext = new List<AsyncWorker__c>();

			for (AsyncStagingWorker stagedWorker : m_asyncWorkList) {
				// grab an instance of the worker to so we know what the next action to take is
				IAsyncWorker worker = (IAsyncWorker)stagedWorker.classType.newInstance();

				if (currentAsyncStackDepth >= MAX_ASYNC_STACK_DEPTH && worker.getMaxDepthAction() == ASYNC_MAX_DEPTH_ENQUEUE_ACTION.DISCARD_AND_LOG) {

					// our enqueued staged worker will not be processed since we have reached the max stack depth and the instruction is to discard the work
					// I would expect DISCARD_AND_LOG would not be used too much
					String message = 'Discarded async worker due to max stack depth being reached\n' +
							String.valueOf(stagedWorker.classType) + '\n\n' +
							'Current Depth: ' + currentAsyncStackDepth + '\n' +
							'Max Depth: ' + MAX_ASYNC_STACK_DEPTH + '\n' +
							'Stack:\n' + stagedWorker.currentStack;

					// TODO Make a setting or const or something..?

					if (message.length() > MAX_MESSAGE_LOG_SIZE) {
						message = message.left(MAX_MESSAGE_LOG_SIZE-3) + '...';
					}

					String params = JSON.serialize(stagedWorker.params);
					if (!String.isEmpty(params) && params.length() > MAX_ASYNC_WORKER_PARAMETER_FIELD_SIZE) {
						params = params.substring(0, MAX_ASYNC_WORKER_PARAMETER_FIELD_SIZE-3) + '...';
					}

					discardedMessages.add(message);
					discardedAdditionalInformation.add(params);

				} else if(currentAsyncStackDepth < MAX_ASYNC_STACK_DEPTH || worker.getMaxDepthAction() == ASYNC_MAX_DEPTH_ENQUEUE_ACTION.FORCE_ASYNC || worker instanceof Database.AllowsCallouts) {
					// this scenario is where we haven't yet reached the max stack depth OR the worker is forcing a new async container
					// usually an async worker will force an async container if it's doing a callout or a mixed_dml operation
					System.debug('Pushing into Platform Event Queueable');
					System.debug(stagedWorker);

					String stack = stagedWorker.currentStack.left(STACK_TRACE_MAXIMUM_SIZE_IN_BYTES);

					// add a new platform event where a new queueable will be kicked off for this piece of work
					// NOTE: That the attributes defined in the worker are snapshotted to ensure these aren't modified inside the actual async execution
					AsyncWorkerEvent__e workerEvent = new AsyncWorkerEvent__e(
							UserId__c = currentAsyncUserId,
							ClassType__c = String.valueOf(stagedWorker.classType),
							CurrentStackDepth__c = currentAsyncStackDepth,
							CurrentStack__c = stack,
							UnitOfWorkSObjectTypes__c = sObjectTypesJSON,
							CurrentLockRetryAttempts__c = 0,
							MaxNumberRetries__c = worker.getRetryAttemptsOnLockFailure(),
							SObjectTypeGroup__c = (worker.getSObjectTypeGroup() != null ? String.valueOf(worker.getSObjectTypeGroup()) : ''),
							RequiresCallouts__c = (worker instanceof Database.AllowsCallouts)
					);

					// split the parameters up into upto 4 additional fields
					// this allows us to send upto 131072*4 = 524k of parameters data
					List<String> serialisedParametersParts = splitByCharacterLength(JSON.serialize(stagedWorker.params), MAX_ASYNC_WORKER_PARAMETER_FIELD_SIZE);
					for(Integer i=0;i<Math.min(3, serialisedParametersParts.size());i++) {
						workerEvent.put('Parameters' + (i+1) + '__c', serialisedParametersParts[i]);
					}

					events.add(workerEvent);

				} else if (currentAsyncStackDepth >= MAX_ASYNC_STACK_DEPTH && (worker.getMaxDepthAction() == null || worker.getMaxDepthAction() == ASYNC_MAX_DEPTH_ENQUEUE_ACTION.PROCESS_SYNC)) {
					// rather than enqueueing this work into an additional async container, we process this work in the existing container since we have reached the maximum stack depth allowed
					// This requires us to create  new async worker record so the work can be executed in the same way it does for other work
					// NOTE: The work to be processed int he current context will all be grouped together irrespective of the grouping rules
					// NOTE: These workers will NEVER have callouts...

					System.debug('Processing additional async worker in the current context since the stack depth would be exceeded');
					System.debug(stagedWorker);

					String stack = stagedWorker.currentStack.left(STACK_TRACE_MAXIMUM_SIZE_IN_BYTES);

					// NOTE: That the attributes defined in the worker are snapshotted to ensure these aren't modified inside the actual async execution
					AsyncWorker__c workerRecord = new AsyncWorker__c(
							UserId__c = currentAsyncUserId,
							ClassType__c = String.valueOf(stagedWorker.classType),
							CurrentStackDepth__c = currentAsyncStackDepth,
							CurrentStack__c = stack,
							UnitOfWorkSObjectTypes__c = sObjectTypesJSON,
							CurrentLockRetryAttempts__c = 0,
							MaxNumberRetries__c = worker.getRetryAttemptsOnLockFailure(),
							SObjectTypeGroup__c = (worker.getSObjectTypeGroup() != null ? String.valueOf(worker.getSObjectTypeGroup()) : ''),
							RequiresCallouts__c = (worker instanceof Database.AllowsCallouts), // <-- will ALWAYS be false
							ForcedIntoCurrentContext__c = true // Signal to ensure the stack depth is not increased since we are processing this in the same transaction
					);

					// split the parameters up into upto 4 additional fields
					// this allows us to send upto 131072*4 = 524k of parameters data
					List<String> serialisedParametersParts = splitByCharacterLength(JSON.serialize(stagedWorker.params), MAX_ASYNC_WORKER_PARAMETER_FIELD_SIZE);
					for(Integer i=0;i<Math.min(3, serialisedParametersParts.size());i++) {
						workerRecord.put('Parameters' + (i+1) + '__c', serialisedParametersParts[i]);
					}

					workersToProcessInCurrentContext.add(workerRecord);

				}
			}

			// for any async workers to require a new container for execution
			if(!events.isEmpty()) {
				// This will trigger ApplicationUnitOfWorkAsyncEventHandler in a new transaction
				ApplicationDatabase.getInstance().eventPublish(events);
			}

			// check if any async workers were discarded due to max depth being reached
			// if we have to discard and not execute then we add a log entry
			if(!discardedMessages.isEmpty()) {
				System.debug('Adding new discarded logs');
				System.debug(discardedMessages);
				System.debug(discardedAdditionalInformation);
				ApplicationLogger.getInstance().logMessage(discardedMessages, discardedAdditionalInformation, LOGGING_APP_NAME, String.valueOf(ApplicationUnitOfWork.class), 'doAsyncWork', '', ApplicationLogger.LoggingLevel.ERROR);
			}

			// any workers needing to be processed in the current context? (because the max stack depth has been reached)
			if(!workersToProcessInCurrentContext.isEmpty()) {
				System.debug('Pushing workers to be processed into the current context');

				ApplicationDatabase.getInstance().dmlInsert(workersToProcessInCurrentContext);

				// execute the workers (in the current context)
				// NOTE: That lock errors would force a separate container for these workers (in which the framework would correctly group)
				// It means the behaviour would be inconsistent, but can't think of another way to do it without making the solution more complex
				ApplicationUnitOfWorkAsyncEventHandler.handleExecution(workersToProcessInCurrentContext);
			}
		}
	}

	/**
	 * Adds the email to registry. The email notification is only dispatched when commitWork is invoked.
	 *
	 * @param srcRecordId id of the record related to the email notification.
	 * @param srcObjectType object type of the record.
	 * @param emailAlertName API name of the pre-configured workflow email alert that will be invoked
	 */
	public void queueEmailNotification(Id srcRecordId, sObjectType srcObjectType, String emailAlertName) {
		ApplicationEmailService.getInstance().queueEmailNotification(srcRecordId, srcObjectType, emailAlertName);
	}

	/**
	 * This will explode a string based on the length passed in. This is useful where we want to break a string up into multiple smaller size strings
	 * NOTE: The performance of this was measured based on 600k string splitting up by 50k chunks and the total processing time was 2-3ms which is acceptable performance
	 */
	private List<String> splitByCharacterLength(String str, Integer length) {
		//Application.Profiler.start('Breakup');

		List<String> parts = new List<String>();

		Integer currentLength = str.length();
		Integer i = 0;
		while(true) {
			parts.add(str.mid((length*i), length));
			i++;

			if((length*i) >= currentLength) {
				break;
			}
		}

		//Application.Profiler.stop('Breakup');

		return parts;
	}

	/**
	 * A base class that other async workers can extend. Provides a basic framework.
	 * NOTE: An AsyncWorker should implement Database.AllowCallouts if it needs to make a callout
	 */
	public abstract class AsyncWorker implements IAsyncWorker {

		protected System.Savepoint calloutSavepoint;

		protected Object params;

		// This will be the user id that enqueued the exclusive async worker
		protected Id userId;


		/**
		 * Where the worker is making a callout, the savepoint needs to be managed directly by the async worker
		 * This method will be invoked automatically at the conclusion of the workers execution by the internal orchestrator
		 * This method works in conjunction with markCalloutSavepoint and is only used when asyn worker implements Database.AllowsCallouts
		 */
		public virtual System.Savepoint getCalloutSavepoint() {
			return calloutSavepoint;
		}

		/**
		 * Method is used to set a rollback point in the case of when an exception is thrown (lock error for example)
		 * This is only needed if the async worker implements Database.AllowsCallouts. Savepoint is generated automatically where there are no callouts involved.
		 * If no savepoint is set, then no rollback will occur if an exception is thrown
		 */
		public virtual void markCalloutSavepoint(System.Savepoint savepoint) {
			calloutSavepoint = savepoint;
		}

		public virtual Object getParams() {
			return params;
		}

		/**
		 * Where deserialisation is not needed, setParams simply sets the param variable directly
		 * This never needs to be called directly apart from how the framework invokes it
		 */
		public void setParams(Object deserialisedParams) {
			this.params = params;
		}

		/**
		 * By default params is serialised into JSON. There may be need a deserialise this in a specific way.
		 * deserialiseParam can be overridden to walk or deserialise into a concrete class
		 * This is invoked by the framework and it should get this.params in the process
		 */
		public virtual void deserialiseParams(String serialisedParams) {
			if(!String.isEmpty(serialisedParams)) {
				this.params = JSON.deserializeUntyped(serialisedParams);
			}
		}

		public virtual void setUserId(Id userId) {
			this.userId = userId;
		}

		public virtual Id getUserId() {
			return this.userId;
		}

		/**
		 * Determines which enqueue action to take when the transaction is already asynchronous
		 * Possible values:
		 *  process_sync: process the additional work synchronously
		 *  discard_and_log: do not do anything with this work and discard the work to be completed and store a log in Application_Log__c
		 *  throw_exception: throw an exception and stop the entire current transaction from completing successfully
		 *  force_async
		 *
		 * NOTE: This is 'serialised' at the time of enqueueing the async operation to ensure the values won't be modified inside the actual async operation which could impact grouping and have other unintended consequences
		 */
		public virtual ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction() {
			return ASYNC_MAX_DEPTH_ENQUEUE_ACTION.PROCESS_SYNC;
		}

		/**
		 * Use this to group asynchronous processing together reducing the risk of overall parallel lock contention.
		 * This should be the primary object that will be updated in the asynchronous process.
		 * Passing null into this variable will force an exclusive async container (used for things like MIXED_DML processing)
		 *
		 * NOTE: This is 'serialised' at the time of enqueueing the async operation to ensure the values won't be modified inside the actual async operation which could impact grouping and have other unintended consequences
		 */
		public virtual SObjectType getSObjectTypeGroup() {
			return null;
		}

		/**
		 * This value must not exceed MAX_LOCK_FAIL_RETRY_ATTEMPTS
		 * NOTE: This is 'serialised' at the time of enqueueing the async operation to ensure the values won't be modified inside the actual async operation which could impact grouping and have other unintended consequences
		 */
		public virtual Integer getRetryAttemptsOnLockFailure() {
			return MAX_LOCK_FAIL_RETRY_ATTEMPTS;
		}

		public abstract void execute(ApplicationUnitOfWork uow);

		public abstract Type getClassType();

	}

	public interface IAsyncWorker {

		System.Savepoint getCalloutSavepoint();
		void markCalloutSavepoint(System.Savepoint savepoint);

		Object getParams();

		/**
		 * Where deserialisation is not needed, setParams simply sets the param variable directly
		 * This never needs to be called directly apart from how the framework invokes it
		 */
		void setParams(Object deserialisedParams);

		/**
		 * By default params is serialised into JSON. There may be need a deserialise this in a specific way.
		 * deserialiseParam can be overridden to walk or deserialise into a concrete class
		 * This is invoked by the framework and it should get this.params in the process
		 */
		void deserialiseParams(String params);

		// This will be the user id that enqueued the exclusive async worker
		void setUserId(Id userId);
		Id getUserId();

		/**
		 * Must be overridden and a concrete type returned.
		 */
		Type getClassType();

		/**
		 * Use this to group asynchronous processing together reducing the risk of overall parallel lock contention.
		 * This should be the primary object that will be updated in the asynchronous process.
		 * Passing null into this variable will force an exclusive async container (used for things like MIXED_DML processing)
		 *
		 * NOTE: This is 'serialised' at the time of enqueueing the async operation to ensure the values won't be modified inside the actual async operation which could impact grouping and have other unintended consequences
		 */
		SObjectType getSObjectTypeGroup();

		/**
		 * Determines which enqueue action to take when the transaction is already asynchronous
		 * Possible values:
		 *  process_sync: process the additional work synchronously
		 *  discard_and_log: do not do anything with this work and discard the work to be completed and store a log in Application_Log__c
		 *  throw_exception: throw an exception and stop the entire current transaction from completing successfully
		 *
		 * NOTE: This is 'serialised' at the time of enqueueing the async operation to ensure the values won't be modified inside the actual async operation which could impact grouping and have other unintended consequences
		 */
		ASYNC_MAX_DEPTH_ENQUEUE_ACTION getMaxDepthAction();

		/**
		 * This value must not exceed MAX_LOCK_FAIL_RETRY_ATTEMPTS
		 *
		 * NOTE: This is 'serialised' at the time of enqueueing the async operation to ensure the values won't be modified inside the actual async operation which could impact grouping and have other unintended consequences
		 */
		Integer getRetryAttemptsOnLockFailure();

		/**
		 * Execute this async worker.
		 * The work should populate a uow which will be committed at the end of the process
		 */
		void execute(ApplicationUnitOfWork uow);

	}

	/**
	 * A staging class for allowing an async worker to be queued up for processing
	 */
	public class AsyncStagingWorker {

		/**
		 * Will be set by the framework. This is to track the current stack of when the item was enqueued for processing
		 * Global search for "currentAsyncStack.add" should produce all the parts of the code where the stack is added to.
		 * TODO: WIP
		 */
		private String currentStack = '';

		/**
		 * Must implement IAsyncWorker interface
		 */
		public Type classType;

		/**
		 * Parameters to pass into the async queueable. This is serialised into JSON and split across multiple long text fields (Currently 4 - upto 524k of data).
		 * Care must be taken in determining what parameters should be passed into an Async Worker.
		 * Remember to account for bulk operations of up to 200 records being passed in. Best practice is to only pass Id's and simple values.
		 * Do not pass sObjects into this as the serialising will cause performance problems and likely exceed size limits (in bulk operations)
		 * NOTE: JSON serialisation is SLOW. Only pass what you absolutely have to!
		 */
		public Object params;

		/**
		 * @param classType Must implement IAsyncWorker interface
		 */
		public AsyncStagingWorker(Type classType) {
			this(classType, null);
		}

		/**
		 * @param classType Must implement IAsyncWorker interface
		 * @param params Parameters to pass into the async queueable. This is serialised into JSON and split across multiple long text fields (Currently 4 - upto 524k of data). Care must be taken in determining what parameters should be passed into an Async Worker. Remember to account for bulk operations of up to 200 records being passed in. Best practice is to only pass Id's and simple values. Do not pass sObjects into this as the serialising will cause performance problems and likely exceed size limits (in bulk operations)
		 */
		public AsyncStagingWorker(Type classType, Object params) {
			this.classType = classType;
			this.params = params;
		}

	}

	/**
	 * AsyncWorker for sending out email notifications registered to the ApplicationEmailService through the unit of work
	 * 
	 */
	public class FlowEmailAsyncWorker extends AsyncWorker {

		private List<ApplicationFlowEmailType> params = new List<ApplicationFlowEmailType>();

		public override void execute(ApplicationUnitOfWork uow) {

			if (this.params != null && !this.params.isEmpty()) {
				// get an instance of ApplicationEmailService
				ApplicationEmailService emailService = ApplicationEmailService.getInstance();

				// go through ApplicationFlowEmailTypes stored as parameters and queue them
				// on the service
				for (ApplicationFlowEmailType flowEmailType : this.params) {
					emailService.queueEmailNotification(flowEmailType);
				}

				// use service to dispatch the email notifications
				emailService.dispatchAllPendingEmailNotifications();
			}
		}
		
		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				try {
					this.params = (List<ApplicationFlowEmailType>) JSON.deserialize(serialisedParams, List<ApplicationFlowEmailType>.class);
				} catch (Exception e) {
					ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Application', FlowEmailAsyncWorker.class.getName(),
							'deserialiseParams', 'Emails', ApplicationLogger.LoggingLevel.ERROR);
				}

			}
		}

		public override Type getClassType() {
			return FlowEmailAsyncWorker.class;
		}
		
	}


	public class AsyncUnitOfWorkException extends Exception { }


}