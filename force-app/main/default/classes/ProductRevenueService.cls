/**************************************************
Type:         Provides methods for product revenue
History:
--------------------------------------------------
2023-09-21    Ken McGuire - Created
**************************************************/
public with sharing class ProductRevenueService {

    public static ProductRevenueService newInstance() {
        return (ProductRevenueService)Application.Utilities.newInstance(ProductRevenueService.class);
    }

    // ***** CONSTANTS ******* //
    public static final String[] months = new String[] { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' };
    public static final String MONTHLY_REVENUE_PREFIX = 'Rev';
    public static final String BUDGET_REVENUE_SUFFIX = '_Revenue_Amount';
    public static final String CUSTOM_SUFFIX = '__c';
    private static final Double MONTHS_IN_YEAR = 12;
    // ***** PRIVATE PROPERTIES ******* //
    // A map of UID / budget and revenue records required to calculate grouped revenues
    private Map<String,Budget_and_Revenue__c> budgetAndRevenues {
        get {
            if (budgetAndRevenues == null) {
                budgetAndRevenues = new Map<String,Budget_and_Revenue__c> ();
            }
            return budgetAndRevenues;
        }
        set;
    }

    // A map of UID / grouped revenue records required to calculate incremental and reatained revenues for opportunity line items.
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

    // Stores the set of accounts that are related to a parent account through the account relationship table
    private Map<Id,Set<Id>> relatedChildAccountsMap{
        get {
            if (relatedChildAccountsMap == null) {
                relatedChildAccountsMap = new  Map<Id,Set<Id>> ();
            }
            return relatedChildAccountsMap;
        }
        set;
    }

    // a map storing the standard salesforce parent of an account
    private Map<Id,Id> childToParentAccountMap{
        get {
            if (childToParentAccountMap == null) {
                childToParentAccountMap = new  Map<Id,Id> ();
            }
            return childToParentAccountMap;
        }
        set;
    }

    // The opportunity line item candidates for recalculation of incremental and retained revenues
    private Map<Id,OpportunityLineItem> opportunityLineItems {
        get {
            if (opportunityLineItems == null) {
                opportunityLineItems = new  Map<Id,OpportunityLineItem>();
            }
            return opportunityLineItems;
        }
        set;
    }

    // The date from which to base all revenue calculations. This will be todays date except for testing.
    @testVisible
    private date calculationDate {
        get {
            if (calculationDate == null) {
                calculationDate = system.today();
            }
            return calculationDate;
        }
        set;
    }

    // ***** PUBLIC STATIC METHODS ******* //



    // Constructs a UID for Grouped Revenue Records based on account, product and financial year of the record.
    public static String getUID(GroupedAccountProductRevenue__c groupedRevenue) {
        return getUID(groupedRevenue.AnchorOrganisation__c,groupedRevenue.PrimaryProduct__c,String.valueOf(groupedRevenue.FinancialYear__c));
    }

    // Constructs a UID for Grouped Revenue Records based on account, product and financial year of the record.
    public static String getUID(Budget_and_Revenue__c customerRevenue) {
        return getUID(customerRevenue.Organisation__c,customerRevenue.Product__c,customerRevenue.Financial_Year__c);
    }

    /*
  * Creates a new instance of the utility to facilitate dependency injection for mocking
  * @return the new instance
  */
    public static ProductRevenueService getInstance() {
        return (ProductRevenueService) Application.Utilities.getInstance(ProductRevenueService.class);
    }

    // ***** PUBLIC METHODS ******* //

    // updates grouped revenues when changes are made to related budget and revenue records
    public List<GroupedAccountProductRevenue__c> updateGroupedRevenues(List<Budget_and_Revenue__c> records, Map<Id,Budget_and_Revenue__c> existingRecords) {
        //Filter records for those that should be processed (if the current month value has changed)
        Map<String,Budget_and_Revenue__c> revenuesToProcess = getRevenuesToProcess(records, existingRecords);
        if (revenuesToProcess.isEmpty()) {
            return new List<GroupedAccountProductRevenue__c>();
        }
        return updateGroupedRevenues(revenuesToProcess,existingRecords);
    }


    /**
      * @description 	Recalculate Grouped Revenues for all the opportunity line items of opportunities
      * @param 			opportunityIds  a set of  ids for the relevant opportunities
      * @return         A list of Grouped Revenue records which have been created or modified.
      */
    public List<GroupedAccountProductRevenue__c> reCalculateGroupRevenuesForOpportunities(Set<Id> opportunityIds) {
        // load opportunity line items
        List<OpportunityLineItem> items = loadProductLineItems(opportunityIds);
        Set<Id> accountIds = new Set<Id>();
        for(OpportunityLineItem item : items) {
            accountIds.add(item.Opportunity.AccountId);
        }

        loadRelatedAccounts(accountIds);
        return reCalculateGroupRevenues(items);
    }

    /**
	   * @description 	Recalculate Grouped Revenues for all the opportunity line items of accounts with active opportunities
	   * @param 			accountids  a set of  ids for the relevant accounts
	   * @return         A list of Grouped Revenue records which have been created or modified.
	   */
    public List<GroupedAccountProductRevenue__c> reCalculateGroupRevenuesForAccounts(Set<Id> accountIds) {
        Set<Id> allAccountIds = loadRelatedAccounts(accountIds);
        Set<Id> opportunityIds = loadOpenOpportunitiesForAccounts(allAccountIds).keySet();
        // load opportunity line items
        List<OpportunityLineItem> items = loadProductLineItems(opportunityIds);
        return reCalculateGroupRevenues(items);
    }

    /**
      * @description 	Recalculate Retained and Incremental values for previously loaded opportunity line items 
      * @return         A list of Opportunity Line Items that have been recalculated.
      */
    public List<OpportunityLineItem> reCalculateRetainedIncremental() {
        // Maintain a list of opportunity line items that have been updated.
        List<OpportunityLineItem> updatedItems = new List<OpportunityLineItem>();
        // update opportunity line item incremental and retained values 
        for (OpportunityLineItem record : opportunityLineItems.values()) {
            // pre-conditions
            if (record.Contract_Start_Date__c != null && record.Contract_End_Date__c!= null) {
                // get last twelve months sales history
                Double pastSales = getSumOfPastTwelveMonths(record.Opportunity.AccountId, record.Product2.Id);
                // update the record based on current values
                updateRetainedIncrementalAnnualised(record,pastSales);
                // add this record to the ones having been updated
                updatedItems.add(record);
            }
        }
        return updatedItems;
    }

    /**
    * @description 	constructs a UID used to retrieve revenue records.
    * @param 			acountId - the account for the revenue record
    * @param 			productId - the product for the revenue record
    * @param 			Year - the financial year of the revenue record
    * @return        	A unique identifier that can be used to retrieve the revenue record
    */
    public static String getUID(Id accountId, Id productId, String year) {
        String orgId = accountId == null ? '' : String.valueOf(accountId).substring(0, 15);
        String prodId = productId == null ? '' : String.valueOf(productId).substring(0, 15);
        return orgId + prodId + year;
    }

    // ***** PRIVATE METHODS ******* //

    private Map<String,Budget_and_Revenue__c> getRevenuesToProcess(List<Budget_and_Revenue__c> records,Map<Id,Budget_and_Revenue__c> existingRecords) {
        Map<String,Budget_and_Revenue__c> requiresProcessing = new Map<String,Budget_and_Revenue__c>();
        for (Budget_and_Revenue__c currentRecord :records) {
            if (currentRecord.Transaction_Type__c == 'REVENUE' && currentRecord.Financial_Year__c == String.valueOf(calculationDate.year())) {
                Double priorValue = existingRecords == null ? 0 : getValueForMonth(existingRecords.get(currentRecord.Id),calculationDate.month());
                if (getValueForMonth(currentRecord,calculationDate.month()) != priorValue) {
                    requiresProcessing.put(currentRecord.uid__c,currentRecord);
                }
            }
        }
        return requiresProcessing;
    }

    private List<GroupedAccountProductRevenue__c> updateGroupedRevenues(Map<String,Budget_and_Revenue__c> revenuesToProcess, Map<Id,Budget_and_Revenue__c> existingRecords) {

        // Grouped revenue records that have been updated by the budget and revenue record changes
        List<GroupedAccountProductRevenue__c> updatedGroupedRevenues = new List<GroupedAccountProductRevenue__c>();

        // specifies the change in value to the current month and FY value in a grouped revenue record based on changes to the budget and revenue record
        Map<String,Double> unprocessedGroupRevenueAdjustments = new Map<String,Double>();

        // tracks products associated with the budget and revenue record that will have to be added to a parent product
        Set<Id> unprocessedProductIds = new Set<Id>();

        // tracks accounts associated with the budget and revenue record that will have to be added to a parent account
        Set<Id> unprocessedAccountIds = new Set<Id>();

        // get the account and product ids associated with the updated budget and revenue records
        for (Budget_and_Revenue__c unprocessedRecord : revenuesToProcess.values()) {
            if(!groupedRevenues.containsKey(unprocessedRecord.uid__c)) {
                unprocessedProductIds.add(unprocessedRecord.Product__c);
                unprocessedAccountIds.add(unprocessedRecord.Organisation__c);
            }
        }

        // get any replacement products associated with the budget and revenue updates
        // loadProductReplacementMap(unprocessedProductIds); Commented Out: replacement products not currently supported

        // load account hierarchy
        loadChildToParentAccountMap(unprocessedAccountIds);

        // load related child accounts
        loadRelatedChildAccountMap(unprocessedAccountIds);

        // convert related child accounts to related parent accounts
        Map<Id,Id> relatedParentAccount = getRelatedParentAccountMap();

        // calculate required updates
        for (Budget_and_Revenue__c record : revenuesToProcess.values()) {
            Integer currentMonth =   calculationDate.month();

            Double priorValue = existingRecords == null ? 0 : getValueForMonth(existingRecords.get(record.Id),currentMonth);
            Double valueChange = getValueForMonth(record,currentMonth) - priorValue;
            Id AccountId = record.Organisation__c;
            Id productId = record.Product__c;
            // Update for related grouped revenue item
            appendGroupRevenueAdjustment(AccountId,productId,valueChange,unprocessedGroupRevenueAdjustments);
            // update to parent account grouped revenue
            if (childToParentAccountMap.containsKey(AccountId) && childToParentAccountMap.get(AccountId) != null) {
                appendGroupRevenueAdjustment(childToParentAccountMap.get(AccountId),productId,valueChange,unprocessedGroupRevenueAdjustments);
            }
            // update to related parent account grouped revenue
            if (relatedParentAccount.containsKey(AccountId) && relatedParentAccount.get(AccountId) != null) {
                appendGroupRevenueAdjustment(relatedParentAccount.get(AccountId),productId,valueChange,unprocessedGroupRevenueAdjustments);
            }
        }

        // Retrieve matching grouped revenues that require updating
        loadGroupedProductRevenues(unprocessedGroupRevenueAdjustments.keySet());
        Integer currentMonth = calculationDate.month();
        // apply adjustments to grouped revenues
        for (String groupRevenueKey : unprocessedGroupRevenueAdjustments.keySet()) {
            if (groupedRevenues.containsKey(groupRevenueKey) && groupedRevenues.get(groupRevenueKey) != null) {
                GroupedAccountProductRevenue__c groupRevenue = groupedRevenues.get(groupRevenueKey);
                Double currentValue = getValueForMonth(groupRevenue,currentMonth);
                Double adjustment = unprocessedGroupRevenueAdjustments.get(groupRevenueKey);
                setValueForMonth(groupRevenue,currentMonth,currentValue+adjustment);
                updatedGroupedRevenues.add(groupRevenue);
            }
        }
        // pass back the updated group revenue records.
        return updatedGroupedRevenues;
    }

    private void appendGroupRevenueAdjustment(Id AccountId, Id productId, Double valueChange,Map<String,Double> unprocessedGroupRevenueAdjustments) {
        Integer currentFY = getAustralianFinancialYear(calculationDate);
        String uniqueId = getUID(AccountId,productId,String.valueOf(currentFY));
        if (!unprocessedGroupRevenueAdjustments.containsKey(uniqueId)) {
            unprocessedGroupRevenueAdjustments.put(uniqueId,0);
        }
        unprocessedGroupRevenueAdjustments.put(uniqueId,unprocessedGroupRevenueAdjustments.get(uniqueId)+valueChange);
    }


    /**
  * Updates the retained and incremental revenue fields for a given OpportunityLineItem record.
  * based on the historical sales value.
  * @param record    The OpportunityLineItem object to be updated.
  * @param pastSales The sales amount for the past twelve months for the account and product related to the record.
  */
    private void updateRetainedIncrementalContractPeriod(OpportunityLineItem record, Double pastSales) {
        // Calculations will be rounded contract whole months.
        Integer contractMonths = contractMonths(record);
        // the value of the opportunity line item over its contract period
        updateRetainedIncremental(record, pastSales, contractMonths);
    }

    /**
* Updates the retained and incremental revenue fields for a given OpportunityLineItem record s
* bbased on annualised value
* @param record    The OpportunityLineItem object to be updated.
* @param pastSales The sales amount for the past twelve months for the account and product related to the record.
*/
    private void updateRetainedIncrementalAnnualised(OpportunityLineItem record, Double pastSales) {
        // Calculations will be rounded contract whole months.
        Integer contractMonths = contractMonths(record);
        // annualise values
        if (contractMonths >12) contractMonths = 12;
        // the value of the opportunity line item over its contract period
        updateRetainedIncremental(record, pastSales, contractMonths);
    }


    /**
* Updates the retained and incremental revenue fields for a given OpportunityLineItem record.
* based on the historical sales value.
* @param record    The OpportunityLineItem object to be updated.
* @param pastSales The sales amount for the past twelve months for the account and product related to the record.
*/
    private void updateRetainedIncremental(OpportunityLineItem record, Double pastSales, Integer contractMonths) {
        // the value of the opportunity line item over its contract period    
        Double totalValue = record.TotalPrice;
        // the annual value of the opportunity line item
        Double annualValue = totalValue/contractMonths*MONTHS_IN_YEAR;
        // sales for the past twelve months    
        record.TweleveMonthRevenue__c = pastSales;
        // calculate retained and incremental based on the sales history    
        if (annualValue>pastSales)
        {
            // sales of the contract exceed historical sales.
            // The retained revenue will be based on sales history
            record.RetainedRevenue__c = pastSales /MONTHS_IN_YEAR * contractMonths;
            // The incremental revenue will be the contract value in excess of sales history
            record.IncrementalRevenue__c = (annualValue-pastSales) /MONTHS_IN_YEAR * contractMonths;
        } else {
            // sales of the contract are less or equal to the sales history.
            // Only retained value applies, and is equal to the total value of the contract.
            record.RetainedRevenue__c = totalValue;
            record.IncrementalRevenue__c = 0;
        }
    }

    /**
    * Calculates the duration of a contract in whole months for a given OpportunityLineItem record.
    * @param record The OpportunityLineItem object whose contract duration is to be calculated.
    * @return Integer representing the contract duration in whole months. Returns a minimum of 1 month if the
    *         calculated duration is zero.
    */
    private Integer contractMonths(OpportunityLineItem record) {
        Integer contractMonths = record.Contract_Start_Date__c.monthsBetween(record.Contract_End_Date__c);
        return contractMonths == 0 ? 1 : contractMonths;
    }

    /**
   * @description 	Recalculate Grouped Revenues for opportunity line items
   * @param 			items  a list of opportunity line items to recalculate grouped revenues for
   * @return         A list of Grouped Revenue records which have been created or modified.
   */
    @TestVisible
    private List<GroupedAccountProductRevenue__c> reCalculateGroupRevenues(List<OpportunityLineItem> items) {
        Set<String> uids = getUIDs(items);
        // get relevant grouped product revenues for the opportunity line items
        Map<String,GroupedAccountProductRevenue__c> unprocessedRevenueRecords =  loadGroupedProductRevenues(uids);
        Map<String,GroupedAccountProductRevenue__c> updatedRevenueRecords = new Map<String,GroupedAccountProductRevenue__c>();         // get related accounts
        uids.addAll(configureProductAccountMaps(items));
        // get all relevant budget and revenue records
        loadBudgetAndRevenueRecords(uids);
        // recalculate group revenue records based on all relevant budget and revenue records
        zeroRevenueValues(unprocessedRevenueRecords.values());

        // reconfigure account and product maps
        Map<Id,Set<Id>> parentToChildAccountMap = getParentToChildAccountMap();

        for(OpportunityLineItem item : opportunityLineItems.values()) {
            Integer currentFY = getAustralianFinancialYear(calculationDate);
            for (Integer year = currentFY-1; year <currentFY+1; year++) {
                // retrieve the grouped revenue records for this item
                GroupedAccountProductRevenue__c currentGroupedRevenue = getCreateGroupedRevenue(unprocessedRevenueRecords,item,year);
                if (currentGroupedRevenue != null) {
                    Boolean isUpdated = false;
                    // add current budget and revenue values
                    if (addRevenueValues(currentGroupedRevenue)) {
                        isUpdated = true;
                    }

                    // add records for child accounts 
                    if (addChildAccountRevenueRecursive(item.Opportunity.AccountId,item.Product2.Id,String.valueOf(year),currentGroupedRevenue,parentToChildAccountMap,0) >0) {
                        isUpdated = true;
                    }
                    // records for related accounts
                    Set<Id> relatedAccounts = relatedChildAccountsMap.containsKey(item.Opportunity.AccountId) &&  relatedChildAccountsMap.get(item.Opportunity.AccountId) !=null ? relatedChildAccountsMap.get(item.Opportunity.AccountId) : new Set<Id>();
                    for (Id relatedAccountId : relatedAccounts) {
                        String relatedAccountRevenueKey = getUID(relatedAccountId,item.Product2.Id,String.valueOf(year));
                        if (addRevenueValues(currentGroupedRevenue,relatedAccountRevenueKey)) {
                            isUpdated = true;
                        }
                        if (addChildAccountRevenueRecursive(relatedAccountId,item.Product2.Id,String.valueOf(year),currentGroupedRevenue,parentToChildAccountMap,0) >0) {
                            isUpdated = true;
                        }
                    }
                    if (isUpdated) {
                        updatedRevenueRecords.put(currentGroupedRevenue.UID__c,currentGroupedRevenue);
                    }
                }
            }
        }
        return updatedRevenueRecords.values();
    }

    /**
     * Retrieves or creates a grouped revenue record for a given opportunity line item and year.
     * 
     * @param unprocessedRevenueRecords A map of existing unprocessed revenue records.
     * @param item The opportunity line item to process.
     * @param year The financial year for the revenue record.
     * @return A GroupedAccountProductRevenue__c instance either retrieved or created.
     */
    private GroupedAccountProductRevenue__c getCreateGroupedRevenue(Map<String, GroupedAccountProductRevenue__c> unprocessedRevenueRecords, OpportunityLineItem item, Integer year) {
        String revenueKey = getUID(item.Opportunity.AccountId, item.Product2.Id, String.valueOf(year));
        GroupedAccountProductRevenue__c revenueRecord = unprocessedRevenueRecords.get(revenueKey);
        if (revenueRecord == null && !groupedRevenues.containsKey(revenueKey)) {
            revenueRecord = new GroupedAccountProductRevenue__c(AnchorOrganisation__c = item.Opportunity.AccountId, PrimaryProduct__c = item.Product2.Id, FinancialYear__c = year, uid__c = revenueKey);
            unprocessedRevenueRecords.put(revenueKey, revenueRecord);
        }
        return revenueRecord;
    }

    /**
   * @description 	Load uids that will be used to retrieve the grouped revenues that require updating
   * @param 			items  a list of opportunity line items to load account relationships from
   * @return         A set of unique record identifiers for use in retrieiving associated grouped revenue records
   */
    private Set<String> getUIDs(List<OpportunityLineItem> items) {
        // retrieve all possible contributing budget and revenue ids
        Set<String> uids = new Set<String>();
        Integer currentFY = getAustralianFinancialYear(calculationDate);
        for(OpportunityLineItem item : items) {
            uids.add(getUID(item?.Opportunity?.AccountId, item?.Product2?.Id,String.valueOf(currentFY)));
            uids.add(getUID(item?.Opportunity?.AccountId, item?.Product2?.Id,String.valueOf(currentFY-1)));
        }
        // get relevant grouped product revenues for the opportunity line items
        return uids;
    }

    /**
   * @description 	Load related accounts and their hierarchial relationships
   * @param 			items  a list of opportunity line items to load account relationships from
   * @return         A set of unique record identifiers for use in retrieiving associated budget and revenue records
   */
    private Set<Id> loadRelatedAccounts(Set<Id> accountIds) {
        Set<Id> allAccounts = new Set<Id>();
        allAccounts.addAll(accountIds);
        // get related accounts
        allAccounts.addAll(loadRelatedChildAccountMap(allAccounts));

        // add related accounts to get their hierarchy
        for (Id parentAccountId : relatedChildAccountsMap.keySet()) {
            Set<Id> relatedAccounts = relatedChildAccountsMap.get(parentAccountId);
            if (relatedAccounts != null) {
                accountIds.addAll(relatedAccounts);
            }
        }

        // load account hierarchy
        loadChildToParentAccountMap(allAccounts);
        return allAccounts;
    }

    /**
    * Configures and returns a set of UIDs for related and child accounts based on opportunity line items.
    *
    * @param items A list of OpportunityLineItem objects to process.
    * @return A set of UIDs representing parent and related accounts.
    */
    private Set<String> configureProductAccountMaps(List<OpportunityLineItem> items) {
        Set<String> relatedUIDs = new Set<String>();
        Map<Id,Set<Id>> parentToChildAccountMap = getParentToChildAccountMap();

        for(OpportunityLineItem item : items) {
            Set<Id> relatedAccounts = relatedChildAccountsMap.containsKey(item.Opportunity.AccountId) &&  relatedChildAccountsMap.get(item.Opportunity.AccountId) !=null ? relatedChildAccountsMap.get(item.Opportunity.AccountId) : new Set<Id>();
            Integer currentFY = getAustralianFinancialYear(calculationDate);
            for (Integer year = currentFY-1; year <currentFY+1; year++) {

                // records for child accounts
                addChildAccountRevenueUIDsRecursive(item.Opportunity.AccountId,item.Product2.Id, String.valueOf(year), parentToChildAccountMap, relatedUIDs);

                //records for any related accounts and their children
                for (Id relatedAccountId : relatedAccounts) {
                    relatedUIDs.add(getUID(relatedAccountId,item.Product2.Id,String.valueOf(year)));
                    addChildAccountRevenueUIDsRecursive(relatedAccountId,item.Product2.Id, String.valueOf(year), parentToChildAccountMap, relatedUIDs);
                }
            }
        }
        return relatedUIDs;
    }

    /**
   * @description 	calculate actual revenue for account products achieved over the past 12 months.
   * @param 			acountId - the account for the revenue record
   * @param 			productId - the product for the revenue record
   * @return        	the total sales value for the last twelve months for the specified account and product.      */
    public Double getSumOfPastTwelveMonths(String AccountId, String productId) {
        Double totalSum = 0.0;
        // Iterate through the past 13 months
        Integer targetYear = getAustralianFinancialYear(calculationDate);
        Integer targetMonth = calculationDate.month();
        for (Integer i = 1; i <= 12; i++) {
            String uniqueId = getUID(AccountId,productId,String.valueOf(targetYear));
            GroupedAccountProductRevenue__c targetData = groupedRevenues.get(uniqueId);
            if (targetData != null) {
                Double monthValue = getValueForMonth(targetData,targetMonth);
                if (monthValue != null) {
                    totalSum += monthValue;
                    //commenting out below rather than deleting it, in case business change their mind about full/partial month revenue decisions
                    //totalSum += (i == 13) ? calculatePartialMonthValue(monthValue): monthValue;
                }
            }
            // adjust target month and financial year.
            targetMonth -= 1;
            if (targetMonth == 6) {
                targetYear -=1;
            }
            else if (targetMonth==0) {
                targetMonth = 12;
            }
        }
        return totalSum;
    }

    /**
	 * @param monthValue i.e. the revenue value for the month
	 *
	 * @return the partial or full revenue for the month base on the calculationDate
	 */
    private Double calculatePartialMonthValue(Double monthValue) {
        return (1 - calculationDate.day() / Date.daysInMonth(calculationDate.year(), calculationDate.month())) * monthValue;
    }


    /**
	 * @description 	adds the actual sales record matching a revenue key to the passed in grouped revenue record.
	 * @param 			summaryRecord - the grouped revenue record for a specified account and product
	 * @param 			revenueKey - the budget and revenue record (actual sales) to add to the summary.
	 * @return        	true if the sales history record was found.
	   */
    private Boolean addRevenueValues(GroupedAccountProductRevenue__c summaryRecord, String revenueKey) {

        if (!budgetAndRevenues.containsKey(revenueKey)) {
            System.debug('***** revenueKey not in budgetandrevenues '+revenueKey);
            return false;
        }
        Budget_and_Revenue__c recordToAdd = budgetAndRevenues.get(revenueKey);
        if (recordToAdd == null) {
            System.debug('***** revenueKey has no record in budgetandrevenues '+revenueKey);
            return false;
        }
        for (Integer i = 1; i<13; i++) {
            Double summaryValue = getValueForMonth(summaryRecord,i);
            Double valueToAdd =  getValueForMonth(recordToAdd,i);
            setValueForMonth(summaryRecord,i,summaryValue+valueToAdd);
        }
        return true;
    }

    private Boolean addRevenueValues(GroupedAccountProductRevenue__c summaryRecord) {
        return addRevenueValues(summaryRecord,summaryRecord.UID__c);
    }


    /**
     * @description 	adds the actual sales record matching a revenue key to the passed in grouped revenue record.
     * @param 			summaryRecord - the grouped revenue record for a specified account and product
     * @param 			revenueKey - the budget and revenue record (actual sales) to add to the summary.
     * @return        	true if the sales history record was found.
    */
    private Integer addChildAccountRevenueRecursive(Id parentAccountId,Id productId, String year, GroupedAccountProductRevenue__c currentGroupedRevenue, Map<Id,Set<Id>> parentToChildAccountMap, Integer updateCount) {
        if (!parentToChildAccountMap.containsKey(parentAccountId)) {
            return updateCount;
        }
        Set<Id> childAccounts =  parentToChildAccountMap.get(parentAccountId);
        if (childAccounts == null) {
            return updateCount;
        }
        // records for child accounts of item account
        for (Id childAccountId : childAccounts) {
            String currentRevenueKey = getUID(childAccountId,productId, year);
            if(addRevenueValues(currentGroupedRevenue,currentRevenueKey)) {
                updateCount++;
            }
            updateCount = addChildAccountRevenueRecursive(childAccountId,ProductId,year,currentGroupedRevenue,parentToChildAccountMap,updateCount);
        }
        return updateCount;
    }

    private void loadBudgetAndRevenueRecords(Set<Id> accountIds, Set<Id> productIds, Set<Integer> financialYears, set<Id> excludeRecords) {
        for (Budget_and_Revenue__c currentBudget : BudgetAndRevenueSelector.newInstance().selectByOrganisationAndProduct(accountIds,productIds,financialYears,excludeRecords)) {
            budgetAndRevenues.put(currentBudget.uid__c, currentBudget);
        }
    }

    private void loadBudgetAndRevenueRecords(Set<String> uniqueIds) {
        Set<String> unloadedIds = new Set<String>();
        for (String uniqueId : uniqueIds) {
            if (!budgetAndRevenues.containsKey(uniqueId)) {
                unloadedIds.add(uniqueId);
                budgetAndRevenues.put(uniqueId,null);
            }
        }
        if(unloadedIds.isEmpty()) {
            return;
        }
        for (Budget_and_Revenue__c currentBudget : BudgetAndRevenueSelector.newInstance().selectByUniqueIds(unloadedIds).values()) {
            budgetAndRevenues.put(currentBudget.uid__c, currentBudget);
        }
    }

    private Map<String,GroupedAccountProductRevenue__c> loadGroupedProductRevenues(Set<String> uniqueIds) {
        Set<String> unloadedIds = new Set<String>();
        for (String uniqueId : uniqueIds) {
            if (!groupedRevenues.containsKey(uniqueId)) {
                unloadedIds.add(uniqueId);
                groupedRevenues.put(uniqueId,null);
            }
        }
        Map<String,GroupedAccountProductRevenue__c> newlyLoadedRecords = new Map<String,GroupedAccountProductRevenue__c>();

        if(unloadedIds.isEmpty()) {
            return newlyLoadedRecords;
        }

        Map<Id, GroupedAccountProductRevenue__c> additionalGroupedRevenues =  GroupedAccountProductRevenueSelector.newInstance().selectByUniqueIds(unloadedIds);

        if (additionalGroupedRevenues == null) {
            return newlyLoadedRecords;
        }
        for (GroupedAccountProductRevenue__c groupedRevenue : additionalGroupedRevenues.values()) {
            groupedRevenues.put(groupedRevenue.uid__c, groupedRevenue);
            newlyLoadedRecords.put(groupedRevenue.uid__c, groupedRevenue);
        }
        return newlyLoadedRecords;
    }

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

    private Map<Id,Opportunity> loadOpenOpportunitiesForAccounts(Set<Id> accountIds) {
        return OpportunitySelector.newInstance().selectOpenOpportunitiesByAccountIds(accountIds);
    }

    private Set<Id> loadRelatedChildAccountMap(Set<Id> parentAccountsToInclude) {
        Set<Id> loadedRelatedAccountIds = new Set<Id>();
        if ( parentAccountsToInclude==null  || parentAccountsToInclude.isEmpty()) {
            return loadedRelatedAccountIds;
        }

        Set<Id> unloadedAccountIds = getUnloadedRelatedAccountIds(parentAccountsToInclude);

        if (unloadedAccountIds.isEmpty()) {
            return loadedRelatedAccountIds;
        }

        for (AccountRelationship__c arr: AccountRelationshipSelector.newInstance().selectByOPCParentEndDateInFuture(unloadedAccountIds)) {
            relatedChildAccountsMap.get(arr.ParentAccount__c).add(arr.RelatedAccount__c);
            loadedRelatedAccountIds.add(arr.RelatedAccount__c);
        }
        return loadedRelatedAccountIds;

    }

    private Set<Id> getUnloadedRelatedAccountIds(Set<Id> accountsToLoad ) {
        Set<Id> unloadedRelatedAccounts = new Set<Id>();
        for (Id accountToLoad : accountsToLoad) {
            if (!relatedChildAccountsMap.containsKey(accountToLoad)) {
                relatedChildAccountsMap.put(accountToLoad,null);
                unloadedRelatedAccounts.add(accountToLoad);
            }
        }
        return unloadedRelatedAccounts;
    }

    // loads the childAccountIds set plus all the children of those accounts down to five levels
    private Set<Id> loadChildToParentAccountMap(Set<Id> accountIds) {
        Set<Id> unloadedAccountIds = new Set<Id>();
        if ( accountIds==null  || accountIds.isEmpty()) {
            return unloadedAccountIds;
        }

        unloadedAccountIds = getUnloadedChildAccounts(accountIds);
        if (unloadedAccountIds.isEmpty()) {
            return unloadedAccountIds;
        }

        Set<SObjectField> fields = new Set<SObjectField>{Account.Id, Account.Parent.Id, Account.Parent.ParentId, Account.Parent.Parent.Parent.Id, Account.Parent.Parent.Parent.Parent.Id,Account.Parent.Parent.Parent.Parent.Parent.Id};
        Map<String, Object> searchParams = new Map<String, Object>{'accId' => unloadedAccountIds,'parentIds' => unloadedAccountIds, 'parentIdsLevel2' => unloadedAccountIds, 'parentIdsLevel3' => unloadedAccountIds,'parentIdsLevel4' => unloadedAccountIds, 'parentIdsLevel5' => unloadedAccountIds, 'parentIdsLevel6' => unloadedAccountIds};
        Set<Object> selectorOptions = new Set<Object> {AccountsSelector.Options.WITH_PARENT_5LEVELS};
        String searchConditions = '1 OR 2 OR 3 OR 4 OR 5 OR 6 OR 7';
        Schema.SObjectField orderByField = Account.Id;
        String sortDirection = 'ASC';
        Set<Id> loadedAccountIds = new Set<Id>();
        List<Account> loadedAccounts = AccountsSelector.newInstance(0, fields).search(searchParams,selectorOptions, searchConditions, orderByField,sortDirection);
        for(Account acc : loadedAccounts) {
            addAccountParent(acc);
            loadedAccountIds.add(acc.Id);
        }
        return loadedAccountIds;
    }

    private void addAccountParent(Account account) {
        if(account.Parent == null) {
            return;
        }
        childToParentAccountMap.put(account.Id, account.parent.Id);
        if (account.Parent.Parent != null) {
            addAccountParent(account.Parent);
        }
    }

    private Set<Id> getUnloadedChildAccounts(Set<Id> childAccountIds) {

        Set<Id> unloadedChildAccounts = new Set<Id>();

        for (Id childAccountId : childAccountIds) {
            if (!childToParentAccountMap.containsKey(childAccountId)) {
                childToParentAccountMap.put(childAccountId,null);
                unloadedChildAccounts.add(childAccountId);
            }
        }
        return unloadedChildAccounts;
    }

    private Map<Id,Set<Id>> getParentToChildAccountMap() {
        Map<Id,Set<Id>> parentToChildMap = new Map<Id,Set<Id>>();
        for (Id childId : childToParentAccountMap.keySet()) {
            Id parentId = childToParentAccountMap.get(childId);
            if (!parentToChildMap.containsKey(parentId)) {
                parentToChildMap.put(parentId, new Set<Id>());
            }
            parentToChildMap.get(parentId).add(childId);
        }
        return parentToChildMap;
    }

    private Map<Id,Id> getRelatedParentAccountMap() {
        Map<Id,Id> childToParentMap = new Map<Id,Id>();
        for (Id parentAccountId : relatedChildAccountsMap.keySet()) {
            if (relatedChildAccountsMap.get(parentAccountId) != null) {
                for (Id childAccountId : relatedChildAccountsMap.get(parentAccountId)) {
                    childToParentMap.put(childAccountId,parentAccountId);
                }
            }
        }
        return childToParentMap;
    }

    /**
    * @description 	clears the values of summary records before recalculating them.
    * @param 			recordsToZero - the grouped revenue records to clear 
    */
    private static void zeroRevenueValues(List<GroupedAccountProductRevenue__c> recordsToZero) {
        for (GroupedAccountProductRevenue__c recordToZero : recordsToZero) {
            for (Integer i = 1; i<=12; i++) {
                setValueForMonth(recordToZero,i,0);
            }
        }
    }

    private static void addChildAccountRevenueUIDsRecursive(Id parentAccountId,Id productId, String year, Map<Id,Set<Id>> parentToChildAccountMap, Set<String> relatedUIDs ) {
        if (!parentToChildAccountMap.containsKey(parentAccountId)) {
            return;
        }
        Set<Id> childAccounts =  parentToChildAccountMap.get(parentAccountId);
        if (childAccounts == null) {
            return;
        }
        // records for child accounts of item account
        for (Id childAccountId : childAccounts) {
            relatedUIDs.add(getUID(childAccountId,productId,year));
            addChildAccountRevenueUIDsRecursive(childAccountId,productId,year,parentToChildAccountMap,relatedUIDs);
        }
    }

    private static Integer getAustralianFinancialYear(Date dateToUse) {
        return dateToUse.month() >= 7 ? dateToUse.year() + 1 : dateToUse.year();
    }

    private static Double getValueForMonth(SObject record, Integer month) {
        if (record.getSObjectType() == Budget_and_Revenue__c.SObjectType) {
            return getSuffixedValueForMonth(record, month ,BUDGET_REVENUE_SUFFIX);
        }
        return getPrefixedValueForMonth(record,month,MONTHLY_REVENUE_PREFIX);
    }

    private static void setValueForMonth(SObject record, Integer month, Double value) {
        if (record.getSObjectType() == Budget_and_Revenue__c.SObjectType) {
            setSuffixedValueForMonth(record, month,BUDGET_REVENUE_SUFFIX,value);
        }
        setPrefixedValueForMonth(record,month,MONTHLY_REVENUE_PREFIX,value);
    }

    private static Double getPrefixedValueForMonth(SObject record, Integer month, String prefix) {
        Double value = (Double)record.get(getPrefixedFieldNameForMonth(month,prefix));
        return value == null ? 0 : value;
    }

    private static Double getSuffixedValueForMonth(SObject record, Integer month, String suffix) {
        Double value = (Double)record.get(getSuffixedFieldNameForMonth(month,suffix));
        return value == null ? 0 : value;
    }

    private static String getPrefixedFieldNameForMonth(Integer month, String prefix) {
        return prefix+String.valueOf(month)+CUSTOM_SUFFIX;
    }

    private static String getSuffixedFieldNameForMonth(Integer month, String suffix) {
        return months[month-1]+suffix+CUSTOM_SUFFIX;
    }

    private static void setPrefixedValueForMonth(SObject record, Integer month, String prefix, Double value) {
        record.put(getPrefixedFieldNameForMonth(month,prefix),value);
    }

    private static void setSuffixedValueForMonth(SObject record, Integer month, String suffix, Double value) {
        record.put(getSuffixedFieldNameForMonth(month,suffix),value);
    }

}