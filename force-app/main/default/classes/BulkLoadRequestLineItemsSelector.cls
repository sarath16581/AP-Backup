/**
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group Selector
 * @tag Selector
 * @tag BulkLoadRequestLineItem__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created
 */

public inherited sharing class BulkLoadRequestLineItemsSelector extends ApplicationSelector {

    public enum Options {
        WITH_BULKLOADREQUEST
    }

    public static BulkLoadRequestLineItemsSelector newInstance() {
        return (BulkLoadRequestLineItemsSelector)Application.Selectors.newInstance(BulkLoadRequestLineItemsSelector.class);
    }
    public static BulkLoadRequestLineItemsSelector newInstance(Integer recordLimit) {
        return (BulkLoadRequestLineItemsSelector)Application.Selectors.newInstance(BulkLoadRequestLineItemsSelector.class).setLimit(recordLimit);
    }

    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
    public static BulkLoadRequestLineItemsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        BulkLoadRequestLineItemsSelector selector = (BulkLoadRequestLineItemsSelector)Application.Selectors.newInstance(BulkLoadRequestLineItemsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     *                          This approach removes data consistency and prevents possible caching of results
     */
    public static BulkLoadRequestLineItemsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        BulkLoadRequestLineItemsSelector selector = (BulkLoadRequestLineItemsSelector)Application.Selectors.newInstance(BulkLoadRequestLineItemsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    protected override SObjectType getSObjectType() {
        return BulkLoadRequestLineItem__c.getSObjectType();
    }

    protected override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
                BulkLoadRequestLineItem__c.Id, BulkLoadRequestLineItem__c.BulkLoadRequest__c, BulkLoadRequestLineItem__c.ErrorMessage__c,
                BulkLoadRequestLineItem__c.LineItemPayload__c, BulkLoadRequestLineItem__c.Status__c, BulkLoadRequestLineItem__c.LineNumber__c
        };
    }

    /**
     * Select bulk load request line items by line item status and the parent request id.
     *
     * @param bulkLoadRequestId parent request id
     * @param status collection of status' to query
     *
     * @return matching BulkLoadRequestLineItem__c records
     */
    public virtual Map<Id, BulkLoadRequestLineItem__c> selectByBulkLoadRequestAndStatus(Id bulkLoadRequestId, Set<String> status) {
        return selectByBulkLoadRequestAndStatus(bulkLoadRequestId, status, new Set<Object>());
    }

    /**
     * Select bulk load request line items by line item status and the parent request id. Also supports passing in selector
     * options to augment the result set returned.
     *
     * @param bulkLoadRequestId parent request id.
     * @param status collection of status' to query
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return matching BulkLoadRequest__c records.
     */
    public virtual Map<Id, BulkLoadRequestLineItem__c> selectByBulkLoadRequestAndStatus(Id bulkLoadRequestId, Set<String> status, Set<Object> selectorOptions) {
        QueryBuilder qb = getLineItemsByBulkLoadRequestAndStatusQueryBuilder(bulkLoadRequestId, status, selectorOptions);
        return new Map<Id, BulkLoadRequestLineItem__c>((List<BulkLoadRequestLineItem__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * Returns a Database.QueryLocator for retrieving line items by status and the parent record id.
     *
     * @param bulkLoadRequestId parent request id.
     * @param status collection of status' to query
     * @param selectorOptions  set of additional selector options to augment the result set
     *
     * @return Database.QueryLocator
     */
    public virtual Database.QueryLocator selectByBulkLoadRequestAndStatusQueryLocator(Id bulkLoadRequestId, Set<String> status, Set<Object> selectorOptions) {
        QueryBuilder qb = getLineItemsByBulkLoadRequestAndStatusQueryBuilder(bulkLoadRequestId, status, selectorOptions);
        return Database.getQueryLocator(qb.toSoqlString());
    }

    private virtual QueryBuilder getLineItemsByBulkLoadRequestAndStatusQueryBuilder(Id bulkLoadRequestId, Set<String> status, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        QueryBuilder.ConditionsManager conditions = qb.addConditions();

        conditions.add(new QueryBuilder.SimpleCondition(BulkLoadRequestLineItem__c.BulkLoadRequest__c + ' = :bulkLoadRequestId'));

        if (!status.isEmpty()) {
            conditions.add(new QueryBuilder.SimpleCondition(BulkLoadRequestLineItem__c.Status__c + ' in :status'));
        }

        return conditions.endConditions();
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_BULKLOADREQUEST)) {
            builder.addRelatedFields(BulkLoadRequestSelector.newInstance(0,fieldOverrides).newQueryBuilder(), 'BulkLoadRequest__r');
        }

        return builder;
    }
}