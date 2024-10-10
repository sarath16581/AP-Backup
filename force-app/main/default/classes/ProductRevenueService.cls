/**************************************************
Type: Provides methods for product revenue
			Extensively commented due to the complexity of the data object calculations and relationships.
History:
--------------------------------------------------
2023-09-21 Ken McGuire - Created
2024-07-05 Moved from PTEST
2024-07-05 	Applied product line item sync fix.
2024-07-08 	Ken McGuire	- code cleanup,
2024-07-12 modify for line items of closed opportunities (major refactoring)
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
	private static final String TRANSACTION_TYPE_REVENUE = 'REVENUE'; 
	@TestVisible private static final String CLASSIFICATION_NEW_BUSINESS = 'New Business';
	@TestVisible private static final String CLASSIFICATION_RENEWAL = 'Renewal';
	@TestVisible private static final String CLASSIFICATION_GROWTH = 'Growth';
	@TestVisible private static final String CLASSIFICATION_WIN_BACK = 'Win Back';
	@TestVisible private static final String CLASSIFICATION_CROSS_SELL = 'Cross Sell';
    private static final String OPPORTUNITY_CLOSED_WON = 'Closed Won';
	private static final integer YEARS_HISTORY = 5;
	private static final integer FINANCIAL_YEAR_STARTING_MONTH = 7;
	private static final integer DAYS_IN_YEAR = 365;
 
	// ***** PUBLIC PROPERTIES ******* //
	// These data objects are maintained as a singleton for the session to facilitate lazy loading

	// Maintains opportunity information for line items that is necessary for the application of business logic
	public Map<Id,Opportunity> opportunityInfo {
		get {
			if (opportunityInfo == null) {
				opportunityInfo = new Map<Id,Opportunity>();
			}
			return opportunityInfo;
		}
	set;
	}

	// Maintains a map of UID => grouped revenue records.
	// this up-to-date records calculate incremental and reatained revenues for opportunity line items.
	public Map<String,GroupedAccountProductRevenue__c> groupedRevenues {
		get {
			if (groupedRevenues == null) {
				groupedRevenues = new Map<String,GroupedAccountProductRevenue__c> ();
			}
			return groupedRevenues;
		}
		set;
	}

	/*
	* Creates a new instance of the utility to facilitate dependency injection for mocking
	* @return the new instance
	*/
	public static ProductRevenueService getInstance() {
		return (ProductRevenueService) Application.Utilities.getInstance(ProductRevenueService.class);
	}

	// ***** PRIVATE PROPERTIES ******* //
	// @description A map of UID / budget and revenue records required to calculate grouped revenues
	private Map<String,Budget_and_Revenue__c> budgetAndRevenues {
		get {
			if (budgetAndRevenues == null) {
				budgetAndRevenues = new Map<String,Budget_and_Revenue__c> ();
			}
		return budgetAndRevenues;
		}
		set;
	}
 
	// @description Stores the set of accounts that are related to a parent account through the account relationship table
	private Map<Id,Set<Id>> relatedChildAccountsMap{
		get {
			if (relatedChildAccountsMap == null) {
				relatedChildAccountsMap = new Map<Id,Set<Id>> ();
			}
			return relatedChildAccountsMap;
		}
		set;
	}
 

	// @description a map storing the standard salesforce parent of an account
	private Map<Id,Id> childToParentAccountMap{
		get {
			if (childToParentAccountMap == null) {
				childToParentAccountMap = new Map<Id,Id> ();
			}
			return childToParentAccountMap;
		}
		set;
	}
    
   private Set<Id> revenueLoadedForAccountIds{
		get {
			if (revenueLoadedForAccountIds == null) {
				revenueLoadedForAccountIds = new Set<Id> ();
			}
			return revenueLoadedForAccountIds;
		}
		set;
	}


	/**
	* @description The default date from which to base all revenue calculations. This defaults to the current date.
	*/
	@TestVisible
	private Date revenueCalculationContextDate {
		get {
			if (revenueCalculationContextDate == null) {
				revenueCalculationContextDate = System.today();
			}
			return revenueCalculationContextDate;
		}
		set;
	}

	// ***** PUBLIC METHODS ******* //

	// @description Constructs a UID for Grouped Revenue Records based on account, product and financial year of the record.
	public static String getUID(GroupedAccountProductRevenue__c groupedRevenue) {
		return getUID(groupedRevenue.AnchorOrganisation__c,groupedRevenue.PrimaryProduct__c,String.valueOf(groupedRevenue.FinancialYear__c));
	}

	// @description Constructs a UID for Grouped Revenue Records based on account, product and financial year of the record.
	public static String getUID(Budget_and_Revenue__c customerRevenue) {
		return getUID(customerRevenue.Organisation__c,customerRevenue.Product__c,customerRevenue.Financial_Year__c);
	}

	/**
	* @description 	constructs a UID used to retrieve revenue records.
	* @param accountId - the account for the revenue record
	* @param productId - the product for the revenue record
	* @param Year - the financial year of the revenue record
	* @return A unique identifier that can be used to retrieve the revenue record
	*/
	public static String getUID(Id accountId, Id productId, String year) {
		return accountId.to15() + productId.to15() + year;
	} 

	/**
	* @description 	Recalculates the Grouped Revenues for all the opportunity line items passed in
	* @param 			opportunityIds a set of ids for the relevant opportunities
	* @return A list of Grouped Revenue records which have been created or modified.
	*/
	public Map<String, GroupedAccountProductRevenue__c> reCalculateGroupRevenuesForLineItems(List<OpportunityLineItem> items) {
		// ensure opportunity info is available
		loadOpportunityInfoForOpportunityLineItems(items);
		// collect accounts associated with the line items
		loadOpportunityAccounts(opportunityInfo.values());
        
		system.debug('Loaded opportunity accounts for items '+items);
		// return the newly created or recalculated grouped revenues
		return reCalculateGroupRevenues(items,false);
	}
 
	/**
	* @description 	Recalculate Retained and Incremental values for opportunity line items.
	* 				Prerequisite: this method relies on the grouped revenues having been loaded 
	* 				though a prior method call such as reCalculateGroupRevenuesForLineItems
	* @return by reference change to the line items provided.
	*/
	public void reCalculateRetainedIncremental(List<OpportunityLineItem> itemsToUpdate) {
		// ensure opportunity info is available
		loadOpportunityInfoForOpportunityLineItems(itemsToUpdate);
		// update opportunity line item incremental and retained values
		for (OpportunityLineItem record : itemsToUpdate) {
            system.debug('*** updating fiancials for record '+record);
			Opportunity recordOpportunity = this.opportunityInfo.get(record.opportunityid);
            system.debug('**** record opportunity '+recordOpportunity);
			record.Hidden_In_Year_Revenue__c = record.In_Year_Revenue__c;
			// pre-conditions
			if (record.Contract_Start_Date__c != null && record.Contract_End_Date__c != null) {
				// get last twelve months sales history
				date startDate = getDateToUse(record);
				system.debug('**** getting past sales account '+recordOpportunity.AccountId +' product '+ record.Product2Id +' start date '+ startDate);
				Double pastSales = getSumOfPastTwelveMonths(recordOpportunity.AccountId, record.Product2Id, startDate);
                system.debug('**** past sales '+pastSales);
				updateRetainedIncrementalAnnualised(record,pastSales);
				record.X3MonthAverageActual__c = getPastMonthsAverage(recordOpportunity.AccountId, record.Product2Id, 3, startDate);
				record.TotalInYearRevenue__c = calculateTotalInYearRevenue(record.contract_Start_Date__c, record.contract_End_Date__c, record.totalPrice);
			}
		}
	}
 
	/**
	* @param lineItems List<OpportunityLineItem>
	* @description use the AccountId on Opp to fire the current GroupedAccount logic to find all the target Accounts, then find the Customer Rev records under the 'GroupedAccount', to determine one of the potential classifications
	*
	* @return List<OpportunityLineItem>
	*/
	public List<OpportunityLineItem> calculateClassification(List<OpportunityLineItem> lineItems, boolean useDefaultDate) {
		
        // ensure opportunity info is available
		loadOpportunityInfoForOpportunityLineItems(lineItems);
		set<id> allAccounts = new Set<id>();
        for (OpportunityLineItem item : lineItems ) {
            Opportunity oppInfo = opportunityInfo.get(item.opportunityid);
            allAccounts.add(oppInfo.accountId);
        }
		loadBudgetAndRevenueRecordsForAccounts(allAccounts);        
        // collect all accounts of the opportunities associated with the line items are
		loadOpportunityAccounts(OpportunityInfo.values());
		// get all the unique identifiers for the accounts, products and years needed
		Set<String> uids = getCreateGroupedRevenues(lineItems, useDefaultDate,YEARS_HISTORY,true);
		// create a map from the account to a set of products that have any sales history (last 5 years)
		Map<Id,Set<id>> accountProductSalesAllTime = new Map<id,Set<Id>>();
		// build out the account sales map
		system.debug('***** groupedRevenues.keyset()  ' + groupedRevenues.keyset());
		for (GroupedAccountProductRevenue__c revenueRecord : groupedRevenues.values()) {
			if (revenueRecord != null && fytotal(revenueRecord)>0) {
				if (!accountProductSalesAllTime.containsKey(revenueRecord.AnchorOrganisation__c)) {
					accountProductSalesAllTime.put(revenueRecord.AnchorOrganisation__c,new Set<id>());
				}
				accountProductSalesAllTime.get(revenueRecord.AnchorOrganisation__c).add(revenueRecord.PrimaryProduct__c);
			}
		}
        for (Budget_And_Revenue__c revenueRecord : budgetAndRevenues.values()) {
			if (revenueRecord != null && fytotal(revenueRecord) >0 ) {
				if (!accountProductSalesAllTime.containsKey(revenueRecord.Organisation__c)) {
					accountProductSalesAllTime.put(revenueRecord.Organisation__c,new Set<id>());
				}
				accountProductSalesAllTime.get(revenueRecord.Organisation__c).add(revenueRecord.Product__c);
			}
		}
        system.debug('***** accountProductSalesAllTime ' + accountProductSalesAllTime);
		// iterate through each line item to classify the opportunity line item
		for (OpportunityLineItem lineItem : lineItems) {
            system.debug('calculating classification for line item  '+lineItem);
			Opportunity oppInfo = opportunityInfo.get(lineItem.opportunityid);
            system.debug('***** oppInfo ' + oppInfo);
			boolean accountHasAnySales = accountProductSalesAllTime.containsKey(oppInfo.accountId);
            system.debug('***** accountHasAnySales ' + accountHasAnySales);
			boolean accountHasProductSales = accountHasAnySales ? accountProductSalesAllTime.get(oppInfo.accountId).contains(lineitem.Product2Id) : false;
            system.debug('***** accountHasAnySales ' + accountHasProductSales);
            system.debug('***** lineItem.IncrementalRevenue__c  ' + lineItem.IncrementalRevenue__c );
			if (!accountHasAnySales) { 
				lineItem.Classification__c = CLASSIFICATION_NEW_BUSINESS; //cannot find any CustomerRev records => new business
			} else if (!accountHasProductSales) {
				lineItem.Classification__c = CLASSIFICATION_CROSS_SELL; //Customer Rev record for this product does not exist, but there are other Customer Rev records for this grouped account
			} else if (lineItem.TweleveMonthRevenue__c > 0) { // the line item has some sales in the past 12 months
				lineItem.Classification__c = lineItem.IncrementalRevenue__c != null && lineItem.IncrementalRevenue__c > 0 ? CLASSIFICATION_GROWTH : CLASSIFICATION_RENEWAL;
			} else {
				lineItem.Classification__c = CLASSIFICATION_WIN_BACK; //opposite of renewal, is the last 12 months logic is 0, but not 0 going before that
			}
            system.debug('classification is '+lineItem.Classification__c);
		}
		return lineItems;
	}

	/**
	* keeps grouped revenue records up to date when changes are made to related budget and revenue records
	* New grouped revenue records will be created where there are no corresponding existing ones for the FY in question.
	* @param items A List of `OpportunityLineItem` objects for which the Grouped Revenue Records need to be created or retrieved.
	* @return new and updated grouped account revenue records
	*/
	public Map<String,GroupedAccountProductRevenue__c> updateGroupedRevenues(List<Budget_and_Revenue__c> records, Map<Id,Budget_and_Revenue__c> existingRecords) {
		//Not all changed budget and revenue records should be applied to grouped revenue records
		//Filter the records passed in to select only those that are relevant to the current month
		Map<String,Budget_and_Revenue__c> revenuesToProcess = getRevenuesToProcess(records, existingRecords);
		//if there are no updated revenue records to be applied to the grouped revenues return an empty list
		if (revenuesToProcess.isEmpty()) {
			return new Map<String,GroupedAccountProductRevenue__c>();
		}
		// update grouped revenue records with the new values from the updated budget and revenue records.
		return updateGroupedRevenues(revenuesToProcess,existingRecords);
	}

	/**
	* @description calculate actual revenue for account products achieved over the past 12 months.
	* @param accountId - the account for the revenue record
	* @param productId - the product for the revenue record
	* @return the total sales value for the last twelve months for the specified account and product.
	* */
	public Double getSumOfPastTwelveMonths(String accountId, String productId, Date targetDate) {
		Double totalSum = 0.0;
		// Iterate through the past 12 months
		Integer targetYear = getAustralianFinancialYear(targetDate);
		Integer targetMonth = targetDate.month();
        system.debug('targetYear = '+targetYear +' target month '+targetMonth);
		for (Integer i = 1; i <= 12; i++) {
			// last twelve months sales does not include the current month
			// go backwards one month
			targetMonth -= 1;
			if (targetMonth == 6) {
				targetYear -=1;
			}
			else if (targetMonth==0) {
				targetMonth = 12;
			}
			String uniqueId = getUID(accountId,productId,String.valueOf(targetYear));
            GroupedAccountProductRevenue__c targetData = groupedRevenues.get(uniqueId);
			if (targetData != null) {
				Double monthValue = getValueForMonth(targetData,targetMonth);
				if (monthValue != null) {
					totalSum += monthValue;
				}
			}
		}
		return totalSum;
 }

	/**
	* @description calculates the average value based on the previous month, and going back as the parameter numberOfMonths indicated
	* @param accountId accountId the account in question
	* @param productId productId the product in question
	* @param numberOfMonths the number of months the average should be calculated for
	* @param revenueStartDate the date to work backwards into sales history from.
	* @return Double the average sales value for the specified product of the specified during the specefied number of months
	*/
	public Double getPastMonthsAverage(String accountId, String productId, Integer numberOfMonths, Date targetDate) {
		Double totalSum = 0.0;
		// Iterate through the past 12 months
		Integer targetYear = getAustralianFinancialYear(targetDate);
		Integer targetMonth = targetDate.month(); // should not include the current month
		String uniqueId = getUID(accountId,productId,String.valueOf(targetYear));
		GroupedAccountProductRevenue__c targetData = groupedRevenues.get(uniqueId);
		for (Integer i = 1; i <= numberOfMonths; i++) {
			// adjust target month and financial year.
			targetMonth -= 1;
			if (targetMonth == 6) {
				targetYear -=1;
				uniqueId = getUID(accountId,productId,String.valueOf(targetYear));
				targetData = groupedRevenues.get(uniqueId);
			}
			else if (targetMonth==0) {
				targetMonth = 12;
			}
			if (targetData != null) {
			Double monthValue = getValueForMonth(targetData,targetMonth);
				if (monthValue != null) {
				totalSum += monthValue;
				}
			}
	 	}
		return totalSum / numberOfMonths;
	}

	/**
	* @description Retrieve grouped product revenue records from the database based on a set of unique ids
	* @param uniqueIds - a set of unique identiifiers that specifies the year, account and product to load
	* @return the grouped revenue records having the unique ids specified.
	* */
	public Map<String,GroupedAccountProductRevenue__c> loadGroupedProductRevenues(Set<String> uniqueIds) {
		Set<String> unloadedIds = new Set<String>();
		// track the grouped revenue records that have already been requested (avoid recursion)
		for (String uniqueId : uniqueIds) {
			if (!groupedRevenues.containsKey(uniqueId)) {
				unloadedIds.add(uniqueId);
				// all requested uids are tracked and set to null by default.
				groupedRevenues.put(uniqueId,null);
			}
		}
		// store the newly loaded records
		Map<String,GroupedAccountProductRevenue__c> newlyLoadedRecords = new Map<String,GroupedAccountProductRevenue__c>();
		// return empty map in the case that there are no new records to load
		if(unloadedIds.isEmpty()) {
			return newlyLoadedRecords;
		}
		// request the new records from the database
		Map<Id, GroupedAccountProductRevenue__c> additionalGroupedRevenues = GroupedAccountProductRevenueSelector.newInstance().selectByUniqueIds(unloadedIds);
		// if no records are returned from the database, return an empty set
		if (additionalGroupedRevenues == null) {
			return newlyLoadedRecords;
		}
		// store the newly retrieved records to the static map of records to avoid requesting them again
			for (GroupedAccountProductRevenue__c groupedRevenue : additionalGroupedRevenues.values()) {
			groupedRevenues.put(groupedRevenue.uid__c, groupedRevenue);
			newlyLoadedRecords.put(groupedRevenue.uid__c, groupedRevenue);
		}
		// return any newly loaded records.
		return newlyLoadedRecords;
	}
    
    
	/**
	* @description Retrieve grouped product revenue records from the database based on a set of unique ids
	* @param uniqueIds - a set of unique identiifiers that specifies the year, account and product to load
	* @return the grouped revenue records having the unique ids specified.
	* */
	public Map<String,GroupedAccountProductRevenue__c> loadGroupedProductRevenuesForAccountIds(Set<String> uniqueIds) {
		Set<String> unloadedIds = new Set<String>();
		// track the grouped revenue records that have already been requested (avoid recursion)
		for (String uniqueId : uniqueIds) {
			if (!groupedRevenues.containsKey(uniqueId)) {
				unloadedIds.add(uniqueId);
				// all requested uids are tracked and set to null by default.
				groupedRevenues.put(uniqueId,null);
			}
		}
		// store the newly loaded records
		Map<String,GroupedAccountProductRevenue__c> newlyLoadedRecords = new Map<String,GroupedAccountProductRevenue__c>();
		// return empty map in the case that there are no new records to load
		if(unloadedIds.isEmpty()) {
			return newlyLoadedRecords;
		}
		// request the new records from the database
		Map<Id, GroupedAccountProductRevenue__c> additionalGroupedRevenues = GroupedAccountProductRevenueSelector.newInstance().selectByUniqueIds(unloadedIds);
		// if no records are returned from the database, return an empty set
		if (additionalGroupedRevenues == null) {
			return newlyLoadedRecords;
		}
		// store the newly retrieved records to the static map of records to avoid requesting them again
			for (GroupedAccountProductRevenue__c groupedRevenue : additionalGroupedRevenues.values()) {
			groupedRevenues.put(groupedRevenue.uid__c, groupedRevenue);
			newlyLoadedRecords.put(groupedRevenue.uid__c, groupedRevenue);
		}
		// return any newly loaded records.
		return newlyLoadedRecords;
	}

	/**
	* @description Retrieve product line items for the specified opportunities.
	* @param opportunityIds - a set of opportunity ids to load.
	* @return a list of opportunity line items.
	* */
	public List<OpportunityLineItem> getProductLineItemsForOpportunities(Set<Id> opportunityIds) {
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
		OpportunityLineItem.SObjectType => new Set<SObjectField>{
			OpportunityLineItem.Id, OpportunityLineItem.Name,OpportunityLineItem.Quantity,
			OpportunityLineItem.Contract_Start_Date__c, OpportunityLineItem.Contract_End_Date__c,OpportunityLineItem.UnitPrice,
			OpportunityLineItem.TotalPrice, OpportunityLineItem.Annualised_Value__c, OpportunityLineItem.RetainedRevenue__c,
			OpportunityLineItem.IncrementalRevenue__c, OpportunityLineItem.TweleveMonthRevenue__c, OpportunityLineItem.X3MonthAverageActual__c,
			OpportunityLineItem.In_Year_Revenue__c, OpportunityLineItem.Hidden_In_Year_Revenue__c, OpportunityLineItem.TotalInYearRevenue__c
		},
		Product2.SObjectType => new Set<SObjectField>{Product2.Name},
		Opportunity.SObjectType => new Set<SObjectField>{Opportunity.Name,Opportunity.AccountId,Opportunity.Id,Opportunity.StageName,Opportunity.DoNotUseAccountHierarchy__c, Opportunity.closedate, Opportunity.Pre_Entry__c, Opportunity.RevenueCalculationAccountIDs__c}
		};
		List<OpportunityLineItem> loadedItems = OpportunityLineItemSelector.newInstance(0, fieldOverrides).selectByOPCCalculationOpportunityIds(opportunityIds, new Set<Object>{OpportunityLineItemSelector.Options.WITH_OPPORTUNITY, OpportunityLineItemSelector.Options.WITH_PRODUCT});
		// store related opportunities 
		for (OpportunityLineItem item : loadedItems) {
			if (!this.opportunityInfo.containskey(item.opportunity.id)) {
				this.opportunityInfo.put(item.opportunityid,item.opportunity);
			}
		}
		return loadedItems;
	}

	/**
	* @description Retrieve product line items for the specified opportunities.
	* @param opportunityIds - a set of opportunity ids to load.
	* @return a list of opportunity line items.
	* */
	public List<OpportunityLineItem> getProductLineItems(Set<Id> lineItemIds) {
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			OpportunityLineItem.SObjectType => new Set<SObjectField>{
			OpportunityLineItem.Id, OpportunityLineItem.Name,OpportunityLineItem.Quantity,
			OpportunityLineItem.Contract_Start_Date__c, OpportunityLineItem.Contract_End_Date__c,OpportunityLineItem.UnitPrice,
			OpportunityLineItem.TotalPrice, OpportunityLineItem.Annualised_Value__c, OpportunityLineItem.RetainedRevenue__c,
			OpportunityLineItem.IncrementalRevenue__c, OpportunityLineItem.TweleveMonthRevenue__c, OpportunityLineItem.X3MonthAverageActual__c,
			OpportunityLineItem.In_Year_Revenue__c, OpportunityLineItem.Hidden_In_Year_Revenue__c
		},
		Product2.SObjectType => new Set<SObjectField>{Product2.Name},
		Opportunity.SObjectType => new Set<SObjectField>{Opportunity.Name,Opportunity.AccountId,Opportunity.Id,Opportunity.StageName,Opportunity.DoNotUseAccountHierarchy__c, Opportunity.closedate, Opportunity.Pre_Entry__c, Opportunity.RevenueCalculationAccountIDs__c}
		};
		List<OpportunityLineItem> loadedItems = OpportunityLineItemSelector.newInstance(0, fieldOverrides).selectbyId(lineItemIds, new Set<Object>{OpportunityLineItemSelector.Options.WITH_OPPORTUNITY, OpportunityLineItemSelector.Options.WITH_PRODUCT});
		// store related opportunities 
		for (OpportunityLineItem item : loadedItems) {
		if (!this.opportunityInfo.containskey(item.opportunity.id)) {
			this.opportunityInfo.put(item.opportunityid,item.opportunity);
			}
		}
		return loadedItems;
	}
 
	public Map<String,String> getOpportunityAccountList(List<Opportunity> opportunities) {
		system.debug('**** generating account list for opportunities '+opportunities);
        Map<String,String> opportunityAccountList = new Map<String,String>();
		Set<Id> loadedAccounts = loadOpportunityAccounts(opportunities);
        
		Map<Id,Set<Id>> parentToChildMap = getParentToChildAccountMap();
        system.debug('**** parent to child account map '+parentToChildMap);
		for(Opportunity opp : opportunities) {
			Set<String> opportunityAccountIds = new Set<String>();
            if (opp.DoNotUseAccountHierarchy__c == false){
				getOpportunityAccountListRecursive(parentToChildMap,opportunityAccountIds,opp.accountId);
            }
			if (relatedChildAccountsMap.containsKey(opp.accountId)) {
				Set<Id> accountIds = relatedChildAccountsMap.get(opp.accountId);
				if (accountIds != null) {
					for (Id nextRelatedAccountId : accountIds) {
						opportunityAccountIds.add(nextRelatedAccountId);
					}
				}
			}
			opportunityAccountList.put(opp.id,setToCSV(opportunityAccountIds));
		}
		return opportunityAccountList;
	}

	private void getOpportunityAccountListRecursive(Map<id,Set<Id>> parentToChildAccountMap, Set<String> opportunityAccountIds, id accountId) {
		if (opportunityAccountIds.contains(accountId)) return;
        opportunityAccountIds.add(accountId);
		if (parentToChildAccountMap.containsKey(accountId)) {
				Set<Id> accountIds = parentToChildAccountMap.get(accountId);
				if (accountIds != null) {
					for (Id nextChildAccountId : accountIds) {
                    	getOpportunityAccountListRecursive(parentToChildAccountMap, opportunityAccountIds,nextChildAccountId);
					}
				}
			}
	}
     
 
	public static String setToCSV(Set<String> stringList) {
		if (stringList == null || stringList.isEmpty()) {
			return '';
		}
 		return String.join(stringList, ',');
	}
 
	public static List<String> csvToList(String csvString) {
		if (String.isBlank(csvString)) {
			return new List<String>();
		}
		return csvString.split(',');
	}

	// ***** PRIVATE METHODS ******* //
	private Set<Id> loadOpportunityAccounts(List<Opportunity> opportunities) {
		Set<Id> accountIds = new Set<Id>();

		for(Opportunity opp : opportunities) {
			// get the primary opportunity account ids
			accountIds.add(opp.AccountId);
			system.debug('all accounts accountIds'+accountIds);
			// if the opportunity specifies revenue accounts, load these as related accounts
            if(!string.isBlank(opp.RevenueCalculationAccountIDs__c)) {
                if (!relatedChildAccountsMap.containsKey(opp.accountId)) {
                    relatedChildAccountsMap.put(opp.accountId, new Set<id>());
                }
                for(String specifiedAccountId : csvToList(opp.RevenueCalculationAccountIDs__c)) {
                    accountIds.add(specifiedAccountId);
                    relatedChildAccountsMap.get(opp.accountId).add(specifiedAccountId);
                }
                system.debug('***** added the following revenue calculation account ids to related accounts '+relatedChildAccountsMap.get(opp.accountId) );
            }
		}
		// collect related accounts
		return LoadAccountsAndRelatedAccounts(accountIds);
	}

	private static double fytotal(GroupedAccountProductRevenue__c record) {
		if (record==null) {
			return 0;
		} 
		return 
        (record.Rev1__c == null ? 0 : record.Rev1__c) +
		(record.Rev2__c == null ? 0 : record.Rev2__c) + 
		(record.Rev3__c == null ? 0 : record.Rev3__c) + 
		(record.Rev4__c == null ? 0 : record.Rev4__c) + 
		(record.Rev5__c == null ? 0 : record.Rev5__c) + 
		(record.Rev6__c == null ? 0 : record.Rev6__c) + 
		(record.Rev7__c == null ? 0 : record.Rev7__c) + 
		(record.Rev8__c == null ? 0 : record.Rev8__c) + 
		(record.Rev9__c == null ? 0 : record.Rev9__c) + 
		(record.Rev10__c == null ? 0 : record.Rev10__c) + 
		(record.Rev11__c == null ? 0 : record.Rev11__c) + 
		(record.Rev12__c == null ? 0 : record.Rev12__c); 
	}
    
    private static double fytotal(Budget_and_Revenue__c record) {
		if (record==null) {
			return 0;
		} 
		return 
        (record.Dec_Revenue_Amount__c == null ? 0 : record.Dec_Revenue_Amount__c) +
		(record.Jan_Revenue_Amount__c == null ? 0 : record.Jan_Revenue_Amount__c) + 
		(record.Feb_Revenue_Amount__c == null ? 0 : record.Feb_Revenue_Amount__c) + 
		(record.Mar_Revenue_Amount__c == null ? 0 : record.Mar_Revenue_Amount__c) + 
		(record.Apr_Revenue_Amount__c == null ? 0 : record.Apr_Revenue_Amount__c) + 
		(record.May_Revenue_Amount__c == null ? 0 : record.May_Revenue_Amount__c) + 
		(record.Jun_Revenue_Amount__c == null ? 0 : record.Jun_Revenue_Amount__c) + 
		(record.Jul_Revenue_Amount__c == null ? 0 : record.Jul_Revenue_Amount__c) + 
		(record.Aug_Revenue_Amount__c == null ? 0 : record.Aug_Revenue_Amount__c) + 
		(record.Sep_Revenue_Amount__c == null ? 0 : record.Sep_Revenue_Amount__c) +  
		(record.Oct_Revenue_Amount__c == null ? 0 : record.Oct_Revenue_Amount__c) + 
		(record.Nov_Revenue_Amount__c == null ? 0 : record.Nov_Revenue_Amount__c)  ; 
	}

	public static Decimal calculateTotalInYearRevenue(Date contractStartDate, Date contractEndDate, Decimal totalPrice) {
		if (contractStartDate == contractEndDate) {
			return totalPrice;
		}
		Date today = Date.today();
        system.debug('**** today '+today);
		Date fiscalYearEnd = Date.newInstance(today.year(), 6, 30);
        system.debug('**** fiscalYearEnd '+fiscalYearEnd);
		Date nextFiscalYearEnd = Date.newInstance(today.year() + 1, 6, 30);
		system.debug('**** nextFiscalYearEnd '+nextFiscalYearEnd);
		Date effectiveEndDate = contractEndDate <= fiscalYearEnd ? contractEndDate : (contractStartDate > fiscalYearEnd ? fiscalYearEnd : nextFiscalYearEnd);
		system.debug('**** effectiveEndDate '+effectiveEndDate);
        Date effectiveStartDate = contractStartDate >= fiscalYearEnd ? contractStartDate : (contractEndDate < fiscalYearEnd ? fiscalYearEnd : today);
		system.debug('**** effectiveStartDate '+effectiveStartDate);
		Decimal totalDays = Decimal.valueOf(contractStartDate.daysBetween(contractEndDate) + 1);
		system.debug('**** totalDays '+totalDays);
        Integer effectiveDays = effectiveStartDate.daysBetween(effectiveEndDate) + 1;
		system.debug('**** effectiveDays '+effectiveDays);
		return totalDays == 0 ? totalPrice : effectiveDays /totalDays * totalPrice;
	}
 
 
	/**
	* @description Creates a new grouped revenue record for the specified uid.
	* @param uid - t he unique identifier consisting of the account id, product id and financial year of the record
	* @return a new grouped revenue record for the specified uid.
	* */
	private static GroupedAccountProductRevenue__c createGroupedRevenueFromUID(String uid) {
		if (uid == null || uid.length() != 34) {
			throw new IllegalArgumentException('Invalid UID format. It should be exactly 34 characters.');
		}
		GroupedAccountProductRevenue__c newRecord = new GroupedAccountProductRevenue__c(
		AnchorOrganisation__c = uid.substring(0, 15),
		PrimaryProduct__c = uid.substring(15,30),
		FinancialYear__c = integer.valueOf(uid.substring(30, 34)),
		uid__c = uid);
		return newRecord;
	}
 

	/**
	* @description Applies business rules for the revenue calculation starting date to be used for a particular line item
	* @param item The opportunity line item to determine the revenue caclulation starting date for
	* @return the calculation revenue starting date to be used.
	* */
	public Date getDateToUse(OpportunityLineItem item) {
		//If the pre-entry scenario checkbox has been ticked, then use the Contract Start Date of the Line Item
		Opportunity recordOpportunity = this.opportunityInfo.get(item.opportunityid);
		if (item.opportunity.Pre_Entry__c == true && item.Contract_Start_Date__c != null) { 
            system.debug(' using item.contract_start_date '+ item.Contract_Start_Date__c);
			return item.Contract_Start_Date__c;
		}
		//If the pre-entry scenario checkbox is unticked, then use the Close Date of the opportunity. 
		if (recordOpportunity.Pre_Entry__c == false && recordOpportunity.StageName == OPPORTUNITY_CLOSED_WON) { 
            system.debug(' using opportunity close date of '+recordOpportunity.CloseDate);
			return recordOpportunity.CloseDate;
		}
		// a default date to use
	    system.debug(' using revenueCalculationContextDate of '+revenueCalculationContextDate);
		return revenueCalculationContextDate;
	}
 
	// Returns a map of updated budget and revenue records that result in the need to update grouped revenue record values
	// this is only the case for revenue type records for the current financial year and month
	private Map<String,Budget_and_Revenue__c> getRevenuesToProcess(List<Budget_and_Revenue__c> records,Map<Id,Budget_and_Revenue__c> existingRecords) {
		Map<String,Budget_and_Revenue__c> requiresProcessing = new Map<String,Budget_and_Revenue__c>();
		for (Budget_and_Revenue__c currentRecord :records) {
			// Only customer revenue records in the same financial year as the context date (by default, todays date) are considered.
			integer currentFY = getAustralianFinancialYear(revenueCalculationContextDate);
			// Only revenue type customer revenue records are applied to the grouped revenue records
			if (currentRecord.Transaction_Type__c == TRANSACTION_TYPE_REVENUE && currentRecord.Financial_Year__c == String.valueOf(currentFY)) {
				// Retrieve the original value for the current month to see if it has changed. If this is a new record, then the original value is deemed 0.
				Double priorValue = existingRecords == null ? 0 : getValueForMonth(existingRecords.get(currentRecord.Id),revenueCalculationContextDate.month());
				// if the budget and revenue record is of type revenue and the current month value has changed,
				// this change needs to be applied to the grouped revenue records.
				if (getValueForMonth(currentRecord,revenueCalculationContextDate.month()) != priorValue) {
					requiresProcessing.put(currentRecord.uid__c,currentRecord);
				}
			}
		}
		return requiresProcessing;
	}



	// syncronises grouped revenue records with changes to budget and revenue records for the current month
	// changes to prior months are ignored
	private Map<String,GroupedAccountProductRevenue__c> updateGroupedRevenues(Map<String,Budget_and_Revenue__c> revenuesToProcess, Map<Id,Budget_and_Revenue__c> existingRecords) {

		// track Grouped revenue records that have been updated by the budget and revenue record changes
		Map<String,GroupedAccountProductRevenue__c> updatedGroupedRevenues = new Map<String,GroupedAccountProductRevenue__c>();

		// specifies the cascading change in value to the current month 
		// that needs to be applied to a record and all its parent records
		Map<String,Double> unprocessedGroupRevenueAdjustments = new Map<String,Double>();

		// tracks products associated with the budget and revenue record that will have to be added to a parent grouped product sales record.
		// even if a parent account does not trade this product, the grouped revenue record must still account for the trade
		Set<Id> unprocessedProductIds = new Set<Id>();

		// tracks the parent accounts associated with the budget and revenue record
		// so that all grouped revenues of all parent accounts are also updated
		Set<Id> unprocessedAccountIds = new Set<Id>();

		// get the collection of account and product ids associated with the updated budget and revenue records
		for (Budget_and_Revenue__c unprocessedRecord : revenuesToProcess.values()) {
			if(!groupedRevenues.containsKey(unprocessedRecord.uid__c)) {
				unprocessedProductIds.add(unprocessedRecord.Product__c);
				unprocessedAccountIds.add(unprocessedRecord.Organisation__c);
			}
		}

		// get any replacement products associated with the budget and revenue updates
		// loadProductReplacementMap(unprocessedProductIds); Commented Out: replacement products not currently supported

		// load account hierarchy for the cascade updates
		loadChildToParentAccountMap(unprocessedAccountIds);

		// load related child accounts (these are manually added relationships that lie outside the standard account hierarchy)
		loadRelatedChildAccountMap(unprocessedAccountIds);
        

		// convert related child accounts to related parent accounts. When cascade uupdating grouped records, we are interested
		// in updating the parents.
		Map<Id,Id> relatedParentAccount = getRelatedParentAccountMap();
		// takes reassigned accounts out of the standard parent heirarchy
		set<id> reassignedAccountIds = getRelatedChildAccountIds();
		// calculate required updates
		for (Budget_and_Revenue__c record : revenuesToProcess.values()) {
			// we are only updating the revenue schedules for the current month
			Integer currentMonth = revenueCalculationContextDate.month();
			// calculate the change in the budget and revenue value
			Double priorValue = existingRecords == null ? 0 : getValueForMonth(existingRecords.get(record.Id),currentMonth);
			Double valueChange = getValueForMonth(record,currentMonth) - priorValue;
			// the account and product associated with this budget and revenue record
			Id AccountId = record.Organisation__c;
			Id productId = record.Product__c;
			// Track the adjustments that need to be made to group revenue records
			// update to parent account heirarchy
			appendGroupRevenueAdjustmentToParentsRecursively(AccountId,productId,valueChange,unprocessedGroupRevenueAdjustments,reassignedAccountIds);
			// update to related parent account grouped revenue
			if (relatedParentAccount.containsKey(AccountId) && relatedParentAccount.get(AccountId) != null) {
				// The adjustment to the related account to the current account. Only the immediate related account is adjusted.
				appendGroupRevenueAdjustment(relatedParentAccount.get(AccountId),productId,valueChange,unprocessedGroupRevenueAdjustments);
			}
		}

		// Retrieve matching grouped revenue records from the db which require updating
		loadGroupedProductRevenues(unprocessedGroupRevenueAdjustments.keySet());
		Integer currentMonth = revenueCalculationContextDate.month();
		// apply adjustments to grouped revenues
		for (String groupRevenueKey : unprocessedGroupRevenueAdjustments.keySet()) {
			if (!this.groupedRevenues.containsKey(groupRevenueKey)) {
				this.groupedRevenues.put(groupRevenueKey,null);
			}
			GroupedAccountProductRevenue__c revenueToBeAdjusted = this.groupedRevenues.get(groupRevenueKey);
			Double adjustment = unprocessedGroupRevenueAdjustments.get(groupRevenueKey);
			if (revenueToBeAdjusted == null) {
				revenueToBeAdjusted = createGroupedRevenueFromUID(groupRevenueKey);
				setValueForMonth(revenueToBeAdjusted,currentMonth,adjustment);
			} else {
				Double currentValue = getValueForMonth(revenueToBeAdjusted,currentMonth);
				setValueForMonth(revenueToBeAdjusted,currentMonth,currentValue+adjustment);
			}
			if (!updatedGroupedRevenues.containsKey(groupRevenueKey)) {
				updatedGroupedRevenues.put(groupRevenueKey,revenueToBeAdjusted);
			}
		}
		// pass back the updated group revenue records.
		return updatedGroupedRevenues;
	}
    
 
	private set<id> getRelatedChildAccountIds() {
		set<id> relatedAccountIds = new set<id>();
        system.debug('************ relatedChildAccountsMap '+relatedChildAccountsMap);
		for (id nextRelatedAccountId : relatedChildAccountsMap.keyset()) {
            Set<id> relatedAccountsToAdd = relatedChildAccountsMap.get(nextRelatedAccountId);
            if (relatedAccountsToAdd != null) {
                relatedAccountIds.addAll(relatedAccountsToAdd);
            }
		}
		return relatedAccountIds;
	}
	
	// adjusts the revenue up the parent account heirarchy
	private void appendGroupRevenueAdjustmentToParentsRecursively(Id AccountId, Id productId, Double valueChange,Map<String,Double> unprocessedGroupRevenueAdjustments, set<id> reassignedAccountIds) {
		// don't apply values that belong to an account whose hierarchy has been reassigned to some other account
		if (! reassignedAccountIds.contains(AccountId)) {
			appendGroupRevenueAdjustment(AccountId,productId,valueChange,unprocessedGroupRevenueAdjustments); 
		}
		if (childToParentAccountMap.containsKey(AccountId) && childToParentAccountMap.get(AccountId) != null) {
			// the adjustment to the parent of the current account
			id parentAccountId = childToParentAccountMap.get(AccountId);
			appendGroupRevenueAdjustmentToParentsRecursively(parentAccountId,productId,valueChange,unprocessedGroupRevenueAdjustments,reassignedAccountIds);
		}
	}
 
 
	// tracks revenue adjustments
	private void appendGroupRevenueAdjustment(Id AccountId, Id productId, Double valueChange,Map<String,Double> unprocessedGroupRevenueAdjustments) {
		Integer currentFY = getAustralianFinancialYear(revenueCalculationContextDate);
		String uniqueId = getUID(AccountId,productId,String.valueOf(currentFY));
		if (!unprocessedGroupRevenueAdjustments.containsKey(uniqueId)) {
			unprocessedGroupRevenueAdjustments.put(uniqueId,0);
		}
		unprocessedGroupRevenueAdjustments.put(uniqueId,unprocessedGroupRevenueAdjustments.get(uniqueId)+valueChange);
	}

	/**
	* Updates the retained and incremental revenue fields for a given OpportunityLineItem record.
	* based on the historical sales value.
	* @param record The OpportunityLineItem object to be updated.
	* @param pastSales The sales amount for the past twelve months for the account and product related to the record.
	*/
	private void updateRetainedIncrementalContractPeriod(OpportunityLineItem record, Double pastSales) {
		// Calculations will be based on contract days.
		Integer contractDays = contractDays(record);
		// the value of the opportunity line item over its contract period
		updateRetainedIncremental(record, pastSales, contractDays);
	}

	/**
	* Updates the retained and incremental revenue fields for a given OpportunityLineItem record based on annualized value
	* @param record The OpportunityLineItem object to be updated.
	* @param pastSales The sales amount for the past twelve months for the account and product related to the record.
	*/
	private void updateRetainedIncrementalAnnualised(OpportunityLineItem record, Double pastSales) {
		// Calculations will be based on contract days.
		Integer contractDays = contractDays(record);
		// Annualize values based on contract days
		if (contractDays > DAYS_IN_YEAR) {
			contractDays = DAYS_IN_YEAR;
		}
		// the value of the opportunity line item over its contract period
		updateRetainedIncremental(record, pastSales, contractDays);
	}

	/**
	* Updates the retained and incremental revenue fields for a given OpportunityLineItem record. based on the historical sales value.
	* @param record Th-------e OpportunityLineItem object to be updated.
	* @param pastSales The sales amount for the past twelve months for the account and product related to the record.
	* @param contractDays contractDays
	*/
	private void updateRetainedIncremental(OpportunityLineItem record, Double pastSales, Integer contractDays) {
		// sales for the past twelve months
		record.TweleveMonthRevenue__c = pastSales;
        double correctedSales = pastSales < 0 ? 0 : pastSales;
		// calculate retained and incremental based on the sales history 
        if (record.Annualised_Value__c > correctedSales) {
            // sales of the contract exceed historical sales.
            // The retained revenue will be based on sales history
            record.RetainedRevenue__c = correctedSales;
            // The incremental revenue will be the contract value in excess of sales history
            record.IncrementalRevenue__c = record.Annualised_Value__c - correctedSales;
        } else {
            // sales of the contract are less or equal to the sales history.
            // Only retained value applies, and is equal to the total value of the contract.
            record.RetainedRevenue__c = record.Annualised_Value__c;
            record.IncrementalRevenue__c = 0;
        } 
    }

	/**
	* Calculates the duration of a contract in days for a given OpportunityLineItem record.
	* @param record The OpportunityLineItem object whose contract duration is to be calculated.
	* @return Integer representing the contract duration in days. Returns a minimum of 1 day if the
	* calculated duration is zero.
	*/
	private Integer contractDays(OpportunityLineItem record) {
		Integer contractDays = record.Contract_Start_Date__c.daysBetween(record.Contract_End_Date__c)+1;
		return contractDays; // == 0 ? 1 : contractDays;
	}

	/**
	* @description 	Recalculate Grouped Revenues for opportunity line items
	* @param 			items a list of opportunity line items to recalculate grouped revenues for
	* @return A list of Grouped Revenue records which have been created or modified.
	*/
	@TestVisible
	private Map<String ,GroupedAccountProductRevenue__c> reCalculateGroupRevenues(List<OpportunityLineItem> items, boolean useDefaultDate) {
		// get the uids for the budget and revenue records that will be needed
		Set<String> uids = getCreateGroupedRevenues(items, useDefaultDate,YEARS_HISTORY,false);
		system.debug('***** uids for items for use in retrieving budget and revenue records '+uids);
		Map<String,GroupedAccountProductRevenue__c> updatedRevenueRecords = new Map<String,GroupedAccountProductRevenue__c>(); 
		// add related and child accounts to the uids to retrieve budget and revenue records
		uids.addAll(configureProductAccountMaps(items, useDefaultDate));
		// get all relevant budget and revenue records
		loadBudgetAndRevenueRecords(uids);
        system.debug('*** have budget and revenue records '+budgetAndRevenues.values());
		// reconfigure account and product maps
		Map<Id,Set<Id>> parentToChildAccountMap = getParentToChildAccountMap();
		for(OpportunityLineItem item : items) {
            system.debug('***** recalculating grouped revenues for item '+ item);
            system.debug('***** useDefaultDate'+ useDefaultDate);
			Date dateToUse = useDefaultDate ? revenueCalculationContextDate : getDateToUse(item);
			Integer currentFY = getAustralianFinancialYear(dateToUse);
            system.debug('******* currentfy '+currentFY);
			opportunity recordOpportunity = opportunityInfo.get(item.opportunityId);
			List<String> accountRestriction = csvToList(recordOpportunity.RevenueCalculationAccountIDs__c);
			for (Integer year = currentFY-YEARS_HISTORY; year <currentFY+1; year++) {
                String revenueKey = getUID(recordOpportunity.AccountId, item.Product2Id, String.valueOf(year));
				system.debug('**** getting grouped revenue record for uid '+revenueKey);
                // retrieve the grouped revenue records for this item
				GroupedAccountProductRevenue__c currentGroupedRevenue =groupedRevenues.get(revenueKey);
                system.debug('**** got grouped revenue '+ currentGroupedRevenue);
				// update the current group revenue figures only in the case that
				// (1) the revenue record is new (doesn't exist) or the revenue record is not more than YEARS_HISTORY FY ago.
                system.debug('**** updating grouped revenue '+ currentGroupedRevenue);
                // zero the values in the revenue record
                zeroRevenueValue(currentGroupedRevenue);
                // don't add the revenue record for update / insert unless it is a new record or has budget and revenue data applied to it
                Boolean isUpdated = currentGroupedRevenue.id == null ? true: false;
                // add current budget and revenue values
                Set<String> childRevenueKeys = new Set<String>{currentGroupedRevenue.uid__c};
                    if (addRevenueValues(currentGroupedRevenue)) {
                        isUpdated = true;
                    }
                // add records for child accounts from the Hierarchy
                if (!recordOpportunity.DoNotUseAccountHierarchy__c) {
                    addChildAccountRevenueRecursive(item.Opportunity.AccountId,item.Product2.Id,String.valueOf(year),currentGroupedRevenue,parentToChildAccountMap,accountRestriction,childRevenueKeys);
                    if (childRevenueKeys.size() > 0) {
                        isUpdated = true;
                    }
                }
                // records for related accounts from the AccountRelationship Object
                Set<Id> relatedAccounts = relatedChildAccountsMap.containsKey(recordOpportunity.AccountId) // AR contains the parent as keys
                    && relatedChildAccountsMap.get(recordOpportunity.AccountId) != null // the children records exist
                    ? relatedChildAccountsMap.get(recordOpportunity.AccountId) : new Set<Id>();
                system.debug('**** relatedAccounts '+relatedAccounts);
                system.debug('**** childRevenueKeys '+childRevenueKeys);
                for (Id relatedAccountId : relatedAccounts) {
                    // adhere to restrictions on accounts to include and don't double up on related accounts that are also child accounts.
                    if(accountRestriction.isempty() || accountRestriction.contains(relatedAccountId)) {
                        String relatedAccountRevenueKey = getUID(relatedAccountId,item.Product2.Id,String.valueOf(year));
                        if(!childRevenueKeys.contains(relatedAccountRevenueKey)) {
                            if (addRevenueValues(currentGroupedRevenue,relatedAccountRevenueKey)) {
                                childRevenueKeys.add(relatedAccountRevenueKey);
                                isUpdated = true;
                            }
                        }
                    }
                }
                system.debug('*** isUpdated = '+isUpdated);
                if (isUpdated) {
                    updatedRevenueRecords.put(currentGroupedRevenue.UID__c,currentGroupedRevenue);
                }
                    
				
			}
		}
		return updatedRevenueRecords;
	}



	/**
	* Retrieves and creates Revenue Records for a list of Opportunity Line Items for a specified number of years. 
	* Existing grouped revenue records are not refreshed against current budget and revenue records.
	* New grouped revenue recordes will need to be populated with current budget and revenue records.
	* @param items A List of `OpportunityLineItem` objects for which the Grouped Revenue Records need to be created or retrieved.
	* @return Set<String> uids loaded or created.
	* loaded and created grouped revenues are stored locally in groupedRevenues
	*/
	private Set<String> getCreateGroupedRevenues(List<OpportunityLineItem> items, boolean useDefaultDate, integer numberOfYears, boolean includeRelatedAccounts) {
		// retrieve any existing grouped account product revenue records so the schedules can link to them.
		// the uids for revenue records that will be required
		Set<String> uids = new Set<String>();
		// ensure opportunityInfo is loaded for the opportunities
		loadOpportunityInfoForOpportunityLineItems(items);
		// work out what revenue records we need
		for (OpportunityLineItem nextItem : items) {
			Date targetDate = useDefaultDate ? revenueCalculationContextDate : getDateToUse(nextItem);
			// the start and end financial years to retrieve revenue records for this item
			Integer startYear = targetDate.month() - 1 >= FINANCIAL_YEAR_STARTING_MONTH ? targetDate.year() + 1 : targetDate.year();
			Integer endYear = nextItem.Contract_End_Date__c.month() >= 7 ? nextItem.Contract_End_Date__c.year() + 3 : nextItem.Contract_End_Date__c.year() + 2;
			// opportunity information for the current product line item
			Opportunity oppInfo = opportunityInfo.get(nextItem.opportunityId);
			// construct revenue record uids for the required years.
			for (Integer year = startYear-numberOfYears; year <= endYear+1; year++) {
				uids.add(getUID(oppInfo.AccountId, nextItem.Product2Id, String.valueOf(year)));
			}
		}
		// this requires that related acconts were previously loaded
		if (includeRelatedAccounts) {
		uids.addAll(configureProductAccountMaps(items,useDefaultDate));
		}
		// try loading the grouped revenues from the db whch have not yet been loaded. These will
		// be stored in the groupedRevenue map after this call.
		loadGroupedProductRevenues(uids);
		// the groupedrevenue map now contains a map of all uids requested. any requested
		// grouped revenue record that was not in the database will be a null entry in the map.
		// replace these null entries with the newly created records above.
		for (String uid : uids) {
            if (groupedRevenues.get(uid) == null) {
                groupedRevenues.put(uid,createGroupedRevenueFromUID(uid));
            }
		}
		// return all relevant uids for the revenue records needed for the line items passed in. 
		return uids;
	}
 

	/**
	* @description Load related accounts and their hierarchical relationships
	* @param accountIds Set<Id>
	* @return A set of unique record identifiers for use in retrieving associated budget and revenue records
	*/
	private Set<Id> LoadAccountsAndRelatedAccounts(Set<Id> accountIds) {
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
        system.debug('all accounts after load '+allAccounts);
		return allAccounts;
	}

	/**
	* Configures and returns a set of UIDs for related and child accounts based on opportunity line items.
	* @param items A list of OpportunityLineItem objects to process.
	* @return A set of UIDs representing parent and related accounts.
	*/
	private Set<String> configureProductAccountMaps(List<OpportunityLineItem> items, boolean useDefaultDate) {
		Set<String> relatedUIDs = new Set<String>();
		Map<Id,Set<Id>> parentToChildAccountMap = getParentToChildAccountMap();

		for(OpportunityLineItem item : items) {
			Date dateToUse = useDefaultDate ? revenueCalculationContextDate : getDateToUse(item);
			Set<Id> relatedAccounts = relatedChildAccountsMap.containsKey(item.Opportunity.AccountId) && relatedChildAccountsMap.get(item.Opportunity.AccountId) !=null ? relatedChildAccountsMap.get(item.Opportunity.AccountId) : new Set<Id>();
			Integer currentFY = getAustralianFinancialYear(dateToUse);
			for (Integer year = currentFY-1; year <currentFY+1; year++) {
				// records for child accounts
				addChildAccountRevenueUIDsRecursive(item.Opportunity.AccountId,item.Product2.Id, String.valueOf(year), parentToChildAccountMap, relatedUIDs);
				//records for any related accounts and their children
				for (Id relatedAccountId : relatedAccounts) {
					relatedUIDs.add(getUID(relatedAccountId,item.Product2.Id,String.valueOf(year)));
					// addChildAccountRevenueUIDsRecursive(relatedAccountId,item.Product2.Id, String.valueOf(year), parentToChildAccountMap, relatedUIDs);
				}
			}
		}
		return relatedUIDs;
	}


	
	/**
	* @param monthValue i.e. the revenue value for the month
	* @return the partial or full revenue for the month base on the revenueCalculationContextDate
	*/
	private Double calculatePartialMonthValue(Double monthValue) {
		return (1 - revenueCalculationContextDate.day() / Date.daysInMonth(revenueCalculationContextDate.year(), revenueCalculationContextDate.month())) * monthValue;
	}


	/**
	* @description 	adds the actual sales record matching a revenue key to the passed in grouped revenue record.
	* @param 			summaryRecord - the grouped revenue record for a specified account and product
	* @param 			revenueKey - the budget and revenue record (actual sales) to add to the summary.
	* @return 	true if the sales history record was found.
	*/
	private Boolean addRevenueValues(GroupedAccountProductRevenue__c summaryRecord, String revenueKey) {
		system.debug('*** Modifying grouped account product revenue with key '+revenueKey);
        if (!budgetAndRevenues.containsKey(revenueKey)) {
			return false;
		}
		Budget_and_Revenue__c recordToAdd = budgetAndRevenues.get(revenueKey);
		if (recordToAdd == null) {
			return false;
		}
        system.debug('*** adding in the budget and revenue record '+revenueKey);
		for (Integer i = 1; i<13; i++) {
			Double summaryValue = getValueForMonth(summaryRecord,i);
			Double valueToAdd = getValueForMonth(recordToAdd,i);
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
	* @return 	true if the sales history record was found.
	*/
	private void addChildAccountRevenueRecursive(Id parentAccountId,Id productId, String year, GroupedAccountProductRevenue__c currentGroupedRevenue, Map<Id,Set<Id>> parentToChildAccountMap, List<String> accountRestriction, set<string> childRevenueKeys) {
		if (!parentToChildAccountMap.containsKey(parentAccountId)) {
			return;
		}
		Set<Id> childAccounts = parentToChildAccountMap.get(parentAccountId);
		if (childAccounts == null) {
			return;
		}
		// records for child accounts of item account
		for (Id childAccountId : childAccounts) {
			if (accountRestriction.isEmpty() || accountRestriction.contains(childAccountId)) {
				String currentRevenueKey = getUID(childAccountId,productId, year);
				if(addRevenueValues(currentGroupedRevenue,currentRevenueKey)) {
					childRevenueKeys.add(currentRevenueKey);
				}
			}
			addChildAccountRevenueRecursive(childAccountId,ProductId,year,currentGroupedRevenue,parentToChildAccountMap,accountRestriction,childRevenueKeys);
		}
	}

	/**
	* @description 	Retrieve budget and revenue records from the database based on uniqueids.
	* @param 			uniqueIds - the unique ids for the revenue recrods that are to be retrieved
	* @return 	populates the global budget and revenue map (lazy loading)
	*/
	private void loadBudgetAndRevenueRecords(Set<String> uniqueIds) {
		// Only load this data from the DB once
		system.debug('**** requested customer revenue uids '+uniqueIds);
		Set<String> unloadedIds = new Set<String>();
		for (String uniqueId : uniqueIds) {
			if (!budgetAndRevenues.containsKey(uniqueId)) {
				unloadedIds.add(uniqueId);
				budgetAndRevenues.put(uniqueId,null);
			}
		}
        system.debug('**** unloadedIds '+unloadedIds);
		if(unloadedIds.isEmpty()) {
			return;
		}
		// populate unloaded budget and revenue records
		for (Budget_and_Revenue__c currentBudget : BudgetAndRevenueSelector.newInstance().selectByUniqueIds(unloadedIds).values()) {
            system.debug('**** adding to budget '+currentBudget);
			budgetAndRevenues.put(currentBudget.uid__c, currentBudget);
		}
	}

    	/**
	* @description 	Retrieve budget and revenue records from the database based on accounts.
	* @param 	accountIds - the accounts for the revenue recrods that are to be retrieved
	* @return 	populates the global budget and revenue map (lazy loading)
	*/
	private void loadBudgetAndRevenueRecordsForAccounts(Set<Id> accountIds) {
		// Only load this data from the DB once
		Set<Id> unloadedIds = new Set<Id>();
		for (String accountId : accountIds) {
			if (!revenueLoadedForAccountIds.contains(accountId)) {
				unloadedIds.add(accountId);
				revenueLoadedForAccountIds.add(accountId);
			}
		}
		if(unloadedIds.isEmpty()) {
			return;
		}
		// populate unloaded budget and revenue records
		for (Budget_and_Revenue__c currentBudget : BudgetAndRevenueSelector.newInstance().selectByOrganisationId(unloadedIds,getHistoricalYears())) {
			budgetAndRevenues.put(currentBudget.uid__c, currentBudget);
		}
	}

	private Set<String> getHistoricalYears() {
	    Set<String> yearsSet = new Set<String>();
	    
	    // Calculate the starting year
	    Integer startYear = revenueCalculationContextDate.year() - YEARS_HISTORY;
	    
	    // Populate the set with each year in the history period
	    for (Integer i = 0; i <= YEARS_HISTORY; i++) {
	        Integer year = startYear + i;
	        yearsSet.add(String.valueOf(year));
	    }
	    
	    return yearsSet;
	}
    
    
	/**
	* @description 	Retrieve opportunities associated with opportunity line items.
	* @param 			items - The opportunityLineItems that require additional opportunity information
	* @return 	populates the global oportunityinfo map (lazy loading)
	*/
	public void loadOpportunityInfoForOpportunityLineItems(List<opportunityLineItem> items) {
		// collect the opportunityids to load 
		Set<id> opportunityIds = new Set<Id>(); 
		for(opportunitylineitem item : items) {
			// only load this information once
			if (!this.opportunityInfo.containsKey(item.opportunityid) || this.opportunityInfo.get(item.opportunityid) == null) {
				opportunityIds.add(item.opportunityid);
			}
		}
		// load based on opportunity ids
		if (!opportunityIds.isEmpty()) {
			loadOpportunityInfo(opportunityIds);
		}
	}
	
	/**
	* @description 	Retrieve opportunities based on opportunity ids.
	* @param 			opportunityIds - The opportunity ids to retrieve
	* @return 	populates the global oportunityinfo map (lazy loading)
	*/
	public Map<Id,Opportunity> loadOpportunityInfo(Set<Id> opportunityIds) {
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
		Opportunity.SObjectType => new Set<SObjectField> { 
			Opportunity.Name,Opportunity.AccountId,Opportunity.Id,Opportunity.StageName,Opportunity.DoNotUseAccountHierarchy__c, Opportunity.CloseDate, Opportunity.Pre_Entry__c, Opportunity.RevenueCalculationAccountIDs__c}
		};
		Map<Id,Opportunity> loadedItems = OpportunitySelector.newInstance(1, fieldOverrides).selectById(opportunityIds);
		for (Opportunity item : loadedItems.values()) {
			this.opportunityInfo.put(item.Id, item);
		}
		return loadedItems;
	}
    
 
	/**
	* @description 	Retrieve grouped revenue schedules for specified line item ids.
	* @param 			lineItemIds - The opportunity line item ids assocaited with the schedules.
	* @return 	a list of grouped revenue schedules assocaited with the line items
	*/
	public static List<GroupedRevenueSchedule__c> getRevenueScheduleForLineItems(Set<String> lineItemIds) {
		return GroupedRevenueScheduleSelector.newInstance().selectByOpportunityProductIds(lineItemIds, null);
	}


	/**
	* @description 	Retrieve accounts that have manually been reparented through the account relationship junction object.
	* @param 			parentAccountsToInclude - The parent account ids that any related accounts are linked to
	* @return 	a set of ids representing the related accounts loaded into the global related account map data object. 
	*/
	private Set<Id> loadRelatedChildAccountMap(Set<Id> parentAccountsToInclude) {
		Set<Id> loadedRelatedAccountIds = new Set<Id>();
		if ( parentAccountsToInclude==null || parentAccountsToInclude.isEmpty()) {
			return loadedRelatedAccountIds;
		}
		// do not reload related accounts for accounts that have already been loaded
		Set<Id> unloadedAccountIds = getUnloadedRelatedAccountIds(parentAccountsToInclude);
		if (unloadedAccountIds.isEmpty()) {
			return loadedRelatedAccountIds;
		}
		
		// retrieve any manually liked related accounts and place them into the global related account map.
		for (AccountRelationship__c arr: AccountRelationshipSelector.newInstance().selectByOPCParentEndDateInFuture(unloadedAccountIds)) {
            if(arr.ParentAccount__c != null && arr.RelatedAccount__c != null) {
                if (!relatedChildAccountsMap.containsKey(arr.ParentAccount__c) || relatedChildAccountsMap.get(arr.ParentAccount__c)== null) {
                    system.debug('**** arr '+arr);
                    relatedChildAccountsMap.put(arr.ParentAccount__c, new Set<Id>{arr.RelatedAccount__c});
                } else {
                    system.debug('arr '+arr);
                    system.debug('arr.ParentAccount__c '+arr.ParentAccount__c );
                    system.debug('arr.RelatedAccount__c '+arr.RelatedAccount__c);
                    system.debug('relatedChildAccountsMap.get(arr.ParentAccount__c) '+relatedChildAccountsMap.get(arr.ParentAccount__c));
                    relatedChildAccountsMap.get(arr.ParentAccount__c).add(arr.RelatedAccount__c);
                }
            }
			loadedRelatedAccountIds.add(arr.RelatedAccount__c);
		}
		return loadedRelatedAccountIds;
	}
 
	/**
	* @description 	Returns accountids that have not had their related accounts loaded yet.
	* @param 			accountsToLoad - The accounts for which related accounts are to be loaded
	* @return 	a set of ids representing the accounts for which related accounts have not yet been queried. 
	*/
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

	/**
	* @description 	loads the childAccountIds set plus all the children of those accounts down to five levels
	* @param 			accountIds - The accounts for which child accounts are to be loaded
	* @return 	a set of ids representing the accounts for which child accounts have been loaded into the global child to parent account map. 
	*/
	private Set<Id> loadChildToParentAccountMap(Set<Id> accountIds) {
		Set<Id> unloadedAccountIds = new Set<Id>();
		if ( accountIds==null || accountIds.isEmpty()) {
			return unloadedAccountIds;
		}
		// retrieve account ids that have not yet had the hierarchy loaded
		unloadedAccountIds = getUnloadedChildAccounts(accountIds);
		if (unloadedAccountIds.isEmpty()) {
			return unloadedAccountIds;
		}
		// retrieve the account hierarchy for specified accounts
		Set<SObjectField> fields = new Set<SObjectField>{Account.Id, Account.Parent.Id, Account.Parent.ParentId, Account.Parent.Parent.Parent.Id, Account.Parent.Parent.Parent.Parent.Id,Account.Parent.Parent.Parent.Parent.Parent.Id};
		Map<String, Object> searchParams = new Map<String, Object>{'accId' => unloadedAccountIds,'parentIds' => unloadedAccountIds, 'parentIdsLevel2' => unloadedAccountIds, 'parentIdsLevel3' => unloadedAccountIds,'parentIdsLevel4' => unloadedAccountIds, 'parentIdsLevel5' => unloadedAccountIds, 'parentIdsLevel6' => unloadedAccountIds};
		Set<Object> selectorOptions = new Set<Object> {AccountsSelector.Options.WITH_PARENT_5LEVELS};
		String searchConditions = '1 OR 2 OR 3 OR 4 OR 5 OR 6 OR 7';
		Schema.SObjectField orderByField = Account.Id;
		String sortDirection = 'ASC';
		Set<Id> loadedAccountIds = new Set<Id>();
		List<Account> loadedAccounts = AccountsSelector.newInstance(0, fields).search(searchParams,selectorOptions, searchConditions, orderByField,sortDirection);
		// populate global account hierarchy maps
		for(Account acc : loadedAccounts) {
			addAccountParent(acc);
			loadedAccountIds.add(acc.Id);
		}
		// return the ids of the accounts loaded
		return loadedAccountIds;
	}

	/**
	* @description 	recursively populates the child to parent account map with an account
	* @param 			account - The accounts for which child accounts are to be loaded
	* @return 	populates the global child to parent account map
	*/
	private void addAccountParent(Account account) {
		if(account.Parent == null) {
			return;
		}
		// recusively add the next child to parent relationship
		childToParentAccountMap.put(account.Id, account.parent.Id);
		if (account.Parent.Parent != null) {
			addAccountParent(account.Parent);
		}
	}
 
	/**
	* @description 	retrieves any accounts whose heirarchy has not yet been loaded
	* @param 			childAccountIds - The account ids to check
	* @return 	the set of account ids not yet having their hierarchy loaded
	*/
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
 
	/**
	* @description 	converts the child to parent map into a parent to child map
	* @return 	a map of parent accounts that link all their child accounts.
	*/
	private Map<Id,Set<Id>> getParentToChildAccountMap() {
		Map<Id,Set<Id>> parentToChildMap = new Map<Id,Set<Id>>();
		for (Id childId : childToParentAccountMap.keySet()) {
			Id parentId = childToParentAccountMap.get(childId);
            if(parentId != null) {
                if (!parentToChildMap.containsKey(parentId)) {
                    parentToChildMap.put(parentId, new Set<Id>());
                }
                parentToChildMap.get(parentId).add(childId);
            }
		}
		return parentToChildMap;
	}
 
	/**
	* @description 	converts the map of parents to related accounts into a map of related accounts to parents
	* @return 	a map of related accounts and the account to which they are related
	*/
	private Map<Id,Id> getRelatedParentAccountMap() {
		Map<Id,Id> relatedToParentMap = new Map<Id,Id>();
		for (Id parentAccountId : relatedChildAccountsMap.keySet()) {
			if (relatedChildAccountsMap.get(parentAccountId) != null) {
				for (Id relatedAccountId : relatedChildAccountsMap.get(parentAccountId)) {
					relatedToParentMap.put(relatedAccountId,parentAccountId);
				}
			}
		}
		return relatedToParentMap;
	}

	/**
	* @description 	clears the values of summary records before recalculating them.
	* @param 			recordsToZero - the grouped revenue records to clear 
	*/
	private static void zeroRevenueValues(List<GroupedAccountProductRevenue__c> recordsToZero) {
		for (GroupedAccountProductRevenue__c recordToZero : recordsToZero) {
			zeroRevenueValue(recordToZero);
		}
	}
 
	/**
	* @description 	clears the values of summary records before recalculating them.
	* @param 			recordsToZero - the grouped revenue records to clear 
	*/
	private static void zeroRevenueValue(GroupedAccountProductRevenue__c recordToZero) {
		for (Integer i = 1; i<=12; i++) {
			setValueForMonth(recordToZero,i,0);
		}
	}
 
	private static void addChildAccountRevenueUIDsRecursive(Id parentAccountId,Id productId, String year, Map<Id,Set<Id>> parentToChildAccountMap, Set<String> relatedUIDs ) {
		if (!parentToChildAccountMap.containsKey(parentAccountId)) {
			return;
		}
		Set<Id> childAccounts = parentToChildAccountMap.get(parentAccountId);
		if (childAccounts == null) {
			return;
		}
		// records for child accounts of item account
		for (Id childAccountId : childAccounts) {
			relatedUIDs.add(getUID(childAccountId,productId,year));
			addChildAccountRevenueUIDsRecursive(childAccountId,productId,year,parentToChildAccountMap,relatedUIDs);
		}
	}

	/**
	* @description 	converts a calendar date to a financial year.
	* @param 	dateToConvert - the date to convert into a financial year. 
	*/
	private static Integer getAustralianFinancialYear(Date dateToConvert) {
		return dateToConvert.month() >= 7 ? dateToConvert.year() + 1 : dateToConvert.year();
	}

	/**
	* @description retrieves a the value of a particular month for a revenue record.
	* @param 	record - budget and revenue or grouped revenue record to retireve the value from
	* @param 	month - the month of the value requested
	* @returns 	Double the value for the requested month. 
	*/
	private static Double getValueForMonth(SObject record, Integer month) {
		if (record.getSObjectType() == Budget_and_Revenue__c.SObjectType) {
			return getSuffixedValueForMonth(record, month ,BUDGET_REVENUE_SUFFIX);
		}
		return getPrefixedValueForMonth(record,month,MONTHLY_REVENUE_PREFIX);
	}
 
	/**
	* @description sets the value of a particular month for a revenue record.
	* @param 	record - budget and revenue or grouped revenue record to set the value of
	* @param 	month - the month of the value requested
	*/
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
 
	/**
	* @description sets the value of a particular month .
	* @param 	record - budget and revenue record to set
	* @param 	month - the month of the value to set
	*/
	private static void setPrefixedValueForMonth(SObject record, Integer month, String prefix, Double value) {
		record.put(getPrefixedFieldNameForMonth(month,prefix),value);
	}
 
	/**
	* @description sets the value of a particular month .
	* @param 	record - budget and revenue record to set
	* @param 	month - the month of the value to set
	*/
	private static void setSuffixedValueForMonth(SObject record, Integer month, String suffix, Double value) {
		record.put(getSuffixedFieldNameForMonth(month,suffix),value);
	}

}