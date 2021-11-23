/**
* @author Nathan Franklin
* @date 2020-04-10
* @group Selector
* @tag Selector
* @tag Group SObject
* @tag GroupMember SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - Nathan Franklin - Created
* 2020-04-30 - Dheeraj Mandavilli - Updated - QueryBuilder.InCondition to QueryBuilder.SimpleCondition in selectbyId Method
*/
public inherited sharing class GroupMembersSelector extends ApplicationSelector {

	public enum Options {
		WITH_GROUP
	}

	public static GroupMembersSelector newInstance() {
		return (GroupMembersSelector)Application.Selectors.newInstance(GroupMembersSelector.class);
	}
	public static GroupMembersSelector newInstance(Integer recordLimit) {
		return (GroupMembersSelector)Application.Selectors.newInstance(GroupMembersSelector.class).setLimit(recordLimit);
	}

	public override SObjectType getSObjectType() {
		return GroupMember.getSObjectType();
	}

	public override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
				GroupMember.GroupId, GroupMember.Id, GroupMember.SystemModstamp, GroupMember.UserOrGroupId
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, GroupMember> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 */
	public Map<Id, GroupMember> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(GroupMember.Id + ' in :ids')).endConditions();
		return new Map<Id, GroupMember>((List<GroupMember>)Database.query(qb.toSoqlString()));
	}

	/**
	 * @description Run a simple query to get records based on Group Id's
	 */
	public Map<Id, GroupMember> selectByGroupIds(Set<Id> groupIds) {
		return selectByGroupIds(groupIds, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Group Id's
	 */
	public Map<Id, GroupMember> selectByGroupIds(Set<Id> groupIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(GroupMember.GroupId + ' in :groupIds')).endConditions();
		return new Map<Id, GroupMember>((List<GroupMember>)Database.query(qb.toSoqlString()));
	}

	public Integer countByMyGroups() {
		return countByMyGroups(null, new Set<Object>());
	}

	public Integer countByMyGroups(List<String> groupIdsOrNamesFilter) {
		return countByMyGroups(groupIdsOrNamesFilter, new Set<Object>());
	}

	public Integer countByMyGroups(List<String> groupIdsOrNamesFilter, Set<Object> selectorOptions) {
		return (Integer)getMyGroups(groupIdsOrNamesFilter, selectorOptions, true);
    }
    

	public Map<Id, GroupMember> selectByMyGroups() {
		return selectByMyGroups(null, new Set<Object>());
	}

	public Map<Id, GroupMember> selectByMyGroups(List<String> groupIdsOrNamesFilter) {
		return selectByMyGroups(groupIdsOrNamesFilter, new Set<Object>());
	}

	public Map<Id, GroupMember> selectByMyGroups(List<String> groupIdsOrNamesFilter, Set<Object> selectorOptions) {
        return new Map<Id, GroupMember>((List<GroupMember>)getMyGroups(groupIdsOrNamesFilter, selectorOptions, false));
	}

	/**
	 * Grab current users GroupMember records
	 * @param groupIdsOrNamesFilter List of either Group Ids or Group Names to filter the return value by
	 * @return Integer, List<SObject>
	 */
	public Object getMyGroups(List<String> groupIdsOrNamesFilter, Set<Object> selectorOptions, Boolean countOnly) {
		Set<Id> groupIds = new Set<Id>();
		Set<String> groupNames = new Set<String>();

		QueryBuilder.ConditionsManager conditionsManager = newQueryBuilder(selectorOptions).addConditions();
		conditionsManager.add(new QueryBuilder.CompareCondition(GroupMember.UserOrGroupId).eq(UserInfo.getUserId()));
		conditionsManager.setConditionOrder('1');

		if(groupIdsOrNamesFilter != null) {
			for(String item : groupIdsOrNamesFilter) {
				if(item.startsWith('00G') && (item.length() == 15 || item.length() == 18)) {
					groupIds.add(item);
				} else {
					groupNames.add(item);
				}
			}

			if(!groupIds.isEmpty()) {
                conditionsManager.add(new QueryBuilder.SimpleCondition(GroupMember.GroupId + ' in :groupIds'));
			}
			if(!groupNames.isEmpty()) {
                conditionsManager.add(new QueryBuilder.SimpleCondition('Group.Name' + ' in :groupNames'));
                conditionsManager.add(new QueryBuilder.SimpleCondition('Group.DeveloperName' + ' in :groupNames'));
			}

			if(!groupIds.isEmpty() && !groupNames.isEmpty()) {
				conditionsManager.setConditionOrder('1 AND (2 OR 3 OR 4)');
			} else if(!groupIds.isEmpty()) {
				conditionsManager.setConditionOrder('1 AND 2');
			} else if(!groupNames.isEmpty()) {
				conditionsManager.setConditionOrder('1 AND (2 OR 3)');
			}
		}

		if(countOnly) {
			return Database.countQuery(conditionsManager.endConditions().toCountString());
		} else {
			return Database.query(conditionsManager.endConditions().toSoqlString());
		}
	}

	public override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

	public override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		if(selectorOptions.contains(Options.WITH_GROUP)) {
			builder.addRelatedFields(GroupsSelector.newInstance().newQueryBuilder(), 'Group');
		}

		return builder;
	}

	public override List<QueryBuilder.Order> getOrderBy() {
		return new List<QueryBuilder.Order>{new QueryBuilder.Order('Id', 'Desc')};
	}



}