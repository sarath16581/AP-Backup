/* @author NAsir Jawed
* @date 2022-05-09
* @group Selector
* @tag Selector
* @tag Apttus_Config2__ProductConfiguration__c
* @domain Apttus
* @description A very simple selector class for Apttus_Config2__ProductConfiguration__c to get createddate
*/
public with sharing class APT_ProductConfigurationsSelector extends ApplicationSelector {
    public enum Options {
    }
    
    public static APT_ProductConfigurationsSelector newInstance() {
        return (APT_ProductConfigurationsSelector)Application.Selectors.newInstance(APT_ProductConfigurationsSelector.class);
    }
    public static APT_ProductConfigurationsSelector newInstance(Integer recordLimit) {
        return (APT_ProductConfigurationsSelector)Application.Selectors.newInstance(APT_ProductConfigurationsSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Apttus_Config2__ProductConfiguration__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus_Config2__ProductConfiguration__c.Id,Apttus_Config2__ProductConfiguration__c.Name,Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c,
            Apttus_Config2__ProductConfiguration__c.Apttus_Config2__Status__c,Apttus_Config2__ProductConfiguration__c.APT_APPC_Count_in_Cart__c   
                };
    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual List<Apttus_Config2__ProductConfiguration__c> selectByConfigId(set<ID> configIds) {
        return selectByConfigId(configIds, new Set<Object>());
    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual List<Apttus_Config2__ProductConfiguration__c> selectByConfigId(set<ID> configIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.ID + ' = :configIds'))
            .endConditions();
        return (List<Apttus_Config2__ProductConfiguration__c>)Database.query(qb.toSoqlString());
    }
    
     /**
* @description Run a simple query to get records based on Proposal Id on Configuration record
*/
    public virtual List<Apttus_Config2__ProductConfiguration__c> selectByProposalId(set<ID> proposalIds) {
        return selectByProposalId(proposalIds, new Set<Object>());
    }    
   
    public virtual List<Apttus_Config2__ProductConfiguration__c> selectByProposalId(set<ID> proposalIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Config2__ProductConfiguration__c.Apttus_QPConfig__Proposald__c + ' = :proposalIds'))
            .endConditions();
        return (List<Apttus_Config2__ProductConfiguration__c>)Database.query(qb.toSoqlString());
    }
}