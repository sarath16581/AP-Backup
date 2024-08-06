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
 */
public inherited sharing class CaseUnifiedProactiveMonitoringModule extends ApplicationModule {
	@TestVisible
	private final static String ERROR_SLA_EXPIRED = 'Case has passed SLA, refer to Knowledge for next steps.';
	private final static QM__c QUEUE_SETTINGS = QM__c.getInstance();

	public static CaseUnifiedProactiveMonitoringModule newInstance() {
		return (CaseUnifiedProactiveMonitoringModule) Application.Utilities.newInstance(CaseUnifiedProactiveMonitoringModule.class);
	}

	// Setup which triggers this module should respond to
	public CaseUnifiedProactiveMonitoringModule() {
		getTriggerEvents().enableBeforeUpdate();
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
	 * @description Validate SLA period of the case's createdDate and update case's status
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
			if (currentDate < fiveBusinessDaysAfterCreation) {
				return true;
			} else {
				newRecord.addError(ERROR_SLA_EXPIRED);
			}
		}
		return false;
	}
}