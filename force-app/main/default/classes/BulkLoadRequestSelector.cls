/**
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group Selector
 * @tag Selector
 * @tag BulkLoadRequest__c
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created
 */

public inherited sharing class BulkLoadRequestSelector extends ApplicationSelector {

    public enum Options {
        WITH_OWNER
    }

    public static BulkLoadRequestSelector newInstance() {
        return (BulkLoadRequestSelector)Application.Selectors.newInstance(BulkLoadRequestSelector.class);
    }
    public static BulkLoadRequestSelector newInstance(Integer recordLimit) {
        return (BulkLoadRequestSelector)Application.Selectors.newInstance(BulkLoadRequestSelector.class).setLimit(recordLimit);
    }

    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
    public static BulkLoadRequestSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        BulkLoadRequestSelector selector = (BulkLoadRequestSelector)Application.Selectors.newInstance(BulkLoadRequestSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     *                          This approach removes data consistency and prevents possible caching of results
     */
    public static BulkLoadRequestSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        BulkLoadRequestSelector selector = (BulkLoadRequestSelector)Application.Selectors.newInstance(BulkLoadRequestSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }

    protected override SObjectType getSObjectType() {
        return BulkLoadRequest__c.getSObjectType();
    }

    protected override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            BulkLoadRequest__c.Id, BulkLoadRequest__c.FileName__c, BulkLoadRequest__c.ProcessedTimestamp__c,
            BulkLoadRequest__c.Status__c, BulkLoadRequest__c.TotalFailed__c, BulkLoadRequest__c.TotalLineItems__c,
            BulkLoadRequest__c.TotalSuccessful__c, BulkLoadRequest__c.Type__c, BulkLoadRequest__c.UploadTimestamp__c,
            BulkLoadRequest__c.CreatedDate
        };
    }

    /**
     * Run a simple query to get records based on Id's.
     *
     * @param ids Bulk load request ids to query
     * @return matching BulkLoadRequest__c records.
     */
    public virtual Map<Id, BulkLoadRequest__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }

    /**
     * Run a simple query to get records based on Id's. Also supports passing in selector options (e.g. Options.WITH_OWNER)
     * to augment the result set returned.
     *
     * @param ids Bulk load request ids to query
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return matching BulkLoadRequest__c records.
     */
    public virtual Map<Id, BulkLoadRequest__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(BulkLoadRequest__c.Id + ' in :ids')).endConditions();
        return new Map<Id, BulkLoadRequest__c>((List<BulkLoadRequest__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * Select bulk load requests by type and file name.
     *
     * @param type filter bulk load request by the type passed in
     * @param fileNames collection of file names to query
     *
     * @return matching BulkLoadRequest__c records
     */
    public virtual Map<Id, BulkLoadRequest__c> selectByTypeAndFileName(String type, Set<String> fileNames) {
        return selectByTypeAndFileName(type, fileNames, new Set<Object>());
    }

    /**
     * Select bulk load requests by type and file name.
     *
     * @param type filter bulk load request by the type passed in
     * @param fileNames collection of file names to query
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return matching BulkLoadRequest__c records
     */
    public virtual Map<Id, BulkLoadRequest__c> selectByTypeAndFileName(String type, Set<String> fileNames, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
                .add(new QueryBuilder.SimpleCondition(BulkLoadRequest__c.Type__c + ' = :type'))
                .add(new QueryBuilder.SimpleCondition(BulkLoadRequest__c.FileName__c + ' in :fileNames'))
                .endConditions();
        return new Map<Id, BulkLoadRequest__c>((List<BulkLoadRequest__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * Select bulk load requests by type and created date.
     *
     * @param numberOfDays number of days for deriving upload date range
     * @param types only return bulk load requests of specific types
     *
     * @return matching BulkLoadRequest__c records.
     */
    public virtual Map<Id, BulkLoadRequest__c> selectByTypeAndUploadDate(Integer numberOfDays, Set<String> types) {
        return selectByTypeAndUploadDate(numberOfDays, types, new Set<Object>());
    }

    /**
     * Select bulk load requests by type and created date. Also supports passing in selector options (e.g. Options.WITH_OWNER)
     * to augment the result set returned.
     *
     * @param numberOfDays number of days for deriving upload date range
     * @param types only return bulk load requests of specific types
     * @param selectorOptions set of additional selector options to augment the result set
     *
     * @return matching BulkLoadRequest__c records.
     */
    public virtual Map<Id, BulkLoadRequest__c> selectByTypeAndUploadDate(Integer numberOfDays, Set<String> types, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions)
                .addConditions()
                .add(new QueryBuilder.SimpleCondition(BulkLoadRequest__c.UploadTimestamp__c + ' >= LAST_N_DAYS:' + numberOfDays))
                .add(new QueryBuilder.SimpleCondition(BulkLoadRequest__c.Type__c + ' in :types'))
                .endConditions();
        return new Map<Id, BulkLoadRequest__c>((List<BulkLoadRequest__c>)Database.query(qb.toSoqlString()));
    }

    /**
     * Grabs a new QueryBuilder based on the selector options passed in
     *
     * @param selectorOptions set of additional selector options to augment the result set
     * @return new QueryBuilder instance
     */
    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_OWNER)) {
            builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
        }

        return builder;
    }
}