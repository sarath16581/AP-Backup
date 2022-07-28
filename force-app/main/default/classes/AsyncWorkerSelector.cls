/**
 * @description
 * Selector class for retrieving AsyncWorker__c records
 *
 * @author Nathan Franklin
 * @date 2020-09-01
 * @group Core
 * @changelog
 */
public inherited sharing class AsyncWorkerSelector extends ApplicationSelector {
	public static AsyncWorkerSelector newInstance() {
		return (AsyncWorkerSelector) Application.Selectors.newInstance(AsyncWorkerSelector.class);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static AsyncWorkerSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		AsyncWorkerSelector selector = (AsyncWorkerSelector) Application.Selectors.newInstance(AsyncWorkerSelector.class)
			.setLimit(recordLimit)
			.setFieldOverrides(fieldOverrides);
		return selector;
	}

	public override SObjectType getSObjectType() {
		return AsyncWorker__c.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			AsyncWorker__c.ClassType__c,
			AsyncWorker__c.CurrentLockRetryAttempts__c,
			AsyncWorker__c.CurrentStack__c,
			AsyncWorker__c.CurrentStackDepth__c,
			AsyncWorker__c.LastError__c,
			AsyncWorker__c.MaxNumberRetries__c,
			AsyncWorker__c.Parameters1__c,
			AsyncWorker__c.Parameters2__c,
			AsyncWorker__c.Parameters3__c,
			AsyncWorker__c.Parameters4__c,
			AsyncWorker__c.QueueableJobId__c,
			AsyncWorker__c.SObjectTypeGroup__c,
			AsyncWorker__c.UnitOfWorkSObjectTypes__c,
			AsyncWorker__c.UserId__c,
			AsyncWorker__c.RequiresCallouts__c,
			AsyncWorker__c.ForcedIntoCurrentContext__c
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<AsyncWorker__c> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<AsyncWorker__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);
		qb.addConditions().add(new QueryBuilder.SimpleCondition(Account.Id + ' in :ids')).endConditions();
		return (List<AsyncWorker__c>) Database.query(qb.toSoqlString());
	}
}