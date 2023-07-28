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

    /**
    * Called when a new record is being inserted.
    */
    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            System.debug('CompensationUtilityModule:onBeforeInsert');
            if(!records.isEmpty()) {
                // update fields on compensation record
                CompensationService.getInstance().updateCurrentArticleInfoOnCompensationRecord ((List<Compensation__c>)records);
            }

        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Australia Post', CompensationUtilityModule.class.getName(), 'onBeforeInsert', 'Compensation Trigger', LoggingLevel.ERROR);
        }
    }

    /**
     * Called when a new record is being inserted.
     */
    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            System.debug('CompensationUtilityModule:onBeforeUpdate');
            if(!records.isEmpty()) {
                // update approved field on update of the record
                CompensationService.getInstance().approveCompensationRecord((List<Compensation__c>)records, (Map<Id, Compensation__c>)existingRecords);

            }

        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Australia Post', StarTrackCalculateCaseDepotModule.class.getName(), 'onBeforeUpdate', 'Compensation Trigger', LoggingLevel.ERROR);
        }
    }

}