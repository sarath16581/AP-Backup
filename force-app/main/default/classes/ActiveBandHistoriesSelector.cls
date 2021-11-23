/**
* @author Dish Kariya
* @date 2020-05-13
* @group Selector
* @tag Selector
* @tag Active Band History SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-05-12 - Disha Kariya - Created
*/
public virtual inherited sharing class ActiveBandHistoriesSelector extends ApplicationSelector {

    public enum Options {
        WITH_ACCOUNT
    }

    public static ActiveBandHistoriesSelector newInstance() {
        return (ActiveBandHistoriesSelector)Application.Selectors.newInstance(ActiveBandHistoriesSelector.class);
    }
    public static ActiveBandHistoriesSelector newInstance(Integer recordLimit) {
        return (ActiveBandHistoriesSelector)Application.Selectors.newInstance(ActiveBandHistoriesSelector.class).setLimit(recordLimit);
    }

    public override SObjectType getSObjectType() {
        return Active_Band_History__c.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                Active_Band_History__c.Id, Active_Band_History__c.Organisation__c, Active_Band_History__c.Band_Type__c, Active_Band_History__c.Offer_type__c, Active_Band_History__c.Change_Date__c, Active_Band_History__c.Freeze_End_Date__c, Active_Band_History__c.Product_Hierarchy__c
        };
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, Active_Band_History__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * @description Run a simple query to get records based on Id's
     */
    public Map<Id, Active_Band_History__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Active_Band_History__c.Id + ' in :ids')).endConditions();
        return new Map<Id, Active_Band_History__c>((List<Active_Band_History__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * @description Run a simple query to get Active Band Histories based on accountIds
     */
    public Map<Id, Active_Band_History__c> selectActiveBandHistoriesByAccountIds(Set<Id> accountIds) {
        return selectActiveBandHistoriesByAccountIds(accountIds, new Set<Object>());
    }

    /**
     * @description Run a simple query to get Active Band History based on accountId
     */
    public Map<Id, Active_Band_History__c> selectActiveBandHistoriesByAccountIds(Set<Id> accountIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Active_Band_History__c.Organisation__c + ' in :accountIds')).endConditions();
        qb.addOrderDesc('CreatedDate');
        return new Map<Id, Active_Band_History__c>((List<Active_Band_History__c>)Database.query(qb.toSoqlString()));
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_ACCOUNT)) {
            builder.addRelatedFields(AccountsSelector.newInstance().newQueryBuilder(), 'Organisation__r');
        }

        return builder;
    }



}