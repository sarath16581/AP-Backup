/***
 * @author Hasantha Liyanage
 * @date 2023-07-25
 * @domain Core
 * @description CompensationService
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Created
 */
public with sharing class CompensationService {
    public static Set<String> COMPENSATION_APPROVED_STATUSES = new Set<String>{
            'APPROVED',
            'PROCESSING',
            'ALTERNATE COMPENSATION',
            'AWAITING MONEY ORDER NUMBER',
            'PAYMENT SUCCESSFUL',
            'APPROVED AWAITING CUSTOMER'
    };
    public static CompensationService getInstance() {
        return (CompensationService) Application.Utilities.getInstance(CompensationService.class);
    }

    /** any updates to compensation record when creation of the record
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
}