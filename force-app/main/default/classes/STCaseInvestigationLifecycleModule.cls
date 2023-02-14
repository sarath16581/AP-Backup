/**
 * @description       : This module handles all operations related to Case Investigation Life Cycle
 * @author            : Dattaraj Deshmukh
 * @domain            : Case Investigation
 * @changelog
 * 2022-12-15 - Dattaraj Deshmukh - created
 * 2023-02-14 - Mahesh Parvathaneni - Added method setCaseInvestigationClosureDate
 **/
public inherited sharing class STCaseInvestigationLifecycleModule extends ApplicationDomain.Module {
	public static STCaseInvestigationLifecycleModule newInstance() {
		return (STCaseInvestigationLifecycleModule) Application.Utilities.newInstance(STCaseInvestigationLifecycleModule.class);
	}

	// Setup which trigger events this module should respond to
	public STCaseInvestigationLifecycleModule() {
		getTriggerEvents().enableAfterInsert();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		//set the case investigation closure date 
		setCaseInvestigationClosureDate((List<CaseInvestigation__c>) records, null, uow);
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		updateCaseStatus((List<CaseInvestigation__c>) records, uow);
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		//set the case investigation closure date 
		setCaseInvestigationClosureDate((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
	}


	/**
	*	@desc: Function to update all child case investigations when parent case is Closed.
	*	@param: List of updated cases, ApplicationUnitOfWork 
	*/
	public void updateAllCaseInvestigations(List<Case> cases, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow) {
		
		Set<Id> caseIds = new Set<Id>();
		List<CaseInvestigation__c> caseInvestigationsToUpdate = new List<CaseInvestigation__c>();

		for(Case updatedCase : cases) {

			//check if status is CLOSED and RecordType is of StarTrack case
			if(existingRecords.containsKey(updatedCase.Id) && updatedCase.Status != existingRecords.get(updatedCase.Id).Status && 
					updatedCase.Status == MyNetworkConstants.CASE_STATUS_CLOSED && updatedCase.StarTrack_RecordType__c) {
				caseIds.add(updatedCase.Id);
			}
		}

		//query CI records based on parent cases.
		//update status = CLOSED for all child case investigations.
		for(CaseInvestigation__c caseInv : CaseInvestigationsSelector.newInstance().selectOpenCaseInvestigationsByCaseIds(caseIds).values()) {
			caseInvestigationsToUpdate.add( new CaseInvestigation__c(Id = caseInv.Id, Status__c = MyNetworkConstants.CASE_INVESTIGATION_CLOSED_STATUS));
		}

		//update case investigations records
		if(!caseInvestigationsToUpdate.isEmpty()) {
			uow.registerDirty(caseInvestigationsToUpdate);
		}
	}


	/**
	 * function to update parent case whenever new CI records are created.
	 */
	@TestVisible
	private void updateCaseStatus(List<CaseInvestigation__c> records, ApplicationUnitOfWork uow) {
		List<Case> casesToUpdate = new List<Case>();

		for(CaseInvestigation__c caseInv : records) {

			//if CI record has OPEN status, set it's parent case status to 'Waiting on operations'
			if(caseInv.Status__c != null && caseInv.Status__c.equals(MyNetworkConstants.CASE_INVESTIGATION_NEW_STATUS)) { 
				casesToUpdate.add(new Case(Id = caseInv.Case__c, Status = MyNetworkConstants.CASE_STATUS_WAITING_ON_OPERATIONS));
			}
		}

		//update cases.
		if(!casesToUpdate.isEmpty()) {
			uow.registerDirty(casesToUpdate);
		}
	}

	//this method set the case investigation closure date time field on case investigation records
	private void setCaseInvestigationClosureDate(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {
		for(CaseInvestigation__c ci : records) {
			if (!ci.IsClosed__c && (existingRecords == null || ci.IsClosed__c != existingRecords.get(ci.Id).IsClosed__c)) {
				//if case investigation is not in any of the closed statuses, reset the case investigation closure date
				ci.CaseInvestigationClosureDate__c = null;
			} else if(ci.IsClosed__c && (existingRecords == null || ci.IsClosed__c != existingRecords.get(ci.Id).IsClosed__c)) {
				//if case investigation is in any of the closed statuses, set the case investigation closure date to now
				ci.CaseInvestigationClosureDate__c = System.now();
			}
		}
	}

}
