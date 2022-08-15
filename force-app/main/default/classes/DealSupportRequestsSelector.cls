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
 * 2022-04-08 - Seth.Heang@auspost.com.au - added APPC related field in SOQL and added search method
 * 2022-05-27 - nasir.jawed@auspost.com.au - added account related field in SOQL  WITH_ORGANISATION
 */
public with sharing class DealSupportRequestsSelector extends ApplicationSelector{
    public enum Options {
        WITH_RECORDTYPE, WITH_OWNER , WITH_PRIMARYCONTACT , WITH_CHARGE_ACCOUNT_REQUEST , WITH_CREDIT_ASSESSMENT, WITH_OPPORTUNITY, WITH_CONTRACT, WITH_ORGANISATION
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
            Deal_Support_Request__c.Sub_Accounts__c , Deal_Support_Request__c.Requestor__c, Deal_Support_Request__c.Compass_Quote_Reference__c, Deal_Support_Request__c.Approved_Event__c,Deal_Support_Request__c.Opportunity__c,Deal_Support_Request__c.Stage__c, Deal_Support_Request__c.Status__c, Deal_Support_Request__c.Product__c,Deal_Support_Request__c.Approved_Pricing_Structure__c,Deal_Support_Request__c.Approved_lodgement_zone__c,Deal_Support_Request__c.Quote_Validity_End_Date__c,Deal_Support_Request__c.Approved_Tier__c
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

    /**
     * Run a SOQL based on the search parameters passed in
     *
     * @param searchParams A map containing searchable values:
     *                       opportunityIds: maps to Opportunity Id (Set<Id>/Id)
     *                       recTypeIds: maps to Record Type Id (Set<Id>/Id)
     *                       productNames: maps to Product Name (Set<String>/String)
     *
     *
     * @param selectorOptions Selector Options
     * @param matchAll If true will search based on AND, else search based on OR
     */
    public virtual List<Deal_Support_Request__c> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
        QueryBuilder builder = newQueryBuilder(selectorOptions);
        // add our tracking query
        QueryBuilder.ConditionsManager conditions = builder.addConditions();

        Set<Id> opportunityIds = (Set<Id>)(searchParams.get('opportunityIds') == null ? new Set<Id>() : (searchParams.get('opportunityIds') instanceof Set<Id> ? searchParams.get('opportunityIds') : new Set<Id>{(Id)searchParams.get('opportunityIds')}));
        Set<Id> recTypeIds = (Set<Id>)(searchParams.get('recTypeIds') == null ? new Set<Id>() : (searchParams.get('recTypeIds') instanceof Set<Id> ? searchParams.get('recTypeIds') : new Set<Id>{(Id)searchParams.get('recTypeIds')}));
        Set<String> productNames = (Set<String>)(searchParams.get('productNames') == null ? new Set<String>() : (searchParams.get('productNames') instanceof Set<String> ? searchParams.get('productNames') : new Set<String>{String.valueOf(searchParams.get('productNames'))}));

        Integer conditionCount = 0;
        if(searchParams.containsKey('opportunityIds')) {
            conditions.add(new QueryBuilder.SimpleCondition(Deal_Support_Request__c.Opportunity__c + ' in :opportunityIds'));
            conditionCount++;
        }
        if(searchParams.containsKey('recTypeIds')) {
            conditions.add(new QueryBuilder.SimpleCondition(Deal_Support_Request__c.RecordTypeId + ' in :recTypeIds'));
            conditionCount++;
        }
        if(searchParams.containsKey('productNames')) {
            conditions.add(new QueryBuilder.SimpleCondition(Deal_Support_Request__c.Product__c + ' in :productNames'));
            conditionCount++;
        }

        // build our condition string which would end up being something liek the following:
        // 1 AND 2 AND 3
        // 1 OR 2 OR 3
        String conditionOrder = '';
        for(Integer i=0;i<conditionCount;i++) {
            conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
        }
        conditions.setConditionOrder(conditionOrder);

        String soql = conditions.endConditions().toSoqlString();
        system.debug('soql:'+ soql);
        return (List<Deal_Support_Request__c>)Database.query(soql);
    }

    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
            builder.addRelatedFields(AccountsSelector.newInstance(recordLimit, fieldOverrides).newQueryBuilder(selectorOptions), 'Organisation__r');
        }
       
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
        
		if(selectorOptions.contains(Options.WITH_CONTRACT)) {
            builder.addRelatedFields(ApttusContractsSelector.newInstance().newQueryBuilder(), 'APT_Contract__r');
        }

		if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
            builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'Organisation__r');
        }
		
        return builder;
    }
}