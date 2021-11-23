/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag Pick Up Location Selector
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-03-30 - Shashwat.nath@auspost.com.au - Created
 */
 
public with sharing class PickUpLocationSelector extends ApplicationSelector{
    public enum Options {
        FILTER_PRIMARY_PICKUP_LOCATION
    }
    public static PickUpLocationSelector newInstance() {
        return (PickUpLocationSelector)Application.Selectors.newInstance(PickUpLocationSelector.class);
    }
    public static PickUpLocationSelector newInstance(Integer recordLimit) {
        return (PickUpLocationSelector)Application.Selectors.newInstance(PickUpLocationSelector.class).setLimit(recordLimit);
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */ 
    public static PickUpLocationSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        PickUpLocationSelector selector = (PickUpLocationSelector)Application.Selectors.newInstance(PickUpLocationSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */ 
    public static PickUpLocationSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        PickUpLocationSelector selector = (PickUpLocationSelector)Application.Selectors.newInstance(PickUpLocationSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }    
    public virtual override SObjectType getSObjectType() {
        return Pick_Up_Location__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Pick_Up_Location__c.Id,Pick_Up_Location__c.Primary_Pick_Up_Location__c,Pick_Up_Location__c.Address__c, Pick_Up_Location__c.Postcode__c, Pick_Up_Location__c.Suburb__c
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual Map<Id, Pick_Up_Location__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }
    /**
     * @description Run a simple query to get records based on Id's
     */

    public virtual Map<Id, Pick_Up_Location__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Pick_Up_Location__c.Id + ' in :ids')).endConditions();
        System.debug('Pickup Location query>>>>>>>>>>>'+qb.toSoqlString());
        return new Map<Id, Pick_Up_Location__c>((List<Pick_Up_Location__c>)Database.query(qb.toSoqlString()));
    }
    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        if(selectorOptions.contains(Options.FILTER_PRIMARY_PICKUP_LOCATION)) {
             builder.addConditions().add(new QueryBuilder.SimpleCondition(Pick_Up_Location__c.Primary_Pick_Up_Location__c + '= true')).endConditions();    
        }
        
       return builder;
    }
}