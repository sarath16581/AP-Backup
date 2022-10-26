/**
* @author Nasir Jawed
* @date 2022-05-13
* @description APT_UsagePriceTierSelector helps to get values of all the API's lineitem matching the KEY.
* @changelog
*/
public virtual inherited sharing class APT_UsagePriceTierSelector extends ApplicationSelector {
    public enum Options {
    }
    
    public static APT_UsagePriceTierSelector newInstance() {
        return (APT_UsagePriceTierSelector)Application.Selectors.newInstance(APT_UsagePriceTierSelector.class);
    }
    public static APT_UsagePriceTierSelector newInstance(Integer recordLimit) {
        return (APT_UsagePriceTierSelector)Application.Selectors.newInstance(APT_UsagePriceTierSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Apttus_Config2__UsagePriceTier__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus_Config2__UsagePriceTier__c.Id,Apttus_Config2__UsagePriceTier__c.Apttus_Config2__LineItemId__c,
            Apttus_Config2__UsagePriceTier__c.Apttus_Config2__Dimension4Value__c,Apttus_Config2__UsagePriceTier__c.Apttus_Config2__Dimension2Value__c,
            Apttus_Config2__UsagePriceTier__c.Apttus_Config2__AdjustmentAmount__c            
            };
    }
    
    /**
* @description Run a simple query to get records based on LineItem 
*/
    public virtual Map<Id, Apttus_Config2__UsagePriceTier__c> selectByLineItemId(List<ID> LineItemId) {
        return selectByLineItemId(LineItemId, new Set<Object>());
    }
    
    /**
* @description Run a simple query to get records based on LineItem to get usage price tier
*/
    public virtual Map<Id, Apttus_Config2__UsagePriceTier__c> selectByLineItemId(List<ID> LineItemId, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Config2__UsagePriceTier__c.Apttus_Config2__LineItemId__c + ' = :LineItemId'))
            .endConditions();
        return new Map<Id, Apttus_Config2__UsagePriceTier__c>((List<Apttus_Config2__UsagePriceTier__c>)Database.query(qb.toSoqlString()));
    }
    
}