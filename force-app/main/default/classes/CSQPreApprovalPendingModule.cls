/***
 * @author SteveL
 * @date 2024-01-30
 * @description Logic related to CSQ records.
 * @changelog
 */

public inherited sharing class CSQPreApprovalPendingModule extends ApplicationModule{
	// Setup which triggers this module should respond to
	public CSQPreApprovalPendingModule() {
		getTriggerEvents().enableBeforeUpdate().enableAfterUpdate();
	}

	/**
	 * Called when a CSQ is being updated.
	 * @param records list of CSQ records
	 * @param existingRecords map of existing CSQ records
	 * @param uow instance of UnitOfWork
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			checkPreApprovalEligibility(records);
			unlockRecordForApprovalEditing(records);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CSQ', CSQPreApprovalAutomationModule.class.getName(), 'onBeforeUpdate', 'Customer_Scoping_Questionnaire__c', ApplicationLogger.LoggingLevel.ERROR);
		}

	}

	/**
	 * @param changedRecords changed records
	 * @description unlocks the record so the approver can edit the referral reasons
	 */
	private static void checkPreApprovalEligibility(List<SObject> records) {
		Map<Id,Group> approverMap = GroupsSelector.newInstance().selectByGroupTypeAndName(new Set<String>{'Queue'}, new Set<String>{'CSQ_Onboarding_Queue'});
		List<Approval.ProcessSubmitRequest> apRequests = new List<Approval.ProcessSubmitRequest>();
		for (Customer_Scoping_Questionnaire__c csq : (List<Customer_Scoping_Questionnaire__c>) records) {
			if (csq.Pick_up_Location_Record_Count_Total__c > 1) {
				csq.PreApprovalStatus__c = CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_REFERRED;
				csq.PreApprovalReferralReasons__c = 'DGs;Bulk Pallets'; //todo change this according to business decision
			} else {
				Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
				req.setComments('Submitting request for approval.');
				req.setObjectId(csq.Id);
				req.setSubmitterId(UserInfo.getUserId());
				req.setProcessDefinitionNameOrId('CSQ_Pre_Approval_Process');
				req.setNextApproverIds(new List<Id>(approverMap.keySet()));
				req.setSkipEntryCriteria(true);

				apRequests.add(req);
			}
		}
		Approval.process(apRequests);
	}

	/**
	 * @param changedRecords changed records
	 * @description unlocks the record so the approver can edit the referral reasons
	 */
	private static void unlockRecordForApprovalEditing(List<SObject> records) {
		for (Customer_Scoping_Questionnaire__c csq : (List<Customer_Scoping_Questionnaire__c>) records) {
			Approval.unlock(csq.Id);
		}
	}
}