/* @author Nathan Franklin
 * @date 2020-11-18
 * @group Tests
 * @tag Selector
 * @tag Credit Assessment
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-11-18 - arjun.singh@austpost.com.au - Created
 * 2021-03-22 - avula.jansiani@auspost.com.au  added 'APT_Credit_Assessment_Status__c'
 * 2023-02-08 - Harry Wang  added new method selectByOpportunityIds
 */
public with sharing class CreditsAssessmentSelector extends ApplicationSelector{
    public enum Options {
         WITH_OWNER,
         WITH_ORGANISATION,
         WITH_CREDIT_ASSESSMENT_NETWOKS
    }
    
    public static String sortOrder ='Desc';
    public static String sortfieldAPIName = 'Id'; 

    
    public static CreditsAssessmentSelector newInstance(String sortField, String order, Integer recordLimit){
        if(!String.isEmpty(sortField))
            sortfieldAPIName = sortField;
        if(!String.isEmpty(order))
            sortOrder = order;
        return (CreditsAssessmentSelector)Application.Selectors.newInstance(CreditsAssessmentSelector.class).setLimit(recordLimit);
    }
    
    public static CreditsAssessmentSelector newInstance() {
        return (CreditsAssessmentSelector)Application.Selectors.newInstance(CreditsAssessmentSelector.class);
    }
    public static CreditsAssessmentSelector newInstance(Integer recordLimit) {
        return (CreditsAssessmentSelector)Application.Selectors.newInstance(CreditsAssessmentSelector.class).setLimit(recordLimit);
    }
    
        /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */ 
     //Commenting it temporarily as it is not used at present
    public static CreditsAssessmentSelector newInstance( Set<SObjectField> fieldOverrides) {
        CreditsAssessmentSelector selector = (CreditsAssessmentSelector)Application.Selectors.newInstance(CreditsAssessmentSelector.class).setFieldOverrides(fieldOverrides);
        return selector;
    }
    
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */ 
     //Commenting it temporarily as it is not used at present
    public static CreditsAssessmentSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        CreditsAssessmentSelector selector = (CreditsAssessmentSelector)Application.Selectors.newInstance(CreditsAssessmentSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    //Commenting it temporarily as it is not used at present
    public static CreditsAssessmentSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        CreditsAssessmentSelector selector = (CreditsAssessmentSelector)Application.Selectors.newInstance(CreditsAssessmentSelector.class).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */ 
     //Commenting it temporarily as it is not used at present
    /*public static CreditsAssessmentSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        CreditsAssessmentSelector selector = (CreditsAssessmentSelector)Application.Selectors.newInstance(CreditsAssessmentSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    } */   
    public virtual override SObjectType getSObjectType() {
        return APT_Credit_Assessment__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            APT_Credit_Assessment__c.Id, APT_Credit_Assessment__c.Name, APT_Credit_Assessment__c.APT_Charge_Account__c, APT_Credit_Assessment__c.Aus_Post_Proposed_for_New_Account__c, APT_Credit_Assessment__c.APT_Credit_Assessment_Status__c,
			APT_Credit_Assessment__c.StarTrack_Proposed_for_New_Account__c, APT_Credit_Assessment__c.Integration_Status__c
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual Map<Id, APT_Credit_Assessment__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    
    public virtual Map<Id, APT_Credit_Assessment__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {        
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(APT_Credit_Assessment__c.Id + ' in :ids')).endConditions();        
        return new Map<Id, APT_Credit_Assessment__c>((List<APT_Credit_Assessment__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * *Query all the Creditassesments for the given org except the 'caId'
     * */
    public Map<Id, APT_Credit_Assessment__c> selectByExcludeId(Id caId, Id orgId) {
        QueryBuilder qb = newQueryBuilder(new Set<Object>()).addConditions().add(new QueryBuilder.SimpleCondition(APT_Credit_Assessment__c.Id + ' != :caId')).endConditions();
        qb.addConditions().add(new QueryBuilder.CompareCondition(APT_Credit_Assessment__c.APT_Organisation_Name__c).eq(orgId)).endConditions();
        return new Map<Id, APT_Credit_Assessment__c>((List<APT_Credit_Assessment__c>)Database.query(qb.toSoqlString()));
    }

    public List<APT_Credit_Assessment__c> selectByOpportunityIds(Set<Id> OpportunityIds){
        QueryBuilder qb = newQueryBuilder().addRelatedFields(APT_ProposalObjectsSelector.newInstance(0, fieldOverrides).newQueryBuilder(), 'APT_Proposal__r')
                .addConditions().add(new QueryBuilder.SimpleCondition('APT_Proposal__r.Apttus_Proposal__Opportunity__c IN :OpportunityIds'))
                .endConditions();
        return Database.query(qb.toSoqlString());
    }

    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }
    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        /*if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
            builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
        }*/

        if(selectorOptions.contains(Options.WITH_OWNER)) {
            builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
        }
        
        if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
            builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'APT_Organisation_Name__r');
        }
        
        if(selectorOptions.contains(Options.WITH_CREDIT_ASSESSMENT_NETWOKS)) {
            Set<Object> canOptions = new Set<Object>();
            canOptions.add(CreditsAssessmentNetworkSelector.Options.WITH_NETWORK);
            builder.addSubQuery(CreditsAssessmentNetworkSelector.newInstance().newQueryBuilder(canOptions), 'Credit_Assessment_Networks__r');
        }
        
        return builder;
    }
    
    /**
     * Forces an order to be applied to any query built with QueryBuilder. This can be overridden if needed
     */
    public virtual override List<QueryBuilder.Order> getOrderBy() {
        return new List<QueryBuilder.Order>{new QueryBuilder.Order(sortfieldAPIName, sortOrder)};
    }
}