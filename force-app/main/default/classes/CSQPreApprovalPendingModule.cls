/***
 * @author SteveL
 * @date 2024-01-30
 * @description Logic related to CSQ records.
 * @changelog
 */

public inherited sharing class CSQPreApprovalPendingModule extends ApplicationModule{
	@TestVisible private static final String AUTO_REFERRAL_REASONS = 'Multiple pickup locations';
	// Setup which triggers this module should respond to
	public CSQPreApprovalPendingModule() {
		getTriggerEvents().enableBeforeUpdate().enableAfterUpdate();
	}

	public static CSQPreApprovalPendingModule newInstance() {
		return (CSQPreApprovalPendingModule) Application.Utilities.newInstance(CSQPreApprovalPendingModule.class);
	}

	/**
	 * Called when a CSQ is being updated.
	 * @param records list of CSQ records
	 * @param existingRecords map of existing CSQ records
	 * @param uow instance of UnitOfWork
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			checkPreApprovalEligibility(records, existingRecords);
			unlockRecordForApprovalEditing(records);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CSQ', CSQPreApprovalPendingModule.class.getName(), 'onBeforeUpdate', 'Customer_Scoping_Questionnaire__c', ApplicationLogger.LoggingLevel.ERROR);
		}

	}

	/**
	 * @description unlocks the record so the approver can edit the referral reasons
	 * @param records List<SObject>
	 * @param existingRecords Map<Id, SObject>
	 */
	private static void checkPreApprovalEligibility(List<SObject> records, Map<Id, SObject> existingRecords) {
		Map<Id,Group> approverMap = GroupsSelector.newInstance().selectByGroupTypeAndDeveloperName(new Set<String>{'Queue'}, new Set<String>{'CSQ_Onboarding_Queue'});
		List<Pick_Up_Location__c> locations = PickUpLocationSelector.newInstance().selectByParentId(existingRecords.keySet(), new Set<Object>());
		Map<Id,Pick_Up_Location__c[]> csqLocations = new Map<Id,Pick_Up_Location__c[]>();
		for (Pick_Up_Location__c location : locations) {
			if (csqLocations.get(location.CSQ__c) == null || csqLocations.get(location.CSQ__c).isEmpty()) {
				csqLocations.put(location.CSQ__c, new List<Pick_Up_Location__c>{location});
			} else {
				csqLocations.get(location.CSQ__c).add(location);
			}
		}

		List<Approval.ProcessSubmitRequest> apRequests = new List<Approval.ProcessSubmitRequest>();
		for (Customer_Scoping_Questionnaire__c csq : (List<Customer_Scoping_Questionnaire__c>) records) {
			Set<String> uniqueAddress = new Set<String>();
			for (Pick_Up_Location__c location : csqLocations.get(csq.Id)) {
				uniqueAddress.add(concatenateLocationString(location));
			}
			if (uniqueAddress.size() > 1) {
				csq.PreApprovalStatus__c = CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_REFERRED;
				csq.PreApprovalReferralReasons__c = AUTO_REFERRAL_REASONS;
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
	 * @param records List<SObject>
	 * @description unlocks the record so the approver can edit the referral reasons
	 */
	private static void unlockRecordForApprovalEditing(List<SObject> records) {
		for (Customer_Scoping_Questionnaire__c csq : (List<Customer_Scoping_Questionnaire__c>) records) {
			Approval.unlock(csq.Id);
		}
	}

	/**
	 * @param location Pick_Up_Location__c
	 *
	 * @return a single string containing address, state, and postcode with whitespace removed and to upper case
	 */
	private static String concatenateLocationString(Pick_Up_Location__c location) {
		String locationString = location.Address__c + location.State__c + location.Postcode__c;
		return locationString.deleteWhitespace().toUpperCase();
	}
}