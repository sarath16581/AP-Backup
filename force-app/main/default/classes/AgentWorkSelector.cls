/**
* @author George Nguyen
* @date 2020-10-18
* @group Selector
* @tag Selector
* @tag AgentWork SObject
* @domain OmniDomain
* @description A very simple selector class that sits in the OmniDomain
* @changelog
* 2020-10-18 - George Nguyen - Created 
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

    public List<AgentWork> selectByAcceptedWorkItemIds(Set<Id> workItemIds, Set<Object> selectorOptions) {
        selectorOptions.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions()
            .add(new QueryBuilder.SimpleCondition(AgentWork.WorkItemId + ' in :workItemIds'))
            .add(new QueryBuilder.SimpleCondition(AgentWork.AcceptDateTime + ' != NULL'))
            .setConditionOrder('1 AND 2')
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