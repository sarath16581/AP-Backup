/* @author avaula.jansirani@auspost.com.au
* @date 2021-05-12
* @group Tests
* @tag Selector
* @tag Credit Assessment Network
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
*/
public without sharing class CreditsAssessmentNetworkSelector extends ApplicationSelector{
    
    public enum Options {
        WITH_NETWORK
    }
    
    public static CreditsAssessmentNetworkSelector newInstance() {
        return (CreditsAssessmentNetworkSelector)Application.Selectors.newInstance(CreditsAssessmentNetworkSelector.class);
    }
    
    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Credit_Assessment_Network__c.Id, Credit_Assessment_Network__c.Name, Credit_Assessment_Network__c.Credit_Assessment__c, Credit_Assessment_Network__c.Network__c  };
                }
    
    /**
    * @description Run a simple query to get records based on Id's
    */
    public virtual Map<Id, Credit_Assessment_Network__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }
    /**
    * @description Run a simple query to get records based on Id's
    */
    
    public virtual Map<Id, Credit_Assessment_Network__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {        
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Credit_Assessment_Network__c.Id + ' in :ids')).endConditions();        
        return new Map<Id, Credit_Assessment_Network__c>((List<Credit_Assessment_Network__c>)Database.query(qb.toSoqlString()));
    }
    
    public virtual override SObjectType getSObjectType() {
        return Credit_Assessment_Network__c.getSObjectType();
    }  
    
    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }
    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
        
        if(selectorOptions.contains(Options.WITH_NETWORK)) {
            builder.addRelatedFields(NetworksSelector.newInstance().newQueryBuilder(), 'Network__r');
        }
        
        return builder;
    }
}