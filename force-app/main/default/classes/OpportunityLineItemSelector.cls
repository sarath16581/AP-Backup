/**
 *  @author Harry Wang
 * @date 2023-04-12
 * @tag Selector
 * @tag Opportunity Product
 * @domain Core
 * @description A selector class that sits in the base domain for OpportunityLineItem
 * @changelog
 * 2023-04-12 - Harry Wang - Created
 * 2024-07-09 - Ken McGuire - added selector options to line item selector
 */
public with sharing class OpportunityLineItemSelector extends ApplicationSelector {
	public enum Options {
		WITH_OPPORTUNITY,
		WITH_PRODUCT
	}

	public static OpportunityLineItemSelector newInstance() {
		return (OpportunityLineItemSelector)Application.Selectors.newInstance(OpportunityLineItemSelector.class);
	}

	public static OpportunityLineItemSelector newInstance(Integer recordLimit) {
		return (OpportunityLineItemSelector)Application.Selectors.newInstance(OpportunityLineItemSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static OpportunityLineItemSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		OpportunityLineItemSelector selector = (OpportunityLineItemSelector)Application.Selectors.newInstance(OpportunityLineItemSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static OpportunityLineItemSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		OpportunityLineItemSelector selector = (OpportunityLineItemSelector)Application.Selectors.newInstance(OpportunityLineItemSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return OpportunityLineItem.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
				OpportunityLineItem.Id, OpportunityLineItem.Annualised_Value__c, OpportunityLineItem.Apttus_Approval__Approval_Status__c, OpportunityLineItem.Classification__c,
				OpportunityLineItem.ServiceDate, OpportunityLineItem.Close_Date__c, OpportunityLineItem.TotalPrice, OpportunityLineItem.Quantity
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public virtual List<OpportunityLineItem> selectById(Set<Id> ids) {
		QueryBuilder qb = newQueryBuilder().addConditions().add(new QueryBuilder.SimpleCondition(OpportunityLineItem.Id + ' in :ids')).endConditions();
		return Database.query(qb.toSoqlString());
	}

   /**
	 * @description Run a simple query to get records based on Id's and selector options
	 */
	public virtual List<OpportunityLineItem> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(OpportunityLineItem.Id + ' in :ids')).endConditions();
		return Database.query(qb.toSoqlString());
	}
    
	/**
	 * @description Select opportunity line item by given opportunity IDs
	 */
	public virtual List<OpportunityLineItem> selectByOpportunity(Set<Id> opportunityIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(OpportunityLineItem.OpportunityId + ' in :OpportunityIds')).endConditions();
		return Database.query(qb.toSoqlString());
	}

	/**
	 * @description Select opportunity line item by given opportunity IDs and Override condition
	 */
	public virtual List<OpportunityLineItem> selectByOPCCalculationOpportunityIds(Set<Id> opportunityIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
				.add(new QueryBuilder.SimpleCondition(OpportunityLineItem.OpportunityId + ' in :OpportunityIds'))
				.endConditions();
		return Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_OPPORTUNITY)) {
			builder.addRelatedFields(OpportunitySelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Opportunity');
		}

		if(selectorOptions.contains(Options.WITH_PRODUCT)) {
			builder.addRelatedFields(ProductsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Product2');
		}
		return builder;
	}
}