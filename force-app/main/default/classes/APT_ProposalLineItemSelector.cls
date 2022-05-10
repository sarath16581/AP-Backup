/* @author Sri Harsha
* @date 2022-04-22
* @group Selector
* @tag Selector
* @tag Apttus_Proposal__Proposal_Line_Item__c 
* @domain Apttus
* @description A very simple selector class for Apttus_Proposal__Proposal_Line_Item__c  to populate expiration date
*/
public virtual inherited sharing class APT_ProposalLineItemSelector extends ApplicationSelector {
    public enum Options {
    WITH_PROPOSAL,WITH_APTTUS_CONFIG_ATTRIBUTE_VALUE
    }
    
    public static APT_ProposalLineItemSelector newInstance() {
        return (APT_ProposalLineItemSelector)Application.Selectors.newInstance(APT_ProposalLineItemSelector.class);
    }
    public static APT_ProposalLineItemSelector newInstance(Integer recordLimit) {
        return (APT_ProposalLineItemSelector)Application.Selectors.newInstance(APT_ProposalLineItemSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return Apttus_Proposal__Proposal_Line_Item__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus_Proposal__Proposal_Line_Item__c.Id,Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__AttributeValueId__c,Apttus_Proposal__Proposal_Line_Item__c.Apttus_Proposal__Proposal__c
                };
                    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual Map<Id, Apttus_Proposal__Proposal_Line_Item__c> selectByConfigId(Set<Id> configIds) {
        return selectByConfigId(configIds, new Set<Object>());
    }
    
    /**
* @description Run a simple query to get records based on Apttus shopping cart config Id's
*/
    public virtual Map<Id, Apttus_Proposal__Proposal_Line_Item__c> selectByConfigId(Set<Id> configIds, Set<Object> selectorOptions) {
      string type=APT_Constants.PARAM_PRODUCT_Type;
      string prodtype=APT_Constants.PARAM_APPC_PRODUCT;
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__ConfigurationId__c + ' = :configIds'))
            .endConditions();
            //+'AND' +Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__LineType__c+ ' =:type'+'AND' +Apttus_Proposal__Proposal_Line_Item__c.APT_Bundle_Product_Name__c +' =:prodtype'
       qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal_Line_Item__c.Apttus_QPConfig__LineType__c+ ' =:type'))
            .endConditions();
            qb.addConditions()
            .add(new QueryBuilder.SimpleCondition(Apttus_Proposal__Proposal_Line_Item__c.APT_Bundle_Product_Name__c+ ' =:prodtype'))
            .endConditions();
        return new Map<Id, Apttus_Proposal__Proposal_Line_Item__c>((List<Apttus_Proposal__Proposal_Line_Item__c>)Database.query(qb.toSoqlString()));
    }
    
      public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);
                  //  builder.addRelatedFields(APT_Proposalproductobjectselector.newInstance().newQueryBuilder(), 'Apttus_QPConfig__AttributeValueId__r');
                   // builder.addRelatedFields(APT_ProposalObjectsSelector.newInstance().newQueryBuilder(), 'Apttus_Proposal__Proposal__r');
   
        if(selectorOptions.contains(Options.WITH_PROPOSAL)) {
                         System.debug('here');
                  builder.addRelatedFields(APT_ProposalObjectsSelector.newInstance().newQueryBuilder(), 'Apttus_Proposal__Proposal__r');
              }
          if(selectorOptions.contains(Options.WITH_APTTUS_CONFIG_ATTRIBUTE_VALUE)) {
               System.debug('here');
              builder.addRelatedFields(APT_Proposalproductobjectselector.newInstance().newQueryBuilder(), 'Apttus_QPConfig__AttributeValueId__r');
           }

        return builder;
        }
    
}