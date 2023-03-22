/**
 * @author Nathan Franklin
 * @date 2023-03-06
 * @description A very simple selector class 
 * @changelog
*/
public virtual inherited sharing class PermissionSetAssignmentsSelector extends ApplicationSelector {

	public enum Options {
		WITH_USER
	}
	
	public static PermissionSetAssignmentsSelector newInstance() {
		return (PermissionSetAssignmentsSelector)Application.Selectors.newInstance(PermissionSetAssignmentsSelector.class);
	}
	public static PermissionSetAssignmentsSelector newInstance(Integer recordLimit) {
		return (PermissionSetAssignmentsSelector)Application.Selectors.newInstance(PermissionSetAssignmentsSelector.class).setLimit(recordLimit);
	}
	
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PermissionSetAssignmentsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
		PermissionSetAssignmentsSelector selector = (PermissionSetAssignmentsSelector)Application.Selectors.newInstance(PermissionSetAssignmentsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static PermissionSetAssignmentsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
		PermissionSetAssignmentsSelector selector = (PermissionSetAssignmentsSelector)Application.Selectors.newInstance(PermissionSetAssignmentsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
		return selector;
	}
	
	
	public override SObjectType getSObjectType() {
		return PermissionSetAssignment.getSObjectType();
	}
	
	public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			PermissionSetAssignment.AssigneeId, PermissionSetAssignment.Id, PermissionSetAssignment.PermissionSetGroupId, PermissionSetAssignment.PermissionSetId, PermissionSetAssignment.SystemModstamp
		};
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<PermissionSetAssignment> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public List<PermissionSetAssignment> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(User.Id + ' in :ids')).endConditions();
		return (List<PermissionSetAssignment>)Database.query(qb.toSoqlString());
	}
	
	/**
	 * @description Run a simple query to get records based on PermissionSetId
	 */
	public List<PermissionSetAssignment> selectByPermissionSet(Set<Id> permissionSetIds) {
		return selectByPermissionSet(permissionSetIds, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on PermissionSetId
	 */
	public List<PermissionSetAssignment> selectByPermissionSet(Set<Id> permissionSetIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PermissionSetAssignment.PermissionSetId + ' in :permissionSetIds')).endConditions();
		return (List<PermissionSetAssignment>)Database.query(qb.toSoqlString());
	}

	/**
	 * @description Run a simple query to get records based on AssigneeId
	 */
	public List<PermissionSetAssignment> selectByAssignee(Set<Id> assigneeIds) {
		return selectByAssignee(assigneeIds, new Set<Object>());
	}
	
	/**
	 * @description Run a simple query to get records based on AssigneeId
	 */
	public List<PermissionSetAssignment> selectByAssignee(Set<Id> assigneeIds, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(PermissionSetAssignment.AssigneeId + ' in :assigneeIds')).endConditions();
		return (List<PermissionSetAssignment>)Database.query(qb.toSoqlString());
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 assigneeIds: maps to AssigneeId (Set<String>/String)
	 *						 permissionSetIds: maps to PermissionSetId (Set<Id>/Id)
	 *						 permissionSetNames: maps to Profile (Set<String>/String)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<PermissionSetAssignment> search(Map<String, Object> searchParams, Boolean matchAll) {
		return search(searchParams, new Set<Object>(), matchAll);
	}

	/**
	 * Run a SOQL based on the search parameters passed in
	 *
	 * @param searchParams A map containing searchable values:
	 *						 assigneeIds: maps to AssigneeId (Set<String>/String)
	 *						 permissionSetIds: maps to PermissionSetId (Set<Id>/Id)
	 *						 permissionSetNames: maps to Profile (Set<String>/String)
	 *
	 *
	 * @param selectorOptions Selector Options
	 * @param matchAll If true will search based on AND, else search based on OR
	 */
	public List<PermissionSetAssignment> search(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {

		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		super.validateSearchParams(searchParams.keySet(), new Set<String>{'assigneeIds', 'permissionSetIds', 'permissionSetNames'});

		Set<Id> assigneeIds = (Set<Id>)(searchParams.get('assigneeIds') == null ? new Set<Id>() : (searchParams.get('assigneeIds') instanceof Set<Id> ? searchParams.get('assigneeIds') : new Set<Id>{(Id)searchParams.get('assigneeIds')}));
		Set<Id> permissionSetIds = (Set<Id>)(searchParams.get('permissionSetIds') == null ? new Set<Id>() : (searchParams.get('permissionSetIds') instanceof Set<Id> ? searchParams.get('permissionSetIds') : new Set<Id>{(Id)searchParams.get('permissionSetIds')}));
		Set<String> permissionSetNames = (Set<String>)(searchParams.get('permissionSetNames') == null ? new Set<String>() : (searchParams.get('permissionSetNames') instanceof Set<String> ? searchParams.get('permissionSetNames') : new Set<String>{String.valueOf(searchParams.get('permissionSetNames'))}));

		return (List<PermissionSetAssignment>)Database.query(getSearchSoql(searchParams, selectorOptions, matchAll));
	}

	/**
	 * Separated from search method so SOQL can be inspected in Test class
	 */
	@TestVisible
	private String getSearchSoql(Map<String, Object> searchParams, Set<Object> selectorOptions, Boolean matchAll) {
		
		QueryBuilder builder = newQueryBuilder(selectorOptions);
		QueryBuilder.ConditionsManager conditions = builder.addConditions();

		Integer conditionCount = 0;
		if(searchParams.containsKey('assigneeIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(PermissionSetAssignment.AssigneeId + ' in :assigneeIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('permissionSetIds')) {
			conditions.add(new QueryBuilder.SimpleCondition(PermissionSetAssignment.PermissionSetId + ' in :permissionSetIds'));
			conditionCount++;
		}
		if(searchParams.containsKey('permissionSetNames')) {
			conditions.add(new QueryBuilder.SimpleCondition('PermissionSet.Name in :permissionSetNames'));
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
			builder.addRelatedFields(UsersSelector.newInstance(0, fieldOverrides).newQueryBuilder(selectorOptions), 'Assignee');
		}
	
		return builder;
	}

	public virtual override List<QueryBuilder.Order> getOrderBy() {
		return null;
	}
	
	
	
}