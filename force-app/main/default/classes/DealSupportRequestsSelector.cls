/* @author Nathan Franklin
 * @date 2020-11-18
 * @group Tests
 * @tag Selector
 * @tag Deal Support Request
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-11-18 - arjun.singh@austpost.com.au - Created
 * 2020-11-18 - Shashwat.nath@auspost.com.au - updated to add related fields with primary contact and Charge Account Request
 * 2021-06-08 - Seth.Heang@auspost.com.au - updated to add related lookup fields with opportunity
 * 2022-06-02 - dattaraj.deshmukh@slalom.com - updated to add Last_Implementation_Stage_Update__c field. 
 */
public with sharing class DealSupportRequestsSelector extends ApplicationSelector{
    public enum Options {
        WITH_RECORDTYPE, WITH_OWNER , WITH_PRIMARYCONTACT , WITH_CHARGE_ACCOUNT_REQUEST , WITH_CREDIT_ASSESSMENT, WITH_OPPORTUNITY
    }
    public static DealSupportRequestsSelector newInstance() {
        return (DealSupportRequestsSelector)Application.Selectors.newInstance(DealSupportRequestsSelector.class);
    }
    public static DealSupportRequestsSelector newInstance(Integer recordLimit) {
        return (DealSupportRequestsSelector)Application.Selectors.newInstance(DealSupportRequestsSelector.class).setLimit(recordLimit);
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */ 
    public static DealSupportRequestsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        DealSupportRequestsSelector selector = (DealSupportRequestsSelector)Application.Selectors.newInstance(DealSupportRequestsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */ 
    public static DealSupportRequestsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        DealSupportRequestsSelector selector = (DealSupportRequestsSelector)Application.Selectors.newInstance(DealSupportRequestsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }    
    public virtual override SObjectType getSObjectType() {
        return Deal_Support_Request__c.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Deal_Support_Request__c.Id,Deal_Support_Request__c.Name, Deal_Support_Request__c.APT_Contract__c, Deal_Support_Request__c.Integration_Status__c , Deal_Support_Request__c.Work_Type__c,
            Deal_Support_Request__c.Billing_Account_Change_of_Details_Type__c, Deal_Support_Request__c.OwnerId, Deal_Support_Request__c.Credit_Work_Type__c, Deal_Support_Request__c.Lodgement_Point_to_Work_Centre_Code__c,
            Deal_Support_Request__c.Sub_Accounts__c , Deal_Support_Request__c.Requestor__c, Deal_Support_Request__c.Last_Implementation_Stage_Update__c 
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual Map<Id, Deal_Support_Request__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
    * @description Run a simple query to get records based on Id's
    */
    public virtual Map<Id, Deal_Support_Request__c> selectByRecordList(List<Deal_Support_Request__c> dsrList) {
        return selectByRecordList(dsrList, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on Id's
     */

    public virtual Map<Id, Deal_Support_Request__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Deal_Support_Request__c.Id + ' in :ids')).endConditions();
        return new Map<Id, Deal_Support_Request__c>((List<Deal_Support_Request__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * @description Run a simple query to get records based on Recordlist
     */
    public virtual Map<Id, Deal_Support_Request__c> selectByRecordList(List<Deal_Support_Request__c> dsrList, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Deal_Support_Request__c.Id + ' in :dsrList')).endConditions();
        return new Map<Id, Deal_Support_Request__c>((List<Deal_Support_Request__c>)Database.query(qb.toSoqlString()));
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
        
        if(selectorOptions.contains(Options.WITH_PRIMARYCONTACT)) {
            builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'APT_Contract__r.Apttus__Primary_Contact__r');
        }
        
        if(selectorOptions.contains(Options.WITH_CHARGE_ACCOUNT_REQUEST)) {
            builder.addRelatedFields(ChargeAccountRequestSelector.newInstance().newQueryBuilder(), 'APT_Contract__r.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r.APT_Charge_Account__r');
        }
        
        if(selectorOptions.contains(Options.WITH_CREDIT_ASSESSMENT)) {
            System.debug('here');
            builder.addRelatedFields(CreditsAssessmentSelector.newInstance().newQueryBuilder(), 'APT_Contract__r.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r');
        }
        
        if(selectorOptions.contains(Options.WITH_OPPORTUNITY)) {
            builder.addRelatedFields(OpportunitySelector.newInstance().newQueryBuilder(), 'Opportunity__r');
        }
        
        return builder;
    }
}