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
            getTrackingDetails(records, null);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackTrackingIDSearchModule.class.getName(), 'onAfterInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            System.debug('StarTrackTrackingIDSearchModule:onAfterUpdate');
            getTrackingDetails(records, existingRecords);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackTrackingIDSearchModule.class.getName(), 'onAfterUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    public void getTrackingDetails(List<SObject> records, Map<Id, SObject> existingRecords) {
        List<Case> selectedCases = new List<Case>();
        for(Case cse:(List<Case>)records) {
            // if the reference has been changed
            if(existingRecords == null || cse.ReferenceID__c != existingRecords.get(cse.Id).get('ReferenceID__c')) {
                // todo check for record types
                selectedCases.add(cse);
            }
        }

        if(!selectedCases.isEmpty()) {
            System.enqueueJob(new TrackingSearchQueueable(selectedCases));
        }
    }


    private without sharing class TrackingSearchQueueable implements Queueable, Database.AllowsCallouts {
        Id caseId;
        String referenceId;
        String articleId;
        public TrackingSearchQueueable(List<Case> records) {
            this.articleId = records[0].ArticleTest__c;
            this.caseId = records[0].Id;
            this.referenceId = records[0].ReferenceID__c;

        }

        public void execute(QueueableContext context) {
            try {
                if(this.articleId == null) {
                    StarTrackTrackingIDSearchService cont = StarTrackTrackingIDSearchService.newInstance();
                    cont.dateRange = '1';
                    cont.searchString = this.referenceId;
                    cont.isConsole = false;
                    cont.map_searchCustomSettings.get(cont.fieldName).Callout_Search_Type__c = 'CONSIGNMENT';
                    cont.searchConsignment();
                    case cse = new Case();
                    cse.Id = this.caseId;
                    cse.ArticleTest__c = cont.lst_article[0].Id;
                    update cse;
                }
            } catch (Exception ex) {
                // Error Logged to Exception object for analysis
                UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, TrackingSearchQueueable.class.getName(), 'execute', '', LoggingLevel.ERROR);
            }
        }
    }
}