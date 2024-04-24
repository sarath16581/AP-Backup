/***
 * @author Ken McGuire
 * @date 2023-11-20
 * @description Calculate retained and incremental revenue for opportunity line items
 * @test GroupedLineItemSalesModule_Test
 * based on revised group revenues.
 */
public inherited sharing  class GroupedLineItemSalesModule extends ApplicationModule {
    /*
	 * Creates a new instance of the module to facilitate dependency injection for mocking
	 * @return the new instance
	 * @deprecated
	 */

    public static Set<Id> updatedOpportunities {
        get {
            if (updatedOpportunities == null) {
                updatedOpportunities = new Set<Id>();
            }
            return updatedOpportunities;
        }
        set;
    }

    public static GroupedLineItemSalesModule newInstance() {
        return (GroupedLineItemSalesModule)Application.Utilities.newInstance(GroupedLineItemSalesModule.class);
    }

    // Constructor
    public GroupedLineItemSalesModule() {
        // Setup which triggers this module should respond to
        getTriggerEvents().enableAfterUpdate().enableAfterInsert();
    }


    public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow)  {
        try {
            performRevenueUpdates(getOpportunitiesToUpdate(records), uow);
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, GroupedLineItemSalesModule.class.getName(), 'onAfterInsert', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow)  {
        try {
            Set<Id> openOppIds = getOpportunitiesToUpdate(records);
            Set<Id> closedWonOppIds = getCloseWonOpportunitiesToUpdate(records, existingRecords);
            if (!openOppIds.isEmpty()) {
                performRevenueUpdates(openOppIds, uow);
            }
            if (!closedWonOppIds.isEmpty()) {
                performScheduleUpdates(closedWonOppIds, uow);
            }
        } catch(Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, GroupedLineItemSalesModule.class.getName(), 'onAfterUpdate', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    public void performRevenueUpdates(Set<Id> opportunityIds, ApplicationUnitOfWork uow) {
        if (opportunityIds.isEmpty()) return;
        ProductRevenueService service = ProductRevenueService.getInstance();
        List<GroupedAccountProductRevenue__c> reCalculatedRevenues = service.reCalculateGroupRevenuesForOpportunities(opportunityIds);
        List<OpportunityLineItem> updatedLineItems = service.reCalculateRetainedIncremental();
        updatedLineItems = service.calculateClassification(updatedLineItems);
        List<GroupedAccountProductRevenue__c> revenuesUpdatable = new List<GroupedAccountProductRevenue__c>();
        List<GroupedAccountProductRevenue__c> revenuesInsertable = new List<GroupedAccountProductRevenue__c>();
        for (GroupedAccountProductRevenue__c revenue: reCalculatedRevenues) {
            if (revenue.Id == null) {
                revenuesInsertable.add(revenue);
            } else {
                revenuesUpdatable.add(revenue);
            }
        }
        if (!revenuesInsertable.isEmpty()) {
            uow.registerNew(revenuesInsertable);
        }
        if (!revenuesUpdatable.isEmpty()) {
            uow.registerDirty(revenuesUpdatable);
        }
        if (!updatedLineItems.isEmpty()) {
            uow.registerDirty(updatedLineItems);
        }
        updatedOpportunities.addAll(opportunityIds);
    }

    /**
     * @param closedWonOppIds Set<Id>
     * @param uow ApplicationUnitOfWork
     *
     * @description perform the Schedule updates when the opp is closed won and contract end date/ start date is changed
     */
    public void performScheduleUpdates(Set<Id> closedWonOppIds, ApplicationUnitOfWork uow) {
        List<GroupedRevenueSchedule__c> schedules = ProductScheduleService.newInstance().createUpdateRevenueSchedules(closedWonOppIds);
        List<GroupedRevenueSchedule__c> schedulesToInsert = new  List<GroupedRevenueSchedule__c>();
        List<GroupedRevenueSchedule__c> schedulesToUpdate = new  List<GroupedRevenueSchedule__c>();
        List<GroupedAccountProductRevenue__c> revenuesToInsert = new  List<GroupedAccountProductRevenue__c>();
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

        if (!schedulesToInsert.isEmpty()) {
            uow.registerNew(schedulesToInsert);
        }

        if (!schedulesToUpdate.isEmpty()) {
            uow.registerDirty(schedulesToUpdate);
        }
    }

    private static Set<Id> getOpportunitiesToUpdate(List<OpportunityLineItem> lineItems) {
        Set<Id> ids = new Set<Id>();
        for (OpportunityLineItem lineItem : lineItems) {
            if (!updatedOpportunities.contains(lineItem.OpportunityId) && !lineItem.Opportunity_Stage__c.containsIgnoreCase('closed')) {
                ids.add(lineItem.OpportunityId);
            }
        }
        return ids;
    }

    private static Set<Id> getCloseWonOpportunitiesToUpdate(List<OpportunityLineItem> lineItems, Map<Id, SObject> existingRecords) {
        Set<Id> ids = new Set<Id>();
        OpportunityLineItem oldLine;
        for (OpportunityLineItem lineItem : lineItems) {
            oldLine = (OpportunityLineItem) existingRecords.get(lineItem.Id);
            if (!updatedOpportunities.contains(lineItem.OpportunityId) && lineItem.Opportunity_Stage__c == OpportunityRevenueScheduleModule.STAGE_CLOSED_WON
                    && (oldLine.Contract_End_Date__c != lineItem.Contract_End_Date__c || oldLine.Contract_Start_Date__c != lineItem.Contract_Start_Date__c)) {
                ids.add(lineItem.OpportunityId);
            }
        }
        return ids;
    }

}