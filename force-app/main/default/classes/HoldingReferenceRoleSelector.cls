/* @author Nathan Franklin
 * @date 2020-11-18
 * @group Tests
 * @tag Selector
 * @tag Holding Reference Role
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-11-18 - Shashwat.Nath@austpost.com.au - Created
 */
public with sharing class HoldingReferenceRoleSelector extends ApplicationSelector{
    public enum Options {
    WITH_RECORDTYPE, WITH_OWNER
    }
    public static HoldingReferenceRoleSelector newInstance() {
    return (HoldingReferenceRoleSelector)Application.Selectors.newInstance(HoldingReferenceRoleSelector.class);
    }
    public static HoldingReferenceRoleSelector newInstance(Integer recordLimit) {
    return (HoldingReferenceRoleSelector)Application.Selectors.newInstance(HoldingReferenceRoleSelector.class).setLimit(recordLimit);
    }
    /**
   * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
   * This approach removes data consistency and prevents possible caching of results
   */  
  public static HoldingReferenceRoleSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
    HoldingReferenceRoleSelector  selector = (HoldingReferenceRoleSelector)Application.Selectors.newInstance(HoldingReferenceRoleSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
    return selector;
    }
    /**
   * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
   * This approach removes data consistency and prevents possible caching of results
   */  
  public static HoldingReferenceRoleSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
    HoldingReferenceRoleSelector  selector = (HoldingReferenceRoleSelector)Application.Selectors.newInstance(HoldingReferenceRoleSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
    return selector;
    }    
    public virtual override SObjectType getSObjectType() {
    return Holding_Role_Reference__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
    return new Set<SObjectField> {
      Holding_Role_Reference__c.Id, Holding_Role_Reference__c.Name
    };
    }
    /**
   * @description Run a simple query to get records based on Id's
   */
  public virtual Map<Id, Holding_Role_Reference__c> selectByName(String Name) {
    return selectByName(Name , new Set<Object>());
    }
    /**
   * @description Run a simple query to get records based on Id's
   */
    
  public virtual Map<Id, Holding_Role_Reference__c> selectByName(String Name, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Holding_Role_Reference__c.name+ ' =:Name')).endConditions();
        system.debug('** Holding Role Query**'+qb.toSoqlString());
        return new Map<Id, Holding_Role_Reference__c>((List<Holding_Role_Reference__c>)Database.query(qb.toSoqlString()));
    }

    /**
	 * @description Run a simple query to get records based on Id's
	 */
    public Map<Id, Holding_Role_Reference__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, Holding_Role_Reference__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Holding_Role_Reference__c.Id + ' in :ids')).endConditions();
        return new Map<Id, Holding_Role_Reference__c>((List<Holding_Role_Reference__c>)Database.query(qb.toSoqlString()));
    }
    
    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
  }

  public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
    QueryBuilder builder = super.newQueryBuilder(selectorOptions);
    return builder;
  }
}