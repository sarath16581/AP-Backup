/* @author Ken McGuire
 * @date 2023-11-20
 * @description Update grouped revenue records and then
 * Calculate retained and incremental revenue for opportunity line items
 * @test GroupedLineItemSalesModule_Test
 * based on revised group revenues.
History:
--------------------------------------------------
2023-11-20Ken McGuire - Created
2024-06-25 	Ken McGuire	- code cleanup
2024-07-12modify for line items of closed opportunities (major refactoring)
 */
public inherited sharing class GroupedLineItemSalesModule extends ApplicationModule {

	// Tracks the opportunities that have had their line items 
	// updated in current session to avoid recursive calculations.
	public static Set<Id> updatedOpportunities {
		get {
			if (updatedOpportunities == null) {
				updatedOpportunities = new Set<Id>();
			}
			return updatedOpportunities;
		}
		set;
	}
	
	// Tracks the line items that have been updated
	// updated in current session to avoid recursive calculations.
	public static Set<Id> updatedLineItems {
		get {
			if (updatedLineItems == null) {
				updatedLineItems = new Set<Id>();
			}
			return updatedLineItems;
		}
		set;
	}
	
	/*
	 * Creates a new instance of the module to facilitate dependency injection for mocking
	 * @return the new instance
	 */
	public static GroupedLineItemSalesModule newInstance() {
		return (GroupedLineItemSalesModule)Application.Utilities.newInstance(GroupedLineItemSalesModule.class);
	}

	// Constructor
	public GroupedLineItemSalesModule() {
		// Setup which triggers this module should respond to
		getTriggerEvents().enableAfterUpdate().enableAfterInsert().enableAfterDelete();
	}

	/**
	 * Handles post-insert logic for opportunity line items, populating retained and incremental revenue
	 * @param records The list of newly inserted opportunity line items.
	 * @param uow The application unit of work context for database operations.
	 * @return void - updates stored in the unit of work
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow){
		try {
			Set<id> openOpportunityIds = getOpenOpportunitiesToUpdate(records);
			Map<Id,OpportunityLineItem> closedInsertedLineItems = getInsertedClosedLineItemsMap(records);
			// update all the line items associated with the opportunities of the opportunity line item records passed in.
			// This will avoid the confusion of having single line items updated on different dates.
			if (!openOpportunityIds.isEmpty()) {
				performRevenueUpdates(openOpportunityIds, uow);
			}
			
			// This executes on newly inserted line items that are attached to closed opportunities.
			// It performs (1) updates to grouped revenues, (2) Update / creation of revenue schedules and 
			// (3) population of retained / incremental and classification on line items.
			if (!closedInsertedLineItems.isEmpty()) {
				system.debug('***** performScheduleUpdatesForLineItems '+closedInsertedLineItems);
				performScheduleUpdatesForLineItems(closedInsertedLineItems, uow);
			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, GroupedLineItemSalesModule.class.getName(), 'onAfterInsert', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
 
	/**
	 * Handles post-update logic for opportunity line items, recalculating retained and incremental revenue.
	 * @param records The list of updated opportunity line items.
	 * @param existingRecords map of record values before the update.
	 * @param uow The application unit of work context for database operations.
	 * @return void - updates stored in the unit of work
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
		try {
			// update all the line items associated with the opportunity of the opportunity line item records passed in.
			// This will avoid the confusion of having single line items updated on different dates. 
 			system.debug('**** line item on after update for '+records);
			Set<Id> openOppIds = getOpenOpportunitiesToUpdate(records);
			Map<Id,opportunityLineItem> updatedClosedLineItemMap = getUpdatedClosedLineItemMap(records, existingRecords);
			if (!openOppIds.isEmpty()) {
				performRevenueUpdates(openOppIds, uow);
			}
			if (!updatedClosedLineItemMap.isEmpty()) {
				// This executes on changed line items that are attached to closed opportunities.
				// It performs (1) updates to grouped revenues, (2) Update / creation of revenue schedules and 
				// (3) population of retained / incremental and classification on line items.
				performScheduleUpdatesForLineItems(updatedClosedLineItemMap, uow);
			}
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			system.debug('***** eorror ' + ex.getStackTraceString());
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, GroupedLineItemSalesModule.class.getName(), 'onAfterUpdate', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
		/**
	 * Handles post-update logic for opportunity line items, recalculating retained and incremental revenue.
	 * @param records The list of updated opportunity line items.
	 * @param existingRecords map of record values before the update.
	 * @param uow The application unit of work context for database operations.
	 * @return void - updates stored in the unit of work
	 */
	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow){
		try {
			removeRevenueSchedulesForRecords(records, uow);
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, GroupedLineItemSalesModule.class.getName(), 'onAfterDelete', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}
	
	/**
	 * Recalculates the retained and incremental revenue values for
	 *all the line items of the specified open opportunities.
	 * @param opportunityIds Set of Open Opportunity IDs for which 
	 * (1) product revenue records are to be updated and 
	 * (2) product line items sales info to be updated.
	 * @param uow The application unit of work context for database operations.
	 * @return void - updates to records are stored in the unit of work
	 */
	public void performRevenueUpdates(Set<Id> opportunityCandidates, ApplicationUnitOfWork uow) {
        try {
            // a collection of opportunity ids whose line items are to be updated
            Set<Id> opportunityIds = new Set<Id>();
            // prevent recursion, no need to update the opportunity line items more than once.
            for (id candidate : opportunityCandidates) {
                if (!updatedOpportunities.contains(candidate)) {
                    opportunityIds.add(candidate);
                }
            }
            // exit in the case that there are no opportunities whose line items require updates
            if (opportunityIds.isEmpty()) {
                 return;
            }
            // instantiate the service responsible for updating product revenues
            ProductRevenueService service = ProductRevenueService.getInstance();
            // load line item candidates
            List<OpportunityLineItem> lineItemCandidates = service.getProductLineItemsForOpportunities(opportunityIds);
            // a subset of line items associated with the opportunity that are to be updated
            Map<Id,OpportunityLineItem> lineItemsToUpdate = new Map<Id,OpportunityLineItem>();
            // prevent recursion in the case that this line item has been updated already.
            for (OpportunityLineItem candidate: lineItemCandidates) {
                if (!updatedLineItems.contains(candidate.id)) {
                    lineItemsToUpdate.put(candidate.id,candidate);
                }
            }
            // exit in the case that there are no opportunity line items to update
            if (lineItemsToUpdate.isEmpty()) {
                return;
            }
             // use the product revenue service to bring the revenue history for all the opportunity line items up to date (current)
            Map<String,GroupedAccountProductRevenue__c> reCalculatedRevenues = service.reCalculateGroupRevenuesForLineItems(lineItemsToUpdate.values());
            // recalculate the retained and incremental values for the line items based on the newly recalculated product revenues
            service.reCalculateRetainedIncremental(lineItemsToUpdate.values());
            // assign a classificaton to the updated line items
            service.calculateClassification(lineItemsToUpdate.values(),true);
            // add the new and updated revenue records to lists for registration with the unit of work.
            Map<String,GroupedAccountProductRevenue__c> revenuesUpdatable = new Map<String,GroupedAccountProductRevenue__c>();
            Map<String,GroupedAccountProductRevenue__c> revenuesInsertable = new Map<String,GroupedAccountProductRevenue__c>();
            for (GroupedAccountProductRevenue__c revenue: reCalculatedRevenues.values()) {
                if (revenue.Id == null) {
                    revenuesInsertable.put(revenue.uid__c,revenue);
                } else {
                    revenuesUpdatable.put(revenue.uid__c, revenue);
                }
            }
            // insert new revenue records
            if (!revenuesInsertable.isEmpty()) {
                uow.registerNew(revenuesInsertable.values());
            }
            // update existing revenue records
            if (!revenuesUpdatable.isEmpty()) {
                uow.registerDirty(revenuesUpdatable.values());
            }
            // update sales information placed on line items
            if (!lineItemsToUpdate.isEmpty()) {
                uow.registerDirty(lineItemsToUpdate.values());
            }
            // prevent recursion.
            updatedOpportunities.addAll(opportunityIds);
            updatedLineItems.addAll(lineItemsToUpdate.keyset());
        } catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, GroupedLineItemSalesModule.class.getName(), 'performRevenueUpdates', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	 /**
	 * For changed line items associated with closed opportunities:
	 * (1) creates / updates product revenues
	 * (2) creates / updates revenue schedules
	 * (3) Updates line items by reference with retained and incremental revenue values, classification etc.
	 * @param lineItemIds Set of line item IDs for which product line items are to be updated.
	 * @param uow The application unit of work context for database operations.
	 * @return void - updates to records are stored in the unit of work
	 */
	public void performScheduleUpdatesForLineItems(Map<id,opportunitylineitem> lineItems, ApplicationUnitOfWork uow) {
		if (lineItems.size()==0) {
			return;
		}
        try {
           	// call on the product schedule service to effect the creation/update of schedules. 
            // The schedule service, in turn, depends on the revenue service to effect updates to revenues and product information
            List<GroupedRevenueSchedule__c> schedules = ProductScheduleService.newInstance().createUpdateRevenueSchedules(lineItems);
            // register all the canged or updated revenue and schedule records with the unit of work data object.
            ProductScheduleService.registerDataForUpdateInsert(schedules,uow);
            //prevent recusion, there is no need to repeat these updates.
            updatedLineItems.AddAll(lineItems.keyset());
        } catch(Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, GroupedLineItemSalesModule.class.getName(), 'performScheduleUpdatesForLineItems', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}

	}
	 

	/**
	* Gets the opportunity ids that are associated with changes to line items
	* Only open opportunities are included
	* @param lineItems List of line items being inserted or changed.
	* @return a set of opportunity ids associated with the line items.
	*/
	private static Set<Id> getOpenOpportunitiesToUpdate(List<OpportunityLineItem> lineItems) {
		// the ids to return
		Set<Id> ids = new Set<Id>();
		for (OpportunityLineItem lineItem : lineItems) {
			// only include if (1) not recursion and (2) opportunity is not closed.
			if (!updatedOpportunities.contains(lineItem.OpportunityId) && !lineItem.Opportunity_Stage__c.containsIgnoreCase('closed')) {
				ids.add(lineItem.OpportunityId);
			}
		}
		return ids;
	}
	 
	/**
	* Filters inserted opportunity line items for those associated with closed opportunities.
	* @param lineItems List of newly inserted line items (after insert).
	* @return List<OpportunityLineItem> - only newly inserted line items that are associated with closed opportunities.
	*/
	private static Map<id,OpportunityLineItem> getInsertedClosedLineItemsMap(List<OpportunityLineItem> lineItems) {
		// the items to be returned
		Map<id,OpportunityLineItem> items = new Map<id,OpportunityLineItem>();
		for (OpportunityLineItem lineItem : lineItems) {
			// only include if (1) not recursion and (2) closed opportunity
			if (!updatedLineItems.contains(lineItem.id) && lineItem.Opportunity_Stage__c.containsIgnoreCase('closed')) {
				items.put(lineItem.id,lineItem);
			}
		}
		return items;
	}
	
	/**
	* Filters updated opportunity line items for those associated with closed opportunities.
	* Only those line items containing changes to price or quantity or start or end dates are included
	* @param lineItems the updated line items
	* @param priorValues - a map of the line item values prior to update
	* @return List<OpportunityLineItem> - only newly inserted line items that are associated with closed opportunities.
	*/
	private static Map<id,OpportunityLineItem>getUpdatedClosedLineItemMap(List<OpportunityLineItem> lineItems, Map<Id,SObject> priorValues) {
		// the items to be returned
		Map<id,OpportunityLineItem> items = new Map<id,OpportunityLineItem>();
		
		for (OpportunityLineItem lineItem : lineItems) {
			// only include if (1) not recursion and (2) closed opportunity....
			if (!updatedLineItems.contains(lineItem.id) && lineItem.Opportunity_Stage__c.containsIgnoreCase('closed') == true) {
				OpportunityLineItem priorValue = (OpportunityLineItem)priorValues.get(lineItem.id);
				// (3) not open opportunity in the process of being closed (4) changes affect sales and forecast values.
				if (priorValue.Opportunity_Stage__c.containsIgnoreCase('closed') == true && (lineItem.unitprice != priorValue.unitPrice || lineItem.Quantity != priorValue.Quantity || lineItem.Contract_Start_Date__c !=priorValue.Contract_Start_Date__c || lineItem.Contract_End_Date__c !=priorValue.Contract_End_Date__c )) {
					items.put(lineItem.id,lineItem);
				}
			}
		}
		return items;
	}

	/**
	* In the case that line items are deleted, remove the schedules associated with them.
	* In principle this should only affect line items of closed opportunities as schedules are not created until
	* The opportunity is closed
	* @param lineItems the updated line items
	* @param priorValues - a map of the line item values prior to update
	* @return List<OpportunityLineItem> - only newly inserted line items that are associated with closed opportunities.
	*/
	private static void removeRevenueSchedulesForRecords(List<OpportunityLineItem> lineItems, ApplicationUnitOfWork uow) {
		// collect the line item ids for items being deleted
		Set<String> lineItemIds = new Set<String>();
		for (OpportunityLineItem item : lineItems) {
			lineItemIds.add(item.id);
		}
		// query the schedules associated with the line items being deleted
		List<GroupedRevenueSchedule__c> schedulesToRemove = ProductRevenueService.getRevenueScheduleForLineItems(lineItemIds);
		// pass the deleted records to the unit of work for processing.
		if (schedulesToRemove.size()>0) {
			uow.registerDeleted(schedulesToRemove,false,'GroupedLineItemSalesModule.removeRevenueSchedulesForRecords');
		}
	}
}