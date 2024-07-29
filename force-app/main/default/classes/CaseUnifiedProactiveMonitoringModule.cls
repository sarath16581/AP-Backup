/**
 * @description Application Module to handle Before Update scenario for pushing the Case to Unified Customer Service Monitoring Queue.
 *				It then validates the SLA period from the Case's createdDate.
 *				- If it's within SLA period, then proceed to update the Status to 'Monitoring' and set exclude automation flag to false.
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
	 * @description Retrieve unified customer service monitoring queue once, and save as a constant for repeated usage
	 */
	private static final Group UNIFIED_CUSTOMER_SERVICE_MONITORING_QUEUE {
		get {
			if (UNIFIED_CUSTOMER_SERVICE_MONITORING_QUEUE == null) {
				UNIFIED_CUSTOMER_SERVICE_MONITORING_QUEUE = ((GroupsSelector) GroupsSelector.newInstance(1).setFieldOverrides(new Set<SObjectField>{ Group.Id, Group.DeveloperName }))
					.selectByGroupTypeAndDeveloperName(new Set<String>{ 'queue' }, new Set<String>{ 'UnifiedCustomerServiceMonitoringQueue' })
					.values()[0];
			}
			return UNIFIED_CUSTOMER_SERVICE_MONITORING_QUEUE;
		}
		private set;
	}

	/**
	 * @description Fetch unified customer service monitoring queue and return back to the LWC
	 * @return Group
	 */
	@AuraEnabled(Cacheable=true)
	public static Group getUnifiedCustomerServiceMonitoringQueue() {
		return UNIFIED_CUSTOMER_SERVICE_MONITORING_QUEUE;
	}

	/**
	 * @description Validate SLA period of the case's createdDate and update case's status and exclude automation flag accordingly
	 * @param records new changes including updates
	 * @param existingRecords old changes without updates
	 * @param uow
	 */
	private void updateCaseForProactiveMonitoring(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow) {
		List<Case> eligibleCasesForUpdate = new List<Case>();
		for (Case updatedCase : records) {
			Case oldCase = existingRecords.get(updatedCase.Id);
			if (checkEligibilityForProactiveMonitoring(oldCase, updatedCase)) {
				eligibleCasesForUpdate.add(updatedCase);
			}
		}
		if (!eligibleCasesForUpdate.isEmpty()) {
			pushCaseToMonitoring(eligibleCasesForUpdate);
		}
	}

	/**
	 * @description Check eligibility and validate the SLA period from case's createdDate and throw error if SLA is not met
	 * @param oldRecord old cases
	 * @param newRecord new cases with updates
	 * @return Boolean
	 */
	private Boolean checkEligibilityForProactiveMonitoring(Case oldRecord, Case newRecord) {
		// Calculate the date 5 business days after the Case's CreatedDate
		Date fiveBusinessDaysAfterCreation = BusinessHoursService.newInstance().calculateNextBusinessDay(newRecord.CreatedDate.date(), 5);
		Date currentDate = Date.today();
		if (oldRecord.OwnerId != newRecord.OwnerId && newRecord.OwnerId.equals(UNIFIED_CUSTOMER_SERVICE_MONITORING_QUEUE.Id)) {
			if (currentDate < fiveBusinessDaysAfterCreation) {
				return true;
			} else {
				newRecord.addError(ERROR_SLA_EXPIRED);
			}
		}
		return false;
	}

	/**
	 * @description update relevant details for eligible cases that met SLA period including status and exclude automation flag
	 * @param eligibleCases filtered case that met eligibility
	 */
	private void pushCaseToMonitoring(List<Case> eligibleCases) {
		for (Case updateCase : eligibleCases) {
			updateCase.Status = 'Monitoring';
			updateCase.Exclude_Subscription_Automation__c = false;
		}
	}
}