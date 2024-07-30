/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Nathan Franklin
 * @date 2024-07-31
 * @changelog
 */
public inherited sharing class ContactRequestTriggerHandler extends ApplicationTriggerHandler {
	
	public override SObjectType getSObjectType() {
		return ContactRequest.SObjectType;
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
			'filterEligibleCaseRequests' => new List<SObject>()
		};
		for(SObject record : records) {
			SObjectType whatIdObjectType = ((Id)record.get('WhatId'))?.getSobjectType();
			if(whatIdObjectType == Case.SObjectType) {
				filteredRecords.get('filterEligibleCaseRequests').add(record);
			}
		}
		return filteredRecords;
	}

	public override void registerModules() {

		// populate the case id on both the relevant agent work records and the contactrequest records themselves
		// This provides an easy to reference lookup to the case the record is associated with
		registerModule(CaseRecordPopulationModule.class, 'filterEligibleCaseRequests');

	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution. 
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			AgentWork.SObjectType
		};
	}


}