/**
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group Selector
 * @tag Selector
 * @tag Disputed_Item__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created
 */

public inherited sharing class DisputedItemsSelector extends ApplicationSelector {

    public static DisputedItemsSelector newInstance() {
        return (DisputedItemsSelector)Application.Selectors.newInstance(DisputedItemsSelector.class);
    }
    public static DisputedItemsSelector newInstance(Integer recordLimit) {
        return (DisputedItemsSelector)Application.Selectors.newInstance(DisputedItemsSelector.class).setLimit(recordLimit);
    }

    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
    public static DisputedItemsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        DisputedItemsSelector selector = (DisputedItemsSelector)Application.Selectors.newInstance(DisputedItemsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * Run a simple query to get records based on case Ids
     *
     * @param caseIds set of case ids
     * @return matching Disputed Items
     */
    public virtual Map<Id, Disputed_Item__c> selectByCaseId(Set<Id> caseIds) {
        return selectByCaseId(caseIds, new Set<Object>());
    }

    /**
     * Run a simple query to get records based on case Ids. Also supports passing in selector options to augment the
     * result set returned.
     *
     * @param caseIds set of case ids
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return matching Disputed Items
     */
    public virtual Map<Id, Disputed_Item__c> selectByCaseId(Set<Id> caseIds, Set<Object> selectorOptions) {
        QueryBuilder qb = getDisputedItemsByCaseIdQueryBuilder(caseIds, selectorOptions);
        return new Map<Id, Disputed_Item__c>((List<Disputed_Item__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * Returns a Database.QueryLocator for retrieving Disputed Items by case Ids.
     *
     * @param caseIds set of case ids
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return Database.QueryLocator instance
     */
    public virtual Database.QueryLocator selectByCaseIdQueryLocator(Set<Id> caseIds, Set<Object> selectorOptions) {
        QueryBuilder qb = getDisputedItemsByCaseIdQueryBuilder(caseIds, selectorOptions);
        return Database.getQueryLocator(qb.toSoqlString());
    }

    private virtual QueryBuilder getDisputedItemsByCaseIdQueryBuilder(Set<Id> caseIds, Set<Object> selectorOptions) {
        return newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Disputed_Item__c.Case__c + ' in :caseIds')).endConditions();
    }

    protected override SObjectType getSObjectType() {
        return Disputed_Item__c.getSObjectType();
    }

    protected override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField>{
                Disputed_Item__c.Id, Disputed_Item__c.Case__c, Disputed_Item__c.Status__c, Disputed_Item__c.Invoice_Number__c,
                Disputed_Item__c.Transaction_ID__c, Disputed_Item__c.Connote__c, Disputed_Item__c.Amount__c, Disputed_Item__c.Amount_Claimed__c,
                Disputed_Item__c.SupportingDocumentDownloadURL__c, Disputed_Item__c.SupportingDocumentWebURL__c
        };
    }
}