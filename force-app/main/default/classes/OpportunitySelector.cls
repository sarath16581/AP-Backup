/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag Opportunity
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-03-30 - Shashwat.nath@auspost.com.au - Created
 * 2021-06-08 - Seth.heang@auspost.com.au - Added Sender_name_to_appear_on_parcel_label__c field into query
 */

public with sharing class OpportunitySelector extends ApplicationSelector{
    public enum Options {

    }
    public static OpportunitySelector newInstance() {
        return (OpportunitySelector)Application.Selectors.newInstance(OpportunitySelector.class);
    }
    public static OpportunitySelector newInstance(Integer recordLimit) {
        return (OpportunitySelector)Application.Selectors.newInstance(OpportunitySelector.class).setLimit(recordLimit);
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static OpportunitySelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        OpportunitySelector selector = (OpportunitySelector)Application.Selectors.newInstance(OpportunitySelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static OpportunitySelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        OpportunitySelector selector = (OpportunitySelector)Application.Selectors.newInstance(OpportunitySelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    public virtual override SObjectType getSObjectType() {
        return Opportunity.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField>{
                Opportunity.Id, Opportunity.Primary_Pick_Up_Location__c, Opportunity.Sender_name_to_appear_on_parcel_label__c, Opportunity.Opportunity_Number__c
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */

    public virtual Map<Id, Opportunity> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }
    /**
     * @description Run a simple query to get records based on Id's
     */

    public virtual Map<Id, Opportunity> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Opportunity.Id + ' in :ids')).endConditions();
        System.debug('Opportunity query>>>>>>>>>>>'+qb.toSoqlString());
        return new Map<Id, Opportunity>((List<Opportunity>)Database.query(qb.toSoqlString()));
    }
    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        return builder;
    }
}