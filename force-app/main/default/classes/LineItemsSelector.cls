/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag LineItemSelector
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-03-30 - Shashwat.nath@auspost.com.au - Created
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
                Apttus_Config2__LineItem__c.Id, Apttus_Config2__LineItem__c.Apttus_Config2__AttributeValueId__c
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
    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        if(selectorOptions.contains(Options.WITH_PRODUCT_ATTRIBUTE_VALUE)) {
            builder.addRelatedFields(ProductAttributeValueSelector.newInstance().newQueryBuilder(), 'Apttus_Config2__AttributeValueId__r');
        }

        return builder;
    }
}