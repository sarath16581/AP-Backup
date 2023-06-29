/**************************************************
Description:    As a part of the Startrack case creation via the new community portal,
this module will bring the tracking details from SAP then create artifices and update data on the relevant case,
this is developed only to support single case record.
History:
--------------------------------------------------
2022-11-07 - H Liyanage - Created
* 2023-06-14 - Nathan Franklin - uplift to domainless architecture
**************************************************/

public inherited sharing class StarTrackTrackingIDSearchModule extends ApplicationModule {

	/**
	 * @deprecated
	 */
    public static StarTrackTrackingIDSearchModule newInstance() {
        return (StarTrackTrackingIDSearchModule)Application.Utilities.newInstance(StarTrackTrackingIDSearchModule.class);
    }

    // Setup which triggers this module should respond to
    public StarTrackTrackingIDSearchModule() {
        getTriggerEvents().enableAfterInsert();
    }

    /**
    * Called after a case is inserted.
    * Performs below operations
    * 1. Creates Activity/Task under the case
    * 2. Submits a record for approval in case of Incorrect Delivery/Items shortage
    */
    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            System.debug('StarTrackTrackingIDSearchModule:onAfterInsert');
            if (!System.isBatch() && !System.isScheduled()) {
                StarTrackTrackingIDSearchUtil.getTrackingDetails(records);
            }
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackTrackingIDSearchModule.class.getName(), 'onAfterInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

}