/**************************************************
Type: Provides data for reporting on opportunity
	Line Item revenue and schedule
History:
--------------------------------------------------
2024-01-22Ken McGuire - Created
2024-07-31 	Ken McGuire	- added refresh revenue capability.
**************************************************/
public class OpportunityRevenueReportController {

	public static final String SUFFIX = '_Revenue_Amount__c';
	public static final String[] months = new String[] { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' };
	public static final String errorMessage = 'Failed to retrieve revenue data. Please contact your administrator.';
	@testVisible
	private static Date calculationDate {
		get {
			if (calculationDate == null) {
				calculationDate = System.today();
			}
			return calculationDate;
		}
		set;
	}

	// Sub-class to represent each row of data
	public class RevenueData {
		@AuraEnabled public String companyName { get; set; }
		@AuraEnabled public Map<String, Decimal> productRevenues { get; set; }

		public RevenueData(String companyName) {
			this.companyName = companyName;
			this.productRevenues = new Map<String, Decimal>();
		}
	}

	// Method to get revenue data
	@AuraEnabled(cacheable=true)
	public static List<RevenueData> getRevenueData(String opportunityId) {
		Map<Id, Opportunity> opportunityMap = ProductRevenueService.newInstance().loadOpportunityInfo(new Set<Id>{opportunityId});
		// all the accounts relevant to this opportunity. Used to retrieve budget and revenue records.
		Set<Id> relevantAccounts = new Set<Id>();
		List<RevenueData> revenues = new List<RevenueData>();
		try {
			// load opportunity line items for this opportunity
			Map<Id,OpportunityLineItem> oppLineItem = loadProductLineItems(opportunityId);
			// the opportunity accountId is returned with the items, use the first one.
			Id mainAccountId = oppLineItem.values()[0].Opportunity.AccountId;
			// add the main account to the relevant accounts
			relevantAccounts.add(mainAccountId);
			// get all the child accounts for the main accounts
			Map<Id,Account> childAccounts = opportunityMap.get(opportunityId).DoNotUseAccountHierarchy__c ? loadMainAccountMap(mainAccountId) : loadChildAccountMap(mainAccountId);

			// add child accounts to relevant accounts
			relevantAccounts.addAll(childAccounts.keySet());
			// get any accounts manually related to the main account
			Map<Id,AccountRelationship__c> relatedAccounts =loadRelatedAccounts(mainAccountId);
			// add these to the relevant accounts
			relevantAccounts.addAll(relatedAccounts.keySet());

			// retrieve relevant budget and revenues for all relevant accounts for this year and last (we need 12 months of sales data)
			Set<String> financialYears = new Set<String> {String.valueOf(getAustralianFinancialYear(calculationDate) - 1), String.valueOf(getAustralianFinancialYear(calculationDate))};
			Map<String,Budget_and_Revenue__c> customerRevenues = loadBudgetAndRevenueRecords(relevantAccounts, oppLineItem.keySet(), financialYears);
			list<String> restrictedAccounts = ProductRevenueService.csvToList( opportunityMap.get(opportunityId).RevenueCalculationAccountIDs__c);
			// get data row for main account
			RevenueData data = new RevenueData(childAccounts.get(mainAccountId)?.Name);
			buildRevenueData(mainAccountId,oppLineItem.values(),customerRevenues,data);
			revenues.add(data);
			// get data rows for child accounts
			for (Account child : childAccounts.values()) {
				if (child.Id != mainAccountId && (restrictedAccounts.isEmpty() || restrictedAccounts.contains(child.id))) {
					data = new RevenueData(child.Name);
					if (buildRevenueData(child.Id,oppLineItem.values(),customerRevenues,data)) {
						revenues.add(data);
					}

				}
			}
			// get data rows for related accounts
			for (AccountRelationship__c relatedAccount : relatedAccounts.values()) {
				if (relatedAccount.relatedAccount__c != mainAccountId && !childAccounts.containsKey(relatedAccount.relatedAccount__c) && (restrictedAccounts.isEmpty() || restrictedAccounts.contains(relatedAccount.relatedAccount__c))) {
					data = new RevenueData(relatedAccount.relatedAccount__r.Name);
					if (buildRevenueData(relatedAccount.relatedAccount__c,oppLineItem.values(),customerRevenues,data)) {
						revenues.add(data);
					}
				}
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
					AccountTriggerUtility.class.getName(), 'getRevenueData',
					'RevenueReport', LoggingLevel.ERROR);
			// Rethrow as an AuraHandledException for the LWC to catch
			throw new AuraHandledException(errorMessage);
		}
		return revenues;
	}

	
	@AuraEnabled
	public static void RefreshRevenue(Id opportunityId) {
		
		performScheduleUpdates(opportunityId);
	}
	
	@AuraEnabled
	public static Boolean hasRefreshRevenuePermission() {
		return new PermissionChecker().hasRefreshRevenuePermission();
	}
	
	
	
	 /**
	 * @description this method creates/ updates all the revenues and schedules for an opportununity's line items 
	 * as if the opportunity was just closed won. useful when an opportunity has products or account relationships 
	 * that change after it is closed won. 
	 * (1) creates / updates product revenues
	 * (2) creates / updates revenue schedules
	 * (3) Updates all line items of the opportunity with retained and incremental revenue values, classification etc.
	 * @param opportunityId the opportunity that requires updating
	 */
	private static void performScheduleUpdates(Id opportunityId) {
		// guard
		if (opportunityId==null) {
			return;
		}
		// call on the product schedule service to create or update the schedules associated with all the product line items. 
		ProductScheduleService productScheduleServiceInstance = ProductScheduleService.newInstance();
		// This service call resets the accounts that are used in the "final" calculations.
		// The service in turn uses the product revenue service for updates to product revenues and product line item sales info 
		List<GroupedRevenueSchedule__c> schedules = productScheduleServiceInstance.createUpdateRevenueSchedules(new Set<id>{opportunityId},true);
		// register all the canged or updated revenue and schedule records with the unit of work data object.
		registerDataForUpdateInsert(schedules);
		Opportunity oppInfo = productScheduleServiceInstance.productRevenueServiceInstance.OpportunityInfo.get(opportunityId);
	 	Opportunity opp = new Opportunity(id = opportunityId, RevenueCalculationAccountIDs__c = oppInfo.RevenueCalculationAccountIDs__c, RevenueRefreshDate__c = date.today(), RevenueRefreshedBy__c = UserInfo.getUserId());
		update(opp);
	}
	
	 /**
	 * @description register related revenue and schedule data records with the UOW
	 * @param closedWonOppIds Set<Id> of the opportunities that have been closed won
	 * @param uow ApplicationUnitOfWork
	 */
	public static void registerDataForUpdateInsert(List<GroupedRevenueSchedule__c> schedules) {
		// newly created revenue schedules
		List<GroupedRevenueSchedule__c> schedulesToInsert = newList<GroupedRevenueSchedule__c>();
		// updated revenue schedules
		List<GroupedRevenueSchedule__c> schedulesToUpdate = newList<GroupedRevenueSchedule__c>();
		// new product revenue records
		List<GroupedAccountProductRevenue__c> revenuesToInsert = newList<GroupedAccountProductRevenue__c>();
		// updated product revenue records
		List<GroupedAccountProductRevenue__c> revenuesToUpdate = newList<GroupedAccountProductRevenue__c>();
		// updated line items
		Map<id,OpportunityLineItem> itemsToUpdate = new Map<id,OpportunityLineItem>();
		for (GroupedRevenueSchedule__c schedule : schedules) {
			// schedules to be created or updated
			if (schedule.Id == null) {
				// record creation
				schedulesToInsert.add(schedule);
			}else {
				// record update
				schedulesToUpdate.add(schedule);
			}
			// revenue records associated with the schedules which are to be created or updated
			if (schedule.GroupedAccountProductRevenue__r != null) {
				if(schedule.GroupedAccountProductRevenue__r.Id == null) { 
					// The Product Revenue record associated with this schedule does not exist yet.
					//(1) register the relationship...
					//uow.registerRelationship(schedule, GroupedRevenueSchedule__c.GroupedAccountProductRevenue__c, schedule.GroupedAccountProductRevenue__r);
					// (2)add the revenue record to the insert list, 
					revenuesToInsert.add(schedule.GroupedAccountProductRevenue__r);
		 		} else {
					// revenue record associated with the schedule already exists, just update it. 
			 		revenuesToUpdate.add(schedule.GroupedAccountProductRevenue__r);
		 		}
			}
			if (schedule.opportunityProduct__r != null && !itemsToUpdate.containsKey(schedule.OpportunityProduct__r.id)) {
				itemsToUpdate.put(schedule.OpportunityProduct__r.id,schedule.opportunityProduct__r);
			}
		}
		// register new revenue records
		if (!revenuesToInsert.isEmpty()) {
		 insert(revenuesToInsert);
		}
		// register new schedules
		if (!schedulesToInsert.isEmpty()) {
			insert(schedulesToInsert);
		}
		if (!revenuesToUpdate.isEmpty()) {
			update(revenuesToUpdate);
		}
		// register schedules to update
		if (!schedulesToUpdate.isEmpty()) {
			update(schedulesToUpdate);
		}
		// register items to update
		if (!itemsToUpdate.isEmpty()) {
			update(itemsToUpdate.values());
		}
	}
	
	
	/**
 * @description calculate actual revenue for account products achieved over the past 12 months.
 * @param accountId - the account for the revenue record
 * @param productId - the product for the revenue record
 * @targetYear the FY to start with
 * @targetMonth the month to start with
 * customerRevenues a map of customer revenues to use in the calculation
 * @return the total sales value for the last twelve months for the specified account and product.
 * */
	private static Double getSumOfPastTwelveMonths(String accountId, String productId,Integer targetYear, Integer targetMonth,Map<String,Budget_and_Revenue__c> customerRevenues) {
		Double totalSum = 0.0;
		// Iterate through the past 12 months
		for (Integer i = 1; i <= 12; i++) {
			// adjust target month and financial year.
			targetMonth -= 1;
			if (targetMonth == 6) {
				targetYear -=1;
			}
			else if (targetMonth==0) {
				targetMonth = 12;
			}
			String uniqueId = ProductRevenueService.getUID(accountId,productId,String.valueOf(targetYear));
			Budget_and_Revenue__c targetRevenue = customerRevenues.get(uniqueId);
			if (targetRevenue != null) {
				Double monthValue = getValueForMonth(targetRevenue,targetMonth);
				if (monthValue != null) {
					totalSum += monthValue;
				}
			}
		}
		return totalSum;
	}

	private static Double getValueForMonth(SObject record, Integer month) {
		return (Double)record.get(months[month-1] + SUFFIX) ?? 0;
	}

	private static Boolean buildRevenueData(Id accountId,List<OpportunityLineItem> oppLineItem,Map<String,Budget_and_Revenue__c> customerRevenues,RevenueData data) {
		Boolean hasData = false;
		for(OpportunityLineItem item : oppLineItem) {
			Date targetDate = item.Contract_Start_Date__c < calculationDate ? item.Contract_Start_Date__c : calculationDate;
			Integer FY = getAustralianFinancialYear(targetDate);
			Integer startMonth = targetDate.month();
			Double amt = getSumOfPastTwelveMonths(accountId,item.Product2.Id,FY,startMonth,customerRevenues);
			data.productRevenues.put(item.Product2.Name,amt);
			if (!hasData && amt>0 ) {
				hasData = true;
			}
		}
		return hasData;
	}

	private static Integer getAustralianFinancialYear(Date dateToUse) {
		return dateToUse.month() >= 7 ? dateToUse.year() + 1 : dateToUse.year();
	}

	private static Map<Id,OpportunityLineItem> loadProductLineItems(Id opportunityId) {
		Map<Id,OpportunityLineItem> oppLineItemMap = new Map<Id,OpportunityLineItem>();
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				OpportunityLineItem.SObjectType => new Set<SObjectField>{OpportunityLineItem.Id, OpportunityLineItem.Name,OpportunityLineItem.Quantity, OpportunityLineItem.Contract_Start_Date__c, OpportunityLineItem.Contract_End_Date__c,OpportunityLineItem.UnitPrice, OpportunityLineItem.TotalPrice, OpportunityLineItem.Annualised_Value__c, OpportunityLineItem.RetainedRevenue__c,OpportunityLineItem.IncrementalRevenue__c, OpportunityLineItem.TweleveMonthRevenue__c},
				Product2.SObjectType => new Set<SObjectField>{Product2.Id,Product2.Name},
				Opportunity.SObjectType => new Set<SObjectField>{Opportunity.Name,Opportunity.AccountId,Opportunity.Id}
		};
		List<OpportunityLineItem> loadedItems = OpportunityLineItemSelector.newInstance(0, fieldOverrides).selectByOpportunity(new Set<Id>{opportunityId}, new Set<Object>{OpportunityLineItemSelector.Options.WITH_OPPORTUNITY, OpportunityLineItemSelector.Options.WITH_PRODUCT});
		for (OpportunityLineItem item : loadedItems) {
			oppLineItemMap.put(item.Product2Id, item);
		}
		return oppLineItemMap;
	}

	private static Map<Id,Account> loadMainAccountMap(Id accountId) {
		return AccountsSelector.newInstance(1, new Set<SObjectField>{Account.Id, Account.Name}).selectById(new Set<Id> {accountId});
	}

	private static Map<Id,Account> loadChildAccountMap(Id accountId) {
		Set<Id> unloadedAccountIds = new Set<Id>{accountId};
		Set<SObjectField> fields = new Set<SObjectField>{Account.Id, Account.Name, Account.Parent.Id, Account.Parent.ParentId, Account.Parent.Parent.Parent.Id, Account.Parent.Parent.Parent.Parent.Id,Account.Parent.Parent.Parent.Parent.Parent.Id};
		Map<String, Object> searchParams = new Map<String, Object>{'accId' => unloadedAccountIds,'parentIds' => unloadedAccountIds, 'parentIdsLevel2' => unloadedAccountIds, 'parentIdsLevel3' => unloadedAccountIds,'parentIdsLevel4' => unloadedAccountIds, 'parentIdsLevel5' => unloadedAccountIds, 'parentIdsLevel6' => unloadedAccountIds};
		Set<Object> selectorOptions = new Set<Object> {AccountsSelector.Options.WITH_PARENT_5LEVELS};
		String searchConditions = '1 OR 2 OR 3 OR 4 OR 5 OR 6 OR 7';
		Schema.SObjectField orderByField = Account.Id;
		String sortDirection = 'ASC';
		Map<Id,Account> loadedAccounts = new Map<Id,Account>();
		for(Account nextAccount : AccountsSelector.newInstance(0, fields).search(searchParams,selectorOptions, searchConditions, orderByField,sortDirection)) {
			loadedAccounts.put(nextAccount.Id,nextAccount);
		}
		return loadedAccounts;
	}


	private static Map<Id,AccountRelationship__c> loadRelatedAccounts(id accountId) {
		Map<Id,AccountRelationship__c> loadedRelatedAccountRelationships = new Map<Id,AccountRelationship__c>();
		Set<Object> selectorOptions = new Set<Object>{AccountRelationshipSelector.Options.WITH_RELATED_ACCOUNT};
		for (AccountRelationship__c arr: AccountRelationshipSelector.newInstance().selectByOPCParentEndDateInFuture(new Set<Id>{accountId},selectorOptions)) {
			loadedRelatedAccountRelationships.put(arr.RelatedAccount__c,arr);
		}
		return loadedRelatedAccountRelationships;
	}



	private static Map<String,Budget_and_Revenue__c> loadBudgetAndRevenueRecords(Set<id> accountIds, Set<Id> productIds, Set<String> financialYears) {
		Map<String,Budget_and_Revenue__c> loadedRevenueMap = new Map<String,Budget_and_Revenue__c>();
		for (Budget_and_Revenue__c currentBudget : BudgetAndRevenueSelector.newInstance().selectByOrganisationAndProduct(accountIds,productIds,financialYears,new Set<Id>())) {
			loadedRevenueMap.put(currentBudget.UniqueId__c, currentBudget);
		}
		return loadedRevenueMap;
	}
	
	public without sharing class PermissionChecker {
		public Boolean hasRefreshRevenuePermission() {
			String permissionSetName = 'BG_Sales_Operations';
			Set<Id> userPermissionSetIds = new Set<Id>();
			
			for (PermissionSetAssignment psa : [
				SELECT PermissionSetId 
				FROM PermissionSetAssignment 
				WHERE AssigneeId = :UserInfo.getUserId()
			]) {
				userPermissionSetIds.add(psa.PermissionSetId);
			}
			
			for (PermissionSet ps : [
				SELECT Id 
				FROM PermissionSet 
				WHERE Name = :permissionSetName
			]) {
				if (userPermissionSetIds.contains(ps.Id)) {
					return true;
				}
			}
			return false;
		}
	}
}