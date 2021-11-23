/* @author Nathan Franklin
 * @date 2020-11-18
 * @group Tests
 * @tag Selector
 * @tag Credit Assessment
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-11-18 - shashwat.nath@austpost.com.au - Created
 */
public with sharing class ChargeAccountRequestSelector extends ApplicationSelector{
    public enum Options {
    WITH_RECORDTYPE, WITH_OWNER
    }
    public static ChargeAccountRequestSelector newInstance() {
    return (ChargeAccountRequestSelector)Application.Selectors.newInstance(ChargeAccountRequestSelector.class);
    }
    public static ChargeAccountRequestSelector newInstance(Integer recordLimit) {
    return (ChargeAccountRequestSelector)Application.Selectors.newInstance(ChargeAccountRequestSelector.class).setLimit(recordLimit);
    }
    /**
   * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
   * This approach removes data consistency and prevents possible caching of results
   */  
  public static ChargeAccountRequestSelector  newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
    ChargeAccountRequestSelector  selector = (ChargeAccountRequestSelector)Application.Selectors.newInstance(ChargeAccountRequestSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
    return selector;
    }
    /**
   * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
   * This approach removes data consistency and prevents possible caching of results
   */  
  public static ChargeAccountRequestSelector  newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
    ChargeAccountRequestSelector  selector = (ChargeAccountRequestSelector)Application.Selectors.newInstance(ChargeAccountRequestSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
    return selector;
    }    
    public virtual override SObjectType getSObjectType() {
    return APT_Charge_Account__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
    return new Set<SObjectField> {
      //APT_Credit_Assessment__c.Id, APT_Credit_Assessment__c.Name, APT_Credit_Assessment__c.APT_Charge_Account__c
      APT_Charge_Account__c.Id, APT_Charge_Account__c.Billing_Account__c, APT_Charge_Account__c.Status__c
    };
    }
    /**
   * @description Run a simple query to get records based on Id's
   */
  public virtual Map<Id, APT_Charge_Account__c> selectById(Set<Id> ids) {
    return selectById(ids, new Set<Object>());
    }
    /**
   * @description Run a simple query to get records based on Id's
   */
    
  public virtual Map<Id, APT_Charge_Account__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        System.debug('selectorOptions>>>'+selectorOptions);
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Charge_Account__c.Id + ' in :ids')).endConditions();
        System.debug('qb.toSoqlString()>>>>>'+qb.toSoqlString());
        return new Map<Id, APT_Charge_Account__c>((List<APT_Charge_Account__c>)Database.query(qb.toSoqlString()));
    }
    public virtual override QueryBuilder newQueryBuilder() {
    return newQueryBuilder(new Set<Object>());
  }

  public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
    QueryBuilder builder = super.newQueryBuilder(selectorOptions);

    if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
      builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
    }

    if(selectorOptions.contains(Options.WITH_OWNER)) {
      builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
        }
    return builder;
  }
}