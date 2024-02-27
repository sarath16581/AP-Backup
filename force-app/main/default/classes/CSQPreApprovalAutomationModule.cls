/***
 * @author SteveL
 * @date 2024-01-30
 * @description Logic related to CSQ records.
 * @changelog
 */

public inherited sharing class CSQPreApprovalAutomationModule extends ApplicationModule{
	// Setup which triggers this module should respond to
	public CSQPreApprovalAutomationModule() {
		getTriggerEvents().enableBeforeUpdate();
	}

	/**
	 * Called when a CSQ is being updated.
	 * @param records list of CSQ records
	 * @param existingRecords map of existing CSQ records
	 * @param uow instance of UnitOfWork
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			enterCSQApprovalUponPreApprovalNotApplicable(records);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CSQ', CSQPreApprovalAutomationModule.class.getName(), 'onBeforeUpdate', 'Customer_Scoping_Questionnaire__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private static void enterCSQApprovalUponPreApprovalNotApplicable(List<SObject> records) {
		for (Customer_Scoping_Questionnaire__c csq : (List<Customer_Scoping_Questionnaire__c>) records) {
			Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
			req1.setComments('Submitting request for approval.');
			req1.setObjectId(csq.Id);
			req1.setSubmitterId(UserInfo.getUserId());
			req1.setProcessDefinitionNameOrId('CSQ_Approval_Process1');
			req1.setSkipEntryCriteria(true);

			Approval.process(req1);
		}
	}
}