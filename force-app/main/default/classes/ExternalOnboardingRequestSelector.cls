/* @author Nathan Franklin
 * @date 2021-03-30
 * @group Tests
 * @tag Selector
 * @tag ExternalOnboardingRequestSelector
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-04-12 - Shashwat.nath@auspost.com.au - Created
 * 2022-08-04 - Seth Heang - Added Request_Object_Id__c field in the query
 */

public with sharing class ExternalOnboardingRequestSelector extends ApplicationSelector{
    public enum Options {
    }
    public static ExternalOnboardingRequestSelector newInstance() {
        return (ExternalOnboardingRequestSelector)Application.Selectors.newInstance(ExternalOnboardingRequestSelector.class);
    }
    public static ExternalOnboardingRequestSelector newInstance(Integer recordLimit) {
        return (ExternalOnboardingRequestSelector)Application.Selectors.newInstance(ExternalOnboardingRequestSelector.class).setLimit(recordLimit);
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static ExternalOnboardingRequestSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        ExternalOnboardingRequestSelector selector = (ExternalOnboardingRequestSelector)Application.Selectors.newInstance(ExternalOnboardingRequestSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static ExternalOnboardingRequestSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        ExternalOnboardingRequestSelector selector = (ExternalOnboardingRequestSelector)Application.Selectors.newInstance(ExternalOnboardingRequestSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    public virtual override SObjectType getSObjectType() {
        return BAMExternalOnboardingRequest__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField>{
                BAMExternalOnboardingRequest__c.Id, BAMExternalOnboardingRequest__c.Response_Payload__c, BAMExternalOnboardingRequest__c.CreatedDate, BAMExternalOnboardingRequest__c.Request_Object_Id__c
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual Map<Id, BAMExternalOnboardingRequest__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }
    /**
     * @description Run a simple query to get records based on Id's
     */

    public virtual Map<Id, BAMExternalOnboardingRequest__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(BAMExternalOnboardingRequest__c.Id + ' in :ids')).endConditions();
        System.debug('External Onboarding Record>>>>>>>>>>>'+qb.toSoqlString());
        return new Map<Id, BAMExternalOnboardingRequest__c>((List<BAMExternalOnboardingRequest__c>)Database.query(qb.toSoqlString()));
    }
    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        return builder;
    }
}