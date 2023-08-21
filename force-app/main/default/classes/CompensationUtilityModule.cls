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
                validateMoreThanOneCompensationsPerReferenceId ((List<Compensation__c>) records);
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
    public void validateMoreThanOneCompensationsPerReferenceId(List<Compensation__c> compensations) {
        // if the user is compensation supervisor no errors should be thrown
        if(isCompensationSupervisor) {
            return;
        }
        Set<Id> relatedCaseIds = new Set<Id>();
        for (Compensation__c compensation : compensations) {
            relatedCaseIds.add(compensation.Case__c);
        }
        // get grouped compensation records by case id for the passed references
        Map<Id, List<Compensation__c>> groupedCompensationByCaseIds = CompensationService.getInstance().getCompensationRecordByCaseIds(relatedCaseIds);
        for (Compensation__c compensation : compensations) {
            List<Compensation__c> compensationsForCaseId = groupedCompensationByCaseIds.get(compensation.Case__c);
            if (!compensationsForCaseId.isEmpty() && compensationsForCaseId.size() > 0) {
                // add message The Reference ID already have a compensation record and only supervisor can create more than one.
                compensation.addError(Label.CompensationMsgMoreThanOnePerCaseReference);
            }
        }
    }
}