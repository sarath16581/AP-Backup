/**
 * @description       : This module checks and retrieves Articles from SAP into SF
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2022-12-13 - Mahesh Parvathaneni - Added beforeInsert trigger event and checkDuplicateCaseInvestigationRecords method
 **/
public inherited sharing class STCaseInvestigationArticleModule extends ApplicationDomain.Module {
	public static STCaseInvestigationArticleModule newInstance() {
		return (STCaseInvestigationArticleModule) Application.Utilities.newInstance(STCaseInvestigationArticleModule.class);
	}

	// Setup which trigger events this module should respond to
	public STCaseInvestigationArticleModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate().enableBeforeInsert();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow){
		checkDuplicateCaseInvestigationRecords((List<CaseInvestigation__c>) records);
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		retrieveArticles((List<CaseInvestigation__c>) records, null, uow);
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		retrieveArticles((List<CaseInvestigation__c>) records, (Map<Id, CaseInvestigation__c>) existingRecords, uow);
	}

	/**
	 * function to check the duplicate case investigation records being created for same case, article and network.
	 */
	private void checkDuplicateCaseInvestigationRecords(List<CaseInvestigation__c> records){
		Set<Id> caseIds = new Set<Id>();
		Set<Id> networkIds = new Set<Id>();
		Set<String> articleReferences = new Set<String>();
		//case id + article reference id + network id is the key
		Set<String> existingCaseArticleNetworkKeys = new Set<String>();
		Set<String> caseArticleNetworkKeys = new Set<String>();

		for (CaseInvestigation__c ci : records) {
			String key = ci.Case__c + ci.ReferenceID__c + ci.Network__c;
			if (caseArticleNetworkKeys.contains(key)) {
				//add error if there are duplicate records in the new list
				ci.addError(String.format(Label.CaseInvestigationDuplicateErrorMessage, new List<String>{ci.ReferenceID__c, ci.Network__c, ci.Case__c}));
			} else {
				caseArticleNetworkKeys.add(key);
			}

			if (ci.Case__c != null) {
				caseIds.add(ci.Case__c);
			}
			if (String.isNotBlank(ci.ReferenceID__c)) {
				articleReferences.add(ci.ReferenceID__c);
			}
			if (ci.Network__c != null) {
				networkIds.add(ci.Network__c);
			}
		}

		if (caseIds.size() > 0 || articleReferences.size() > 0 || networkIds.size() > 0) {
			//get existing case investigation related to the case, network and article reference ids
			for (CaseInvestigation__c eci : CaseInvestigationsSelector.newInstance().selectOpenCaseInvestigationsByCaseArticleNetworkId(caseIds, articleReferences, networkIds).values()) {
				String exisitngKey = eci.Case__c + eci.ReferenceID__c + eci.Network__c;
				existingCaseArticleNetworkKeys.add(exisitngKey);
			}

			for (CaseInvestigation__c ci : records) {
				String key = ci.Case__c + ci.ReferenceID__c + ci.Network__c;
				if (existingCaseArticleNetworkKeys.contains(key)) {
					//add error if there are duplicate records
					ci.addError(String.format(Label.CaseInvestigationDuplicateErrorMessage, new List<String>{ci.ReferenceID__c, ci.Network__c, ci.Case__c}));
				}
			}
		}
	}

	void retrieveArticles(List<CaseInvestigation__c> records, Map<Id, CaseInvestigation__c> existingRecords, ApplicationUnitOfWork uow) {
		Set<String> referenceIds = new Set<String>();
		for(CaseInvestigation__c ci: records) {
			if(String.isBlank(ci.ReferenceId__c) == false && (existingRecords == null || ci.ReferenceId__c != existingRecords.get(ci.Id).ReferenceId__c)) {
				referenceIds.add(ci.ReferenceId__c);
			}
		}

		if (referenceIds.isEmpty() == false) {
			
			// use the replicate version here. 
		}
	}

	

}
