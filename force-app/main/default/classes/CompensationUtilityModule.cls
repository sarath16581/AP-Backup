/**
 * @author Hasantha Liyanage
 * @date 2023-07-12
 * @group Module
 * @tag Module
 * @tag Compensation
 * @domain Core
 * @description Compensation Module class
 * @changelog
 * 2023-07-15 - Hasantha Liyanage - Created
 * 2024-1-25 - Swati Mogadala	- Updated to check reference Id against all cases
 */

public with sharing class CompensationUtilityModule extends ApplicationModule {
    public static CompensationUtilityModule newInstance() {
        return (CompensationUtilityModule) Application.Utilities.newInstance(CompensationUtilityModule.class);
    }

    public CompensationUtilityModule() {
        getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
    }

    public static Boolean isCompensationSupervisor {
        get {
            if (isCompensationSupervisor == null) {
                isCompensationSupervisor = FeatureManagement.checkPermission('Is_Compensation_Supervisor');
            }
            return isCompensationSupervisor;
        }
        private set;
    }

    /**
    * Called when a new record is being inserted.
    */
    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            if (!records.isEmpty()) {
                // update fields on compensation record
                CompensationService.getInstance().updateCurrentArticleInfoOnCompensationRecord ((List<Compensation__c>) records);
                validateCompensationsAgainstCaseDetails((List<Compensation__c>) records);
            }
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Australia Post', CompensationUtilityModule.class.getName(), 'onBeforeInsert', 'Compensation Trigger', LoggingLevel.ERROR);
        }
    }

    /**
     * Trigger level validation for more than one compensation record per case based on the user permissions
     * @param compensations
     */
    public void validateCompensationsAgainstCaseDetails(List<Compensation__c> compensations) {
        // if the user is compensation supervisor no errors should be thrown
        if(isCompensationSupervisor) {
            return;
        }
        Set<Id> relatedCaseIds = new Set<Id>();
        for (Compensation__c compensation : compensations) {
            relatedCaseIds.add(compensation.Case__c);
        }
        // get the related cases
        Map<Id,Case> cases = CasesSelector.newInstance(1).selectById(relatedCaseIds);
        // get grouped compensation records by case id for the passed references
        Map<Id, List<Compensation__c>> groupedCompensationByCaseIds = CompensationService.getInstance().getCompensationRecordByCase(cases.values());
        for (Compensation__c compensation : compensations) {
            if(compensation.Case__c != null && cases!= null && String.isEmpty(cases.get(compensation.Case__c).ReferenceID__c)) {
                // add message The Reference ID cannot be blank on the case
                compensation.addError(Label.CompensationMsgCaseMustHaveReference);
            } else {
                 // if the reference ID on the case is available and has more than one compensation records
                 //List<Compensation__c> compensationsForCaseId = groupedCompensationByCaseIds.get(compensation.Case__c);
                // if a compensation record exists for the reference id for any case Id 
                if (!groupedCompensationByCaseIds.values().isEmpty() && groupedCompensationByCaseIds.size() >= 1 )
                {
                    // add message The Reference ID already have a compensation record and only supervisor can create more than one.
                    compensation.addError(Label.CompensationMsgMoreThanOnePerCaseReference);
                }
            }
        }
    }
}