/***
 * @author Hasantha Liyanage
 * @date 2023-07-25
 * @domain Core
 * @description CompensationService
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Created
 */
public with sharing class CompensationService {
    public static CompensationService getInstance() {
        return (CompensationService) Application.Utilities.getInstance(CompensationService.class);
    }

    /**
     * any updates to compensation record when creation of the record
     * @param compensations
     */
    public void updateCurrentArticleInfoOnCompensationRecord(List<Compensation__c> compensations) {
        Set<Id> relatedCases = new Set<Id>();
        for (Compensation__c compensation : compensations) {
            relatedCases.add(compensation.Case__c);
        }
        //Stores the article id from Case as static value to track the article that the compensation record was intended for.
        // this is only updated when creating the record and should not update
        Map<Id, Case> cases = CasesSelector.newInstance().selectById(relatedCases, new Set<Object>{
                CasesSelector.Options.WITH_ARTICLE
        });
        for (Compensation__c compensation : compensations) {
            compensation.CurrentArticleId__c = cases.get(compensation.Case__c)?.ReferenceID__c;
        }
    }

    /**
     * get grouped compensation records per case by passing the Id
     * @param relatedCaseIds
     *
     * @return Map<Id, List<Compensation__c>> compensations grouped by case
     */
    public Map<Id, List<Compensation__c>> getCompensationRecordByCaseIds(Set<Id> relatedCaseIds) {
        if (relatedCaseIds == null || relatedCaseIds.isEmpty()) {
            return new Map<Id, List<Compensation__c>>();
        }
        // get the related cases
        List<Case> cases = CasesSelector.newInstance(1).selectById(relatedCaseIds).values();
        return getCompensationRecordByCase(cases);
    }

    /**
      * Grouping compensations per case based on the reference ID, used a list of case to prevent multiple
      * caseSelector calls to retrieve cases and overridden by getCompensationRecordByCaseIds method to
      * be called with case Id
      * @param cases
      *
      * @return Map<Id, List<Compensation__c>> compensations grouped by case
      */
    public Map<Id, List<Compensation__c>> getCompensationRecordByCase(List<Case> cases) {
        Map<Id, List<Compensation__c>> compensationsByCase;
        // find the reference IDs
        Set<String> referenceIds = new Set<String>();
        for (Case cse : cases) {
            // if the reference ID is blank do not need to check
            if(String.isNotBlank(cse.ReferenceID__c)){
                referenceIds.add(cse.ReferenceID__c);
            }
        }
        // with the reference ID let's find how many cases available
        Map<Id, Case> allCases = CasesSelector.newInstance().selectByReferenceIdOrderByCreatedDate(referenceIds);
        // on all the cases found are there one or more compensation(s) already exists?
        List<Compensation__c> allCompensations = CompensationSelector.newInstance().selectByCaseIds(allCases.keySet(), new Set<Object>{
                CompensationSelector.Options.WITH_CASE
        });
        // group them by case reference
        compensationsByCase = new Map<Id, List<Compensation__c>>();
        if(allCompensations == null) {
            return compensationsByCase;
        }
        for (Compensation__c comp : allCompensations) {
            List<Compensation__c> compensationsGroup = compensationsByCase.get(comp.Case__c);
            if (compensationsGroup == null) {
                compensationsByCase.put(comp.Case__c, new List<Compensation__c>{
                        comp
                });
                continue;
            }
            compensationsGroup.add(comp);
        }
        return compensationsByCase;
    }
}