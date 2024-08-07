/**
 * @author Parveen Kaushik
 * @date 2024-07-18
 * @group ScheduledActions
 * @tag Selector
 * @domain Core
 * @description The ApplicationScheduledAction class is the base super class that all other Scheduled Actions extend from.
 * It defines key methods and properties that are required by all other Scheduled Actions to implement or override as necessary.
 * NOTE: It's very important that this interface should support batch processing (bulkification) and recommended to support queueable/async processing.
 * 		 does not define explicit sharing. It should always inherit sharing based on the preference of the calling code. This allows the class to be
 *		flexible enough to be used in any circumstance that requires data.
 * @changelog
 * 2024-07-18 - Parveen Kaushik - Created
 */
public inherited sharing abstract class ApplicationScheduledAction {
	// Override this so it always returns the current class name. Used to set the actionType__c field on ScheduledAction__c
	public virtual String getName() {
		return ApplicationScheduledAction.class.getName();
	}

	// This will be the main entry point from configured Flow with Scheduled Paths via the ApplicationScheduledActionService.executeAll() Invocable method
	public virtual void execute(List<Id> actionRecordIds) {
		// Salesforce will group the scheduled path actions as part of internal run time optimisation and pass
		// a list of all Scheduled Action record Ids that are to be executed in bulk.

		// Throw an exception as this method shall be implemented in specific actions (exmaple: CaseMonitoring5DayAutoClosureAction)
		throw new ApplicationScheduledActionException('Not Implemented');
	}

	// Checks all eligibility conditions for the parent records and return a Map of parentRecordId --> ValidationStatus
	// This method shall be implemented in specific actions (exmaple: CaseMonitoring5DayAutoClosureAction)
	protected abstract Map<Id, Boolean> validate(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow);

	// Entry point for Parent Triggers for intial setup (create) and revalidation (update) of scheduledAction__c
	public virtual void setup(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow, Boolean revalidateOperation) {
		Map<Id, Boolean> validationStatusMap = validate(parentRecords, uow);
		// filter validationStatusMap and saved failed record into failedValidatedCase and successful records into successfulValidatedCase
		Map<Id, SObject> successfulValidatedCase = new Map<Id, SObject>();
		Map<Id, SObject> failedValidatedCase = new Map<Id, SObject>();
		if (revalidateOperation) {
			// 1. Filter all failed parent records from validationStatusMap
			// 2. Find all child ScheduledAction__c records for this parent cases. Use Case__c field
			Map<Id, ScheduledAction__c> existingActionsForDelete = new Map<Id, ScheduledAction__c>();
			Map<Id, ScheduledAction__c> existingActionsForAdd = new Map<Id, ScheduledAction__c>();
			// 3. Delete the ScheduledAction__c records (using remove() method)
			if (!existingActionsForDelete.isEmpty()) {
				remove(new List<Id>(existingActionsForDelete.keySet()), uow);
			}
			if (existingActionsForAdd.isEmpty()) {
				add(existingActionsForAdd, uow);
			}
		} else {
			// 1. Filter all successful parent records from validationStatusMap
			// 2. Create new ScheduledAction__c records using add() method.
			if (!successfulValidatedCase.isEmpty()) {
				// Create new ScheduledAction__c records for successfully validated case
				add(successfulValidatedCase, uow);
			}
		}
		throw new ApplicationScheduledActionException('Not Implemented');
	}

	public virtual void revalidate(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow) {
		setup(parentRecords, uow, true);
	}

	// Prepares a new ScheduledAction__c record to be added. Use this to calculate business hours and set ScheduledDate__c.
	// Set actionType__c = getName() and Case__c = parentRecord.Id
	public abstract List<ScheduledAction__c> add(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow);

	// Delete the ScheduledAction__c records as identified by input list
	public abstract void remove(List<Id> actionRecordIds, ApplicationUnitOfWork uow);

	public class ApplicationScheduledActionException extends Exception {
	}
}