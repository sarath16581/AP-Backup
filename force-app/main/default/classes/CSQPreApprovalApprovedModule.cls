/***
 * @author SteveL
 * @date 2024-02-19
 * @description Logic related to CSQ records.
 * @changelog
 */


public inherited sharing class CSQPreApprovalApprovedModule extends ApplicationModule{
	@TestVisible private static final String APPROVED_STATUS = 'Approved';

	// Setup which triggers this module should respond to
	public CSQPreApprovalApprovedModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	public static CSQPreApprovalApprovedModule newInstance() {
		return (CSQPreApprovalApprovedModule) Application.Utilities.newInstance(CSQPreApprovalApprovedModule.class);
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
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('CSQPreApprovalApprovedModule', records, existingRecords, monitoredFields);
			setPickupLocationApproval(changedRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CSQ', CSQPreApprovalApprovedModule.class.getName(), 'onAfterUpdate', 'Customer_Scoping_Questionnaire__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private void setPickupLocationApproval(List<ApplicationRecursion.RecordState> changedRecords) {
		Set<Id> csqIds = new Set<Id>();
		for (ApplicationRecursion.RecordState recordState : changedRecords) {
			csqIds.add(recordState.record.Id);
		}

		List<Pick_Up_Location__c> locations = PickUpLocationSelector.newInstance().selectByParentId(csqIds, new Set<Object>());
		for (Pick_Up_Location__c location : locations) {
			location.Pick_up_Location_Status__c = APPROVED_STATUS;
		}
		// using dmlUpdate as these are related records of the CSQs, hence not supported by the uow
		ApplicationDatabase.getInstance().dmlUpdate(locations);
	}
}