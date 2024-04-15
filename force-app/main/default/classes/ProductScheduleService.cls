/**************************************************
Type:         Service class for managing revenue schedules associated with Salesforce Opportunities and their line items.
History:
--------------------------------------------------
2023-09-21    Ken McGuire - Created
**************************************************/
public with sharing class ProductScheduleService {

    public static ProductScheduleService newInstance() {
        return (ProductScheduleService)Application.Utilities.newInstance(ProductScheduleService.class);
    }

    public static final String MONTHLY_SCHEDULE_PREFIX = 'For';
    public static final String CUSTOM_SUFFIX = '__c';
    // A map of UID / grouped revenue records containing the incremental and retained revenues for account products.
    @testVisible
    private Map<String,GroupedAccountProductRevenue__c> groupedRevenues {
        get {
            if (groupedRevenues == null) {
                groupedRevenues = new Map<String,GroupedAccountProductRevenue__c> ();
            }
            return groupedRevenues;
        }
        set;
    }

    //A map of UID / grouped revenue schedule records that contains the sales schedule for opportunity line items
    private Map<String,GroupedRevenueSchedule__c> groupedSchedules {
        get {
            if (groupedSchedules == null) {
                groupedSchedules = new  Map<String,GroupedRevenueSchedule__c>();
            }
            return groupedSchedules;
        }
        set;
    }

    // The opportunity line items to create schedules against
    private Map<Id,OpportunityLineItem> opportunityLineItems {
        get {
            if (opportunityLineItems == null) {
                opportunityLineItems = new  Map<Id,OpportunityLineItem>();
            }
            return opportunityLineItems;
        }
        set;
    }

    @testVisible
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


    /**
     * Creates or updates revenue schedules for a given set of Opportunity IDs. 
     * @param opportunityIds A Set of Opportunity Ids for which the revenue schedules need to be created or updated. 
     * @return List<GroupedRevenueSchedule__c> A list of 'GroupedRevenueSchedule__c' objects that have been created or updated 
     *         for the product line items of the provided Opportunity IDs. 
     */
    public List<GroupedRevenueSchedule__c> createUpdateRevenueSchedules(Set<Id> opportunityIds) {
        // get the associated line items and create the grouped schedules for each of them
        List<OpportunityLineItem> items = loadProductLineItems(opportunityIds);
        // retrieve the revenue records for the schedule to look up to
        Set<String> uids = getCreateGroupedRevenues(items);
        // ensure all opportunity items have revenue schedule records
        return createUpdateRevenueSchedules(items, uids);
    }

    /**
	  * Creates or updates revenue schedules for a given list of opportunity line items.
	  * @param items List<OpportunityLineItem>
	  * @param uids Set<String>
	  * @return List<GroupedRevenueSchedule__c> A list of 'GroupedRevenueSchedule__c' objects that have been created or updated
	  *         for the product line items of the provided Opportunity IDs.
	  */
    private List<GroupedRevenueSchedule__c>  createUpdateRevenueSchedules(List<OpportunityLineItem> items, Set<String> uids) {
        // contains the new grouped revenue schedules to insert
        List<GroupedRevenueSchedule__c> schedulesToCreateOrUpdate = new List<GroupedRevenueSchedule__c>();
        // load any existing schedules for the line items
        // first grab the opportunity line item ids in question
        Set<String> oppLineItemIds = new Set<String>();
        for (OpportunityLineItem item : items) {
            oppLineItemIds.add(item.Id);
        }
        loadGroupedRevenueSchedules(oppLineItemIds);
        // create or modify revenue schedules
        ProductRevenueService prodRevService = ProductRevenueService.newInstance();
        prodRevService.loadGroupedProductRevenues(uids);
        for (OpportunityLineItem nextItem : opportunityLineItems.values()) {
            RevenueScheduleCalculator calculator = new RevenueScheduleCalculator(nextItem.Contract_Start_Date__c,nextItem.Contract_End_Date__c,defaultRevenueAllocation);
            for (Integer financialYear = calculator.financialYearStart; financialYear <= calculator.financialYearEnd; financialYear++) {
                // obtain revenue schedule record for the year
                String scheduleUid = getUID(nextItem.Id, String.valueOf(financialYear));
                Double nrtBaseline = prodRevService.getPastMonthsAverage(nextItem.Opportunity.AccountId, nextItem.Product2.Id, 3);
                Double incrementalNRT = prodRevService.calculateIncrementalNRT(nextItem.Opportunity.AccountId, nextItem.Product2.Id, nrtBaseline);
                GroupedRevenueSchedule__c scheduleToCalculate = groupedSchedules.containsKey(scheduleUid) ? groupedSchedules.get(scheduleUid) : new GroupedRevenueSchedule__c(OpportunityProduct__c = nextItem.Id, Opportunity__c = nextItem.OpportunityId, NRTBaseline__c = nrtBaseline, IncrementalNRT__c = incrementalNRT);
                if (scheduleToCalculate.GroupedAccountProductRevenue__c == null) {
                    // link a revenue record to the schedule
                    String revenueUid = ProductRevenueService.getUID(nextItem.Opportunity.AccountId, nextItem.Product2.Id, String.valueOf(financialYear));
                    GroupedAccountProductRevenue__c revenue = groupedRevenues.get(revenueUid);
                    if (revenue == null) {
                        scheduleToCalculate.GroupedAccountProductRevenue__r = new GroupedAccountProductRevenue__c(AnchorOrganisation__c = nextItem.Opportunity.AccountId, PrimaryProduct__c = nextItem.Product2.Id, FinancialYear__c = financialYear, UID__c = revenueUid);
                    } else {
                        scheduleToCalculate.GroupedAccountProductRevenue__c = revenue.Id;
                        scheduleToCalculate.GroupedAccountProductRevenue__r = revenue;
                    }
                }
                // recalculate the schedule
                calculator.recalculateScheduleByReference(scheduleToCalculate);
                schedulesToCreateOrUpdate.add(scheduleToCalculate);
            }
        }
        return schedulesToCreateOrUpdate;
    }

    /**
     * Retrieves and creates Revenue Records for a list of Opportunity Line Items
     * ensuring that every schedule has a corresponding Revenue Record. 
     * @param items A List of `OpportunityLineItem` objects for which the Grouped Revenue Records need to be created or retrieved.
     * @return Set<String> uids
     */
    private Set<String> getCreateGroupedRevenues(List<OpportunityLineItem> items) {
        // retrieve any existing grouped account product revenue records so the schedules can link to them.
        Set<String> uids = new Set<String>();
        for (OpportunityLineItem nextItem : opportunityLineItems.values()) {
            Integer startYear = nextItem.Contract_Start_Date__c.month() >= 7 ? nextItem.Contract_Start_Date__c.year() + 1 : nextItem.Contract_Start_Date__c.year();
            Integer endYear = nextItem.Contract_End_Date__c.month()  >= 7 ? nextItem.Contract_End_Date__c.year() + 1 : nextItem.Contract_End_Date__c.year();
            for (Integer year = startYear; year <= endYear; year++) {
                String uid = ProductRevenueService.getUID(nextItem.Opportunity.AccountId, nextItem.Product2.Id, String.valueOf(year));
                if (!groupedRevenues.containsKey(uid)) {
                    // create a new placeholder revenue record. This will be replaced with any existing records once loaded.
                    GroupedAccountProductRevenue__c revenueRecord = new GroupedAccountProductRevenue__c(AnchorOrganisation__c = nextItem.Opportunity.AccountId, PrimaryProduct__c = nextItem.Product2.Id, FinancialYear__c = year, UID__c = uid);
                    groupedRevenues.put(uid, revenueRecord);
                }
                uids.add(uid);
            }
        }
        loadGroupedProductRevenues(uids);
        return uids;
    }

    /**
     * Loads existing Grouped Revenue Schedule records associated with specified Opportunity Line Item IDs. te.
     * @param oppLineItemIds A Set of Opportunity Line Item IDs for which Grouped Revenue Schedules need to be loaded.
     * @return Map<String,GroupedRevenueSchedule__c> A map of loaded Grouped Revenue Schedule records keyed by their 
     *         associated Opportunity Line Item IDs. This map can be used for further processing in revenue schedule calculations.
     */
    private Map<String,GroupedRevenueSchedule__c> loadGroupedRevenueSchedules(Set<String> oppLineItemIds) {
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
            groupedSchedules.put(getUID(groupedSchedule.OpportunityProduct__c, String.valueOf(groupedSchedule.Year__c)), groupedSchedule);
            newlyLoadedRecords.put(getUID(groupedSchedule.OpportunityProduct__c, String.valueOf(groupedSchedule.Year__c)), groupedSchedule);
        }
        return newlyLoadedRecords;
    }

    /**
    * Retrieves Opportunity Line Items associated with a set of Opportunity IDs. 
    * @param opportunityIds A Set of Opportunity IDs for which the Opportunity Line Items are to be loaded.
    * @return List<OpportunityLineItem> A list of loaded Opportunity Line Items associated with the provided Opportunity IDs. 
    **/
    private List<OpportunityLineItem> loadProductLineItems(Set<Id> opportunityIds) {

        Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
                OpportunityLineItem.SObjectType => new Set<SObjectField>{OpportunityLineItem.Id, OpportunityLineItem.Name,OpportunityLineItem.Quantity, OpportunityLineItem.Contract_Start_Date__c, OpportunityLineItem.Contract_End_Date__c,OpportunityLineItem.UnitPrice, OpportunityLineItem.TotalPrice, OpportunityLineItem.Annualised_Value__c, OpportunityLineItem.RetainedRevenue__c,OpportunityLineItem.IncrementalRevenue__c, OpportunityLineItem.TweleveMonthRevenue__c},
                Product2.SObjectType => new Set<SObjectField>{Product2.Name},
                Opportunity.SObjectType => new Set<SObjectField>{Opportunity.Name,Opportunity.AccountId,Opportunity.Id}
        };

        List<OpportunityLineItem> loadedItems = OpportunityLineItemSelector.newInstance(0, fieldOverrides).selectByOpportunity(opportunityIds, new Set<Object>{OpportunityLineItemSelector.Options.WITH_OPPORTUNITY, OpportunityLineItemSelector.Options.WITH_PRODUCT});
        for (OpportunityLineItem item : loadedItems) {
            opportunityLineItems.put(item.Id, item);
        }
        return loadedItems;
    }


    /**
     * Loads existing Grouped Product Revenue records 
     * @param uids A Set of String UIDs used to identify and load the relevant `GroupedAccountProductRevenue__c` records.
     * @return void 
     */
    private void loadGroupedProductRevenues(Set<String> uids) {
        Map<Id, GroupedAccountProductRevenue__c> additionalGroupedRevenues = GroupedAccountProductRevenueSelector.newInstance().selectByUniqueIds(uids);
        if (additionalGroupedRevenues == null) {
            return;
        }
        for (GroupedAccountProductRevenue__c groupedRevenue : additionalGroupedRevenues.values()) {
            groupedRevenues.put(groupedRevenue.UID__c, groupedRevenue);
        }
    }

    // Constructs a UID for Grouped Revenue Records based on account, product and financial year of the record.
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
        public Integer financialYearEnd  {get; private set;}
        Integer calendarYearEnd;
        Integer endMonth;
        Double startMonthAllocation;
        Double endMonthAllocation;
        Double totalAllocation;
        Double[] revenueAllocation;

        public  RevenueScheduleCalculator(Date startDate, Date endDate, Double[] revenueAllocation) {
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
            Integer totalWholeMonths =  startDate.monthsBetween(endDate);


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