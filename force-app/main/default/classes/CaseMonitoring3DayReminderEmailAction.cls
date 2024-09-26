/**
 * @author Seth Heang
 * @date 2024-07-26
 * @group ScheduledActions
 * @domain Core
 * @description This class contains Scheduled Actions related functionality for 3 Day case monitoring case-automated action, including:
 *				- Creation of scheduled action
 *				- Removal of scheduled action
 *				- Eligibility Check on 3 Day case monitoring condition
 *				- Entry method for sending a reminder email after 3 days, invoked by a record-triggered flow at a scheduled date time
 *
 * @changelog
 * 2024-07-26 - Seth Heang - Created
 * 2024-09-24 - Ranjeewa Silva - Updated to send customer notification email using ApplicationEmailService
 */
public with sharing class CaseMonitoring3DayReminderEmailAction extends ApplicationScheduledAction {

	// email alerts to use to notify customer on the case.
	@TestVisible private static final String EMAIL_ALERT_NO_SCANS_OR_UPDATES_AP = 'UnifiedCaseNoScansOrUpdatesNotificationAP';
	@TestVisible private static final String EMAIL_ALERT_NO_SCANS_OR_UPDATES_ST = 'UnifiedCaseNoScansOrUpdatesNotificationST';

	private final static QM__c QUEUE_SETTINGS = QM__c.getInstance();
	private final static Id RECORD_TYPE_UNIFIED_INVESTIGATION_ID {
		get {
			return CaseUnifiedAutomationService.getUnifiedInvestigationCaseRecordTypeId();
		}
	}

	public static CaseMonitoring3DayReminderEmailAction newInstance() {
		return (CaseMonitoring3DayReminderEmailAction) Application.Utilities.newInstance(CaseMonitoring3DayReminderEmailAction.class);
	}

	/**
	 * @description Get class name. Used to set the actionType__c field on ScheduledAction__c
	 * @return String
	 */
	public override String getName() {
		return CaseMonitoring3DayReminderEmailAction.class.getName();
	}

	/**
	 * @description This will be the main entry point from configured Flow with Scheduled Paths via the ApplicationScheduledActionService.executeAll() Invocable method
	 * @param actionRecordIds
	 */
	public override void execute(List<Id> actionRecordIds) {
		List<ScheduledAction__c> actions = ((ScheduledActionsSelector)ScheduledActionsSelector.newInstance().setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{
				ScheduledAction__c.SObjectType => new Set<SObjectField>{ScheduledAction__c.Id, ScheduledAction__c.Case__c},
				Case.SObjectType => new Set<SObjectField>{Case.Id, Case.ProductSubCategory__c}
		})).selectById(new Set<Id>(actionRecordIds), new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE });

		if (!actions.isEmpty()) {
			ApplicationEmailService emailService = ApplicationEmailService.getInstance();
			for (ScheduledAction__c action : actions) {
				String emailAlertName = CaseUnifiedAutomationService.isStarTrackCase(action.Case__r)
						? EMAIL_ALERT_NO_SCANS_OR_UPDATES_ST
						: EMAIL_ALERT_NO_SCANS_OR_UPDATES_AP;
				emailService.queueEmailNotification(action.Case__c, Case.SObjectType, emailAlertName);
			}
			emailService.dispatchAllPendingEmailNotifications();
		}
	}

	/**
	 * @description Checks all eligibility conditions for the parent records with below criteria:
	 *				1. isClosed = False AND
	 *				2. Owner = Unified Customer Service Monitoring Queue AND
	 *				3. RecordType = UnifiedInvestigation Cases only AND
	 *				4. Enquiry Sub Type = Late Item AND
	 *				5. Related ContactEmail (business contact or consumer) is not blank AND
	 *				6. No individual agent assignments since creation (excluding the agent who created the case) AND
	 *				7. Case age is still within first 3 business days since created date
	 * @param parentRecords Cases
	 * @param uow
	 * @return Map<Id, Boolean> Map of parentRecordId to ValidationStatus
	 */
	@TestVisible
	protected override Map<Id, Boolean> validate(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow) {
		Map<Id, Boolean> caseValidationStatus = new Map<Id, Boolean>();
		Map<Id, Boolean> caseIdHasIndividualAgentAssignmentMap = getCaseIdHasNoIndividualAgentAssignmentsMap((Map<Id, Case>) parentRecords);
		for (Case newCase : (List<Case>) parentRecords.values()) {
			Boolean validatedResult = (newCase.IsClosed == false &&
			newCase.OwnerId == ((Id) QUEUE_SETTINGS.UnifiedDefaultMonitoringQueueId__c) &&
			newCase.RecordTypeId == RECORD_TYPE_UNIFIED_INVESTIGATION_ID &&
			newCase.EnquirySubType__c == 'Late Item' &&
			newCase.Exclude_Subscription_Automation__c == false &&
			newCase.ContactEmail != null &&
			caseIdHasIndividualAgentAssignmentMap.get(newCase.Id) == true &&
			Date.today() <= BusinessHoursService.newInstance().calculateNextBusinessDay(newCase.CreatedDate.date(), 3));
			caseValidationStatus.put(newCase.Id, validatedResult);
		}
		return caseValidationStatus;
	}

	/**
	 * @description check if the case has any individual agent assignments in the past since creation, excluding the agent who created the case
	 * @param cases
	 * @return Map<Id, Boolean> caseId to True/False
	 */
	@TestVisible
	private Map<Id, Boolean> getCaseIdHasNoIndividualAgentAssignmentsMap(Map<Id, Case> cases) {
		Map<Id, Boolean> caseIdHasNoIndividualAgentAssignment = new Map<Id, Boolean>();
		for (Case newCase : cases.values()) {
			caseIdHasNoIndividualAgentAssignment.put(newCase.Id, true); // default to true
		}

		Map<Id, List<AgentWork>> caseIdToAgentWorkMap = new Map<Id, List<AgentWork>>();
		Map<Id, Id> caseIdToCreatorUserIdMap = new Map<Id, Id>();
		// Query AgentWork and initialise maps
		List<AgentWork> agentWorks = AgentWorkSelector.newInstance().selectByWorkItemIds(cases.keySet(), new Set<Object>{ AgentWorkSelector.Options.WITH_CASE });
		for (AgentWork work : agentWorks) {
			if (caseIdToAgentWorkMap.get(work.Case__c) == null) {
				caseIdToAgentWorkMap.put(work.Case__c, new List<AgentWork>());
			}
			caseIdToAgentWorkMap.get(work.Case__c).add(work);
			caseIdToCreatorUserIdMap.put(work.Case__c, work.Case__r.CreatedById);
		}
		// Validate if AgentWork has individual user assignment, excluding case creator
		String userPrefix = User.getSObjectType().getDescribe().getKeyPrefix();
		for (Id caseId : caseIdToAgentWorkMap.keySet()) {
			for (AgentWork work : caseIdToAgentWorkMap.get(caseId)) {
				String workOwnerPrefix = work.OwnerId.toString().substring(0, 3);
				Id caseCreatorUserId = caseIdToCreatorUserIdMap.get(work.Case__c);
				if (workOwnerPrefix == userPrefix && !work.OwnerId.equals(caseCreatorUserId)) {
					caseIdHasNoIndividualAgentAssignment.put(work.Case__c, false);
				}
			}
		}
		return caseIdHasNoIndividualAgentAssignment;
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
					Name = '3 Day Customer Email Alert',
					Case__c = newCase.Id,
					ActionType__c = getName(),
					ScheduledDate__c = businessHoursService.calculateNextBusinessDateTime(newCase.CreatedDate, 3), // set to next 3 business dateTime
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