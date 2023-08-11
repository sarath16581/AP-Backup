/**
 * @author Nathan Franklin
 * @date 2023-03-06
 * @description A very simple selector class 
 * @changelog
 * 2023-08-10 - Mahesh Parvathaneni - Added providerNames in searchParams
*/
public virtual inherited sharing class ThirdPartyAccountLinksSelector extends ApplicationSelector {

	public enum Options {
		WITH_USER
	}
	
	public static ThirdPartyAccountLinksSelector newInstance() {
		return (ThirdPartyAccountLinksSelector)Application.Selectors.newInstance(ThirdPartyAccountLinksSelector.class);
	}
	public static ThirdPartyAccountLinksSelector newInstance(Integer recordLimit) {
		return (ThirdPartyAccountLinksSelector)Application.Selectors.newInstance(ThirdPartyAccountLinksSelector.class).setLimit(recordLimit);
	}
	
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ThirdPartyAccountLinksSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		ThirdPartyAccountLinksSelector selector = (ThirdPartyAccountLinksSelector)Application.Selectors.newInstance(ThirdPartyAccountLinksSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static ThirdPartyAccountLinksSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		ThirdPartyAccountLinksSelector selector = (ThirdPartyAccountLinksSelector)Application.Selectors.newInstance(ThirdPartyAccountLinksSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	
	public override SObjectType getSObjectType() {
		return ThirdPartyAccountLink.getSObjectType();
	}
	
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			ThirdPartyAccountLink.Handle, ThirdPartyAccountLink.Id, ThirdPartyAccountLink.IsNotSsoUsable, ThirdPartyAccountLink.Provider, ThirdPartyAccountLink.RemoteIdentifier, ThirdPartyAccountLink.SsoProviderId, ThirdPartyAccountLink.SsoProviderName, ThirdPartyAccountLink.ThirdPartyAccountLinkKey, ThirdPartyAccountLink.UserId
		};
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<ThirdPartyAccountLink> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<ThirdPartyAccountLink> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(User.Id + ' in :ids')).endConditions();
		return Database.query(qb.toSoqlString());
	}
	
	/**
	 * @description Run a simple query to get records based on PermissionSetId
	 */
	public List<ThirdPartyAccountLink> selectByUser(Set<Id> userIds) {
		return selectByUser(userIds, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on PermissionSetId
	 */
	public List<ThirdPartyAccountLink> selectByUser(Set<Id> userIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ThirdPartyAccountLink.UserId + ' in :userIds')).endConditions();
		return (List<ThirdPartyAccountLink>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 userIds: maps to UserId (Set<Id>/Id)
	 *						 providerIds: maps to SsoProviderId (Set<Id>/Id)
	 *						 providerNames: maps to SsoProviderName (Set<String>/String)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<ThirdPartyAccountLink> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 userIds: maps to UserId (Set<Id>/Id)
	 *						 providerIds: maps to SsoProviderId (Set<Id>/Id)
	 *						 providerNames: maps to SsoProviderName (Set<String>/String)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<ThirdPartyAccountLink> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		Set<Id> userIds = (Set<Id>)(searchParams.get('userIds') == null ? new Set<Id>() : (searchParams.get('userIds') instanceof Set<Id> ? searchParams.get('userIds') : new Set<Id>{(Id)searchParams.get('userIds')}));
		Set<Id> providerIds = (Set<Id>)(searchParams.get('providerIds') == null ? new Set<Id>() : (searchParams.get('providerIds') instanceof Set<Id> ? searchParams.get('providerIds') : new Set<Id>{(Id)searchParams.get('providerIds')}));
		Set<String> providerNames = (Set<String>)(searchParams.get('providerNames') == null ? new Set<String>() : (searchParams.get('providerNames') instanceof Set<String> ? searchParams.get('providerNames') : new Set<String>{(String)searchParams.get('providerNames')}));

		return (List<ThirdPartyAccountLink>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'userIds', 'providerIds', 'providerNames'});
		
		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('userIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(ThirdPartyAccountLink.UserId + ' in :userIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('providerIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(ThirdPartyAccountLink.SsoProviderId + ' in :providerIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('providerNames')) {
			conditions.add(new QueryBuilder.SimpleCondition(ThirdPartyAccountLink.SsoProviderName + ' in :providerNames'));
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

		return conditions.endConditions().toSoqlString();
	}
	
	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);
	
		if(selectorOptions.contains(Options.WITH_USER)) {
			builder.addRelatedFields(UsersSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'User');
		}
	
		return builder;
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return null;
	}
	
	
	
}