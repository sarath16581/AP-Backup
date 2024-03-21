/***
 * @author SteveL
 * @date 2024-01-30
 * @description Logic related to CSQ records.
 * @changelog
 */

public inherited sharing class CSQPreApprovalAutomationModule extends ApplicationModule{
	private static final String REFERRAL_ERROR = 'Please go to the CSQ record to ensure the Pre-Approval Referral Reasons field is not blank before rejecting the CSQ Pre-Approval.';

	// Setup which triggers this module should respond to
	public CSQPreApprovalAutomationModule() {
		getTriggerEvents().enableBeforeUpdate().enableAfterUpdate();
	}

	public static CSQPreApprovalAutomationModule newInstance() {
		return (CSQPreApprovalAutomationModule) Application.Utilities.newInstance(CSQPreApprovalAutomationModule.class);
	}

	/**
	 * Called when a CSQ is being updated.
	 * @param records list of CSQ records
	 * @param existingRecords map of existing CSQ records
	 * @param uow instance of UnitOfWork
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			enforceReferralReasons(records);
			updateDateSubmitted(records);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CSQ', CSQPreApprovalAutomationModule.class.getName(), 'onBeforeUpdate', 'Customer_Scoping_Questionnaire__c', ApplicationLogger.LoggingLevel.ERROR);
		}
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
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords('CSQPreApprovalAutomationModule', records, existingRecords, monitoredFields);
			enterCSQApprovalUponPreApprovalNotApplicable(changedRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CSQ', CSQPreApprovalAutomationModule.class.getName(), 'onAfterUpdate', 'Customer_Scoping_Questionnaire__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private static void enforceReferralReasons(List<SObject> records) {
		for (Customer_Scoping_Questionnaire__c csq : (List<Customer_Scoping_Questionnaire__c>) records) {
			if (String.isEmpty(csq.PreApprovalReferralReasons__c)) {
				csq.addError(REFERRAL_ERROR);
			}
		}
	}

	private static void updateDateSubmitted(List<SObject> records) {
		for (Customer_Scoping_Questionnaire__c csq : (List<Customer_Scoping_Questionnaire__c>) records) {
			csq.DateSubmitted__c = System.today();
		}
	}

	@TestVisible
	private static void enterCSQApprovalUponPreApprovalNotApplicable(List<ApplicationRecursion.RecordState> changedRecords) {
		List<Approval.ProcessSubmitRequest> apRequests = new List<Approval.ProcessSubmitRequest>();
		for (ApplicationRecursion.RecordState recordState : changedRecords) {
			Customer_Scoping_Questionnaire__c csq = (Customer_Scoping_Questionnaire__c) recordState.record;
			Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
			req.setComments('Submitting request for approval.');
			req.setObjectId(csq.Id);
			req.setSubmitterId(UserInfo.getUserId());
			req.setProcessDefinitionNameOrId('CSQ_Approval_Process1');
			req.setSkipEntryCriteria(true);

			apRequests.add(req);
		}
		Approval.process(apRequests);
	}
}