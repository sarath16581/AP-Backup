/***
 * @author SteveL
 * @date 2024-01-30
 * @description Logic related to CSQ records.
 * @changelog
 */

public inherited sharing class CSQPreApprovalPendingModule extends ApplicationModule{
	// Setup which triggers this module should respond to
	public CSQPreApprovalPendingModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	/**
	 * Called when a CSQ is being updated.
	 * @param records list of CSQ records
	 * @param existingRecords map of existing CSQ records
	 * @param uow instance of UnitOfWork
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			Set<SObjectField> monitoredFields = new Set<SObjectField>{Customer_Scoping_Questionnaire__c.PreApprovalStatus__c};
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('CSQPreApprovalPendingModule', records, existingRecords, monitoredFields);
			unlockRecordForApprovalEditing(changedRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CSQ', CSQPreApprovalAutomationModule.class.getName(), 'onAfterUpdate', 'Customer_Scoping_Questionnaire__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @param changedRecords changed records
	 * @description unlocks the record so the approver can edit the referral reasons
	 */
	private static void unlockRecordForApprovalEditing(List<ApplicationRecursion.RecordState> changedRecords) {
		for (ApplicationRecursion.RecordState recordState : changedRecords) {
			Customer_Scoping_Questionnaire__c csq = (Customer_Scoping_Questionnaire__c) recordState.record;
			Approval.unlock(csq.Id);
		}
	}
}