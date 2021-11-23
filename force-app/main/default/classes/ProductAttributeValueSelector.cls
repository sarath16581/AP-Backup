/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag Product Attribute Value
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-03-30 - Shashwat.nath@auspost.com.au - Created
 */

public with sharing class ProductAttributeValueSelector extends ApplicationSelector{
    public enum Options {

    }
    public static ProductAttributeValueSelector newInstance() {
        return (ProductAttributeValueSelector)Application.Selectors.newInstance(ProductAttributeValueSelector.class);
    }
    public static ProductAttributeValueSelector newInstance(Integer recordLimit) {
        return (ProductAttributeValueSelector)Application.Selectors.newInstance(ProductAttributeValueSelector.class).setLimit(recordLimit);
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static ProductAttributeValueSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        ProductAttributeValueSelector selector = (ProductAttributeValueSelector)Application.Selectors.newInstance(ProductAttributeValueSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static ProductAttributeValueSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        ProductAttributeValueSelector selector = (ProductAttributeValueSelector)Application.Selectors.newInstance(ProductAttributeValueSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    public virtual override SObjectType getSObjectType() {
        return Apttus_Config2__ProductAttributeValue__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                Apttus_Config2__ProductAttributeValue__c.Id,Apttus_Config2__ProductAttributeValue__c.APT_StarTrack_Service_Type__c,
                Apttus_Config2__ProductAttributeValue__c.Service_Code_Startrack__c
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual Map<Id, Apttus_Config2__ProductAttributeValue__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }
    /**
     * @description Run a simple query to get records based on Id's
     */

    public virtual Map<Id, Apttus_Config2__ProductAttributeValue__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductAttributeValue__c.Id + ' in :ids')).endConditions();
        System.debug('Product Attribute Query>>>>>>>>>>>'+qb.toSoqlString());
        return new Map<Id, Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(qb.toSoqlString()));
    }
    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        return builder;
    }
}