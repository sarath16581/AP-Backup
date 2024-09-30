/**************************************************
Type: Service class for managing revenue schedules associated with Salesforce Opportunities and their line items.
			 Extensively commented due to the complexity of the data object calculations and relationships.
History:
--------------------------------------------------
2023-09-21 Ken McGuire - Created
2024-06-25 	Ken McGuire	- code cleanup, revenue sync fix
2024-07-12 modify for line items of closed opportunities (major refactoring)
**************************************************/
public with sharing class ProductScheduleService {
	/*
		* Creates a new instance of the module to facilitate dependency injection for mocking
		* @return the new instance
		*/
	public static ProductScheduleService newInstance() {
		return (ProductScheduleService)Application.Utilities.newInstance(ProductScheduleService.class);
	}
	// Constants
	public static final String MONTHLY_SCHEDULE_PREFIX = 'For';
	public static final String CUSTOM_SUFFIX = '__c';
 
	//A map of UID / grouped revenue schedule records that contains the sales schedule for opportunity line items
	private Map<String,GroupedRevenueSchedule__c> groupedSchedules {
		get {
			if (groupedSchedules == null) {
				groupedSchedules = new Map<String,GroupedRevenueSchedule__c>();
			}
			return groupedSchedules;
		}
		set;
	}
 
	/* provides a default allocation to use in revenue forecasts that is
	* based on the days in each month (as opposed to seasonally adjusted for example)
	*/
	@testvisible
	private Double[] defaultRevenueAllocation {
		get {
			if (defaultRevenueAllocation == null) {
				defaultRevenueAllocation = new Double[12];
				for (Integer m = 0; m < 12; m++) {
					defaultRevenueAllocation[m] = (Double)Date.daysInMonth(2023, m+1)/365;
				}
			}
			return defaultRevenueAllocation;
		}
		set;
	}

	// The Revenue schedule data object srves as a junction object between
	// a product line item and a grouped product revenue record.
	// This service reference provides for requisite
	// grouped product revenue record and associated line item operations.
	public ProductRevenueService productRevenueServiceInstance {
		get {
			if (productRevenueServiceInstance == null) {
				productRevenueServiceInstance = ProductRevenueService.newInstance();
			}
			return productRevenueServiceInstance;
		}
		set;
	} 
 

	/**
	* Creates or updates revenue schedules for a given set of Opportunity IDs. 
	* This is typically called when an opportunity is moved to closed won.
	* @param opportunityIds A Set of Opportunity Ids to create or update schedules against. 
	* @return List<GroupedRevenueSchedule__c> A list of 'GroupedRevenueSchedule__c' objects that have been created or updated 
	* for the product line items of the provided Opportunity IDs. 
	*/
	public List<GroupedRevenueSchedule__c> createUpdateRevenueSchedules(Set<Id> opportunityIds, boolean resetRevenueAccountIds) {
		// get the associated line items for the opportunities. This process will also load the opportunity information needed for business logic
		List<OpportunityLineItem> items = productRevenueServiceInstance.getProductLineItemsForOpportunities(opportunityIds);
		// reset all the relevant accounts used to calculate the grouped revenues and schedules.
		// this record is an important state for audit purposes, should account heirarchy or related accounts change later
		if (resetRevenueAccountIds==true) {
			for (Id nextOpportunityId : opportunityIds) {
				productRevenueServiceInstance.opportunityInfo.get(nextOpportunityId).RevenueCalculationAccountIDs__c = '';
			}
		}
		// Each line item will have one schedule for each FY of the contract period (forecasted sales).
		// Each of these schedules will have one grouped revenue record associated with it (actual sales) 
		// retrieve exisitng or create new revenue records needed for the schedules, ensuring that they are current.
		// The revenue records are lazy loaded into the groupedRevenues variable.
		// The method returns a set of unique identifiers for each revenue based on accountId, productId and financial year. 
		// One uid is needed for each product line item for each financial year.
		// additional revenue records will be loaded for historical purposes used in calculating OPC classification 
		// reCalculateGroupRevenuesForLineItems
		Map<String, GroupedAccountProductRevenue__c> revenues = productRevenueServiceInstance.reCalculateGroupRevenuesForLineItems(items);
		// The revenue records have been freshly re calculated, so update the product line item fields dependent on these records
		// (1) update the product line item financials
		productRevenueServiceInstance.reCalculateRetainedIncremental(items);
		// (2) update the product line item classification 
		productRevenueServiceInstance.calculateClassification(items,true);
		// update or create the revenue schedules (sales forecast) for the opportunity line items.
		// This process will also refresh the values of the associated revenue records (actual sales)
		List<GroupedRevenueSchedule__c> results = createUpdateRevenueSchedules(items, revenues.keyset());
		Map<String,String> opportunityAccountList = ProductRevenueServiceInstance.getOpportunityAccountList(ProductRevenueServiceInstance.opportunityInfo.values());
		if (resetRevenueAccountIds==true) {
			for (Opportunity opportunityToUpdate : ProductRevenueServiceInstance.opportunityInfo.values()) {
				opportunityToUpdate.RevenueCalculationAccountIDs__c = opportunityAccountList.get(opportunityToUpdate.id);
			}
		}
		return results;
	}
 
	// override where the need to reset the accounts used in the calculation is not specified, defaluting to false
	public List<GroupedRevenueSchedule__c> createUpdateRevenueSchedules(Set<Id> opportunityIds) {
		return createUpdateRevenueSchedules(opportunityIds,false);
	}
 
	/**
	* Creates or updates revenue schedules for a given set of LineItem IDs.
	* This is typically callled after inserting a new line item into an existing closed opportunity (edge case) 
	* @param lineItemMap an opportunity line item map containing the line items against which schedules are to be created. 
	* @return List<GroupedRevenueSchedule__c> A list of 'GroupedRevenueSchedule__c' objects 
	* that have been created or updated for the product line items of the provided Opportunity IDs.
	* This method also updates product revenues by way of the revenue service
	* and updates financials and classification values of the lineitems passed in (by reference) 
	*/
	public List<GroupedRevenueSchedule__c> createUpdateRevenueSchedules(Map<id,OpportunityLineItem> lineItemMap) {
		// retrieve exisitng or create new revenue records associated with the schedules from the product revenue service.
		List<OpportunityLineItem> lineItems = productRevenueServiceInstance.getProductLineItems(lineItemMap.keyset());
		Map<String,GroupedAccountProductRevenue__c> reCalculatedRevenues = productRevenueServiceInstance.reCalculateGroupRevenuesForLineItems(lineItems);
		// The revenue records have been freshly re calculated, so update the product line item fields dependent on these records
		// (1) update the product line item financials
		productRevenueServiceInstance.reCalculateRetainedIncremental(lineItems);
		// (2) update the product line item classification 
		productRevenueServiceInstance.calculateClassification(lineItems,true);
		// collect opportunityIds for the line items, they are needed in the calculations
		Set<id> opportunityIds = new Set<id>();
		for (OpportunityLineItem item: lineItems) {
			OpportunityIds.add(item.opportunityid);
		}
		// Now that we have the product revenue records we need for the schedule we can
		// create or update revenue schedules for the line items. The created or updated revenue record associated with
		// each revenue schedule will be provided inside GroupedRevenueSchedule.GroupedAccountProductRevenue__r 
		return createUpdateRevenueSchedules(lineItems, reCalculatedRevenues.keyset());
	}

	/**
	* @description register related revenue and schedule data records with the UOW
	* @param closedWonOppIds Set<Id> of the opportunities that have been closed won
	* @param uow ApplicationUnitOfWork
	*/
	public static void registerDataForUpdateInsert(List<GroupedRevenueSchedule__c> schedules, ApplicationUnitOfWork uow) {
        system.debug('*** database register for schedues '+schedules);
		// newly created revenue schedules
		Map<String,GroupedRevenueSchedule__c> schedulesToInsert = new Map<String,GroupedRevenueSchedule__c>();
		// updated revenue schedules
		Map<String,GroupedRevenueSchedule__c> schedulesToUpdate = new Map<String,GroupedRevenueSchedule__c>();
        // revenue schedules to delete (ouside revised contract dates)
        Map<String,GroupedRevenueSchedule__c> schedulesToDelete = new Map<String,GroupedRevenueSchedule__c>();
		// new product revenue records
		Map<String,GroupedAccountProductRevenue__c> revenuesToInsert = new Map<String,GroupedAccountProductRevenue__c>();
		// updated product revenue records
		Map<String,GroupedAccountProductRevenue__c> revenuesToUpdate = new Map<String,GroupedAccountProductRevenue__c>();
		// updated line items
		Map<id,OpportunityLineItem> itemsToUpdate = new Map<id,OpportunityLineItem>();
		for (GroupedRevenueSchedule__c schedule : schedules) {
            // schedules to be deleted
             system.debug('*** database register for schedue '+schedule);
            if (schedule.id !=null && schedule.GroupedAccountProductRevenue__c == null && schedule.GroupedAccountProductRevenue__r == null) {
                system.debug('*** adding schedule to delete ' +schedule.id);
            	schedulesToDelete.put(schedule.id,schedule);
            } else {
            	if (schedule.Id == null) {
                    // record creation
                    string uid = schedule.GroupedAccountProductRevenue__c == null ? schedule.GroupedAccountProductRevenue__r.uid__c : schedule.GroupedAccountProductRevenue__c;
                   	system.debug('*** adding schedule to insert ' +uid);
                    schedulesToInsert.put(schedule.GroupedAccountProductRevenue__r.uid__c,schedule);
                } else {
                    // record update
                   system.debug('*** adding schedule to update ' +schedule.id);
                    schedulesToUpdate.put(schedule.id,schedule);
                }
                // revenue records associated with the schedules which are to be created or updated
                if (schedule.GroupedAccountProductRevenue__r != null) {
                    if(schedule.GroupedAccountProductRevenue__r.Id == null) { 
                        // The Product Revenue record associated with this schedule does not exist yet.
                        //  (1) register the relationship...
                        uow.registerRelationship(schedule, GroupedRevenueSchedule__c.GroupedAccountProductRevenue__c, schedule.GroupedAccountProductRevenue__r);
                        // (2) add the revenue record to the insert list, 
                        system.debug('*** adding revenue to insert ' +schedule.GroupedAccountProductRevenue__r.uid__c);
                        revenuesToInsert.put(schedule.GroupedAccountProductRevenue__r.uid__c, schedule.GroupedAccountProductRevenue__r);
                    } else {
                        // revenue record associated with the schedule already exists, just update it. 
                        system.debug('*** adding revenue to update ' +schedule.GroupedAccountProductRevenue__r.uid__c);
                        revenuesToUpdate.put(schedule.GroupedAccountProductRevenue__r.uid__c,schedule.GroupedAccountProductRevenue__r);
                    }
                }
                if (schedule.opportunityProduct__r != null && !itemsToUpdate.containsKey(schedule.OpportunityProduct__r.id)) {
                    system.debug('*** adding itemsToUpdate ' +schedule.OpportunityProduct__r.id);
                    itemsToUpdate.put(schedule.OpportunityProduct__r.id,schedule.opportunityProduct__r);
                }
            }
		}
		// register new revenue records
		system.debug('*** revenuesToInsert ' +revenuesToInsert);
		if (!revenuesToInsert.isEmpty()) {
			uow.registerNew(revenuesToInsert.values());
		}
		// register new schedules
		system.debug('*** schedulesToInsert ' +schedulesToInsert);
		if (!schedulesToInsert.isEmpty()) {
			uow.registerNew(schedulesToInsert.values());
		}
        system.debug('*** revenuesToUpdate ' +revenuesToUpdate);
		if (!revenuesToUpdate.isEmpty()) {
			uow.registerDirty(revenuesToUpdate.values());
		}
		// register schedules to update
		system.debug('*** schedulesToUpdate ' +schedulesToUpdate);
		if (!schedulesToUpdate.isEmpty()) {
			uow.registerDirty(schedulesToUpdate.values());
		}
        system.debug('*** schedulesToDelete ' +schedulesToDelete);
        // register schdules to delete
       	if (!schedulesToDelete.isEmpty()) {
			uow.registerDeleted(schedulesToDelete.values());
		}
		// register items to update
		system.debug('*** itemsToUpdate ' +itemsToUpdate);
		if (!itemsToUpdate.isEmpty()) {
			uow.registerDirty(itemsToUpdate.values());
		}
	}
 

	/**
	* Creates or updates all the revenue schedules (sales forecast) for a given list of opportunity line items.
	* a pre-requisite for this private method is that the revenue records (actual sales) have previously been loaded (and are current)
	* @param items List<OpportunityLineItem> the items to create or update schedules against
	* @param uids Set<String> the uids that tie the revenue schedules to specific account revenue records and products for a given financial year.
	* @return List<GroupedRevenueSchedule__c> The created or updated revenue schedules 
	* for the product line items. these records include updated product revenue records via 
	* the GroupedAccountProductRevenue__r relationship and items via the OpportunityProduct__r relationship
	*/
	private List<GroupedRevenueSchedule__c> createUpdateRevenueSchedules(List<OpportunityLineItem> items, Set<String> uids) {
		// the records to be returned
		Map<String,GroupedRevenueSchedule__c> schedulesToCreateOrUpdate = new Map<String,GroupedRevenueSchedule__c>();
		// collect relevant line item ids for the schedules
		Set<id> oppLineItemIds = new Set<id>();
		for (OpportunityLineItem item : items) {
			oppLineItemIds.add(item.id);
		}
		// load the schedules from the database
		loadGroupedRevenueSchedules(oppLineItemIds);
		// create or modify revenue schedules
		//productRevenueServiceInstance.loadGroupedProductRevenues(uids);
		// create the requisite schedules (forecast) for each line item, including the link to the revenue records (actual sales)
		for (OpportunityLineItem nextItem : items) {
			Opportunity oppInfo = productRevenueServiceInstance.opportunityInfo.get(nextItem.opportunityId);
			// create a calculator (helper) instance for this line item. The helper distributes the line item value across the monthy forecast in the schedules
			RevenueScheduleCalculator calculator = new RevenueScheduleCalculator(nextItem.Contract_Start_Date__c,nextItem.Contract_End_Date__c,defaultRevenueAllocation);
			// the revenue records should be up to date or refreshed for this value to be current.
			Double nrtBaseline = productRevenueServiceInstance.getPastMonthsAverage(oppInfo.AccountId, nextItem.Product2Id, 3, nextItem.Contract_Start_Date__c);
            system.debug(' ****** processing schedule for item '+nextItem);
            system.debug(' ****** calculator.financialYearStart '+ calculator.financialYearStart);
            system.debug(' ****** calculator.calculator.financialYearEnd '+ calculator.financialYearEnd);
			for (Integer financialYear = calculator.financialYearStart; financialYear <= calculator.financialYearEnd; financialYear++) {
				// obtain revenue schedule record for the year
				String scheduleUid = getUID(nextItem.Id, String.valueOf(financialYear));
				GroupedRevenueSchedule__c scheduleToCalculate = groupedSchedules.containsKey(scheduleUid) ? groupedSchedules.get(scheduleUid) : new GroupedRevenueSchedule__c(OpportunityProduct__c = nextItem.Id, Opportunity__c = nextItem.OpportunityId, NRTBaseline__c = nrtBaseline);
				if (scheduleToCalculate.GroupedAccountProductRevenue__c == null) {
					// link a revenue record to the schedule
					String revenueUid = ProductRevenueService.getUID(oppInfo.AccountId, nextItem.Product2Id, String.valueOf(financialYear));
					GroupedAccountProductRevenue__c revenue = productRevenueServiceInstance.groupedRevenues.get(revenueUid);
					if (revenue == null) {
						scheduleToCalculate.GroupedAccountProductRevenue__r = new GroupedAccountProductRevenue__c(AnchorOrganisation__c = oppInfo.AccountId, PrimaryProduct__c = nextItem.Product2Id, FinancialYear__c = financialYear, UID__c = revenueUid);
					} else {
						// if a new revenue record has been created, the revenue.id will be null;
						scheduleToCalculate.GroupedAccountProductRevenue__c = revenue.Id;
						scheduleToCalculate.GroupedAccountProductRevenue__r = revenue;
					}
				}
				// recalculate the schedule. This calculation only depends on the value of the line item, not its sales history.
				calculator.recalculateScheduleByReference(scheduleToCalculate);
				// assign the line item
				scheduleToCalculate.OpportunityProduct__r=nextItem;
                string uid = nextItem.id +  String.valueOf(financialYear);
				system.debug('*** adding uid '+uid);
                schedulesToCreateOrUpdate.put(uid,scheduleToCalculate);
			}
            // delete any other schedules associated with this product line item outside those of the revised revenue dates
            system.debug('***** checking schedues to delete for product: '+nextItem.id);
            for (GroupedRevenueSchedule__c nextSchedule : groupedSchedules.values()) {
                if (nextSchedule!=null) {
                    system.debug('***** checking schedue product: '+nextSchedule.OpportunityProduct__c+' '+'Year '+nextSchedule.year__c);
                    if (nextSchedule.OpportunityProduct__c == nextItem.id && (nextSchedule.Year__c < calculator.financialYearStart || nextSchedule.Year__c > calculator.financialYearEnd)) {
                        string scheduleUID = getUID(nextSchedule);
                        if (!schedulesToCreateOrUpdate.containsKey(scheduleUID)) {
                            nextSchedule.GroupedAccountProductRevenue__c = null;
                            system.debug('********** marking for deletion the schedule '+nextSchedule);
                            schedulesToCreateOrUpdate.put(getUID(nextSchedule),new GroupedRevenueSchedule__c(id = nextSchedule.id));
                        }
                    }
                }
            }
		}
		return schedulesToCreateOrUpdate.values();
	}


	/**
	* Loads existing Grouped Revenue Schedule records associated with specified Opportunity Line Item IDs. te.
	* @param oppLineItemIds A Set of Opportunity Line Item IDs for which Grouped Revenue Schedules need to be loaded.
	* @return Map<String,GroupedRevenueSchedule__c> A map of loaded Grouped Revenue Schedule records keyed by their 
	* associated Opportunity Line Item IDs. This map can be used for further processing in revenue schedule calculations.
	*/
	private Map<String,GroupedRevenueSchedule__c> loadGroupedRevenueSchedules(Set<id> oppLineItemIds) {
		Set<String> unloadedIds = new Set<String>();
		for (String oppLineItemId : oppLineItemIds) {
			if (!groupedSchedules.containsKey(oppLineItemId)) {
				unloadedIds.add(oppLineItemId);
				groupedSchedules.put(oppLineItemId,null);
			}
		}
		Map<String,GroupedRevenueSchedule__c> newlyLoadedRecords = new Map<String,GroupedRevenueSchedule__c>();

		if(unloadedIds.isEmpty()) {
			return newlyLoadedRecords;
		}

		List<GroupedRevenueSchedule__c> additionalRevenueSchedules = GroupedRevenueScheduleSelector.newInstance().selectByOpportunityProductIds(unloadedIds,null);

		if (additionalRevenueSchedules == null) {
			return newlyLoadedRecords;
		}
		for (GroupedRevenueSchedule__c groupedSchedule : additionalRevenueSchedules) {
			groupedSchedules.put(getUID(groupedSchedule), groupedSchedule);
			newlyLoadedRecords.put(getUID(groupedSchedule), groupedSchedule);
		}
		return newlyLoadedRecords;
	}

	// Constructs a UID for Grouped Schedule Records based on the line item id and the year.
    public static String getUID(GroupedRevenueSchedule__c schedule) {
        if (schedule == null || schedule.OpportunityProduct__c ==null || schedule.Year__c ==null) {
            return null;
        } 
        return getUID(schedule.OpportunityProduct__c, String.valueOf(schedule.Year__c));
    }

	// Constructs a UID for Grouped Schedule Records based on the line item id and the year.
	private static String getUID(String oppProductId, String financialYear) {
		return oppProductId + financialYear;
	}
    
    

	/**
	* Inner class designed for calculating revenue schedules based on Opportunity Line Item details.
	* Key functionalities include:
	* - Calculating the start and end of the financial years based on contract dates.
	* - Determining the allocation of revenue for each month within the contract period.
	* - Adjusting revenue allocation based on the contract's start and end months.
	* - Providing a method to recalculate revenue schedules for a given Grouped Revenue Schedule record.
	*/
	@testVisible
	private class RevenueScheduleCalculator {
		public Integer financialYearStart {get; private set;}
		Integer calendarYearStart;
		Integer startMonth;
		public Integer financialYearEnd {get; private set;}
		Integer calendarYearEnd;
		Integer endMonth;
		Double startMonthAllocation;
		Double endMonthAllocation;
		Double totalAllocation;
		Double[] revenueAllocation;

		public RevenueScheduleCalculator(Date startDate, Date endDate, Double[] revenueAllocation) {
			this.revenueAllocation = revenueAllocation;
			calculateValues(startDate,endDate);
		}

		public void recalculateScheduleByReference(GroupedRevenueSchedule__c schedule) {
			Integer calendarYear = (Integer)schedule.GroupedAccountProductRevenue__r.FinancialYear__c;
			for (Integer month = 1; month <=12; month++) {
				Double monthRevenueAllocation = 0;
				if (month == 7) {
					calendarYear = calendarYear -1;
				}
				if (month == startMonth && calendarYear == calendarYearStart) {
					monthRevenueAllocation = startMonthAllocation/totalAllocation;
				}
				else if(month == endMonth && calendarYear == calendarYearEnd) {
					monthRevenueAllocation = endMonthAllocation/totalAllocation;
				}
				else if (isYearMonthInRange(calendarYear,month)) {
					monthRevenueAllocation = revenueAllocation[month-1]/totalAllocation;
				} else {
					monthRevenueAllocation =0;
				}
				schedule.put(MONTHLY_SCHEDULE_PREFIX+String.valueOf(month)+CUSTOM_SUFFIX,monthRevenueAllocation*100);
			}
		}

		private void calculateValues(Date startDate, Date endDate) {
			calendarYearStart = startDate.year();
			startMonth = startDate.month();
			financialYearStart = startMonth >= 7 ? calendarYearStart + 1 : calendarYearStart;
			Integer startDay = startDate.day();
			calendarYearEnd = endDate.year();
			endMonth = endDate.month();
			financialYearEnd = endMonth >= 7 ? calendarYearEnd + 1 : calendarYearEnd;
			Integer endDay = endDate.day();
			Integer totalWholeMonths = startDate.monthsBetween(endDate);


			totalAllocation = 0;
			// calculate startMonth proportion based on number of days remaining in that month 
			startMonthAllocation = (1-startDay/(Decimal)Date.daysInMonth(calendarYearStart,startMonth)) * revenueAllocation[startMonth-1];
			// calculate allocations for whole months
			totalAllocation += startMonthAllocation;
			Integer targetMonth = startMonth;

			for (Integer i = 1; i < totalWholeMonths; i++) {
				targetMonth = targetMonth+1;
				// adjust target month and financial year.
				if (targetMonth == 13) {
					targetMonth = 1;
				}
				totalAllocation += revenueAllocation[targetMonth-1];
			}
			// calculate end month allocation based on number of days transpired in that month
			endMonthAllocation = endDay/(Decimal)Date.daysInMonth(calendarYearEnd,endMonth) * revenueAllocation[endMonth-1];
			totalAllocation += endMonthAllocation;
		}
		@testVisible
		private Boolean isYearMonthInRange(Integer givenYear, Integer givenMonth) {
			Integer startYearMonth = calendarYearStart * 12 + startMonth;
			Integer endYearMonth = calendarYearEnd * 12 + endMonth;
			Integer givenYearMonth = givenYear * 12 + givenMonth;
			return givenYearMonth >= startYearMonth && givenYearMonth <= endYearMonth;
		}
	}
}