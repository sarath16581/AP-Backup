/**
 * @author Seth Heang
 * @date 2024-07-29
 * @group ScheduledActions
 * @domain Core
 * @description This class contains Scheduled Actions related functionality for 5 Day case monitoring case-automated action, including:
 *				- Creation of scheduled action
 *				- Removal of scheduled action
 *				- Eligibility Check on 5 Day case monitoring condition
 *				- Entry method for processing CaseClosure and CaseReassignment logic from CaseUnifiedAutomationService, invoked by a record-triggered flow at a scheduled date time
 *
 * @changelog
 * 2024-07-29 - Seth Heang - Created
 */
public with sharing class CaseMonitoring5DayAutoClosureAction extends ApplicationScheduledAction {

	private final static QM__c QUEUE_SETTINGS = QM__c.getInstance();
	private final static Id RECORD_TYPE_UNIFIED_INVESTIGATION_ID {
		get {
			return CaseUnifiedAutomationService.getUnifiedInvestigationCaseRecordTypeId();
		}
	}

	public static CaseMonitoring5DayAutoClosureAction newInstance() {
		return (CaseMonitoring5DayAutoClosureAction) Application.Utilities.newInstance(CaseMonitoring5DayAutoClosureAction.class);
	}

	/**
	 * @description Get the current class name. Used to set the actionType__c field on ScheduledAction__c
	 * @return
	 */
	public override String getName() {
		return CaseMonitoring5DayAutoClosureAction.class.getName();
	}

	/**
	 * @description This will be the main entry point from configured Flow with Scheduled Paths via the ApplicationScheduledActionService.executeAll() Invocable method.
	 *				Check eligibility for CaseClosure OR CaseReassignment and create recordWrappers and pass them to respective methods in CaseUnifiedAutomationService for processing
	 * @param actionRecordIds
	 */
	public override void execute(List<Id> actionRecordIds) {
		List<CaseUnifiedAutomationService.RecordWrapper> caseClosureWrappers = new List<CaseUnifiedAutomationService.RecordWrapper>();
		List<CaseUnifiedAutomationService.RecordWrapper> caseReassignmentWrappers = new List<CaseUnifiedAutomationService.RecordWrapper>();
		List<ScheduledAction__c> actions = ScheduledActionsSelector.newInstance().selectById(new Set<Id>(actionRecordIds), new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE });
		for (ScheduledAction__c action : actions) {
			Case newCase = action.Case__r;
			// check CaseClosure eligibility and build a RecordWrapper
			if (checkEligibilityForCaseClosure(newCase)) {
				CaseUnifiedAutomationService.RecordWrapper recordWrapper = new CaseUnifiedAutomationService.RecordWrapper();
				recordWrapper.srcObjectType = Case.sObjectType;
				recordWrapper.srcRecordId = newCase.Id;
				recordWrapper.caseRecord = newCase;
				recordWrapper.newRootCause = 'Service Failure';
				recordWrapper.newResolutionCode = 'Lost - unscanned';
				caseClosureWrappers.add(recordWrapper);
			}
			// check checkEligibilityForCaseReassignment eligibility and build a RecordWrapper
			if (checkEligibilityForCaseReassignment(newCase)) {
				CaseUnifiedAutomationService.RecordWrapper recordWrapper = new CaseUnifiedAutomationService.RecordWrapper();
				recordWrapper.srcObjectType = Case.sObjectType;
				recordWrapper.srcRecordId = newCase.Id;
				recordWrapper.caseRecord = newCase;
				recordWrapper.isClosedBySystem = false;
				caseReassignmentWrappers.add(recordWrapper);
			}
		}
		// Call CaseUnifiedAutomationService to process CaseClosure and CaseReassignment appropriately
		if (!caseClosureWrappers.isEmpty()) {
			CaseUnifiedAutomationService.getInstance().processForCaseClosure(caseClosureWrappers, CaseUnifiedAutomationService.InvocationPoint.PROACTIVEAUTO, null);
		}
		if (!caseReassignmentWrappers.isEmpty()) {
			CaseUnifiedAutomationService.getInstance().processForCaseReassignment(caseReassignmentWrappers, CaseUnifiedAutomationService.InvocationPoint.PROACTIVEAUTO, null);
		}
	}

	/**
	 * @description Contain a set of criteria for eligibility check for Case Closure
	 * @param newCase
	 *
	 * @return True/False
	 */
	private Boolean checkEligibilityForCaseClosure(Case newCase) {
		return newCase.IsClosed == false &&
			newCase.OwnerId == ((Id) QUEUE_SETTINGS.UnifiedDefaultMonitoringQueueId__c) &&
			newCase.RecordTypeId == RECORD_TYPE_UNIFIED_INVESTIGATION_ID &&
			newCase.Exclude_Subscription_Automation__c == false &&
			newCase.ContactEmail != null;
	}

	/**
	 * @description Contain a set of criteria for eligibility check for Case Reassignment
	 * @param newCase
	 *
	 * @return True/False
	 */
	private Boolean checkEligibilityForCaseReassignment(Case newCase) {
		return newCase.IsClosed == false &&
			newCase.OwnerId == ((Id) QUEUE_SETTINGS.UnifiedDefaultMonitoringQueueId__c) &&
			newCase.RecordTypeId == RECORD_TYPE_UNIFIED_INVESTIGATION_ID &&
			(newCase.Exclude_Subscription_Automation__c == true ||
			newCase.ContactEmail == null);
	}

	/**
	 * @description Checks all eligibility conditions for the parent records with below criteria:
	 *				1. isClosed = False AND
	 *				2. Owner = Unified Customer Service Monitoring Queue AND
	 *				3. RecordType = UnifiedInvestigation Cases only AND
	 *				4. Enquiry Sub Type = Late Item AND
	 *				5. Case age is still within first 5 business days since created date
	 * @param parentRecords Cases
	 * @param uow
	 *
	 * @return Map<Id, Boolean> Map of parentRecordId to ValidationStatus
	 */
	@TestVisible
	protected override Map<Id, Boolean> validate(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow) {
		Map<Id, Boolean> caseValidationStatus = new Map<Id, Boolean>();
		for (Case newCase : (List<Case>) parentRecords.values()) {
			Boolean validatedResult = (newCase.IsClosed == false &&
			newCase.OwnerId == ((Id) QUEUE_SETTINGS.UnifiedDefaultMonitoringQueueId__c) &&
			newCase.RecordTypeId == RECORD_TYPE_UNIFIED_INVESTIGATION_ID &&
			newCase.EnquirySubType__c == 'Late Item' &&
			Date.today() <= BusinessHoursService.newInstance().calculateNextBusinessDay(newCase.CreatedDate.date(), 5));
			caseValidationStatus.put(newCase.Id, validatedResult);
		}
		return caseValidationStatus;
	}

	/**
	 * @description Entry point for Parent Triggers for initial setup (create) and revalidation (update) of scheduledAction__c
	 *				Validate the case eligibility check and manage the creation/removal of ScheduledAction__c
	 * @param parentRecords
	 * @param uow
	 * @param revalidateOperation
	 */
	public override void setup(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow, Boolean revalidateOperation) {
		Map<Id, Boolean> validationStatusMap = this.validate(parentRecords, uow);
		Map<Id, SObject> successfulValidatedRecords = new Map<Id, SObject>();
		Map<Id, SObject> failedValidatedRecords = new Map<Id, SObject>();
		// Filter and group successful and failed parent records from validationStatusMap
		for (Id caseId : validationStatusMap.keySet()) {
			if (validationStatusMap.get(caseId) == true) {
				successfulValidatedRecords.put(caseId, parentRecords.get(caseId));
			} else {
				failedValidatedRecords.put(caseId, parentRecords.get(caseId));
			}
		}
		if (revalidateOperation) {
			// Find all child ScheduledAction__c records
			Map<Id, ScheduledAction__c> existingActionsForDelete = new Map<Id, ScheduledAction__c>();
			Map<Id, SObject> recordsWithExistingActions = new Map<Id, SObject>();
			if(!validationStatusMap.isEmpty()){
				for (ScheduledAction__c action : ScheduledActionsSelector.newInstance().selectByCaseId(validationStatusMap.keySet())){
					if (successfulValidatedRecords.get(action.Case__c) != null && action.ActionType__c.equals(getName()) ){
						recordsWithExistingActions.put(action.Case__c, parentRecords.get(action.Case__c));
					}
					else if (failedValidatedRecords.get(action.Case__c) != null && action.ActionType__c.equals(getName())){
						existingActionsForDelete.put(action.Id, action);
					}
				}
			}
			// Remove child ScheduledAction__c records for failed validation case
			if (!existingActionsForDelete.isEmpty()) {
				remove(new List<Id>(existingActionsForDelete.keySet()), uow);
			}

			// If there is no existing child ScheduledAction__c records under successful validated case, add them
			Map<Id, SObject> caseToAddActions = new Map<Id, SObject>();
			for (SObject newRecord: successfulValidatedRecords.values()){
				if (recordsWithExistingActions.get(newRecord.Id) == null){
					caseToAddActions.put(newRecord.Id, newRecord);
				}
			}
			if (!caseToAddActions.isEmpty()) {
				add(caseToAddActions, uow);
			}
		} else {
			// Check for existing ScheduledAction__c checks is not necessary for Insert Trigger context
			if (!successfulValidatedRecords.isEmpty()) {
				// Create new ScheduledAction__c records for successfully validated case
				add(successfulValidatedRecords, uow);
			}
		}
	}

	/**
	 * @description Insert a new ScheduledAction__c with appropriate attribute mapping including scheduledDate__c via UnitOfWork framework
	 * @param parentRecords
	 * @param uow
	 * @return List<ScheduledAction__c>
	 */
	public override List<ScheduledAction__c> add(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow) {
		List<ScheduledAction__c> actionsForInsert = new List<ScheduledAction__c>();
		BusinessHoursService businessHoursService = BusinessHoursService.newInstance();
		for (Case newCase : (List<Case>) parentRecords.values()) {
			actionsForInsert.add(
				new ScheduledAction__c(
					Name = '5 Day Customer Auto Closure',
					Case__c = newCase.Id,
					ActionType__c = getName(),
					ScheduledDate__c = businessHoursService.calculateNextBusinessDateTime(newCase.CreatedDate, 5), // set to next 5 business dateTime
					Active__c = true
				)
			);
		}
		if (!actionsForInsert.isEmpty()) {
			return uow.registerNew(actionsForInsert);
		}
		return null;
	}

	/**
	 * @description Delete the ScheduledAction__c records via UnitOfWork framework
	 * @param actionRecordIds
	 * @param uow
	 */
	public override void remove(List<Id> actionRecordIds, ApplicationUnitOfWork uow) {
		// create a list of SObject to pass into uow.registeredDeleted() as it doesn't take List<Id>
		List<ScheduledAction__c> actionsForDelete = new List<ScheduledAction__c>();
		for (Id actionId : actionRecordIds) {
			actionsForDelete.add(new ScheduledAction__c(Id = actionId));
		}
		if (!actionsForDelete.isEmpty()) {
			uow.registerDeleted(actionsForDelete);
		}
	}
}