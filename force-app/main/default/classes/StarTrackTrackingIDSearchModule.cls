/**
 * Created by hasan on 7/11/2022.
 */

public inherited sharing class StarTrackTrackingIDSearchModule extends ApplicationDomain.Module {

    public static StarTrackTrackingIDSearchModule newInstance() {
        return (StarTrackTrackingIDSearchModule)Application.Utilities.newInstance(StarTrackTrackingIDSearchModule.class);
    }

    /**
    * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
    */
    public class Constructor implements ApplicationDomain.IConstructableModule {
        public ApplicationDomain.Module construct() {
            return (ApplicationDomain.Module)StarTrackTrackingIDSearchModule.newInstance();
        }
    }

    // Setup which triggers this module should respond to
    public StarTrackTrackingIDSearchModule() {
        getTriggerEvents().enableAfterInsert().enableAfterUpdate();
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
            StarTrackTrackingIDSearchUtil.getTrackingDetails(records, null);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackTrackingIDSearchModule.class.getName(), 'onAfterInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

/*    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            // TODO to be removed by Hasantha once the logic is confirmed
            System.debug('StarTrackTrackingIDSearchModule:onAfterUpdate records '+records.size());
            System.debug('StarTrackTrackingIDSearchModule:onAfterUpdate existingRecords '+existingRecords.size());
            StarTrackTrackingIDSearchUtil.getTrackingDetails(records, existingRecords);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackTrackingIDSearchModule.class.getName(), 'onAfterUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }*/


}