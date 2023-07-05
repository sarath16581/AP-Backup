/**
 * @description Service responsible for expanding public group membership based on the specified member types.
 *			  Returns all users who are group members via at least one of the specified member types.
 *
 *			  Supported member types are:
 *			  MemberTypes.USER  - Include users who are configured as direct members on the group
 *			  MemberTypes.ROLE  - Include users who's role is configured as a direct member on the group
 *			  MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL - Include users either in the top level role or an internal subordinate
 *														   role of a member role configured with 'RoleAndSubordinatesInternal'
 *														   type on the group.
 *
 *			  IMPORTANT: Other types of group members (e.g. groups (of type 'Regular') within groups) are not supported currently.
 *
 *			  Group memberships including direct member users, member roles and all internal subordinate roles are stored in
 *			  platform cache with a time-to-live value of 24 hours for each group after it is initially computed. Note that
 *			  users in member roles are always queried real time to ensure the service take into account new users and user
 *			  movements.
 *
 *			  Usage:
 *			  Prior to using this service it is very important to carefully consider each use case and particularly how
 *			  this service is called (synchronous or asynchronous) and the makeup of candidate public group expanded using this service.
 *			  - Groups with members of type 'RoleAndSubordinatesInternal' will involve loading all internal roles (~500 roles)
 *				and determining the subordinate roles based on the member role configured in group.
 *			  - Groups with members of type 'Role' and 'RoleAndSubordinatesInternal' will require SOQL to query active
 *				users in those member roles. In addition to contributing to the per-transaction limit of number of records
 *				retrieved via SOQL, this operation could also take time depending on the number of users in member roles.
 *
 * @author Ranjeewa Silva
 * @group Service
 * @Test GroupMembershipService_Test
 * @domain Core
 * @changelog
 * 2023-05-09 - Ranjeewa Silva - Created
 */
public inherited sharing class GroupMembershipService {

	// supported member types for determining group member users.
	public enum MemberTypes {
		USER, // include users who are direct members of the group
		ROLE, // include users in a role configured as a group member with member type 'Role'
		ROLE_AND_SUBORDINATES_INTERNAL  // include users in a role or an internal subordinate role of a role configured
										// directly as a group member with member type 'RoleAndSubordinatesRole'
	}

	// cache key setting (CacheKeySetting__mdt) name for accessing platform cache
	private static final String CACHE_KEY_PUBLIC_GROUP_MEMBERSHIP = 'PUBLIC_GROUP_MEMBERSHIP';

	// transactional cache containing a map of parent role to all internal subordinate roles. only contain parent roles
	// configured as public group members with the type 'Role and Subordinates Internal' on groups expanded during current transaction.
	// avoids the need to traverse through the 'directChildRolesMap' to determine all role and subordinate roles of a
	// parent role already computed in current transaction.
	private static Map<Id, Set<Id>> roleAndInternalSubordinateRolesCache = new Map<Id, Set<Id>>();

	// map of parent role to direct child roles. external roles (partner and customer) are excluded from this mapping.
	// loaded in a single soql when expanding groups involving member groups of type 'role and internal subordinates'
	private static Map<Id, Set<Id>> directChildRolesMap {
		get {
			if (directChildRolesMap == null) {
				// query all internal salesforce roles.
				List<UserRole> roles = ((UserRolesSelector) UserRolesSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
						UserRole.Id, UserRole.ParentRoleId
				})).selectByPortalType(new Set<String>{'None'});

				Map<Id, Set<Id>> results = new Map<Id, Set<Id>>();
				for (UserRole role: roles) {
					if (results.get(role.ParentRoleId) == null) {
						results.put(role.ParentRoleId, new Set<Id>());
					}
					results.get(role.ParentRoleId).add(role.Id);
				}

				directChildRolesMap = results;
			}
			return directChildRolesMap;
		}
		set;
	}

	/**
	 * Creates a new instance. This allows use to use dependency injection for mocking
	 * @return the new instance
	 */
	public static GroupMembershipService getInstance() {
		return (GroupMembershipService) Application.Utilities.getInstance(GroupMembershipService.class);
	}

	/**
	 * Expand group members corresponding to the group member types specified.
	 *
	 * Supported member types are:
	 *	  MemberTypes.USER  - Include users who are configured as direct members on the group
	 *	  MemberTypes.ROLE  - Include users who's role is configured as a direct member on the group
	 *	  MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL - Include users either in the top level role or an internal subordinate
	 *												   role of a member role configured with 'RoleAndSubordinatesInternal'
	 *												   type on the group.
	 *
	 * IMPORTANT: Other types of group members (e.g. groups within groups) are not supported currently.
	 *			Please review usage notes in service class description.
	 *
	 * @param groupDeveloperNames group developer names
	 * @param groupMemberTypes member types in scope for calculating group members. this is mandatory and an exception
	 *						 is thrown if not specified.
	 *
	 * @return set of member user ids by group developer name (key - group developer name, value - member user ids).
	 */
	public Map<String, Set<Id>> expandGroupMembership(Set<String> groupDeveloperNames, Set<MemberTypes> groupMemberTypes) {

		if (groupMemberTypes == null || groupMemberTypes.isEmpty()) {
			// member types are not specified by the caller. throw an exception as member types are mandatory.
			String msg = 'Expanding group members not supported when \'groupMemberTypes\' not explicitly set.';
			throw new GroupMembershipServiceException(msg);
		}

		Map<String, GroupMembership> groupMemberships = getGroupMemberships(groupDeveloperNames);

		// select all users corresponding to computed group membership.
		return getGroupMemberUsers(groupMemberships.values(), groupMemberTypes);
	}

	/**
	 * Returns the memberships of specified groups considering supported member types.
	 *
	 * @param groupDeveloperNames developer names of groups.
	 *
	 * @return group memberships for each group (key = group developer name, value = group membership instance).
	 */
	private Map<String, GroupMembership> getGroupMemberships(Set<String> groupDeveloperNames) {
		// first check if sales specialist group memberships are already available in platform cache.
		// only compute membership if not available in cache.
		Map<String, GroupMembership> groupMemberships = (Map<String, GroupMembership>) CacheManager.get(CACHE_KEY_PUBLIC_GROUP_MEMBERSHIP);
		//Map<String, GroupMembership> groupMemberships = null;
		groupMemberships = (groupMemberships == null ? new Map<String, GroupMembership>() : groupMemberships);

		if (!groupMemberships.keySet().containsAll(groupDeveloperNames)) {
			// group membership of some groups are not available in platform cache.
			// work out the groups that require membership to be computed
			Set<String> groupsToComputeMembership = groupDeveloperNames.clone();
			groupsToComputeMembership.removeAll(groupMemberships.keySet());

			// select groups by developer names for the groups that require membership to be computed.
			// child group members (i.e. direct members) are also retrieved.
			Map<Id, Group> groups = ((GroupsSelector) GroupsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
					Group.Id, Group.DeveloperName, Group.Type
			})).selectByDeveloperName(groupsToComputeMembership, new Set<Object>{GroupsSelector.Options.WITH_DIRECT_MEMBERS});

			// compute membership of the required groups
			Map<String, GroupMembership> computedGroupMemberships = computeGroupMembership(groups);
			// merge with the memberships retrieved from platform cache
			groupMemberships.putAll(computedGroupMemberships);
			// also populate platform cache so it is available later
			CacheManager.put(CACHE_KEY_PUBLIC_GROUP_MEMBERSHIP, groupMemberships);
		}

		// all required memberships are now available. either read from platform cache or newly computed and updated in platform cache.
		// now work out what we need to return based on the developer names specified by the caller.
		Map<String, GroupMembership> results = new Map<String, GroupMembership>();
		for (String groupDeveloperName: groupDeveloperNames) {
			GroupMembership membership = groupMemberships.get(groupDeveloperName);
			if (membership != null) {
				results.put(groupDeveloperName, membership);
			}
		}

		return results;
	}

	/**
	 * Compute members of specified groups. Only members of supported member types are included.
	 *
	 * @param groups public groups
	 *
	 * @return group membership for specified groups (key - group developer name, value - group membership)
	 */
	@TestVisible private Map<String, GroupMembership> computeGroupMembership(Map<Id, Group> groups) {

		Map<String, GroupMembership> groupMemberships = new Map<String, GroupMembership>();

		// groups can have child groups as members. any one child group can be a member of more than one parent group.
		// even-though this component doesn't support regular public groups ( Type = 'Regular') as group members, we still need
		// to support groups representing roles and rolesAndInternalSubordinates as group members.

		// keep a map of child group Id to parent group Ids
		Map<Id, Set<Id>> memberGroupToParentGroupMapping = new Map<Id, Set<Id>>();

		for (Group g: groups.values()) {

			GroupMembership membership = new GroupMembership();
			membership.groupId = g.Id;
			membership.developerName = g.DeveloperName;
			groupMemberships.put(g.DeveloperName, membership);

			// iterate through direct members of this group.
			// when group member is a user ( 'UserOrGroupId' points to a User) then add as a direct member user.
			// when group member is another group ( 'UserOrGroupId' points to a Group ), we need to retrieve target group
			// details and inspect Type of the group to check if it is one of supported types - 'Role' or 'RoleAndSubordinatesInternal'.
			for (GroupMember gm: g.GroupMembers) {
				SObjectType userOrGroupType = gm.UserOrGroupId.getSobjectType();
				if (userOrGroupType == User.SObjectType) {
					// group member is a user
					membership.addDirectMemberUser(gm.UserOrGroupId);
				} else if (userOrGroupType == Group.SObjectType) {
					// group member is another group and we need to inspect target group to see if it represents a Role
					// or Role and Internal Subordinates of a Role
					if (memberGroupToParentGroupMapping.get(gm.UserOrGroupId) == null) {
						memberGroupToParentGroupMapping.put(gm.UserOrGroupId, new Set<Id>());
					}
					memberGroupToParentGroupMapping.get(gm.UserOrGroupId).add(gm.GroupId);
				}
			}
		}

		if (!memberGroupToParentGroupMapping.isEmpty()) {
			// found instances where the group member is another group.
			// query all such child groups based on the ids collected. we need to inspect target group to see if it represents a Role
			// or Role and Internal Subordinates of a Role
			Map<Id, Group> memberGroups = ((GroupsSelector) GroupsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
					Group.Id, Group.DeveloperName, Group.Type, Group.RelatedId
			})).selectById(memberGroupToParentGroupMapping.keySet());

			for (Group memberGroup: memberGroups.values()) {
				// check the Type to see if members have to be computed for this group
				if ((memberGroup.Type == 'Role') || (memberGroup.Type == 'RoleAndSubordinatesInternal')) {
					// member group type is supported for computing members.
					for (Id parentGroupId: memberGroupToParentGroupMapping.get(memberGroup.Id)) {
						String parentGroupDeveloperName = groups.get(parentGroupId).DeveloperName;
						GroupMembership membership = groupMemberships.get(parentGroupDeveloperName);
						membership.addDirectMemberGroup(memberGroup);
					}
				}
			}
		}

		return groupMemberships;
	}

	/**
	 * Get all users based on the GroupMemberships and member types passed in.
	 *
	 * @param groupMemberships list of group memberships
	 * @param groupMemberTypes member types in scope for determining member users
	 *
	 * @return set of member user ids per each group. key - parent group developer name, value - set of user Ids
	 */
	@TestVisible private Map<String, Set<Id>> getGroupMemberUsers(List<GroupMembership> groupMemberships, Set<MemberTypes> groupMemberTypes) {
		Map<String, Set<Id>> results = new Map<String, Set<Id>>();

		// collect all role ids included in group membership. we need to retrieve users in these roles.
		Set<Id> memberRoleIds = new Set<Id>();
		for (GroupMembership membership: groupMemberships) {
			results.put(membership.developerName, new Set<Id>());
			if (groupMemberTypes.contains(MemberTypes.USER)) {
				// caller is interested in direct member users. add them to the results returned.
				results.get(membership.developerName).addAll(membership.directMemberUsers);
			}

			if (groupMemberTypes.contains(MemberTypes.ROLE)) {
				// caller is interested in member roles. add them to a collection so that users can be queried for these roles.
				memberRoleIds.addAll(membership.memberRoles);
			}

			if (groupMemberTypes.contains(MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL)) {
				// caller is interested in 'role and internal subordinate roles' members. add role and all subordinate roles
				// to the collection so that users can be queried for these roles.
				memberRoleIds.addAll(membership.roleAnSubordinateMemberRoles);
			}
		}

		if (!memberRoleIds.isEmpty()) {
			// query all active users in the roles
			List<User> users = UsersSelector.newInstance(0, new Set<SObjectField>{User.Id, User.UserRoleId, User.IsActive}).search(new Map<String, Object> {
					'roleIds' => memberRoleIds,
					'isActive' => true
			}, true);

			for (User u: users) {
				for (GroupMembership membership: groupMemberships) {

					if ((groupMemberTypes.contains(MemberTypes.USER) && membership.directMemberUsers.contains(u.Id))
							|| (groupMemberTypes.contains(MemberTypes.ROLE) && membership.memberRoles.contains(u.UserRoleId))
							|| (groupMemberTypes.contains(MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL) && membership.roleAnSubordinateMemberRoles.contains(u.UserRoleId))) {
						results.get(membership.developerName).add(u.Id);
					}
				}
			}
		}

		return results;
	}

	@TestVisible private class GroupMembership {
		@TestVisible private Id groupId;
		@TestVisible private String developerName;
		@TestVisible private Set<Id> directMemberUsers = new Set<Id>();
		@TestVisible private Map<Id, MemberGroup> directMemberGroups = new Map<Id, MemberGroup>();
		@TestVisible private Set<Id> memberRoles = new Set<Id>();
		@TestVisible private Set<Id> roleAnSubordinateMemberRoles = new Set<Id>();

		private void addDirectMemberGroup(Group directMemberGroup) {
			this.directMemberGroups.put(directMemberGroup.Id, new MemberGroup(directMemberGroup));
			if (directMemberGroup.Type == 'Role') {
				this.memberRoles.add(directMemberGroup.RelatedId);
			} else if (directMemberGroup.Type == 'RoleAndSubordinatesInternal') {
				this.roleAnSubordinateMemberRoles.addAll(getRoleAndSubordinateRoles(directMemberGroup.RelatedId));
			}
		}

		private void addDirectMemberUser(Id userId) {
			this.directMemberUsers.add(userId);
		}

		private Set<Id> getRoleAndSubordinateRoles(Id roleId) {
			if (roleAndInternalSubordinateRolesCache.containsKey(roleId)) {
				return roleAndInternalSubordinateRolesCache.get(roleId);
			}

			Set<Id> results = getChildRoles(roleId);
			roleAndInternalSubordinateRolesCache.put(roleId, results);

			return results;
		}

		private Set<Id> getChildRoles(Id roleId) {

			// include specified role id in the results. next we will check if this role has any subordinate roles.
			Set<Id> results = new Set<Id>{roleId};

			// check if the specified role has any direct children. if no direct children then this is a leaf node in
			// role hierarchy and we just return the specified role in results.
			Set<Id> directChildRoles = directChildRolesMap.get(roleId);
			if (directChildRoles != null && !directChildRoles.isEmpty()) {
				// specified role has direct children. we need to get child roles of each of the direct child roles and
				// include into the results returned.
				for (Id r : directChildRoles) {
					results.addAll(getChildRoles(r));
				}
			}

			return results;
		}
	}

	private class MemberGroup {
		private Id id;
		private String developerName;
		private String type;
		private Id relatedId;

		private MemberGroup(Group g) {
			this.id = g.Id;
			this.developerName = g.DeveloperName;
			this.type = g.Type;
			this.relatedId = g.RelatedId;
		}
	}

	// exception thrown by the service
	public class GroupMembershipServiceException extends Exception {}
}