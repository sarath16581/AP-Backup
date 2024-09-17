/***
 * @description
 * Another take at a framework with domainless architecture. Domains can be controlled by naming conventions with ApplicationModule
 * 
 * @author Nathan Franklin
 * @date 2023-06-12
 * @changelog
 */
public inherited sharing abstract class ApplicationTriggerHandler {

	/**
	 * Derived from the records provided during construction, provides the native describe for the standard or custom object
	 **/
	public SObjectType sObjectType { get; private set; }

	/**
	 * Stores a cached copy of the domain modules to minimise the need to continually instantiating new instances
	 */
	private static Map<String, Map<Type, ApplicationModule>> cachedModules;
	@TestVisible
	private static Map<String, Map<Type, String>> recordFilterIndexes;

	public enum TriggerState {
		BEFORE,
		AFTER
	}

	private List<Type> modules = new List<Type>();

	static {
		cachedModules = new Map<String, Map<Type, ApplicationModule>>();
		recordFilterIndexes = new Map<String, Map<Type, String>>();
	}

	/**
	 * A list of ApplicationModule types that are used within this trigger handler
	 * Each of these modules will be executed when the trigger is fired (if not disabled using ApplicationFeatures)
	 */
	public abstract void registerModules();

	/**
	 * The unit of work to be used for the SObject in question
	 * This is a combination of all the sobjects used within all the modules of an SObject
	 * This is a single Unit of Work to improve the overall efficiency and bulkification of the trigger
	 */
	public abstract ApplicationUnitOfWork newUnitOfWork();

	/**
	 * This trigger handler's SObject type
	 */
	public abstract SObjectType getSObjectType();

	/**
	 * Grab the name of the class for various actions. Since Apex does not provide class Reflection then it's necessary to use this in order to know what the name of the most subclassed class is.
	 * In tests, using String.valueOf(this).substringBefore(':') consistently return results of 1-4ms which, in my opinion, is an acceptable overhead
	 *
	 * Test for this
	 * Application.Profiler.start('this');
	 * for(Integer i = 0;i<5000;i++) {
	 *	  aef_ApplicationUnitOfWorkAsyncHandler d = new ApplicationUnitOfWorkAsyncHandler();
	 *	  String classNameD = String.valueOf(d).substringBefore(':');
	 *	  ApplicationUnitOfWorkBase c = new ApplicationUnitOfWorkBase();
	 *	  String classNameC = String.valueOf(c).substringBefore(':');
	 *	  QueryBuilder s = new aef_QueryBuilder();
	 *	  String classNameS = String.valueOf(s).substringBefore(':');
	 * }
	 * System.assert(false, Application.Profiler.stop('this'));
	 */
	public String className {
		get {
			if (String.isEmpty(className)) {
				className = String.valueOf(this).substringBefore(':');
			}
			return className;
		}
		private set;
	}

	public ApplicationTriggerHandler() {
		registerModules();
	}

	/**
	 * At the start of each execution cycle, this method allows us to prepopulate records based on the filters the trigger handler needs
	 * This cuts down on repetitive looping in each module to filter out only the records relevent to the module
	 */
	public virtual Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		return new Map<String, List<SObject>>();
	}

	public void dispatch() {
		// Process the runtime Apex Trigger context
		dispatch(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.isUndelete, Trigger.new, Trigger.oldMap);
	}

	// execute the trigger handler
	@TestVisible
	private void dispatch(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete,
							List<SObject> newRecords, Map<Id, SObject> oldRecordsMap) {

		System.debug('Dispatch: ' + getSObjectType() + ' ' + className + ', isAfter:  ' + isAfter + ', isBefore: ' + isBefore + ', isInsert: ' + isInsert + ', isUpdate: ' + isUpdate + ', isDelete: ' + isDelete + ', isUnDelete: ' + isUndelete);

		// grab instances of the modules
		Map<Type, ApplicationModule> instances = cachedModules.get(className);
		if(instances == null) {
			instances = new Map<Type, ApplicationModule>();
		}

		Map<Type, String> recordFilterIndexKeys = recordFilterIndexes.get(className);
		if(recordFilterIndexKeys == null) {
			recordFilterIndexKeys = new Map<Type, String>();
		}

		// grab a new unit of work to be passed throughout the different domains
		ApplicationUnitOfWork unitOfWork = newUnitOfWork();

		// these can be used to pass into modules to reduce repetitive looping in each module
		Map<String, List<SObject>> filteredRecords = primeRecordFilters((isDelete ? oldRecordsMap.values() : newRecords));

		for (Type instanceType : instances.keySet()) {
			ApplicationModule instance = instances.get(instanceType);
			ApplicationModule.TriggerEvent events = instance.getTriggerEvents();
			String filterIndexKey = recordFilterIndexKeys.get(instanceType);
			
			List<SObject> records = (isDelete ? oldRecordsMap.values() : newRecords);
			if(!String.isEmpty(filterIndexKey) && filteredRecords.get(filterIndexKey) != null) {
				records = filteredRecords.get(filterIndexKey);
			}

			// Invoke the applicable handler
			if(isBefore) {
				if(isInsert && events.beforeInsertEnabled) {
					instance.onBeforeInsert(records, unitOfWork);
				} else if (isUpdate && events.beforeUpdateEnabled) {
					instance.onBeforeUpdate(records, oldRecordsMap, unitOfWork);
				} else if(isDelete && events.beforeDeleteEnabled) {
					instance.onBeforeDelete(records, unitOfWork); // NOTE: Trigger.new / Trigger.newMap are not available in delete triggers
				}
			} else {
				if(isInsert && events.afterInsertEnabled) {
					instance.onAfterInsert(records, unitOfWork);
				} else if(isUpdate && events.afterUpdateEnabled) {
					instance.onAfterUpdate(records, oldRecordsMap, unitOfWork);
				} else if (isDelete && events.afterDeleteEnabled) {
					instance.onAfterDelete(records, unitOfWork); // NOTE: Trigger.new / Trigger.newMap are not available in delete triggers
				} else if (isUndelete && events.afterUndeleteEnabled) {
					instance.onAfterUndelete(records, unitOfWork);
				}
			}
		}

		// commit the unit of work for the current trigger run
		// the unit of work will take all the queued operations and commit them to the database
		// NOTE: During the execution, domains/modules can explicitly cause an exception to be thrown if needed (using throwOnError parameter of the register* methods in uow)
		//          If throwOnException is not set, any database errors will be logged in Application_Log__c
		// NOTE: If an exception is thrown the entire operation will be rolled back and the user will be presented with an error on screen
		unitOfWork.commitWork();
	}

	@TestVisible
	protected void registerModule(Type moduleType) {
		registerModule(moduleType, null);
	}

	protected void registerModule(Type moduleType, String filterKey) {
		// remove any modules which are not 'active'
		if(!ApplicationFeatures.getInstance().isModuleActive(moduleType)) {
			System.debug('Skipping Module: ' + moduleType);
			return;
		}

		// store this module in transaction cache
		String thisClass = className;
		if (cachedModules.get(thisClass) == null) {
			cachedModules.put(thisClass, new Map<Type, ApplicationModule>());
			recordFilterIndexes.put(thisClass, new Map<Type, String>());
		}
		if (cachedModules.get(thisClass).get(moduleType) == null) {
			cachedModules.get(thisClass).put(moduleType, Application.Modules.newInstance(moduleType));
			recordFilterIndexes.get(thisClass).put(moduleType, filterKey);
		}
	}

}