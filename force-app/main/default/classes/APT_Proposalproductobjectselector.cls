/* @author Sri Harsha
* @date 2022-04-22
* @group Selector
* @tag Selector
* @tag Apttus_QPConfig__ProposalProductAttributeValue__c
* @domain Apttus
* @description A very simple selector class for Apttus_QPConfig__ProposalProductAttributeValue__c to get quote validty date from deal supportrequest
*/
public virtual inherited sharing class APT_Proposalproductobjectselector extends ApplicationSelector {
    public enum Options {
    }
    
    public static APT_Proposalproductobjectselector newInstance() {
        return (APT_Proposalproductobjectselector)Application.Selectors.newInstance(APT_Proposalproductobjectselector.class);
    }
    public static APT_Proposalproductobjectselector newInstance(Integer recordLimit) {
        return (APT_Proposalproductobjectselector)Application.Selectors.newInstance(APT_Proposalproductobjectselector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Apttus_QPConfig__ProposalProductAttributeValue__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus_QPConfig__ProposalProductAttributeValue__c.Id
                };
                    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual Map<Id, Apttus_QPConfig__ProposalProductAttributeValue__c> selectByConfigId(Set<Id> configIds) {
        return selectByConfigId(configIds, new Set<Object>());
    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual Map<Id, Apttus_QPConfig__ProposalProductAttributeValue__c> selectByConfigId(Set<Id> configIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_QPConfig__ProposalProductAttributeValue__c.ID + ' = :configIds'))
            .endConditions();
        return new Map<Id, Apttus_QPConfig__ProposalProductAttributeValue__c>((List<Apttus_QPConfig__ProposalProductAttributeValue__c>)Database.query(qb.toSoqlString()));
    }
    
    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
                    builder.addRelatedFields(APT_Dealsupportobjectselector.newInstance().newQueryBuilder(), 'Applied_PSR__r');
        return builder;
        }
    
}