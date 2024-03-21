/***
 * @author SteveL
 * @date 2024-03-14
 * @description Logic related to CSQ records.
 * @changelog
 */

public inherited sharing class CSQPreApprovalUnderReviewModule extends ApplicationModule {
	public CSQPreApprovalUnderReviewModule() {
		getTriggerEvents().enableBeforeUpdate();
	}

	public static CSQPreApprovalUnderReviewModule newInstance() {
		return (CSQPreApprovalUnderReviewModule) Application.Utilities.newInstance(CSQPreApprovalUnderReviewModule.class);
	}

	/**
	 * Called when a CSQ is being updated.
	 * @param records list of CSQ records
	 * @param existingRecords map of existing CSQ records
	 * @param uow instance of UnitOfWork
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			setUnderReviewPreApprover(records, existingRecords);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CSQ', CSQPreApprovalUnderReviewModule.class.getName(), 'onBeforeUpdate', 'Customer_Scoping_Questionnaire__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @description set the PreApprover__c field to the current user if the pre approval status is changed to Under Onboarding Review
	 * @param records List<SObject>
	 * @param existingRecords Map<Id, SObject>
	 */
	private static void setUnderReviewPreApprover(List<SObject> records, Map<Id, SObject> existingRecords) {
		Customer_Scoping_Questionnaire__c oldCsq;
		for (Customer_Scoping_Questionnaire__c csq : (List<Customer_Scoping_Questionnaire__c>) records) {
			oldCsq = (Customer_Scoping_Questionnaire__c) existingRecords.get(csq.Id);
			if (csq.PreApprovalStatus__c == CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_UNDER_ONBOARDING_REVIEW && oldCsq.PreApprovalStatus__c != CSQAutomationTriggerHandler.PRE_APPROVAL_STATUS_UNDER_ONBOARDING_REVIEW) {
				csq.PreApprover__c = UserInfo.getUserId();
			}
		}
	}
}