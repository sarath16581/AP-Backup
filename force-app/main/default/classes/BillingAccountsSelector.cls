/**
 * @author Nathan Franklin
 * @date 2020-07-22
 * @group Selector
 * @domain Core
 * @description A very simple selector class that sits in the Core domain
 * @changelog
 * 2020-10-18 - Nathan Franklin - Added selectByAccountNumber
 * 18-12-2020 - avula.jansirani@auspost.com.au  added FILTER_CUST_TYPE
 * 23-03-2021 - avula.jansirani@auspost.com.au  added FILTER_ACTIVE
 * 10-07-2021 - Snehil.jaiswal@salesforce.com |PBRP - added fields Billing_Account__c.State_Allocation__c, Billing_Account__c.Street__c, Billing_Account__c.Suburb__c, Billing_Account__c.Type__c, Billing_Account__c.Organisation__c,Billing_Account__c.BSC__c, Billing_Account__c.Calc_Exclude_Notification_Automation__c,	
 *				Billing_Account__c.StarTrack_Account_Manager__c
 * 2021-08-06 - Seth Heang - Added selectByLikedNameOrderByName
 * 2021-08-24 - Seth Heang - Uplift SF API Version to 52
 * 2022-05-30 - Seth Heang - Added PAYER_ACCOUNT_ID related list and selectByOrgId method
 * 2023-07-10 - Mahesh Parvathaneni - Added options FILTER_TYPE_NOT_IN_SBBA_CASH, FILTER_SOURCE_SYSTEM_NOT_IN_PEOPLE_SOFT
 * 2023-10-27 - Harry Wang - Added method selectByLeaderAccountId and option FILTER_TYPE_FOLLOWER
 */
public virtual inherited sharing class BillingAccountsSelector extends ApplicationSelector {

	public enum Options {
		WITH_ORGANISATION,
		FILTER_CUST_TYPE,
		FILTER_ACTIVE,
		WITH_PAYER_ACCOUNT_ID,
		FILTER_TYPE_NOT_IN_SBBA_CASH,
		FILTER_SOURCE_SYSTEM_NOT_IN_PEOPLE_SOFT,
		FILTER_TYPE_FOLLOWER
	}

	public static String sortOrder ='Desc';
	public static String sortfieldAPIName = 'CreatedDate';

	public static BillingAccountsSelector newInstance() {
		return (BillingAccountsSelector)Application.Selectors.newInstance(BillingAccountsSelector.class);
	}

	public static BillingAccountsSelector newInstance(Integer recordLimit) {
		return (BillingAccountsSelector)Application.Selectors.newInstance(BillingAccountsSelector.class).setLimit(recordLimit);
	}


	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static BillingAccountsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		BillingAccountsSelector selector = (BillingAccountsSelector)Application.Selectors.newInstance(BillingAccountsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static BillingAccountsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		BillingAccountsSelector selector = (BillingAccountsSelector)Application.Selectors.newInstance(BillingAccountsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return Billing_Account__c.getSObjectType();
	}

	public static BillingAccountsSelector newInstance(String sortField, String order, Set<SObjectField> fieldOverrides) {
		if(!String.isEmpty(sortField)){
			sortfieldAPIName = sortField;
		}
		if(!String.isEmpty(order)){
			sortOrder = order;
		}
		return (BillingAccountsSelector)Application.Selectors.newInstance(BillingAccountsSelector.class).setFieldOverrides(fieldOverrides);
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Billing_Account__c.ABN__c, Billing_Account__c.Account_manager__c, Billing_Account__c.Account_Manager_Team__c, Billing_Account__c.ACN__c, Billing_Account__c.Additional_Info__c, Billing_Account__c.Assigned_Unassigned__c,
				Billing_Account__c.Calc_Customer_ID__c, Billing_Account__c.Calc_Depot_Collection__c, Billing_Account__c.Calc_Despatch_ID__c, Billing_Account__c.Country__c, Billing_Account__c.CreatedById, Billing_Account__c.CreatedDate,
				Billing_Account__c.Credit_Group__c, Billing_Account__c.Credit_Group_Formula__c, Billing_Account__c.Credit_Limit__c, Billing_Account__c.Credit_Limit_Formula__c, Billing_Account__c.Credit_Person__c,
				Billing_Account__c.Credit_Person_Code__c, Billing_Account__c.Credit_Person_Phone__c, Billing_Account__c.Credit_Status__c, Billing_Account__c.Credit_Status_Formula__c,
				Billing_Account__c.Credit_Status_Image__c, Billing_Account__c.Customer_Name__c, Billing_Account__c.Customer_Name_2__c, Billing_Account__c.Customer_Number__c, Billing_Account__c.Date_Postal_Code_Changed__c,
				Billing_Account__c.Despatch_ID__c, Billing_Account__c.Email__c, Billing_Account__c.Fax_Number__c, Billing_Account__c.Id, Billing_Account__c.Integration_Id__c, Billing_Account__c.LastModifiedDate, Billing_Account__c.Leader_Master_Number__c,
				Billing_Account__c.LEGACY_ID__c, Billing_Account__c.MLID__c, Billing_Account__c.Name, Billing_Account__c.Organisation__c, Billing_Account__c.PAYER_ACCOUNT_ID__c, Billing_Account__c.Payer_Account_Legacy_Id__c,
				Billing_Account__c.Phone_Number__c, Billing_Account__c.Postal_Code__c, Billing_Account__c.SAP_marked_for_deletion__c, Billing_Account__c.Source_System__c, Billing_Account__c.State__c,
				Billing_Account__c.State_Allocation__c, Billing_Account__c.Street__c, Billing_Account__c.Suburb__c, Billing_Account__c.Type__c, Billing_Account__c.Organisation__c,Billing_Account__c.BSC__c, Billing_Account__c.Calc_Exclude_Notification_Automation__c,	
				Billing_Account__c.StarTrack_Account_Manager__c
		};
	}

	public Map<Id, Billing_Account__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	public Map<Id, Billing_Account__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		String soql = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition('Id in :ids')).endConditions().toSoqlString();
		return new Map<Id, Billing_Account__c>((List<Billing_Account__c>)Database.query(soql));
	}

	public Map<Id, Billing_Account__c> selectByAccountNumber(Set<String> accountNumbers) {
		return selectByAccountNumber(accountNumbers, new Set<Object>());
	}
	public Map<Id, Billing_Account__c> selectByAccountNumber(Set<String> accountNumbers, Set<Object> selectorOptions) {
		String soql = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Billing_Account__c.LEGACY_ID__c + ' in :accountNumbers')).endConditions().toSoqlString();
		return new Map<Id, Billing_Account__c>((List<Billing_Account__c>)Database.query(soql));
	}

	public Map<Id, Billing_Account__c> selectByIdorAccountNumber(List<Billing_Account__c> ids, Set<String> accountNumbers) {
		return selectByIdorAccountNumber(ids, accountNumbers , new Set<Object>());
		
	}
	public Map<Id, Billing_Account__c> selectByIdorAccountNumber(List<Billing_Account__c> ids, Set<String> accountNumbers, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition('Id in :ids')).endConditions();
		//QueryBuilder builder = super.newQueryBuilder(selectorOptions);
		qb.addConditions().add(new QueryBuilder.SimpleCondition(Billing_Account__c.LEGACY_ID__c + ' in :accountNumbers')).setConditionOrder('1 OR 2').endConditions();
		return new Map<Id, Billing_Account__c>((List<Billing_Account__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Select Billing Account based on 'LIKE' name and order by name
	 * @param String name of billing account
	 * @return matching billing account records
 	*/
	public Map<Id, Billing_Account__c> selectByLikedNameOrderByName(String name) {
		return selectByLikedNameOrderByName(name, new Set<Object>());
	}

	/**
	 * @description Select Billing Account based on 'LIKE' name and order by name
	 * @param String name of billing account
	 * @return matching billing account records
	 */
	public Map<Id, Billing_Account__c> selectByLikedNameOrderByName(String name, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.LikeCondition(Billing_Account__c.Name).likeAnyBoth(name)).endConditions();
		qb.addOrderAsc(Billing_Account__c.Name);
		return new Map<Id, Billing_Account__c>((List<Billing_Account__c>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Select Billing Account based on organisation Id
	 * @param String orgIds
	 * @return matching organisation Id records
	 */
	public Map<Id, Billing_Account__c> selectByOrgId(Set<Id> orgIds) {
		return selectByOrgId(orgIds, new Set<Object>());
	}
	/**
	 * @description Select Billing Account based on organisation Id
	 * @param String orgIds
	 * @param Set<Object> selectorOptions
	 * @return matching organisation Id records
	 */
	public Map<Id, Billing_Account__c> selectByOrgId(Set<Id> orgIds, Set<Object> selectorOptions) {
		String soql = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Billing_Account__c.Organisation__c + ' in :orgIds')).endConditions().toSoqlString();
		return new Map<Id, Billing_Account__c>((List<Billing_Account__c>)Database.query(soql));
	}

	/**
	 * @description Select billing accounts by leader account id
	 * @param leaderAccountIds leader account Id
	 * @param selectorOptions selector options
	 * @return matching list of billing accounts
	 */
	public List<Billing_Account__c> selectByLeaderAccountId(Set<Id> leaderAccountIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Billing_Account__c.LeaderAccount__c + ' in :leaderAccountIds')).endConditions();
		return (List<Billing_Account__c>)Database.query(qb.toSoqlString());
	}

	public override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
			builder.addRelatedFields(AccountsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Organisation__r');
		}

		if(selectorOptions.contains(Options.FILTER_CUST_TYPE)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(Billing_Account__c.Type__c).eq('CUST')).endConditions();
		}

		if(selectorOptions.contains(Options.FILTER_ACTIVE)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(Billing_Account__c.SAP_marked_for_deletion__c).eq(false)).endConditions();
		}
		if(selectorOptions.contains(Options.WITH_PAYER_ACCOUNT_ID)) {
			// limit 1 to prevent recursive loop due to self-lookup
			builder.addRelatedFields(BillingAccountsSelector.newInstance(1).newQueryBuilder(), 'PAYER_ACCOUNT_ID__r');
		}

		if (selectorOptions.contains(Options.FILTER_TYPE_NOT_IN_SBBA_CASH)) {
			builder.addConditions().add((new QueryBuilder.InCondition(Billing_Account__c.Type__c)).notInCollection(new Set<String>{'SBBA', 'CASH'})).endConditions();
		}

		if (selectorOptions.contains(Options.FILTER_SOURCE_SYSTEM_NOT_IN_PEOPLE_SOFT)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(Billing_Account__c.Source_System__c).ne('PeopleSoft')).endConditions();
		}

		if (selectorOptions.contains(Options.FILTER_TYPE_FOLLOWER)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(Billing_Account__c.BillingAccountType__c).eq('Follower')).endConditions();
		}

		return builder;
	}

	/**
	 * Forces an order to be applied to any query built with QueryBuilder. This can be overridden if needed
	 */
	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order(sortfieldAPIName, sortOrder)};
	}

}