/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag LineItemSelector
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-03-30 - Shashwat.nath@auspost.com.au - Created
 * 2022-05-20 - nasir.jawed@auspost.com.au - added the method to get line item record by passing parameter config id and Line Type
 */

public with sharing class LineItemsSelector extends ApplicationSelector{
    public enum Options {
        WITH_PRODUCT_ATTRIBUTE_VALUE
    }
    public static LineItemsSelector newInstance() {
        return (LineItemsSelector)Application.Selectors.newInstance(LineItemsSelector.class);
    }
    public static LineItemsSelector newInstance(Integer recordLimit) {
        return (LineItemsSelector)Application.Selectors.newInstance(LineItemsSelector.class).setLimit(recordLimit);
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static LineItemsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        LineItemsSelector selector = (LineItemsSelector)Application.Selectors.newInstance(LineItemsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static LineItemsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        LineItemsSelector selector = (LineItemsSelector)Application.Selectors.newInstance(LineItemsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    public virtual override SObjectType getSObjectType() {
        return Apttus_Config2__LineItem__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField>{
                Apttus_Config2__LineItem__c.Id, Apttus_Config2__LineItem__c.Apttus_Config2__AttributeValueId__c,Apttus_Config2__LineItem__c.Apttus_Config2__LineType__c,Apttus_Config2__LineItem__c.APT_Product_Code__c,
                Apttus_Config2__LineItem__c.Apttus_Config2__ConfigurationId__c,Apttus_Config2__LineItem__c.Compass_LineItem_Identifier__c,
                Apttus_Config2__LineItem__c.Apttus_Config2__NetPrice__c,Apttus_Config2__LineItem__c.SAP_Custom_Reference__c,
                Apttus_Config2__LineItem__c.Apttus_Config2__IsCustomPricing__c,Apttus_Config2__LineItem__c.Apttus_Config2__PricingStatus__c,Apttus_Config2__LineItem__c.Apttus_Config2__AddedByRuleInfo__c 
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual Map<Id, Apttus_Config2__LineItem__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }
    /**
     * @description Run a simple query to get records based on Id's
     */

    public virtual Map<Id, Apttus_Config2__LineItem__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus_Config2__LineItem__c.Id + ' in :ids')).endConditions();
        System.debug('Line Item Query>>>>>>>>>>>'+qb.toSoqlString());
        return new Map<Id, Apttus_Config2__LineItem__c>((List<Apttus_Config2__LineItem__c>)Database.query(qb.toSoqlString()));
    }

	/**
	 * @description Run a query by passing the prod config id
	 */
	public virtual List<Apttus_Config2__LineItem__c> selectByProdConfId(set<ID> prodConfIds) {
		return selectByProdConfId(prodConfIds, new Set<Object>());
	}

	public virtual List<Apttus_Config2__LineItem__c> selectByProdConfId(Set<ID> prodConfIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions)
		.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Config2__LineItem__c.Apttus_Config2__ConfigurationId__c + ' = :prodConfIds'))
		.endConditions();
		return new List<Apttus_Config2__LineItem__c>((List<Apttus_Config2__LineItem__c>)Database.query(qb.toSoqlString()));
	}

	/**
	* @description Run a query by passing the prod config id, LineType
	*/
	public virtual List<Apttus_Config2__LineItem__c> selectByProdConfigAndLineType(Set<ID> prodConfigIds, Set<String> lineType) {
		return selectByProdConfigAndLineType(prodConfigIds, lineType, new Set<Object>());
	}

	/**
	* @description Run a query by passing the prod config id, LineType
	*/
	public virtual List<Apttus_Config2__LineItem__c> selectByProdConfigAndLineType(Set<ID> prodConfigIds, Set<String> lineType, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions()
			.add(new QueryBuilder.SimpleCondition(Apttus_Config2__LineItem__c.Apttus_Config2__ConfigurationId__c + ' = :prodConfigIds'))
			.add(new QueryBuilder.SimpleCondition(Apttus_Config2__LineItem__c.Apttus_Config2__LineType__c + ' = :lineType'))
		.endConditions();
		return new List<Apttus_Config2__LineItem__c>((List<Apttus_Config2__LineItem__c>)Database.query(qb.toSoqlString()));
	}
	/**
	 * @description Using query builder to get the fields from Product Attribute Value objects
	 */
	public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_PRODUCT_ATTRIBUTE_VALUE)) {
			builder.addRelatedFields(APT_ProductAttributeValuesSelector.newInstance().newQueryBuilder(), 'Apttus_Config2__AttributeValueId__r');
		}
		return builder;
	}
    
    public virtual Map<Id, Apttus_Config2__LineItem__c> selectByProdConfId(ID lineItemIds) {
        return selectByProdConfId(lineItemIds, new Set<Object>());
    }
    
    public virtual Map<Id, Apttus_Config2__LineItem__c> selectByProdConfId(ID ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus_Config2__LineItem__c.Apttus_Config2__ConfigurationId__c + ' = :ids')).endConditions();
        System.debug('totallineItem'+qb.toSoqlString());
        return new Map<Id, Apttus_Config2__LineItem__c>((List<Apttus_Config2__LineItem__c>)Database.query(qb.toSoqlString()));
    }
}