/**
 * @description Application Module to handle Before Update scenario for pushing the Case to Unified Customer Service Monitoring Queue.
 *				It then validates the SLA period from the Case's createdDate.
 *				- If it's within SLA period, then proceed to update the Status to 'Monitoring'
 *				- If it's outside SLA priod, throw an error and do not commit dml
 * @author Seth Heang
 * @date 2024-07-10
 * @test CaseUnifiedProactiveMonitoringModuleTest
 * @changelog
 * 2024-07-10 - Seth Heang - Created.
 * 2024-07-18 - Seth Heang - Added new methods for processing 3 days and 5 days monitoring alerts
 * 2024-07-28 - Seth Heang - remove isClosed check from entry condition for processing scheduledActions
 * 2024-09-06 - George Nguyen - removed invalid comments
 * 2024-09-29 - Parveen Kaushik - Added exemption for proactive monitoring SLA if Bypass_Data_enforcement__c = TRUE
 */
public inherited sharing class CaseUnifiedProactiveMonitoringModule extends ApplicationModule {
	@TestVisible
	private final static String ERROR_SLA_EXPIRED = 'Case has passed SLA, refer to Knowledge for next steps.';
	private final static QM__c QUEUE_SETTINGS = QM__c.getInstance();
	private final static Set<Id> UNIFIED_RECORD_TYPE_IDS = CaseUnifiedAutomationService.getUnifiedCaseRecordTypeIds();

	public static CaseUnifiedProactiveMonitoringModule newInstance() {
		return (CaseUnifiedProactiveMonitoringModule) Application.Utilities.newInstance(CaseUnifiedProactiveMonitoringModule.class);
	}

	// Setup which triggers this module should respond to
	public CaseUnifiedProactiveMonitoringModule() {
		getTriggerEvents().enableBeforeUpdate().enableAfterInsert().enableAfterUpdate();
	}

	/**
	 * @description Called a before Update and Performs below operations:
	 * 1. Validate Case's SLA period from createdDate and update relevent details if applicable
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			updateCaseForProactiveMonitoring((List<Case>) records, (Map<Id, Case>) existingRecords, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseUnifiedProactiveMonitoringModule.class.getName(), 'onBeforeUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @description Called After an insert and validate case for 3 days and 5 days case monitoring scheduled action
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			validateCaseForScheduledActions((List<Case>) records, null, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseUnifiedProactiveMonitoringModule.class.getName(), 'onAfterInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @description Called After an Update and validate case for 3 days and 5 days case monitoring scheduled action
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			validateCaseForScheduledActions((List<Case>) records, (Map<Id, Case>) existingRecords, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', CaseUnifiedProactiveMonitoringModule.class.getName(), 'onAfterUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @description Validate SLA period of the case's createdDate and update case's status to 'Monitoring'
	 * @param records new changes including updates
	 * @param existingRecords old changes without updates
	 * @param uow
	 */
	private void updateCaseForProactiveMonitoring(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow) {
		String context = CaseUnifiedProactiveMonitoringModule.class.getName();
		Set<SObjectField> monitoredFields = new Set<SObjectField>{ Case.OwnerId };
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, records, existingRecords, monitoredFields);
		// Eligibility Check on changed state
		for (ApplicationRecursion.RecordState recordState : changedRecords) {
			Case updatedCase = (Case) recordState.record;
			Set<SObjectField> changed = recordState.changedFields;
			if (!changed.isEmpty() && changed.contains(Case.OwnerId)) {
				if (checkEligibilityForProactiveMonitoring(updatedCase)) {
					updatedCase.Status = SSSWConstants.CASE_STATUS_MONITORING;
				}
			}
		}
	}

	/**
	 * @description Check eligibility and validate the SLA period from case's createdDate and throw error if SLA is not met
	 * @param newRecord new cases with updates
	 * @return Boolean
	 */
	private Boolean checkEligibilityForProactiveMonitoring(Case newRecord) {
		// Calculate the date 5 business days after the Case's CreatedDate
		Date fiveBusinessDaysAfterCreation = BusinessHoursService.newInstance().calculateNextBusinessDay(newRecord.CreatedDate.date(), 5);
		Date currentDate = Date.today();
		if (newRecord.OwnerId.equals((Id) QUEUE_SETTINGS.UnifiedDefaultMonitoringQueueId__c)) {
			if (currentDate < fiveBusinessDaysAfterCreation || newRecord.Bypass_Data_enforcement__c == true) {
				return true;
			} else {
				newRecord.addError(ERROR_SLA_EXPIRED);
			}
		}
		return false;
	}

	/**
	 * @description Validate Case for 3 days and 5 days case monitoring scheduled action with below criteria:
	 *				- Case is not closed
	 *				- Case Record type is UnifiedInvestigation
	 *				Then enqueue an async worker for eligibile case to be executed in async context
	 * @param records
	 * @param existingRecords
	 * @param uow
	 * @param revalidate false for Insert context, true for Update context
	 */
	private void validateCaseForScheduledActions(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow) {
		List<Case> eligibleCasesForScheduledActions = new List<Case>();
		Boolean revalidate = existingRecords != null && !existingRecords.isEmpty();
		for (Case updatedCase : records) {
			if (UNIFIED_RECORD_TYPE_IDS.contains(updatedCase.RecordTypeId)) {
				eligibleCasesForScheduledActions.add(updatedCase);
			}
		}
		// register and enqueue an async worker
		if (!eligibleCasesForScheduledActions.isEmpty()) {
			CaseUnifiedScheduledActionsParam params = new CaseUnifiedScheduledActionsParam(eligibleCasesForScheduledActions, revalidate);
			uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(AsyncUnifiedCaseScheduledActionWorker.class, params));
		}
	}

	/**
	 * @description Wrapper to be passed as parameters to the Async Worker Framwork for scheduled action automation
	 */
	public class CaseUnifiedScheduledActionsParam {
		@TestVisible
		private List<Case> cases;
		@TestVisible
		private Boolean revalidateOperation;

		public CaseUnifiedScheduledActionsParam(List<Case> cases, Boolean revalidate) {
			this.cases = cases;
			this.revalidateOperation = revalidate;
		}
	}

	/**
	 * Async worker implementation that schedule action for Unified Case proactive monitoring if applicable
	 */
	public without sharing class AsyncUnifiedCaseScheduledActionWorker extends ApplicationUnitOfWork.AsyncWorker {
		@TestVisible
		private CaseUnifiedScheduledActionsParam params;

		/**
		 * @description Run logic to validate and insert/delete scheduled action, by calling ApplicationScheduledActionsService
		 * @param uow
		 */
		public override void execute(ApplicationUnitOfWork uow) {
			try {
				if (this.params != null) {
					ApplicationScheduledActionsService.newInstance().validateCaseActionsSetup(new Map<Id, Case>(params.cases), params.revalidateOperation, uow);
				}
			} catch (Exception ex) {
				ApplicationLogger.getInstance()
						.logException(ApplicationLogger.wrapException(ex), 'UnifiedCase', AsyncUnifiedCaseScheduledActionWorker.class.getName(), 'execute', 'Case', ApplicationLogger.LoggingLevel.ERROR);
			}
		}

		public override Type getClassType() {
			return AsyncUnifiedCaseScheduledActionWorker.class;
		}

		public override SObjectType getSObjectTypeGroup() {
			return Case.SObjectType;
		}

		public override void deserialiseParams(String serialisedParams) {
			if (!String.isEmpty(serialisedParams)) {
				this.params = (CaseUnifiedScheduledActionsParam) JSON.deserialize(serialisedParams, CaseUnifiedScheduledActionsParam.class);
			}
		}
	}
}