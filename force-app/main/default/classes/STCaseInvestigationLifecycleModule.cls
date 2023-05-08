/**
 * @description			: This module handles all operations related to Case Investigation Life Cycle
 * @author				: Dattaraj Deshmukh
 * @domain				: Case Investigation
 * @changelog
 * 2022-12-15 - Dattaraj Deshmukh - created
 * 2023-02-14 - Mahesh Parvathaneni - Added method setCaseInvestigationClosureDate
 * 2022-02-22 - Dattaraj Deshmukh 	- Added recordTypeIds to 'selectOpenCaseInvestigationsByCaseIds' method call.
 **/
public inherited sharing class STCaseInvestigationLifecycleModule extends ApplicationDomain.Module {
	public static STCaseInvestigationLifecycleModule newInstance() {
		return (STCaseInvestigationLifecycleModule) Application.Utilities.newInstance(STCaseInvestigationLifecycleModule.class);
	}

	// Setup which trigger events this module should respond to
	public STCaseInvestigationLifecycleModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterInsert().enableBeforeUpdate();
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
		resetValuesOnNetworkChange((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
	}

	// this method resets the owner id back to the case's ownerid, status to In Progress and sets Require More Information, Still Under Investigation and Is Printed to FALSE
	@TestVisible
	private void resetValuesOnNetworkChange(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {
		Map<Id, CaseInvestigation__c> validCIs = new Map<Id, CaseInvestigation__c>();
		for(CaseInvestigation__c ci: records) {
			if(ci.Network__c != existingRecords.get(ci.Id).Network__c) {
				validCIs.put(ci.Id, ci);
			}
		}

		if(validCIs.isEmpty() == false) {
			Map<Id, CaseInvestigation__c> ciWithCaseDetails = CaseInvestigationsSelector.newInstance().selectById(validCIs.keySet(), new Set<Object>{CaseInvestigationsSelector.Options.WITH_CASE_DETAILS});
			for(CaseInvestigation__c ci: validCIs.values()) {
				if(ciWithCaseDetails.containsKey(ci.Id) == true) {
					CaseInvestigation__c ciWithCaseDetail = ciWithCaseDetails.get(ci.Id);
					if(ciWithCaseDetail.Case__r != null && ciWithCaseDetail.Case__r.OwnerId != null) {
						ci.OwnerId = ci.CreatedById;
						ci.RequireMoreInformation__c = false;
						ci.StillUnderInvestigation__c = false;
						ci.Status__c = 'In Progress';
						ci.IsPrinted__c = false;
					}
				}
			}
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
			if (!ci.IsClosed__c && (existingRecords == null || (existingRecords != null && ci.IsClosed__c != existingRecords.get(ci.Id).IsClosed__c))) {
				//if case investigation is not in any of the closed statuses, reset the case investigation closure date
				ci.CaseInvestigationClosureDate__c = null;
			} else if(ci.IsClosed__c && (existingRecords == null || (existingRecords != null && ci.IsClosed__c != existingRecords.get(ci.Id).IsClosed__c))) {
				//if case investigation is in any of the closed statuses, set the case investigation closure date to now
				ci.CaseInvestigationClosureDate__c = System.now();
			}
		}
	}
}