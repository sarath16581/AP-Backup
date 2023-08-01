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
            if (!records.isEmpty()) {
                // update fields on compensation record
                CompensationService.getInstance().updateCurrentArticleInfoOnCompensationRecord ((List<Compensation__c>) records);
            }

        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Australia Post', CompensationUtilityModule.class.getName(), 'onBeforeInsert', 'Compensation Trigger', LoggingLevel.ERROR);
        }
    }
}