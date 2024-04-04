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
            performRevenueUpdates(getOpportunitiesToUpdate(records), uow);
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
        List<GroupedAccountProductRevenue__c> revenuesUpdatable = new List<GroupedAccountProductRevenue__c>();
        List<GroupedAccountProductRevenue__c> revenuesInsertable = new List<GroupedAccountProductRevenue__c>();
        for (GroupedAccountProductRevenue__c revenue: reCalculatedRevenues) {
            if (revenue.Id == null) {
                revenuesInsertable.add(revenue);
            } else {
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

    private static Set<Id> getOpportunitiesToUpdate(List<OpportunityLineItem> lineItems) {
        Set<Id> ids = new Set<Id>();
        for (OpportunityLineItem lineItem : lineItems) {
            if (!updatedOpportunities.contains(lineItem.OpportunityId)) {
                ids.add(lineItem.OpportunityId);
            }
        }
        return ids;
    }

}