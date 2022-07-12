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
				if(isInsert) {
					instance.onBeforeInsert(unitOfWork);
				} else if(isUpdate) {
					instance.onBeforeUpdate(oldRecordsMap, unitOfWork);
				}
				// TODO
				//else if(isDelete) domainObject.onBeforeDelete();
			} else {
				if(isInsert) {
					instance.onAfterInsert(unitOfWork);
				} else if(isUpdate) {
					instance.onAfterUpdate(oldRecordsMap, unitOfWork);
				}
				else if(isDelete){
					instance.onAfterDelete(oldRecordsMap.values(), unitOfWork);
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

			// Construct the domain class constructor class
			String domainClassName = domainType.getName();
			Type constructableClass = Type.forName(domainClassName + '.Constructor');
			ApplicationDomain.IConstructable domainConstructor = (ApplicationDomain.IConstructable) constructableClass.newInstance();
			instances.add(domainConstructor.construct(newRecords));

		}

		return instances;
	}
}