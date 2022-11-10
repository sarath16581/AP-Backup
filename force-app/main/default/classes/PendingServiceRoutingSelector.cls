/**
* @author George Nguyen
* @date 2022-11-02
* @group Selector
* @tag Selector
* @tag PendingServiceRouting SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2022-11-02 - George Nguyen - Created
*/
public inherited sharing class PendingServiceRoutingSelector extends ApplicationSelector {

    public enum Options {
		WITH_WORKITEM
	}

	public static PendingServiceRoutingSelector newInstance() {
		return (PendingServiceRoutingSelector)Application.Selectors.newInstance(PendingServiceRoutingSelector.class);
	}

	public static PendingServiceRoutingSelector newInstance(Integer recordLimit) {
		return (PendingServiceRoutingSelector)Application.Selectors.newInstance(PendingServiceRoutingSelector.class).setLimit(recordLimit);
	}

	public virtual override SObjectType getSObjectType() {
		return PendingServiceRouting.getSObjectType();
	}

	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
            PendingServiceRouting.CustomRequestedDateTime, 
            PendingServiceRouting.CapacityWeight,
            PendingServiceRouting.OwnerId, 
            PendingServiceRouting.PreferredUserId,
            PendingServiceRouting.QueueId,
            PendingServiceRouting.WorkItemId,
            PendingServiceRouting.IsPreferredUserRequired,
            PendingServiceRouting.IsPushed, 
            PendingServiceRouting.GroupId, 
            PendingServiceRouting.IsPushAttempted,
            PendingServiceRouting.IsReadyForRouting,
            PendingServiceRouting.IsTransfer,
            PendingServiceRouting.RoutingModel,
            PendingServiceRouting.RoutingType 
		};
	}

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_WORKITEM)) {
			builder.addRelatedFields(CasesSelector.newInstance(new Set<SObjectField>{ Case.Priority, Case.CreatedDate }).newQueryBuilder(), 'WorkItem');
		}

		return builder;
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<PendingServiceRouting> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

    /**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<PendingServiceRouting> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PendingServiceRouting.Id + ' in :ids')).endConditions();
		return (List<PendingServiceRouting>)Database.query(qb.toSoqlString());
	}

    /**
	 * @description Run a simple query to get records based on WorkItemId's
	 */
	public List<PendingServiceRouting> selectByWorkItemId(Set<Id> workItemIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PendingServiceRouting.WorkItemId + ' in :workItemIds')).endConditions();
		return (List<PendingServiceRouting>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on WorkItemId's
	 */
	public List<PendingServiceRouting> selectByLastModifiedDateLessThanLastNDays(Integer lastNDays, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PendingServiceRouting.LastModifiedDate + ' < LAST_N_DAYS:' + lastNDays)).endConditions();
		return (List<PendingServiceRouting>)Database.query(qb.toSoqlString());
	}
}
