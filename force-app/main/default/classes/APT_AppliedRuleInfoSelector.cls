/* @author Nasir Jawed
* @date 2022-10-10
* @group Selector
* @tag Selector
* @tag Apttus_Config2__AppliedRuleInfo__c
* @domain Apttus
* @description A very simple selector class for Apttus_Config2__AppliedRuleInfo__c to get field values
* @changelog: 
* 
* 
*/
public virtual inherited sharing class APT_AppliedRuleInfoSelector extends ApplicationSelector {
    public enum Options {
    }
    
    public static APT_AppliedRuleInfoSelector newInstance() {
        return (APT_AppliedRuleInfoSelector)Application.Selectors.newInstance(APT_AppliedRuleInfoSelector.class);
    }
    public static APT_AppliedRuleInfoSelector newInstance(Integer recordLimit) {
        return (APT_AppliedRuleInfoSelector)Application.Selectors.newInstance(APT_AppliedRuleInfoSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Apttus_Config2__AppliedRuleInfo__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus_Config2__AppliedRuleInfo__c.Id,Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__Invalid__c,
            Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__ConstraintRuleId__c,Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__PrimaryLineNumber__c,
            Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__NeedProcessing__c ,Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__ConfigurationId__c 
            };
    }
    
    /**
* @description Run a simple query to get records based on LineItem 
*/
    public virtual List<Apttus_Config2__AppliedRuleInfo__c> selectByConfigId(Set<ID> configId) {
        return selectByConfigId(configId, new Set<Object>());
    }
    
    /**
* @description Run a simple query to get records based on LineItem to get usage price tier
*/
    public virtual List<Apttus_Config2__AppliedRuleInfo__c> selectByConfigId(set<ID> configId, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Config2__AppliedRuleInfo__c.Apttus_Config2__ConfigurationId__c + ' = :configId'))
            .endConditions();
        return new List<Apttus_Config2__AppliedRuleInfo__c>((List<Apttus_Config2__AppliedRuleInfo__c>)Database.query(qb.toSoqlString()));
    }
    
}