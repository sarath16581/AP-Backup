/**************************************************
Type:         Selector class for OpportunityProductRevenueForecast__c
History:
--------------------------------------------------
2023-09-21    Ken McGuire - Created
**************************************************/
public virtual inherited sharing class OpportunityProductRevForecastSelector extends ApplicationSelector {

    public enum Options {
        WITH_OPPORTUNITY_PRODUCT
    }

    public static OpportunityProductRevForecastSelector newInstance() {
        return (OpportunityProductRevForecastSelector)Application.Selectors.newInstance(OpportunityProductRevForecastSelector.class);
    }

    public static OpportunityProductRevForecastSelector newInstance(Integer recordLimit) {
        return (OpportunityProductRevForecastSelector)Application.Selectors.newInstance(OpportunityProductRevForecastSelector.class).setLimit(recordLimit);
    }

    public override SObjectType getSObjectType() {
        return OpportunityProductRevenueForecast__c.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                OpportunityProductRevenueForecast__c.Id,
                OpportunityProductRevenueForecast__c.OpportunityProduct__c,
                OpportunityProductRevenueForecast__c.FinancialYear__c,
                OpportunityProductRevenueForecast__c.Rev1__c,
                OpportunityProductRevenueForecast__c.Rev2__c,
                OpportunityProductRevenueForecast__c.Rev3__c,
                OpportunityProductRevenueForecast__c.Rev4__c,
                OpportunityProductRevenueForecast__c.Rev5__c,
                OpportunityProductRevenueForecast__c.Rev6__c,
                OpportunityProductRevenueForecast__c.Rev7__c,
                OpportunityProductRevenueForecast__c.Rev8__c,
                OpportunityProductRevenueForecast__c.Rev9__c,
                OpportunityProductRevenueForecast__c.Rev10__c,
                OpportunityProductRevenueForecast__c.Rev11__c,
                OpportunityProductRevenueForecast__c.Rev12__c,
                OpportunityProductRevenueForecast__c.FCT1__c,
                OpportunityProductRevenueForecast__c.FCT2__c,
                OpportunityProductRevenueForecast__c.FCT3__c,
                OpportunityProductRevenueForecast__c.FCT4__c,
                OpportunityProductRevenueForecast__c.FCT5__c,
                OpportunityProductRevenueForecast__c.FCT6__c,
                OpportunityProductRevenueForecast__c.FCT7__c,
                OpportunityProductRevenueForecast__c.FCT8__c,
                OpportunityProductRevenueForecast__c.FCT9__c,
                OpportunityProductRevenueForecast__c.FCT10__c,
                OpportunityProductRevenueForecast__c.FCT11__c,
                OpportunityProductRevenueForecast__c.FCT12__c
        };
    }

    public Map<Id, OpportunityProductRevenueForecast__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    public Map<Id, OpportunityProductRevenueForecast__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(OpportunityProductRevenueForecast__c.Id + ' in :ids')).endConditions();
        return new Map<Id, OpportunityProductRevenueForecast__c>((List<OpportunityProductRevenueForecast__c>)Database.query(qb.toSoqlString()));
    }

    public Map<Id, OpportunityProductRevenueForecast__c> selectByOpportunityProductIds(Set<Id> opportunityProductIds) {
        return selectByOpportunityProductIds(opportunityProductIds, new Set<Object>());
    }

    public Map<Id, OpportunityProductRevenueForecast__c> selectByOpportunityProductIds(Set<Id> opportunityProductIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(OpportunityProductRevenueForecast__c.OpportunityProduct__c + ' in :opportunityProductIds')).endConditions();
        qb.addOrderDesc('CreatedDate');
        return new Map<Id, OpportunityProductRevenueForecast__c>((List<OpportunityProductRevenueForecast__c>)Database.query(qb.toSoqlString()));
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        return builder;
    }
}