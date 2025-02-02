/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author SteveL
 * @date 2024-01-30
 * @changelog
 */

public inherited sharing class CSQAutomationTriggerHandler extends ApplicationTriggerHandler{
	public static final String PRE_APPROVAL_STATUS_REFERRED = 'Referred';
	public static final String PRE_APPROVAL_STATUS_PENDING_ONBOARDING = 'Pending Onboarding Approval';
	public static final String PRE_APPROVAL_STATUS_APPROVED = 'Approved';
	public static final String PRE_APPROVAL_STATUS_UNDER_ONBOARDING_REVIEW = 'Under Onboarding Review';

	public override SObjectType getSObjectType() {
		return Customer_Scoping_Questionnaire__c.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	/**
	 * Pre filter records to minimise repetitive looping inside the modules
	 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered
	 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
	 *
	 * @return Map<String, List<SObject>>
	 * @param records List<SObject>
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
				'filterCSQPreApprovalReferred' => new List<SObject>(),
				'filterCSQPreApprovalPending' => new List<SObject>(),
				'filterCSQPreApprovalUnderReview' => new List<SObject>(),
				'filterCSQPreApprovalApproved' => new List<SObject>()
		};

		for(SObject record : records) {
			String preApprovalStatus = (String)record.get('PreApprovalStatus__c');

			if (preApprovalStatus == PRE_APPROVAL_STATUS_PENDING_ONBOARDING) {
				filteredRecords.get('filterCSQPreApprovalPending').add(record);
			} else if (preApprovalStatus == PRE_APPROVAL_STATUS_UNDER_ONBOARDING_REVIEW) {
				filteredRecords.get('filterCSQPreApprovalUnderReview').add(record);
			} else if (preApprovalStatus == PRE_APPROVAL_STATUS_REFERRED) {
				filteredRecords.get('filterCSQPreApprovalReferred').add(record);
			} else if (preApprovalStatus == PRE_APPROVAL_STATUS_APPROVED) {
				filteredRecords.get('filterCSQPreApprovalApproved').add(record);
			}
		}
		return filteredRecords;
	}

	public override void registerModules() {
		registerModule(CSQPreApprovalPendingModule.class, 'filterCSQPreApprovalPending');
		registerModule(CSQPreApprovalUnderReviewModule.class, 'filterCSQPreApprovalUnderReview');
		registerModule(CSQPreApprovalAutomationModule.class, 'filterCSQPreApprovalReferred');
		registerModule(CSQPreApprovalApprovedModule.class, 'filterCSQPreApprovalApproved');
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution.
	 * It also defines the order in which the work will be committed
	 *
	 * @return List<SObjectType>
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				Customer_Scoping_Questionnaire__c.SObjectType
		};
	}
}