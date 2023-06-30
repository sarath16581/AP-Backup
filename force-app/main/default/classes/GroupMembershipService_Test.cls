/**
 * @description
 * Test class for GroupMembershipService
 * @author Ranjeewa Silva
 * @group Tests
 * @domain Core
 * @changelog
 * 2023-05-18 - Ranjeewa Silva - Created
 */
@IsTest
private class GroupMembershipService_Test {

	/**
	 * Test to ensure direct member users are included in computing group membership
	 */
	@IsTest
	static void testComputeGroupMembershipGroupHavingDirectMemberUsersOnly() {
		// =====================================
		// Data Preparation
		// =====================================
		List<User> users = ApplicationTestDataFactory.getUsers(3, true);

		Group g = ApplicationTestDataFactory.getGroups(1, true)[0];
		List<GroupMember> members = ApplicationTestDataFactory.getGroupMembers(3, new List<Id>{g.Id, g.Id, g.Id}, new List<Id>{users[0].Id, users[1].Id, users[2].Id}, true);

		g = (Group) ApplicationTestDataFactory.setChildRelationships(g, new Map<String, List<SObject>>{'GroupMembers' => members});

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, GroupMembershipService.GroupMembership> membershipMap = GroupMembershipService.getInstance().computeGroupMembership(new Map<Id, Group>{g.Id => g});
		Test.stopTest();

		System.assertEquals(1, membershipMap.size(), 'Expected to compute and return membership of the group passed in');
		System.assertEquals(g.DeveloperName, membershipMap.keySet().iterator().next(), 'Expected to compute and return membership of the group passed in');

		GroupMembershipService.GroupMembership membership = membershipMap.get(g.DeveloperName);
		System.assertEquals(g.Id, membership.groupId, 'Expected group id to be populated in returned membership details');
		System.assertEquals(g.DeveloperName, membership.developerName, 'Expected group developer name to be populated in returned membership details');
		System.assertEquals(members.size(), membership.directMemberUsers.size(), 'Expected direct member users to be populated in returned membership');
		System.assert(membership.directMemberUsers.containsAll(new Set<Id>{users[0].Id, users[1].Id, users[2].Id}), 'Expected direct member users to be populated in returned membership');
		System.assert(membership.directMemberGroups.isEmpty(), 'Expected direct member groups to be empty');
		System.assert(membership.memberRoles.isEmpty(), 'Expected direct member roles to be empty');
		System.assert(membership.roleAnSubordinateMemberRoles.isEmpty(), 'Expected role and subordinate role members to be empty');
	}

	/**
	 * Test to ensure direct member roles are included in computing group membership
	 */
	@IsTest
	static void testComputeGroupMembershipGroupHavingMemberRoles() {
		// =====================================
		// Data Preparation
		// =====================================
		List<UserRole> roles = ApplicationTestDataFactory.getUserRoles(3, true);

		Group g = ApplicationTestDataFactory.getGroups(1, true)[0];

		List<Group> roleGroups = ApplicationTestDataFactory.getGroups(3, true);
		for(Integer i=0; i<roleGroups.size(); i++) {
			roleGroups[i] = (Group) ApplicationTestDataFactory.setUnwritableFields(roleGroups[i], new Map<String, Object>{
				'RelatedId' => roles[i].Id,
				'Type' => 'Role'
			});
		}

		List<GroupMember> members = ApplicationTestDataFactory.getGroupMembers(3, new List<Id>{g.Id, g.Id, g.Id}, new List<Id>{roleGroups[0].Id, roleGroups[1].Id, roleGroups[2].Id}, true);

		g = (Group) ApplicationTestDataFactory.setChildRelationships(g, new Map<String, List<SObject>>{'GroupMembers' => members});

		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>(roleGroups));
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, GroupMembershipService.GroupMembership> membershipMap = GroupMembershipService.getInstance().computeGroupMembership(new Map<Id, Group>{g.Id => g});
		Test.stopTest();

		System.assertEquals(1, membershipMap.size(), 'Expected to compute and return membership of the group passed in');
		System.assertEquals(g.DeveloperName, membershipMap.keySet().iterator().next(), 'Expected to compute and return membership of the group passed in');

		GroupMembershipService.GroupMembership membership = membershipMap.get(g.DeveloperName);
		System.assertEquals(g.Id, membership.groupId, 'Expected group id to be populated in returned membership details');
		System.assertEquals(g.DeveloperName, membership.developerName, 'Expected group developer name to be populated in returned membership details');
		System.assert(membership.directMemberUsers.isEmpty(), 'Expected direct member users to be empty');
		System.assertEquals(members.size(), membership.directMemberGroups.size(), 'Expected direct member groups to be populated in returned membership');
		System.assert(membership.directMemberGroups.keySet().containsAll(new Set<Id>{roleGroups[0].Id, roleGroups[1].Id, roleGroups[2].Id}), 'Expected direct member groups to be populated in returned membership');
		System.assert(membership.memberRoles.containsAll(new Map<Id, UserRole>(roles).keySet()), 'Expected member role ids to be populated');
		System.assert(membership.roleAnSubordinateMemberRoles.isEmpty(), 'Expected role and subordinate role members to be empty');
	}

	/**
	 * Test to ensure roles and subordinate member roles are included in computing group membership
	 */
	@IsTest
	static void testComputeGroupMembershipGroupHavingRoleAndInternalSubordinateMemberRoles() {
		// =====================================
		// Data Preparation
		// =====================================
		List<UserRole> roles = ApplicationTestDataFactory.getUserRoles(3, true);
		// set up 3 roles in a hierarchy
		roles[1].ParentRoleId = roles[0].Id;
		roles[2].ParentRoleId = roles[1].Id;

		Group g = ApplicationTestDataFactory.getGroups(1, true)[0];

		// set up a group representing role and subordinate roles of roles[0].
		Group roleGroup = ApplicationTestDataFactory.getGroups(1, true)[0];
		roleGroup = (Group) ApplicationTestDataFactory.setUnwritableFields(roleGroup, new Map<String, Object>{
					'RelatedId' => roles[0].Id,
					'Type' => 'RoleAndSubordinatesInternal'
		});

		List<GroupMember> members = ApplicationTestDataFactory.getGroupMembers(1, new List<Id>{g.Id}, new List<Id>{roleGroup.Id}, true);

		g = (Group) ApplicationTestDataFactory.setChildRelationships(g, new Map<String, List<SObject>>{'GroupMembers' => members});

		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
		UserRolesSelector mockRolesSelector = (UserRolesSelector)MockUtility.mockSelector(UserRolesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>{roleGroup.Id => roleGroup});
		MockUtility.Mocks.when(mockRolesSelector.selectByPortalType((Set<String>)fflib_Match.anyObject())).thenReturn(roles);
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, GroupMembershipService.GroupMembership> membershipMap = GroupMembershipService.getInstance().computeGroupMembership(new Map<Id, Group>{g.Id => g});
		Test.stopTest();

		System.assertEquals(1, membershipMap.size(), 'Expected to compute and return membership of the group passed in');
		System.assertEquals(g.DeveloperName, membershipMap.keySet().iterator().next(), 'Expected to compute and return membership of the group passed in');

		GroupMembershipService.GroupMembership membership = membershipMap.get(g.DeveloperName);
		System.assertEquals(g.Id, membership.groupId, 'Expected group id to be populated in returned membership details');
		System.assertEquals(g.DeveloperName, membership.developerName, 'Expected group developer name to be populated in returned membership details');
		System.assert(membership.directMemberUsers.isEmpty(), 'Expected direct member users to be empty');
		System.assertEquals(members.size(), membership.directMemberGroups.size(), 'Expected direct member groups to be populated in returned membership');
		System.assert(membership.directMemberGroups.keySet().contains(roleGroup.Id), 'Expected direct member groups to be populated in returned membership');
		System.assert(membership.roleAnSubordinateMemberRoles.containsAll(new Map<Id, UserRole>(roles).keySet()), 'Expected role and subordinate member role ids to be populated');
		System.assert(membership.memberRoles.isEmpty(), 'Expected role members to be empty');
	}

	/**
	 * Test to ensure group memberships are computed for multiple groups together
	 */
	@IsTest
	static void testComputeGroupMembershipMultipleGroups() {
		// =====================================
		// Data Preparation
		// =====================================

		// test scenario
		// groups[0] - no members
		// groups[1] - direct member users only
		// groups[2] - direct member users, and groups representing roles and 'roles and internal subordinate' roles
		List<Group> groups = ApplicationTestDataFactory.getGroups(3, true);

		List<User> users = ApplicationTestDataFactory.getUsers(3, true);

		List<UserRole> roles = ApplicationTestDataFactory.getUserRoles(3, true);
		// set up 2 roles in a hierarchy, other one sits on it's own.
		roles[1].ParentRoleId = roles[0].Id;

		// set up a group representing role and subordinate roles of roles[0].
		Group roleAndSubordinateGroup = ApplicationTestDataFactory.getGroups(1, true)[0];
		roleAndSubordinateGroup = (Group) ApplicationTestDataFactory.setUnwritableFields(roleAndSubordinateGroup, new Map<String, Object>{
				'RelatedId' => roles[0].Id,
				'Type' => 'RoleAndSubordinatesInternal'
		});

		// setup another group representing roles[2]
		Group roleGroup = ApplicationTestDataFactory.getGroups(1, true)[0];
		roleGroup = (Group) ApplicationTestDataFactory.setUnwritableFields(roleGroup, new Map<String, Object>{
				'RelatedId' => roles[2].Id,
				'Type' => 'Role'
		});

		// group members for groups[1]
		List<GroupMember> membersGroupOne = ApplicationTestDataFactory.getGroupMembers(2, new List<Id>{groups[1].Id, groups[1].Id}, new List<Id>{users[0].Id, users[1].Id}, true);
		groups[1] = (Group) ApplicationTestDataFactory.setChildRelationships(groups[1], new Map<String, List<SObject>>{'GroupMembers' => membersGroupOne});

		List<GroupMember> membersGroupTwo = ApplicationTestDataFactory.getGroupMembers(3, new List<Id>{groups[2].Id, groups[2].Id, groups[2].Id}, new List<Id>{users[2].Id, roleGroup.Id, roleAndSubordinateGroup.Id}, true);
		groups[2] = (Group) ApplicationTestDataFactory.setChildRelationships(groups[2], new Map<String, List<SObject>>{'GroupMembers' => membersGroupTwo});

		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
		UserRolesSelector mockRolesSelector = (UserRolesSelector)MockUtility.mockSelector(UserRolesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>{roleGroup.Id => roleGroup, roleAndSubordinateGroup.Id => roleAndSubordinateGroup});
		MockUtility.Mocks.when(mockRolesSelector.selectByPortalType((Set<String>)fflib_Match.anyObject())).thenReturn(roles);
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, GroupMembershipService.GroupMembership> membershipMap = GroupMembershipService.getInstance().computeGroupMembership(new Map<Id, Group>(groups));
		Test.stopTest();

		System.assertEquals(3, membershipMap.size(), 'Expected to compute and return membership of the group passed in');

		GroupMembershipService.GroupMembership group0Membership = membershipMap.get(groups[0].DeveloperName);
		System.assert(group0Membership.directMemberUsers.isEmpty(), 'Expected direct member users to be empty');
		System.assert(group0Membership.directMemberGroups.isEmpty(), 'Expected direct member groups to be empty');

		GroupMembershipService.GroupMembership group1Membership = membershipMap.get(groups[1].DeveloperName);
		System.assertEquals(2, group1Membership.directMemberUsers.size(), 'Expected 2 direct member users to be populated on membership');
		System.assert(group1Membership.directMemberGroups.isEmpty(), 'Expected direct member groups to be empty');

		GroupMembershipService.GroupMembership group2Membership = membershipMap.get(groups[2].DeveloperName);
		System.assertEquals(1, group2Membership.directMemberUsers.size(), 'Expected 1 direct member user to be populated on membership');
		System.assertEquals(2, group2Membership.directMemberGroups.size(), 'Expected direct member groups to be populated on membership');
		System.assertEquals(2, group2Membership.roleAnSubordinateMemberRoles.size(), 'Expected role and subordinate member role ids to be populated');
		System.assertEquals(1, group2Membership.memberRoles.size(), 'Expected member role ids to be populated');
	}

	/**
	 * Test to ensure only direct member users are returned when member type filter MemberTypes.USER is specified.
	 */
	@IsTest
	static void testGetGroupMemberUsersWithDirectMemberUsersFilter() {
		// =====================================
		// Data Preparation
		// =====================================
		List<User> users = ApplicationTestDataFactory.getUsers(2, true);

		List<Group> groups = ApplicationTestDataFactory.getGroups(1, true);

		List<UserRole> roles = ApplicationTestDataFactory.getUserRoles(2, true);

		// setup group membership to be passed into test method.
		GroupMembershipService.GroupMembership membership = new GroupMembershipService.GroupMembership();
		membership.developerName = groups[0].DeveloperName;
		membership.directMemberUsers = new Map<Id, User>(users).keySet();
		membership.memberRoles = new Set<Id>{roles[1].Id};
		membership.roleAnSubordinateMemberRoles = new Set<Id>{roles[0].Id};
		List<GroupMembershipService.GroupMembership> membershipsList = new List<GroupMembershipService.GroupMembership>{membership};

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Set<Id>> memberUsersMap = GroupMembershipService.getInstance().getGroupMemberUsers(membershipsList, new Set<GroupMembershipService.MemberTypes>{
				GroupMembershipService.MemberTypes.USER
		});
		Test.stopTest();

		// verify that users are not queried when only direct member users are requested.
		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, 0)).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());

		System.assertEquals(1, memberUsersMap.size(), 'Expected to compute and return member users of the group passed in');
		System.assertEquals(2, memberUsersMap.get(groups[0].DeveloperName).size(), 'Only direct member users must be returned when MemberTypes.USER is specified.');
	}

	/**
	 * Test to ensure only users in direct member roles are returned when member type filter MemberTypes.ROLE is specified.
	 */
	@IsTest
	static void testGetGroupMemberUsersWithMemberRolesFilter() {
		// =====================================
		// Data Preparation
		// =====================================
		List<UserRole> roles = ApplicationTestDataFactory.getUserRoles(3, true);

		List<User> users = ApplicationTestDataFactory.getUsers(3, true);
		users[0].UserRoleId = roles[0].Id; // roles[0] is a 'roleAndInternalSubordinate' group member
		users[1].UserRoleId = roles[1].Id; // roles[1] is a direct 'role' group member
		users[2].UserRoleId = roles[2].Id; // roles[2] is not a group member, users[2] is configured as a direct member of the group.

		List<Group> groups = ApplicationTestDataFactory.getGroups(1, true);

		// setup group membership to be passed into test method.
		GroupMembershipService.GroupMembership membership = new GroupMembershipService.GroupMembership();
		membership.developerName = groups[0].DeveloperName;
		membership.directMemberUsers = new Set<Id>{users[2].Id};
		// setup roles[0] as a 'roleAndInternalSubordinate' member
		membership.roleAnSubordinateMemberRoles = new Set<Id>{roles[0].Id};
		// setup roles[1] as a member role
		membership.memberRoles = new Set<Id>{roles[1].Id};
		List<GroupMembershipService.GroupMembership> membershipsList = new List<GroupMembershipService.GroupMembership>{membership};

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>{users[1]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Set<Id>> memberUsersMap = GroupMembershipService.getInstance().getGroupMemberUsers(membershipsList, new Set<GroupMembershipService.MemberTypes>{
				GroupMembershipService.MemberTypes.ROLE
		});

		Test.stopTest();

		// verify that users are queried for member roles only when only users in member roles are requested.
		// service should not query users in 'role and internal subordinate' roles.
		fflib_ArgumentCaptor argCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, 1)).search((Map<String, Object>)argCaptor.capture(), fflib_Match.anyBoolean());
		Map<String, Object> userSearchParameters = (Map<String, Object>) argCaptor.getValue();

		System.assert(userSearchParameters.containsKey('roleIds'), 'Expected to pass roleIds as a parameters into search method');
		System.assertEquals(1, ((Set<Id>)userSearchParameters.get('roleIds')).size(), 'Expected to pass only the id of direct member role. role and subordinate roles must not be passed');
		System.assert(((Set<Id>)userSearchParameters.get('roleIds')).contains(roles[1].Id), 'Expected to pass only the id of direct member role. role and subordinate roles must not be passed');

		System.assertEquals(1, memberUsersMap.size(), 'Expected to compute and return member users of the group passed in');
		System.assertEquals(1, memberUsersMap.get(groups[0].DeveloperName).size(), 'Only users in member roles must be returned when MemberTypes.ROLE is specified.');
		System.assertEquals(users[1].Id, memberUsersMap.get(groups[0].DeveloperName).iterator().next(), 'Only users in member roles must be returned when MemberTypes.ROLE is specified.');
	}

	/**
	 * Test to ensure only users in member role or subordinate roles are returned when member type filter
	 * MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL is specified.
	 */
	@IsTest
	static void testGetGroupMemberUsersWithRoleAndInternalSubordinateRolesFilter() {
		// =====================================
		// Data Preparation
		// =====================================
		List<UserRole> roles = ApplicationTestDataFactory.getUserRoles(3, true);

		List<User> users = ApplicationTestDataFactory.getUsers(3, true);
		users[0].UserRoleId = roles[0].Id; // roles[0] is a 'roleAndInternalSubordinate' group member
		users[1].UserRoleId = roles[1].Id; // roles[1] is a direct 'role' group member
		users[2].UserRoleId = roles[2].Id; // roles[2] is not a group member, users[2] is configured as a direct member of the group.

		List<Group> groups = ApplicationTestDataFactory.getGroups(1, true);

		// setup group membership to be passed into test method.
		GroupMembershipService.GroupMembership membership = new GroupMembershipService.GroupMembership();
		membership.developerName = groups[0].DeveloperName;
		membership.directMemberUsers = new Set<Id>{users[2].Id};
		// setup roles[0] as a 'roleAndInternalSubordinate' member
		membership.roleAnSubordinateMemberRoles = new Set<Id>{roles[0].Id};
		// setup roles[1] as a member role
		membership.memberRoles = new Set<Id>{roles[1].Id};
		List<GroupMembershipService.GroupMembership> membershipsList = new List<GroupMembershipService.GroupMembership>{membership};

		// =====================================
		// Stubbing
		// =====================================
		UsersSelector mockUsersSelector = (UsersSelector) MockUtility.mockSelector(UsersSelector.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUsersSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<User>{users[0]});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Set<Id>> memberUsersMap = GroupMembershipService.getInstance().getGroupMemberUsers(membershipsList, new Set<GroupMembershipService.MemberTypes>{
				GroupMembershipService.MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL
		});
		Test.stopTest();

		// verify that users are queried for member roles only when only users in member roles are requested.
		// service should not query users in 'role and internal subordinate' roles.
		fflib_ArgumentCaptor argCaptor = fflib_ArgumentCaptor.forClass(Map<String, Object>.class);
		((UsersSelector)MockUtility.Mocks.verify(mockUsersSelector, 1)).search((Map<String, Object>)argCaptor.capture(), fflib_Match.anyBoolean());
		Map<String, Object> userSearchParameters = (Map<String, Object>) argCaptor.getValue();

		System.assert(userSearchParameters.containsKey('roleIds'), 'Expected to pass roleIds as a parameters into search method');
		System.assertEquals(1, ((Set<Id>)userSearchParameters.get('roleIds')).size(), 'Expected to pass only the id of role and subordinate member role. direct member roles must not be passed');
		System.assert(((Set<Id>)userSearchParameters.get('roleIds')).contains(roles[0].Id), 'Expected to pass only the id of role and subordinate member role. direct member roles must not be passed');

		System.assertEquals(1, memberUsersMap.size(), 'Expected to compute and return member users of the group passed in');
		System.assertEquals(1, memberUsersMap.get(groups[0].DeveloperName).size(), 'Only users in member roles must be returned when MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL is specified.');
		System.assertEquals(users[0].Id, memberUsersMap.get(groups[0].DeveloperName).iterator().next(), 'Only users in member roles must be returned when MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL is specified.');
	}

	/**
	 * Test to ensure service throws exception when member types parameter is invalid
	 */
	@IsTest
	static void testExpandGroupMembershipWithInvalidMemberTypesThrowsException() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Group> groups = ApplicationTestDataFactory.getGroups(1, true);

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			GroupMembershipService.getInstance().expandGroupMembership(new Set<String>{groups[0].DeveloperName}, null);
			System.assert(false, 'Expected to throw GroupMembershipServiceException when member types parameter is null');
		} catch (Exception e) {
			System.assert(e.getTypeName() == GroupMembershipService.GroupMembershipServiceException.class.getName(), 'Expected to throw GroupMembershipServiceException but got : ' + e.getTypeName());
		}

		try {
			GroupMembershipService.getInstance().expandGroupMembership(new Set<String>{groups[0].DeveloperName}, new Set<GroupMembershipService.MemberTypes>());
			System.assert(false, 'Expected to throw GroupMembershipServiceException when member types parameter is empty');
		} catch (Exception e) {
			System.assert(e.getTypeName() == GroupMembershipService.GroupMembershipServiceException.class.getName(), 'Expected to throw GroupMembershipServiceException but got : ' + e.getTypeName());
		}
		Test.stopTest();
	}

	/**
	 * Test to ensure service returns expanded group membership when passing in valid member types
	 */
	@IsTest
	static void testExpandGroupMembershipWithValidMemberTypes() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Group> groups = ApplicationTestDataFactory.getGroups(2, true);

		List<User> users = ApplicationTestDataFactory.getUsers(4, true);

		// users[0] and users[1] are direct members of groups[0].
		// users[2] and users[3] are direct members of groups[1].
		List<GroupMember> members = ApplicationTestDataFactory.getGroupMembers(4, new List<Id>{groups[0].Id, groups[0].Id, groups[1].Id, groups[1].Id}, new List<Id>{users[0].Id, users[1].Id, users[2].Id, users[3].Id}, true);

		groups[0] = (Group) ApplicationTestDataFactory.setChildRelationships(groups[0], new Map<String, List<SObject>>{'GroupMembers' => new List<GroupMember>{members[0], members[1]}});
		groups[1] = (Group) ApplicationTestDataFactory.setChildRelationships(groups[1], new Map<String, List<SObject>>{'GroupMembers' => new List<GroupMember>{members[2], members[3]}});

		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector) MockUtility.mockSelector(GroupsSelector.class);

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectByDeveloperName((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>(groups));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Set<Id>> groupMembers = GroupMembershipService.getInstance().expandGroupMembership(new Set<String>{groups[0].DeveloperName, groups[1].DeveloperName}, new Set<GroupMembershipService.MemberTypes>{
				GroupMembershipService.MemberTypes.USER, GroupMembershipService.MemberTypes.ROLE, GroupMembershipService.MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL
		});

		Test.stopTest();

		System.assertEquals(2, groupMembers.size(), 'Expected to return group members for each group requested');
		System.assert(groupMembers.get(groups[0].DeveloperName).containsAll(new Set<Id>{users[0].Id, users[1].Id}));
		System.assert(groupMembers.get(groups[1].DeveloperName).containsAll(new Set<Id>{users[2].Id, users[3].Id}));
	}
}