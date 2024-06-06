/**
 * @description
 * Test class for ReopenDisqualifiedLeadsInvocable
 * @author Ranjeewa Silva
 * @group Tests
 * @changelog
 * 2024-05-16 - Ranjeewa Silva - Created
 */
@IsTest
private class ReopenDisqualifiedLeadsInvocable_Test {

	/**
	 * Test to ensure leads disqualified by non lead verification team members are not reopened.
	 */
	@IsTest
	static void testDisqualifiedLeadsNotReopenedWhenUserNotInLeadVerificationTeam() {
		// =====================================
		// Data Preparation
		// =====================================
		Lead lead = ApplicationTestDataFactory.getLeads(1, true)[0];
		lead.Status = 'Disqualified';

		Map<Id, User> leadVerificationTeamMembers = new Map<Id, User>(ApplicationTestDataFactory.getUsers(3, true));

		// =====================================
		// Stubbing
		// =====================================
		GroupMembershipService groupMembershipService = (GroupMembershipService)MockUtility.mockUtility(GroupMembershipService.class);
		LeadsSelector leadsSelector = (LeadsSelector)MockUtility.mockSelector(LeadsSelector.class);
		ApplicationDatabase applicationDatabase = (ApplicationDatabase)MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(groupMembershipService.expandGroupMembership(
				(Set<String>)fflib_Match.anyObject(),
				(Set<GroupMembershipService.MemberTypes>)fflib_Match.anyObject()
		)).thenReturn(new Map<String, Set<Id>>{'Lead_Vero_Group' => leadVerificationTeamMembers.keySet()});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ReopenDisqualifiedLeadsInvocable.reopenLeads(new List<Id>{lead.Id});
		Test.stopTest();

		// verify that leads are not queried as there is nothing to do - current user is not part of lead verification team.
		((LeadsSelector)MockUtility.Mocks.verify(leadsSelector, 0)).selectById((Set<Id>)fflib_Match.anyObject());
		// verify that no lead records are updated
		((ApplicationDatabase)MockUtility.Mocks.verify(applicationDatabase, 0)).dmlUpdate((List<Lead>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
	}

	/**
	 * Test to ensure leads disqualified by lead verification team members are reopened.
	 */
	@IsTest
	static void testDisqualifiedLeadsReopenedWhenUserInLeadVerificationTeam() {
		// =====================================
		// Data Preparation
		// =====================================
		Lead lead = ApplicationTestDataFactory.getLeads(1, true)[0];
		lead.Status = 'Disqualified';

		Map<Id, User> leadVerificationTeamMembers = new Map<Id, User>(ApplicationTestDataFactory.getUsers(3, true));
		leadVerificationTeamMembers.put(UserInfo.getUserId(), new User(Id=UserInfo.getUserId()));

		// =====================================
		// Stubbing
		// =====================================
		GroupMembershipService groupMembershipService = (GroupMembershipService)MockUtility.mockUtility(GroupMembershipService.class);
		LeadsSelector leadsSelector = (LeadsSelector)MockUtility.mockSelector(LeadsSelector.class);
		ApplicationDatabase applicationDatabase = (ApplicationDatabase)MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(groupMembershipService.expandGroupMembership(
				(Set<String>)fflib_Match.anyObject(),
				(Set<GroupMembershipService.MemberTypes>)fflib_Match.anyObject()
		)).thenReturn(new Map<String, Set<Id>>{'Lead_Vero_Group' => leadVerificationTeamMembers.keySet()});

		MockUtility.Mocks.when(leadsSelector.selectById(
				(Set<Id>)fflib_Match.anyObject()
		)).thenReturn(new Map<Id, Lead>{lead.Id => lead});

		MockUtility.Mocks.when(applicationDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean()))
				.thenAnswer(new MockUtility.AnswerGenericDMLUpdated());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ReopenDisqualifiedLeadsInvocable.reopenLeads(new List<Id>{lead.Id});
		Test.stopTest();

		// verify that leads are queried.
		((LeadsSelector)MockUtility.Mocks.verify(leadsSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());

		// verify that lead records are updated
		fflib_ArgumentCaptor sobjectUpdateCapture = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase)MockUtility.Mocks.verify(applicationDatabase, 1)).dmlUpdate((List<SObject>)sobjectUpdateCapture.capture(), fflib_Match.anyBoolean());
		List<SObject> updated = (List<SObject>) sobjectUpdateCapture.getValue();
		Assert.areEqual(1, updated.size(), 'Only one Lead record is expected to be updated, but updated [' + updated.size() + '] records.');
		Assert.areEqual(lead.Id, updated[0].id, 'Expected to update the lead record passed into invocable method, but updated some other record.');
		Assert.areEqual('New', ((Lead)updated[0]).Status, 'Expected to update lead status to \'New\'.');
		Assert.areEqual(1, ((Lead)updated[0]).RequeueAttempts__c, 'Expected to increment RequeueAttempts__c');
		Assert.isNull(((Lead)updated[0]).Lead_Converted_or_Disqualified_Time__c, 'Expected to reset disqualified time on reopening the lead.');
		Assert.isTrue(updated[0].getOptions().assignmentRuleHeader.useDefaultRule, 'Expected DMLOption not set to run active assignment rule on save.');
	}
}