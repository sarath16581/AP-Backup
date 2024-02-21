/**************************************************
Type:         Provides data for reporting on opportunity
			  Line Item revenue and schedule
History:
--------------------------------------------------
2024-01-22    Ken McGuire - Created
**************************************************/
public class OpportunityRevenueReportController {

    public static final String SUFFIX = '_Revenue_Amount__c';
    public static final String[] months = new String[] { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' };

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
        // all the accounts relevant to this opportunity. Used to retrieve budget and revenue records.
        Set<Id> relevantAccounts = new Set<Id>();
        // load opportunity line items for this opportunity
        Map<Id,OpportunityLineItem> oppLineItem = loadProductLineItems(opportunityId);
        // the opportunity accountId is returned with the items, use the first one.
        Id mainAccountId = oppLineItem.values()[0].Opportunity.AccountId;
        // add the main account to the relevant accounts
        relevantAccounts.add(mainAccountId);
        // get all the child accounts for the main accounts
        Map<Id,Account> childAccounts = loadChildAccountMap(mainAccountId);
        // add child accounts to relevant accounts
        relevantAccounts.addAll(childAccounts.keySet());
        // get any accounts manually related to the main account
        Map<Id,AccountRelationship__c> relatedAccounts =  loadRelatedAccounts(mainAccountId);
        // add these to the relevant accounts
        relevantAccounts.addAll(relatedAccounts.keySet());
        Integer FY = getAustralianFinancialYear(calculationDate);
        Integer startMonth = calculationDate.month() - 1;

		// the calculation for past months revenue counts back wards, so if it reaches zero it means it should reset the month to 12, and go the previous year
        if (startMonth == 0) {
            startMonth = 12;
            FY -=1;
        }
        // retrieve relevant budget and revenues for all relevant accounts for this year and last (we need 12 months of sales data)
        Set<String> financialYears = new Set<String> {String.valueOf(FY-1), String.valueOf(FY)};
        Map<String,Budget_and_Revenue__c> customerRevenues =  loadBudgetAndRevenueRecords(relevantAccounts, oppLineItem.keySet(), financialYears);
        List<RevenueData> revenues = new List<RevenueData>();
        // get data row for main account
        RevenueData data = new RevenueData(childAccounts.get(mainAccountId)?.Name);
        buildRevenueData(mainAccountId,oppLineItem.values(),FY,startMonth,customerRevenues,data);
        revenues.add(data);
        // get data rows for child accounts
        for (Account child : childAccounts.values()) {
            if (child.Id != mainAccountId) {
                data = new RevenueData(child.Name);
                if (buildRevenueData(child.Id,oppLineItem.values(),FY,startMonth,customerRevenues,data)) {
                    revenues.add(data);
                }

            }
        }
        // get data rows for related accounts
        for (AccountRelationship__c relatedAccount : relatedAccounts.values()) {
            if (relatedAccount.relatedAccount__c != mainAccountId && !childAccounts.containsKey(relatedAccount.relatedAccount__c)) {
                data = new RevenueData(relatedAccount.relatedAccount__r.Name);
                if (buildRevenueData(relatedAccount.relatedAccount__c,oppLineItem.values(),FY,startMonth,customerRevenues,data)) {
                    revenues.add(data);
                }
            }
        }

        return revenues;
    }

    private static Boolean buildRevenueData(Id accountId,List<OpportunityLineItem> oppLineItem,Integer targetYear, Integer targetMonth,Map<String,Budget_and_Revenue__c> customerRevenues,RevenueData data) {
        Boolean hasData = false;
        for(OpportunityLineItem item : oppLineItem) {
            Double amt = new ProductRevenueService().getSumOfPastTwelveMonths(accountId,item.Product2.Id);
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
        Map<String,Budget_and_Revenue__c> loadedRevenueMap = new   Map<String,Budget_and_Revenue__c>();
        for (Budget_and_Revenue__c currentBudget : BudgetAndRevenueSelector.newInstance().selectByOrganisationAndProduct(accountIds,productIds,financialYears,new Set<Id>())) {
            loadedRevenueMap.put(currentBudget.uid__c, currentBudget);
        }
        return loadedRevenueMap;
    }
}