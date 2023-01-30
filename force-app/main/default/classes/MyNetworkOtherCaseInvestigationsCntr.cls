/**
* @author Dattaraj Deshmukh
* @date 2022-12-07
* @domain MyNetwork
* @description Controller to list case investigations other than passed record Id on MyNetwork CI detail page.
* @changelog
* @test MyNetworkOtherCaseInvestigations_Test
* 2022-12-07 - Dattaraj Deshmukh - Created.
*/
public with sharing class MyNetworkOtherCaseInvestigationsCntr {
	
	@AuraEnabled(cacheable=true)
	public static List<CaseInvestigation__c> getOtherCaseInvestigations(Id caseInvestigationRecordId) { 

		List<CaseInvestigation__c> otherCaseInvestigations = new List<CaseInvestigation__c>();
		
		CaseInvestigation__c selectedCI = CaseInvestigationsSelector.newInstance().selectById(new Set<Id>{caseInvestigationRecordId}).values()[0];

		List<CaseInvestigation__c> caseInvestigations = new List<CaseInvestigation__c>();
		caseInvestigations = CaseInvestigationsSelector.newInstance().selectOpenCaseInvestigationsByCaseIds(new Set<Id>{selectedCI.Case__c},
															new Set<Object>{CaseInvestigationsSelector.Options.WITH_CASE_DETAILS,
																				CaseInvestigationsSelector.Options.WITH_ARTICLES,
																				CaseInvestigationsSelector.Options.WITH_NETWORKS}).values();
		
		for(CaseInvestigation__c ci : caseInvestigations) {
			if(ci.Id == caseInvestigationRecordId) {
				continue;
			}
			else {
				otherCaseInvestigations.add(ci);
			}
		}
		return otherCaseInvestigations;
	}
}
