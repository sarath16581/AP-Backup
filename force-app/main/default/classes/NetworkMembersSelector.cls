/**
 * @description Selector class to cover NetworkMember
 * @author Nathan Franklin
 * @date 2023-07-14
 * @changelog
 */
public inherited sharing class NetworkMembersSelector extends ApplicationSelector {

	public enum Options {
		
	}

	public static NetworkMembersSelector newInstance() {
		return (NetworkMembersSelector)Application.Selectors.newInstance(NetworkMembersSelector.class);
	}
	public static NetworkMembersSelector newInstance(Integer recordLimit) {
		return (NetworkMembersSelector)Application.Selectors.newInstance(NetworkMembersSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return NetworkMember.getSObjectType();
	}

	public override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			NetworkMember.Id, NetworkMember.MemberId, NetworkMember.NetworkId
		};
	}

	public List<NetworkMember> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<NetworkMember> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(GroupMember.Id + ' in :ids')).endConditions();
		return (List<NetworkMember>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 memberIds: maps to MemberId (Set<Id>/Id)
	 *						 networkIds: maps to NetworkId (Set<Id>/Id)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<NetworkMember> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 memberIds: maps to MemberId (Set<Id>/Id)
	 *						 networkIds: maps to NetworkId (Set<Id>/Id)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<NetworkMember> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {

		Set<Id> memberIds = (Set<Id>)(searchParams.get('memberIds') == null ? new Set<Id>() : (searchParams.get('memberIds') instanceof Set<Id> ? searchParams.get('memberIds') : new Set<Id>{(Id)searchParams.get('memberIds')}));
		Set<Id> networkIds = (Set<Id>)(searchParams.get('networkIds') == null ? new Set<Id>() : (searchParams.get('networkIds') instanceof Set<Id> ? searchParams.get('networkIds') : new Set<Id>{(Id)searchParams.get('networkIds')}));

		return (List<NetworkMember>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'memberIds', 'networkIds'});

		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('networkIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(NetworkMember.NetworkId + ' in :networkIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('memberIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(NetworkMember.MemberId + ' in :memberIds'));
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

	public override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('Id', 'Desc')};
	}



}