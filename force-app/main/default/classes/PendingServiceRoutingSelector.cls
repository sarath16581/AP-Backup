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
* 2023-02-06 - Nathan Franklin - Added search method and additional selector options and field overrides
* 2023-02-08 - Noel Lim - Added method selectByLastModifiedDateLessThanEqualNDaysAgo
*/
public inherited sharing class PendingServiceRoutingSelector extends ApplicationSelector {

	public enum Options {
		WITH_WORKITEM, WITH_SKILLREQUIREMENTS, EXCLUDE_ISPUSHED
	}

	public static PendingServiceRoutingSelector newInstance() {
		return (PendingServiceRoutingSelector)Application.Selectors.newInstance(PendingServiceRoutingSelector.class);
	}

	public static PendingServiceRoutingSelector newInstance(Integer recordLimit) {
		return (PendingServiceRoutingSelector)Application.Selectors.newInstance(PendingServiceRoutingSelector.class).setLimit(recordLimit);
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PendingServiceRoutingSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PendingServiceRoutingSelector selector = (PendingServiceRoutingSelector) Application.Selectors.newInstance(PendingServiceRoutingSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 */
	public static PendingServiceRoutingSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PendingServiceRoutingSelector selector = (PendingServiceRoutingSelector) Application.Selectors.newInstance(PendingServiceRoutingSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
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
			PendingServiceRouting.RoutingType,
			PendingServiceRouting.RoutingPriority,
			PendingServiceRouting.SecondaryRoutingPriority
		};
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
	* @description Retrieve PSRs based on the LastModifiedDate
	* @param nDaysAgo Specify a day in the past to retrieve PendingServiceRouting records dated on that day or older 
	* @param selectorOptions Options
	* @return QueryLocator
	*/
	public virtual Database.QueryLocator selectByLastModifiedDateLessThanEqualNDaysAgo(Integer nDaysAgo, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PendingServiceRouting.LastModifiedDate + ' <= N_DAYS_AGO:' + nDaysAgo)).endConditions();
		return Database.getQueryLocator(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						  limitToCaseOnly: boolean to add a Case limiter to ensure only Cases are returned (Boolean)
	 *						  limitToSkillWorkOnly: boolean to ensure that only records with at least 1 skill attached will be returned (Boolean)
	 *						  idGreaterThan: return records greater than the id passed in (Id)
	 *						  orderBy: set the order by field (SObjectField)
	 *						  sortOrder: set the sort direction (asc,desc)
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return Map<Id, PendingServiceRouting>
	 */
	public List<PendingServiceRouting> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>{}, matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 * NOTE: entityIds OR documentIds MUST be passed to avoid a runtime error
	 *
	 * @param searchParams A map containing searchable values:
	 *						  limitToCaseOnly: boolean to add a Case limiter to ensure only Cases are returned (Boolean)
	 *						  limitToSkillWorkOnly: boolean to ensure that only records with at least 1 skill attached will be returned (Boolean)
	 *						  idGreaterThan: return records greater than the id passed in (Id)
	 *						  orderBy: set the order by field (SObjectField)
	 *						  sortOrder: set the sort direction (asc,desc)
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 * @return Map<Id, PendingServiceRouting>
	 */
	public List<PendingServiceRouting> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		System.debug('searchParams: ' + searchParams);

		Boolean limitToCaseOnly = (searchParams.get('limitToCaseOnly') == null || searchParams.get('limitToCaseOnly') == false ? false : true);
		Boolean limitToSkillWorkOnly = (searchParams.get('limitToSkillWorkOnly') == null || searchParams.get('limitToSkillWorkOnly') == false ? false : true);
		Id idGreaterThan = searchParams.get('idGreaterThan') == null ? null : (Id)searchParams.get('idGreaterThan');
		SObjectField orderBy = searchParams.get('orderBy') == null ? null : (SObjectField)searchParams.get('orderBy');
		String sortOrder = searchParams.get('sortOrder') == null ? '' : String.valueOf(searchParams.get('sortOrder'));

		QueryBuilder builder = newQueryBuilder(selectorOptions);

		// these will override the sorting parameters when they are requested from the getOrderBy method
		String sortingFieldOverride = (orderBy != null ? String.valueOf(orderBy) : this.getOrderBy()[0].getSortingField());
		String sortingOrderOverride = (orderBy != null ? String.valueOf(sortOrder) : this.getOrderBy()[0].getSortingOrder());
		QueryBuilder.Order qbOrderBy = new QueryBuilder.Order(sortingFieldOverride, sortingOrderOverride);
		builder.setOrder(qbOrderBy); // override the default sorting

		// add our tracking query
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;

		// this is a cheeky hack to limit to cases since WorkItem.Type = 'Case' does not work for whatever reason
		if(limitToCaseOnly) {
			conditions.add(new QueryBuilder.SimpleCondition(PendingServiceRouting.WorkItemId + ' > \'500000000000000\''));
			conditions.add(new QueryBuilder.SimpleCondition(PendingServiceRouting.WorkItemId + ' < \'501000000000000\''));
			conditionCount++;
			conditionCount++;
		}
		if(limitToSkillWorkOnly) {
			conditions.add(new QueryBuilder.SimpleCondition(PendingServiceRouting.Id + ' In (SELECT RelatedRecordId From SkillRequirement)'));
			conditionCount++;
		}
		if(idGreaterThan != null) {
			conditions.add(new QueryBuilder.SimpleCondition(PendingServiceRouting.Id + ' > :idGreaterThan'));
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

		String soql = conditions.endConditions().toSoqlString();
		return (List<PendingServiceRouting>)Database.query(soql);
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_WORKITEM)) {
			builder.addRelatedFields(CasesSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'WorkItem');
		}
		if(selectorOptions.contains(Options.WITH_SKILLREQUIREMENTS)) {
			builder.addSubQuery(SkillRequirementSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'SkillRequirements');
		}
		if(selectorOptions.contains(Options.EXCLUDE_ISPUSHED)) {
			builder.addConditions().add(new QueryBuilder.CompareCondition(PendingServiceRouting.IsPushed).eq(false)).endConditions();
		}

		return builder;
	}
}