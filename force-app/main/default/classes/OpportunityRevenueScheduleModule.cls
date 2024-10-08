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
        getTriggerEvents().enableBeforeUpdate().enableAfterUpdate();
    }
    
    /**
    * Handles pre-update logic for Opportunity records.
    * updates revenue account list for opportunities that are transitioning to closed-won
    * @param records A List of updated SObjects (Opportunity records in this context) after the update operation.
    * @param existingRecords A Map linking the record Ids to their corresponding existing (pre-update) SObject instances.
    * @param uow An instance of ApplicationUnitOfWork, used for managing the database transactions (insertions, updates) in a consolidated manner.
    */
    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow)  {
        try {
                system.debug('**** opportunity onBeforeUPdate ENTRY');
                // Recursion
                Set<SObjectField> monitoredFields = new Set<SObjectField>{Opportunity.StageName};
                String context = 'updateRevenueAccountList.action';
                List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, records, existingRecords, monitoredFields); 
                Map<Id,Opportunity> closingOpportunties = getClosingOpportunityMap(records,changedRecords);
                system.debug('**** closing opportunities '+closingOpportunties);
                Map<String,String> opportunityAccountList =  ProductRevenueService.newInstance().getOpportunityAccountList(closingOpportunties.values());
                system.debug('**** opportunityAccountList '+opportunityAccountList);
                for (Opportunity opportunityToUpdate : closingOpportunties.values()) {
                    opportunityToUpdate.RevenueCalculationAccountIDs__c = opportunityAccountList.get(opportunityToUpdate.id);
                    system.debug('**** opportunityToUpdate.RevenueCalculationAccountIDs__c  '+opportunityToUpdate.RevenueCalculationAccountIDs__c );
                }
                system.debug('**** opportunity onAfterUPdate EXIT');
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            system.debug('***** error '+ex);
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterUpdate', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
        }
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
                system.debug('**** opportunity onAfterUPdate ENTRY');
                // Recursion
                Set<SObjectField> monitoredFields = new Set<SObjectField>{Opportunity.StageName};
                String context = 'createGroupedRevenueSchedules.action';
                List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, records, existingRecords, monitoredFields); 
                Map<Id,Opportunity> closingOpportunties = getClosingOpportunityMap(records,changedRecords);
                system.debug('**** performScheduleUpdates '+closingOpportunties);
                performScheduleUpdates(closingOpportunties, uow);
                system.debug('**** opportunity onAfterUPdate EXIT');
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            system.debug('***** error '+ex);
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, CaseSurveyInvitationModule.class.getName(), 'onAfterUpdate', 'BudgetAndRevenueTrigger', LoggingLevel.ERROR);
        }
    }

    
    /**
    * Filters updated opportunities for those transitioning to closed-won.
    * @param lineItems the updated line items
    * @param priorValues - a map of the line item values prior to update
    * @return List<OpportunityLineItem> - only newly inserted line items that are associated with closed opportunities.
    */
    private static Map<Id,Opportunity> getClosingOpportunityMap(List<Opportunity> opportunities,List<ApplicationRecursion.RecordState> changedRecords) {
        Set<Id> changedIds = new Set<Id>();
        for (ApplicationRecursion.RecordState recordState : changedRecords) {
            changedIds.add(recordState.record.Id);
        }
        Map<Id,Opportunity>  closingOpportunities = new  Map<Id,Opportunity>();
        for (Opportunity opp : opportunities) {
            if (opp.StageName == OpportunityRevenueScheduleModule.STAGE_CLOSED_WON && changedIds.contains(opp.id)) 
            {
               closingOpportunities.put(opp.id,opp);
            }
        }
        return closingOpportunities;
    }
    
    /**
     * @description when an oportunity is moved from open to closed won:
     * (1) creates / updates product revenues
     * (2) creates / updates revenue schedules
     * (3) Updates all line items of the opportunity with retained and incremental revenue values, classification etc.
     * @param closedWonOppIds Set<Id> of the opportunities that have been closed won
     * @param uow ApplicationUnitOfWork
     */
    public void performScheduleUpdates(Map<Id,Opportunity> closedWonOpportunities, ApplicationUnitOfWork uow) {
        // the case where there are no opportunities in the trigger whcih have moved to closed-won status
        if (closedWonOpportunities.size()==0) {
            return;
        }
        // call on the product schedule service to create the schedules. 
        // This service in turn uses the product revenue service for updates to product revenues and product line item sales info 
        List<GroupedRevenueSchedule__c> schedules = ProductScheduleService.newInstance().createUpdateRevenueSchedules(closedWonOpportunities.keyset());
        // register all the canged or updated revenue and schedule records with the unit of work data object.
        ProductScheduleService.registerDataForUpdateInsert(schedules,uow);
    }
}