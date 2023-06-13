/**
* @author George Nguyen
* @date 2022-10-18
* @changelog
* 2022-10-18 - George Nguyen - Created 
* 2023-05-21 - Nathan Franklin - Added new constructors
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