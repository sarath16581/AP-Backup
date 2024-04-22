/**
 * @description manages revenue schedules for opportunities
 * @author Ken McGuire
 * @date 2024-01-17
 * @changelog
*/
public inherited sharing class OpportunityRevenueScheduleModule extends ApplicationModule {
    // Constants
    public static final String STAGE_CLOSED_WON = 'Closed Won';

    /*
     * Creates a new instance of the utility to facilitate dependency injection for mocking
     * @return the new instance
     */
    public static OpportunityRevenueScheduleModule newInstance() {
        return (OpportunityRevenueScheduleModule )Application.Utilities.newInstance(OpportunityRevenueScheduleModule.class);
    }

    // Setup which triggers this module should respond to
    public OpportunityRevenueScheduleModule () {
        getTriggerEvents().enableAfterUpdate();
    }

    /**
	* Handles post-update logic for Opportunity records.
	* creates or updating revenue schedules for Opportunities that have moved to the 'Closed Won' stage.
	* @param records A List of updated SObjects (Opportunity records in this context) after the update operation.
	* @param existingRecords A Map linking the record Ids to their corresponding existing (pre-update) SObject instances.
	* @param uow An instance of ApplicationUnitOfWork, used for managing the database transactions (insertions, updates) in a consolidated manner.
	*/
    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow)  {
        try {
            createGroupedRevenueSchedules((List<Opportunity>)records, (Map<Id,Opportunity>)existingRecords, uow);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterUpdate', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
        }
    }


    /**
     * Creates revenue schedules for opportunities that have transitioned to the 'Closed Won' stage.
     * This method examines a list of updated opportunities and identifies those whose stage has changed to 'Closed Won'.
     * 
     * @param opportunities A List of `Opportunity` objects that have been updated and need to be evaluated for revenue schedule creation.
     * @param oldOpportunities A Map linking Opportunity Ids to their corresponding pre-update `Opportunity` instances for comparison.
     * @param uow An instance of `ApplicationUnitOfWork` for managing database transactions during the creation and update of revenue schedules.
  	*/
    private static void createGroupedRevenueSchedules(List<Opportunity> opportunities, Map<Id,Opportunity> oldOpportunities,  ApplicationUnitOfWork uow) {
        // Recursion
        Set<SObjectField> monitoredFields = new Set<SObjectField>{Opportunity.StageName};
        String context = 'createGroupedRevenueSchedules.action';
        List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, opportunities, oldOpportunities, monitoredFields);
        //Collect opportunities being closed as won
        Set<Id> closedWonOpportunityIds = new Set<Id>();
        for(ApplicationRecursion.RecordState recordState : changedRecords){
            Opportunity currentRecord = (Opportunity)recordState.record;
            if(currentRecord.StageName == STAGE_CLOSED_WON){
                closedWonOpportunityIds.add(currentRecord.Id);
            }
        }

        if(!closedWonOpportunityIds.isEmpty()){
            // create or update revenue schedules for opportunities being closed as won
            List<GroupedRevenueSchedule__c> schedules = ProductScheduleService.newInstance().createUpdateRevenueSchedules(closedWonOpportunityIds);
            List<GroupedRevenueSchedule__c> schedulesToInsert = new  List<GroupedRevenueSchedule__c>();
            List<GroupedRevenueSchedule__c> schedulesToUpdate = new  List<GroupedRevenueSchedule__c>();
            List<GroupedAccountProductRevenue__c> revenuesToInsert = new  List<GroupedAccountProductRevenue__c>();
            // gather schedule records to insert or update
            // together with any new revenue records that the schedules have a lookup to.
            for (GroupedRevenueSchedule__c schedule : schedules) {
                if (schedule.Id == null) {
                    schedulesToInsert.add(schedule);
                }else {
                    schedulesToUpdate.add(schedule);
                }
                if (schedule.GroupedAccountProductRevenue__r != null && schedule.GroupedAccountProductRevenue__r.Id == null) { // Group Account Product Revenue record does not exist yet, put it into a to insert list, and register the relationship
                    uow.registerRelationship(schedule, GroupedRevenueSchedule__c.GroupedAccountProductRevenue__c, schedule.GroupedAccountProductRevenue__r);
                    revenuesToInsert.add(schedule.GroupedAccountProductRevenue__r);
                }
            }

            // register new revenue records
            if (!revenuesToInsert.isEmpty()) {
                uow.registerNew(revenuesToInsert);
            }
            // register new schedule records
            if (!schedulesToInsert.isEmpty()) {
                uow.registerNew(schedulesToInsert);
            }
            // register pre-existing schedules.
            if (!schedulesToUpdate.isEmpty()) {
                uow.registerDirty(schedulesToUpdate);
            }

        }
        // reset the recursion state to ensure changes we have made won't re-trigger on next pass (if there is one
        ApplicationRecursion.getInstance().updateRecordState(context, changedRecords, monitoredFields);
    }
}