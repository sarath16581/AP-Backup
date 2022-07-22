/***
 * @description
 * Used to dispatch a trigger execution flow and launch Domain classes
 * There should be only a single class extending this class per SObject.
 * See CaseTriggerHandler2 for an example implementation.
 *
 * @author Nathan Franklin
 * @date 2020-07-27
 * @group Core
 * @domain Core
 * @changelog
 * 2022-02-24 - Nathan Franklin - added logic for async and features
 * 2022-03-14 - Nathan Franklin - uplifted to version 52
 */
public abstract inherited sharing class ApplicationDomainTriggerHandler {
	private enum TriggerState {BEFORE, AFTER}

	private List<Type> domains = new List<Type>();

	// TODO
	//	// used to stack instances of each domain class so they can be surfaced in before/after pairs
	//	private Map<Type, List<ApplicationDomain>> instanceStack = new Map<Type, List<ApplicationDomain>>;

	/**
	 * A list of ApplicationDomain types that are used within this trigger handler
	 * Each of these domains will be executed when the trigger is fired
	 */
	public abstract List<Type> registerDomains();

	/**
	 * The unit of work to be used for the SObject in question
	 * This is a combination of all the sobjects used within all the domains of an SObject
	 * This is a single Unit of Work to improve the overall efficiency and bulkification of the trigger
	 */
	public abstract ApplicationUnitOfWork newUnitOfWork();

	/**
	 * This trigger handler's SObject type
	 */
	public abstract SObjectType getSObjectType();

	public ApplicationDomainTriggerHandler() {
		domains = registerDomains();

		// remove any domains which are not 'active'
		for(Integer i=domains.size()-1;i>=0;i--) {
			if(!ApplicationFeatures.getInstance().isDomainActive(domains[i])) {
				System.debug('Skipping Domain: ' + domains[i]);
				domains.remove(i);
			}
		}
	}

	public void dispatch() {
		// Process the runtime Apex Trigger context
		dispatch(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.isUndelete, Trigger.new, Trigger.oldMap);
	}

	// execute the trigger handler
	@TestVisible
	private void dispatch(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, List<SObject> newRecords, Map<Id, SObject> oldRecordsMap) {
		System.debug('Dispatch: ' + getSObjectType() + ', isAfter:  ' + isAfter + ', isBefore: ' + isBefore + ', isInsert: ' + isInsert + ', isUpdate: ' + isUpdate + ', isDelete: ' + isDelete + ', isUnDelete: ' + isUndelete);

		// grab instances of the domains
		List<ApplicationDomain> instances = getDomainInstances((isDelete ? oldRecordsMap.values() : newRecords), (isBefore ? TriggerState.BEFORE : TriggerState.AFTER));

		// grab a new unit of work to be passed throughout the different domains
		ApplicationUnitOfWork unitOfWork = newUnitOfWork();

		for(ApplicationDomain instance : instances) {
			// TODO at some point
			//	if(isUpdate) {
			//	    instance.registerTriggerChangedState(oldRecordsMap);
			//  }

			// Invoke the applicable handler
			if(isBefore) {
				// NOTE: currentAsyncStack does not need to be modified here since registerAsyncWork is not allowed in these methods
				if(isInsert) {
					instance.onBeforeInsert(unitOfWork);
				} else if(isUpdate) {
					instance.onBeforeUpdate(oldRecordsMap, unitOfWork);
				}

//				// check if any async or exclusive async work was registered
//				// if it was we throw an exception since these operations should not be used in a before cycle
//				// this is to allow for better grouping and consolidation of async operations
//				if(unitOfWork.getAsyncWorkCount() > 0) {
//					throw new ApplicationUnitOfWork.AsyncUnitOfWorkException('Async work can not be enqueued in a Before context');
//				}

				// TODO
				//else if(isDelete) domainObject.onBeforeDelete();
			} else {
				if(isInsert) {
					// Add an entry to the stack so if registerAsyncWork is called it take a snap shot of the stack so it can copy it into a new AsyncWorker__e platform event
					// This helps keep track of the stack for debugging
					ApplicationUnitOfWork.currentAsyncStack.add('Trigger: ' + getSObjectType() + ' - After Insert');
					Integer stackElement = ApplicationUnitOfWork.currentAsyncStack.size() - 1;

					instance.onAfterInsert(unitOfWork);

					// since the currentAsyncStack is a static, we need to remove the item that was just added
					ApplicationUnitOfWork.currentAsyncStack.remove(stackElement);
				} else if(isUpdate) {
					// Add an entry to the stack so if registerAsyncWork is called it take a snap shot of the stack so it can copy it into a new AsyncWorker__e platform event
					// This helps keep track of the stack for debugging
					ApplicationUnitOfWork.currentAsyncStack.add('Trigger: ' + getSObjectType() + ' - After Update');
					Integer stackElement = ApplicationUnitOfWork.currentAsyncStack.size() - 1;

					instance.onAfterUpdate(oldRecordsMap, unitOfWork);

					// since the currentAsyncStack is a static, we need to remove the item that was just added
					ApplicationUnitOfWork.currentAsyncStack.remove(stackElement);
				}
				// TODO
				//			else if(isDelete) domainObject.handleAfterDelete();
				//			else if(isUndelete) domainObject.handleAfterUndelete();
			}
		}

		// commit the unit of work for the current trigger run
		// the unit of work will take all the queued operations and commit them to the database
		// NOTE: During the execution, domains/modules can explicitly cause an exception to be thrown if needed (using throwOnError parameter of the register* methods in uow)
		//          If throwOnException is not set, any database errors will be logged in Application_Log__c
		// NOTE: If an exception is thrown the entire operation will be rolled back and the user will be presented with an error on screen
		unitOfWork.commitWork();

	}

	public List<ApplicationDomain> getDomainInstances(List<SObject> newRecords, TriggerState stateEnum) {
		// TODO
		//		if(stateEnum == TriggerState.BEFORE) {
		//			// push a new instance to the stack
		//		} else if(stateEnum == TriggerState.AFTER) {
		//			// pop the top instance off the stack
		//		}

		List<ApplicationDomain> instances = new List<ApplicationDomain>();
		for(Type domainType : domains) {
			instances.add(ApplicationDomain.newInstance(domainType, newRecords));
		}

		return instances;
	}
}