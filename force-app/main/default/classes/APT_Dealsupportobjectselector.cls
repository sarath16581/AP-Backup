/* @author Sri Harsha
* @date 2022-04-22
* @group Selector
* @tag Selector
* @tag Deal_Support_Request__c
* @domain Apttus
* @description A very simple selector class for Deal_Support_Request__c to get quote validty date
*/
public virtual inherited sharing class APT_Dealsupportobjectselector extends ApplicationSelector {
    public enum Options {
    }
    
    public static APT_Dealsupportobjectselector newInstance() {
        return (APT_Dealsupportobjectselector)Application.Selectors.newInstance(APT_Dealsupportobjectselector.class);
    }
    public static APT_Dealsupportobjectselector newInstance(Integer recordLimit) {
        return (APT_Dealsupportobjectselector)Application.Selectors.newInstance(APT_Dealsupportobjectselector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Deal_Support_Request__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Deal_Support_Request__c.Id,Deal_Support_Request__c.Quote_Validity_End_Date__c
                };
                    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual Map<Id, Deal_Support_Request__c> selectByConfigId(Set<Id> configIds) {
        return selectByConfigId(configIds, new Set<Object>());
    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual Map<Id, Deal_Support_Request__c> selectByConfigId(Set<Id> configIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Deal_Support_Request__c.ID + ' = :configIds'))
            .endConditions();
        return new Map<Id, Deal_Support_Request__c>((List<Deal_Support_Request__c>)Database.query(qb.toSoqlString()));
    }
    
}