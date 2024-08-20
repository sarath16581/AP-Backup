/**
* @author George Nguyen
* @date 2022-10-18
* @changelog
* 2022-10-18 - George Nguyen - Created 
* 2023-05-21 - Nathan Franklin - Added new constructors
* 2024-08-09 - Ranjeewa Silva - Added new search method with search parameter validation
*/
public inherited sharing class AgentWorkSelector extends ApplicationSelector {

	public enum Options {
		WITH_USER,
		WITH_CASE
	}

	public static AgentWorkSelector newInstance() {
		return (AgentWorkSelector)Application.Selectors.newInstance(AgentWorkSelector.class);
	}

	public static AgentWorkSelector newInstance(Integer recordLimit) {
		return (AgentWorkSelector)Application.Selectors.newInstance(AgentWorkSelector.class).setLimit(recordLimit);
	}

	public static AgentWorkSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		AgentWorkSelector selector = (AgentWorkSelector) Application.Selectors.newInstance(AgentWorkSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public static AgentWorkSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		AgentWorkSelector selector = (AgentWorkSelector) Application.Selectors.newInstance(AgentWorkSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	public virtual override SObjectType getSObjectType() {
		return AgentWork.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			AgentWork.WorkItemId,
			AgentWork.Status,
			AgentWork.UserId
		};
	}

	public List<AgentWork> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public List<AgentWork> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(AgentWork.Id + ' in :ids')).endConditions();
		return (List<AgentWork>)Database.query(qb.toSoqlString());
	}

	public List<AgentWork> selectByWorkItemIds(Set<Id> workItemIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(AgentWork.WorkItemId + ' in :workItemIds')).endConditions();
		return (List<AgentWork>)Database.query(qb.toSoqlString());
	}

	public List<AgentWork> selectByAcceptedWorkItemIdsAndActiveUser(Set<Id> workItemIds, Set<Object> selectorOptions) {
		selectorOptions.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
			.add(new QueryBuilder.SimpleCondition(AgentWork.WorkItemId + ' in :workItemIds'))
			.add(new QueryBuilder.SimpleCondition(AgentWork.AcceptDateTime + ' != NULL'))
			.add(new QueryBuilder.SimpleCondition('User.IsActive = TRUE'))
			.endConditions();

		qb.addOrder(new QueryBuilder.Order(AgentWork.WorkItemId))
			.addOrder(new QueryBuilder.Order(AgentWork.AcceptDateTime).setSortingOrderDesc());

		return (List<AgentWork>)Database.query(qb.toSoqlString());
	}

	public List<AgentWork> selectByAcceptedWorkItemIds(Set<Id> workItemIds, Set<Object> selectorOptions) {
		selectorOptions.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
			.add(new QueryBuilder.SimpleCondition(AgentWork.WorkItemId + ' in :workItemIds'))
			.add(new QueryBuilder.SimpleCondition(AgentWork.AcceptDateTime + ' != NULL'))
			.endConditions();

		qb.addOrder(new QueryBuilder.Order(AgentWork.WorkItemId))
			.addOrder(new QueryBuilder.Order(AgentWork.AcceptDateTime).setSortingOrderDesc());

		return (List<AgentWork>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 * @param searchParams A map containing searchable values:
	 *					 workItemIds: maps to WorkItemId (Set<Id>/Id)
	 *					 status: maps to Status (Set<String>/String)
	 * @param matchAll If true will search based on AND, else search based on OR
	 *
	 * @return list of AgentWork records
	 */
	public List<AgentWork> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 workItemIds: maps to WorkItemId (Set<Id>/Id)
	 *						 status: maps to Status (Set<String>/String)
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 *
	 * @return list of AgentWork records
	 */
	public List<AgentWork> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		Set<Id> workItemIds = (Set<Id>)(searchParams.get('workItemIds') == null ? new Set<Id>() : (searchParams.get('workItemIds') instanceof Set<Id> ? searchParams.get('workItemIds') : new Set<Id>{(Id)searchParams.get('workItemIds')}));
		Set<String> status = (Set<String>)(searchParams.get('status') == null ? new Set<String>() : (searchParams.get('status') instanceof Set<String> ? searchParams.get('status') : new Set<String>{(String)searchParams.get('status')}));
		return (List<AgentWork>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		validateSearchParams(searchParams.keySet(), new Set<String>{'workItemIds', 'status'});

		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if (searchParams.containsKey('workItemIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(AgentWork.WorkItemId + ' in :workItemIds'));
			conditionCount++;
		}
		if (searchParams.containsKey('status')) {
			conditions.add(new QueryBuilder.SimpleCondition(AgentWork.Status + ' in :status'));
			conditionCount++;
		}

		// build our condition string which would end up being something like the following:
		// 1 AND 2 AND 3
		// 1 OR 2 OR 3
		String conditionOrder = '';
		for (Integer i=0; i<conditionCount; i++) {
			conditionOrder += (!String.isEmpty(conditionOrder) ? (matchAll ? ' AND ' : ' OR ') : '') + ' ' + (i+1);
		}
		conditions.setConditionOrder(conditionOrder);

		return conditions.endConditions().toSoqlString();
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_USER)) {
			builder.addRelatedFields(UsersSelector.newInstance().newQueryBuilder(), 'User');
		}

		if(selectorOptions.contains(Options.WITH_CASE)) {
			builder.addRelatedFields(CasesSelector.newInstance().newQueryBuilder(), 'WorkItem');
		}

		return builder;
	}
}