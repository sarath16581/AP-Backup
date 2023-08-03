/* @author Nathan Franklin
 *@date 2020-11-18
 *@group Tests
 *@tag Selector
 *@tag Credit Assessment
 *@domain Core
 *@description A very simple selector class that sits in the base domain
 *@changelog
 *2020-11-18 - arjun.singh@austpost.com.au - Created
 *2020-12-09 - Shashwat.Nath@Auspost.com - Added WITH_PROPOSAL option
 *2022-08-04 - Seth Heang - Added APT_APPC_Count__c, Apttus__FF_Agreement_Number__c in the query
 *2022-11-26 - Harry Wang - added selector method for sales intermediary
 *2023-03-01 - Deepak Kemidi - CI-703 Added search method and additional selector options and field overrides
 *2023-03-31-Nasir Jawed-Added Apttus__Status_Category__c,Apttus__Status__c in the query
2023-05-16 - Yatika Bansal - Added Apttus_QPComply__RelatedProposalId__c in the query.
2023-07-06 - Yatika Bansal - Added few fields and new method selectByAgreementNumber to query contract using agreement number field.
2023-07-17 - Yatika Bansal - Added APT_Contract_Type__c in the query.
2023-07-27 - Yatika Bansal - Added recordTypeID in the query.
 */
public with sharing class ApttusContractsSelector extends ApplicationSelector{
	public enum Options {
		WITH_RECORDTYPE, WITH_OWNER, WITH_ORGANISATION, WITH_CONTACT, WITH_CREDIT_ASSESSMENT , WITH_PROPOSAL , WITH_OPPORTUNITY
	}
	public static ApttusContractsSelector newInstance() {
		return (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class);
	}
	public static ApttusContractsSelector newInstance(Integer recordLimit) {
		return (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class).setLimit(recordLimit);
	}

	/**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
	public static ApttusContractsSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ApttusContractsSelector selector = (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ApttusContractsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ApttusContractsSelector selector = (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ApttusContractsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ApttusContractsSelector selector = (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	public virtual override SObjectType getSObjectType() {
		return Apttus__APTS_Agreement__c.getSObjectType();
	}
	public virtual override Set<SObjectField> getSObjectFieldList() {
	//CI-703 Added new fields Apttus__APTS_Agreement__c.Contract_Relationship__c,Apttus__APTS_Agreement__c.Apttus__Status__c,Apttus__APTS_Agreement__c.Apttus__Status_Category__c
		return new Set<SObjectField> {
			Apttus__APTS_Agreement__c.Id,Apttus__APTS_Agreement__c.Name, Apttus__APTS_Agreement__c.Apttus__Account__c,
				Apttus__APTS_Agreement__c.APT_Review_Date__c,Apttus__APTS_Agreement__c.Apttus__Related_Opportunity__c,
				Apttus__APTS_Agreement__c.Apttus__Contract_Start_Date__c, Apttus__APTS_Agreement__c.Apttus__Contract_End_Date__c,
				Apttus__APTS_Agreement__c.Term__c, Apttus__APTS_Agreement__c.APT_APPC_Count__c, Apttus__APTS_Agreement__c.Apttus__FF_Agreement_Number__c,Apttus__APTS_Agreement__c.Contract_Relationship__c,
				Apttus__APTS_Agreement__c.Apttus__Status__c,Apttus__APTS_Agreement__c.Apttus__Status_Category__c,Apttus__APTS_Agreement__c.Apttus_QPComply__RelatedProposalId__c,Apttus__APTS_Agreement__c.Apttus__Primary_Contact__c, Apttus__APTS_Agreement__c.APT_Contract_Number__c,
				Apttus__APTS_Agreement__c.Included_Product_Lines__c, Apttus__APTS_Agreement__c.APT_SelectedContractAmendRenewCategory__c,Apttus__APTS_Agreement__c.APT_Require_Customer_Signature__c,Apttus__APTS_Agreement__c.Apttus__Term_Months__c,
				Apttus__APTS_Agreement__c.APT_Contract_Type__c, Apttus__APTS_Agreement__c.recordTypeID
		};
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual Map<Id, Apttus__APTS_Agreement__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	/**
	 * @description Run a simple query to get records based on Id's
	 */

	public virtual Map<Id, Apttus__APTS_Agreement__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {

		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Id + ' in :ids')).endConditions();
		return new Map<Id, Apttus__APTS_Agreement__c>((List<Apttus__APTS_Agreement__c>)Database.query(qb.toSoqlString()));
	}

	/**
	* Returns a query locator to retrieve Apttus Contracts (Apttus__APTS_Agreement__c) based on the account ids passed in.
	* If set of account ids is null or empty, returns all Apttus Contract records having a parent account.
	* Query results are ordered by parent account Id desc
	* @param accountIds set of parent account ids. returns all child Apttus Contract records associated with a parent account if null
	* or empty set is supplied.
	* @param selectorOptions set of additional selector options to augment the result set
	* @return query locator of Apttus Contract records
	*/
	public Database.QueryLocator selectByAccountOrderByAccountIdQueryLocator(Set<Id> accountIds, Set<Object> selectorOptions) {

		Set<Object> options = (selectorOptions != null ? selectorOptions : new Set<Object>());
		options.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);

		QueryBuilder qb = newQueryBuilder(options);
		QueryBuilder.ConditionsManager conditions = qb.addConditions();
		if (accountIds != null && !accountIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Apttus__Account__c + ' in :accountIds'));
		} else {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Apttus__Account__c + ' != null'));
		}

		qb = conditions.endConditions().addOrderDesc(Apttus__APTS_Agreement__c.Apttus__Account__c);
		return Database.getQueryLocator(qb.toSoqlString());
	}
	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 * agreementId / agreementId: maps to Apttus__FF_Agreement_Number__c
	 * accountId / accountIds: maps to Apttus__Account__c
	 * pricingCategory / pricingCategories: maps to APT_Pricing_Category__c
	 * status / status: maps to Apttus__Status__c
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return list<Apttus__APTS_Agreement__c>
	 */
	public list<Apttus__APTS_Agreement__c> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>{}, matchAll);
	}
	/**
	*@description Run a query to get records based on Agreement number
	*/
	public virtual List<Apttus__APTS_Agreement__c> selectByAgreementNumber(Set<String> numbers, Set<Object> selectorOptions){
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(
			new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Apttus__FF_Agreement_Number__c + ' in :numbers')).endConditions();
		return new List<Apttus__APTS_Agreement__c>((List<Apttus__APTS_Agreement__c>)Database.query(qb.toSoqlString()));
	}

	/*
	* Run a SOQL based on the search parameters passed in
	*
	* @param searchParams A map containing searchable values:
	* agreementNum / agreementNums: maps to Apttus__FF_Agreement_Number__c
	* accountId / accountIds: maps to Apttus__Account__c
	* pricingCategory / pricingCategories: maps to APT_Pricing_Category__c
	* status / status: maps to Apttus__Status__c
	* orderBy: set the order by field (SObjectField)
	* sortOrder: set the sort direction (asc,desc)
	* @param matchAll If true will search based on AND, else search based on OR
	* @return list<Apttus__APTS_Agreement__c>
	*/
	public list<Apttus__APTS_Agreement__c> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		Set<String> agreementNums = (Set<String>)(searchParams.get('agreementNums') == null ? new Set<String>() : (searchParams.get('agreementNums') instanceof Set<String> ? searchParams.get('agreementNums') : new Set<String>{(String)searchParams.get('agreementNums')}));
		Set<Id> accountIds = (Set<Id>)(searchParams.get('accountIds') == null ? new Set<Id>() : (searchParams.get('accountIds') instanceof Set<Id> ? searchParams.get('accountIds') : new Set<Id>{(Id)searchParams.get('accountIds')}));
		Set<String> pricingCategories = (Set<String>)(searchParams.get('pricingCategories') == null ? new Set<String>() : (searchParams.get('pricingCategories') instanceof Set<String> ? searchParams.get('pricingCategories') : new Set<String>{String.valueOf(searchParams.get('pricingCategories'))}));
		Set<String> status = (Set<String>)(searchParams.get('status') == null ? new Set<String>() : (searchParams.get('status') instanceof Set<String> ? searchParams.get('status') : new Set<String>{String.valueOf(searchParams.get('status'))}));
		SObjectField orderBy = searchParams.get('orderBy') == null ? null : (SObjectField)searchParams.get('orderBy');
		String sortOrder = searchParams.get('sortOrder') == null ? '' : String.valueOf(searchParams.get('sortOrder'));
		QueryBuilder builder = newQueryBuilder(selectorOptions);

		// these will override the sorting parameters when they are requested from the getOrderBy method
		String sortingFieldOverride = (orderBy != null ? String.valueOf(orderBy) : this.getOrderBy()[0].getSortingField());
		String sortingOrderOverride = (orderBy != null ? String.valueOf(sortOrder) : this.getOrderBy()[0].getSortingOrder());
		QueryBuilder.Order qbOrderBy = new QueryBuilder.Order(sortingFieldOverride, sortingOrderOverride);
		builder.setOrder(qbOrderBy); // override the default sorting

		// add our tracking query
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;

		// this is a cheeky hack to limit to cases since WorkItem.Type = 'Case' does not work for whatever reason
		if(!agreementNums.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Apttus__FF_Agreement_Number__c + ' In :agreementNums'));
			conditionCount++;
		}
		if(!accountIds.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Apttus__Account__c + ' In :accountIds'));
			conditionCount++;
		}
		if(!pricingCategories.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.APT_Pricing_Category__c + ' In :pricingCategories'));
			conditionCount++;
		}
		if(!status.isEmpty()) {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Apttus__Status__c + ' In :status'));
			conditionCount++;
		}

		// build our condition string which would end up being something liek the following:
		// 1 AND 2 AND 3
		// 1 OR 2 OR 3
		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);

		String soql = conditions.endConditions().toSoqlString();
		return (List<Apttus__APTS_Agreement__c>)Database.query(soql);
	}



	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
			builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
		}

		if(selectorOptions.contains(Options.WITH_OWNER)) {
			builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
		}
		if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
			builder.addRelatedFields(AccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Apttus__Account__r');
		}
		if(selectorOptions.contains(Options.WITH_CONTACT)) {
			builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'Apttus__Primary_Contact__r');
		}
		if(selectorOptions.contains(Options.WITH_CREDIT_ASSESSMENT)) {
			builder.addRelatedFields(CreditsAssessmentSelector.newInstance().newQueryBuilder(), 'Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r');
		}
		if(selectorOptions.contains(Options.WITH_PROPOSAL)) {
			builder.addRelatedFields(ProposalSelector.newInstance().newQueryBuilder(), 'Apttus_QPComply__RelatedProposalId__r');
		}
		if(selectorOptions.contains(Options.WITH_OPPORTUNITY)) {
			builder.addRelatedFields(OpportunitySelector.newInstance().newQueryBuilder(), 'Apttus__Related_Opportunity__r');
		}
		return builder;
	}
}