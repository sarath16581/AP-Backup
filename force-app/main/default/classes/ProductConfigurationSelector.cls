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
 * 2023-12-01 - Bharat Patel - Added APT_Configuration_Update_Version__c field to query
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
				Apttus_Config2__ProductConfiguration__c.Apttus_Config2__Status__c,Apttus_Config2__ProductConfiguration__c.APT_APPC_Count_in_Cart__c,Apttus_Config2__ProductConfiguration__c.OwnerId, Apttus_Config2__ProductConfiguration__c.APT_Configuration_Update_Version__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Apttus_Config2__ProductConfiguration__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, Apttus_Config2__ProductConfiguration__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		String Status = 'Finalized';
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c + ' in :ids'))
				.add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.Apttus_Config2__Status__c + ' =:Status')).endConditions();
		System.debug('Product Configuration QUERY>>>>>>>>>>>'+qb.toSoqlString());
		return new Map<Id, Apttus_Config2__ProductConfiguration__c>((List<Apttus_Config2__ProductConfiguration__c>)Database.query(qb.toSoqlString()));
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