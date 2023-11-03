/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag Product Configuration
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-03-30 - Shashwat.nath@auspost.com.au - Created
 * 2022-05-09 - NAsir Jawed - Added selectByConfigId, selectByProposalId methods
 * 22-11-30 - NAsir Jawed - Added methods selectByProposalIdAndStatusWithOrder
 * 2023-07-26 - NAsir Jawed - Added OwnerId field to query
 * 2023-10-31 - Ranjeewa Silva - Added search method with related proposal ids and product configuration status as supported search parameters.
 */
public virtual inherited sharing class ProductConfigurationSelector extends ApplicationSelector {
	public enum Options {
		WITH_LINE_ITEMS,WITH_ACCOUNT
	}

	public static ProductConfigurationSelector newInstance() {
		return (ProductConfigurationSelector)Application.Selectors.newInstance(ProductConfigurationSelector.class);
	}
	public static ProductConfigurationSelector newInstance(Integer recordLimit) {
		return (ProductConfigurationSelector)Application.Selectors.newInstance(ProductConfigurationSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ProductConfigurationSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ProductConfigurationSelector selector = (ProductConfigurationSelector)Application.Selectors.newInstance(ProductConfigurationSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *This approach removes data consistency and prevents possible caching of results
	 */
	public static ProductConfigurationSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ProductConfigurationSelector selector = (ProductConfigurationSelector)Application.Selectors.newInstance(ProductConfigurationSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return Apttus_Config2__ProductConfiguration__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				Apttus_Config2__ProductConfiguration__c.ID, Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c, Apttus_Config2__ProductConfiguration__c.Name,
				Apttus_Config2__ProductConfiguration__c.Apttus_Config2__Status__c,Apttus_Config2__ProductConfiguration__c.APT_APPC_Count_in_Cart__c,Apttus_Config2__ProductConfiguration__c.OwnerId
		};
	}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart config Id's
	*/
	public virtual List<Apttus_Config2__ProductConfiguration__c> selectByConfigId(set<ID> configIds) {
		return selectByConfigId(configIds, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Apttus shopping cart config Id's
	*/
	public virtual List<Apttus_Config2__ProductConfiguration__c> selectByConfigId(set<ID> configIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.ID + ' = :configIds'))
			.endConditions();
		return (List<Apttus_Config2__ProductConfiguration__c>)Database.query(qb.toSoqlString());
	}

	/**
	* @description Run a simple query to get records based on Proposal Id on Configuration record
	*/
	public virtual List<Apttus_Config2__ProductConfiguration__c> selectByProposalId(set<ID> proposalIds) {
		return selectByProposalId(proposalIds, new Set<Object>());
	}

	public virtual List<Apttus_Config2__ProductConfiguration__c> selectByProposalId(set<ID> proposalIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c + ' = :proposalIds'))
			.endConditions();
		return (List<Apttus_Config2__ProductConfiguration__c>)Database.query(qb.toSoqlString());
	}


	/**
	* @description Run a simple query to get records based on Proposal Id and status on Configuration record
	*/
	public virtual List<Apttus_Config2__ProductConfiguration__c> selectByProposalIdAndStatusWithOrder(Set<Id> proposalIds,Set<String> status) {
		return selectByProposalIdAndStatusWithOrder(proposalIds,status, new Set<Object>());
	}

	/**
	* @description Run a simple query to get records based on Proposal Id and status on Configuration record
	*/
	public virtual List<Apttus_Config2__ProductConfiguration__c> selectByProposalIdAndStatusWithOrder(Set<Id> proposalIds,Set<String> status, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);

		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c + ' = :proposalIds'))
			.add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.Apttus_Config2__Status__c+ '=:status'))
			.endConditions();
			qb.addOrderDesc(Apttus_Config2__ProductConfiguration__c.createdDate);
		return (List<Apttus_Config2__ProductConfiguration__c>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *					  - proposalIds: maps to Apttus_QPConfig__Proposald__c (Set<Id>/Id)
	 *					  - status: maps to Apttus_Config2__Status__c (Set<String>/String)
	 * @param selectorOptions Additional selector options to augment the result set
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @param orderByField If supplied together with 'sortDirection' parameter, sort results based on this field.
	 *						Uses Application Selector framework's default order if not specified.
	 * @param sortDirection If supplied together with 'orderByField' parameter, sort results based on the direction specified (ASC or DESC).
	 *						Uses Application Selector framework's default order if not specified.
	 *
	 * @return list of Product Configuration records.
	 */
	public List<Apttus_Config2__ProductConfiguration__c> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll, Schema.SobjectField orderByField, String sortDirection) {
		Set<Id> proposalIds = (Set<Id>)(searchParams.get('proposalIds') == null ? new Set<Id>() : (searchParams.get('proposalIds') instanceof Set<Id> ? searchParams.get('proposalIds') : new Set<Id>{(Id)searchParams.get('proposalIds')}));
		Set<String> status = (Set<String>)(searchParams.get('status') == null ? new Set<String>() : (searchParams.get('status') instanceof Set<String> ? searchParams.get('status') : new Set<String>{String.valueOf(searchParams.get('status'))}));
		return (List<Apttus_Config2__ProductConfiguration__c>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll, orderByField, sortDirection));
	}

	/**
	 * Generates the SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *					  - proposalIds: maps to Apttus_QPConfig__Proposald__c (Set<Id>/Id)
	 *					  - status: maps to Apttus_Config2__Status__c (Set<String>/String)
	 * @param selectorOptions Additional selector options to augment the result set
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @param orderByField If supplied together with 'sortDirection' parameter, sort results based on this field.
	 *						Uses Application Selector framework's default order if not specified.
	 * @param sortDirection If supplied together with 'orderByField' parameter, sort results based on the direction specified (ASC or DESC).
	 *						Uses Application Selector framework's default order if not specified.
	 *
	 * @return the generated SOQL
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll, Schema.SobjectField orderByField, String sortDirection) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'proposalIds', 'status'});

		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('proposalIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c  + ' in :proposalIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('status')) {
			conditions.add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.Apttus_Config2__Status__c + ' in :status'));
			conditionCount++;
		}

		// build our condition string which would end up being something like the following:
		// 1 AND 2 AND 3
		// 1 OR 2 OR 3
		String conditionOrder = '';
		for(Integer i=0;i<conditionCount;i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);

		if (orderByField != null && String.isNotBlank(sortDirection)) {
			QueryBuilder.Order qbOrderBy = new QueryBuilder.Order(String.valueOf(orderByField), sortDirection);
			builder.setOrder(qbOrderBy);
		}

		return conditions.endConditions().toSoqlString();
	}



	/**
	 * @description Grabs a new QueryBuilder based on the selector options passed in
	 */
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_LINE_ITEMS)) {
			builder.addSubQuery(LineItemsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(new Set<Object>{LineItemsSelector.Options.WITH_PRODUCT_ATTRIBUTE_VALUE}), 'Apttus_Config2__LineItems__r');
		}
		if(selectorOptions.contains(Options.WITH_ACCOUNT)) {
			builder.addRelatedFields(AccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(selectorOptions), 'Apttus_Config2__AccountId__r');
		}

		return builder;
	}

}