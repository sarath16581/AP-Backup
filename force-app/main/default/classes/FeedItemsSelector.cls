/**
 * @author Dattaraj Deshmukh
 * @date 2022-01-12
 * @group Selector
 * @tag Selector
 * @tag FeedItem SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-01-12 Dattaraj Deshmukh - Created
*/
public virtual inherited sharing class FeedItemsSelector extends ApplicationSelector  {

	public enum Options {
		WITH_CREATEDBY
	}

	public static FeedItemsSelector newInstance() {
		return (FeedItemsSelector)Application.Selectors.newInstance(FeedItemsSelector.class);
	}

	public static FeedItemsSelector newInstance(Integer recordLimit) {
		return (FeedItemsSelector)Application.Selectors.newInstance(FeedItemsSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static FeedItemsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		FeedItemsSelector selector = (FeedItemsSelector)Application.Selectors.newInstance(FeedItemsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static FeedItemsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		FeedItemsSelector selector = (FeedItemsSelector)Application.Selectors.newInstance(FeedItemsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}


	public override SObjectType getSObjectType() {
		return FeedItem.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			FeedItem.Id, FeedItem.ParentId, FeedItem.Body, FeedItem.CreatedById, FeedItem.CreatedDate 
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, FeedItem> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, FeedItem> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(FeedItem.Id + ' in :ids')).endConditions();
		return new Map<Id, FeedItem>((List<FeedItem>)Database.query(qb.toSoqlString()));
	}

	public Map<Id, FeedItem> selectByTextPostParentIds(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions);//.addConditions();
		qb.addConditions().add(new QueryBuilder.SimpleCondition(FeedItem.ParentId + ' in :ids'));
		qb.addConditions().add(new QueryBuilder.SimpleCondition(FeedItem.Type + ' = '+'\'TextPost\'')).endConditions();
		return new Map<Id, FeedItem>((List<FeedItem>)Database.query(qb.toSoqlString()));
	}

	public Map<Id, FeedItem> selectByTextPostParentIds(Set<Id> ids) {
		return selectByTextPostParentIds(ids, new Set<Object>());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_CREATEDBY)) {
			Set<SObjectField> fieldOverrides = new Set<SObjectField>{
				User.Id, User.FirstName, User.LastName
			};
			builder.addRelatedFields(UsersSelector.newInstance(1, fieldOverrides).newQueryBuilder(selectorOptions), 'CreatedBy');
		}
		return builder;
	}

	
}
