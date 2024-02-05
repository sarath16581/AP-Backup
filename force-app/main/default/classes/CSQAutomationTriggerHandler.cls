/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author SteveL
 * @date 2024-01-30
 * @changelog
 */

public inherited sharing class CSQAutomationTriggerHandler extends ApplicationTriggerHandler{
	private static final String PRE_APPROVAL_STATUS_NOT_APPLICABLE = 'Not Applicable';

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
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
				'filterCSQPreApproval' => new List<SObject>()
		};
		for(SObject record : records) {
			if ((String)record.get('PreApprovalStatus__c') == PRE_APPROVAL_STATUS_NOT_APPLICABLE) {
				filteredRecords.get('filterCSQPreApproval').add(record);
			}
		}
		return filteredRecords;
	}

	public override void registerModules() {
		registerModule(CSQAutomationModule.class, 'filterCSQPreApproval');
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution.
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				Customer_Scoping_Questionnaire__c.SObjectType
		};
	}
}