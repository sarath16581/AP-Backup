/**
 * @description Contains the Apex @InvocableMethod to reopen leads and requeue them based on the Lead assignment rule
 *			  active at the time. Invoked by record triggered flow Scheduled Path action.
 *			  Currently apex is necessary to set DMLOption 'Database.DMLOptions.AssignmentRuleHeader'.
 * @author Ranjeewa Silva
 * @date 2024-05-16
 * @Test ReopenDisqualifiedLeadsInvocable_Test
 * @changelog
 * 2024-05-16 - Ranjeewa Silva - Created.
 */
public inherited sharing class ReopenDisqualifiedLeadsInvocable {

	// flag indicating if current user is a member of the lead verification team. lead verification team members are
	// maintained currently via public group - Lead_vero_Group.
	private static Boolean isCurrentUserLeadVerificationTeamMember {
		get {
			if (isCurrentUserLeadVerificationTeamMember == null) {
				Map<String, Set<Id>> leadVerificationTeamMembers = GroupMembershipService.getInstance().expandGroupMembership(new Set<String>{'Lead_Vero_Group'}, new Set<GroupMembershipService.MemberTypes>{
						GroupMembershipService.MemberTypes.USER, GroupMembershipService.MemberTypes.ROLE, GroupMembershipService.MemberTypes.ROLE_AND_SUBORDINATES_INTERNAL
				});

				isCurrentUserLeadVerificationTeamMember = !leadVerificationTeamMembers.isEmpty() && leadVerificationTeamMembers.values()[0].contains(UserInfo.getUserId());
			}
			return isCurrentUserLeadVerificationTeamMember;
		}
		set;
	}

	/**
	 * Reopen leads passed in and ensure they are reassign based on active assignment rule. Currently only leads disqualified
	 * by lead verification team (users in public group 'Lead_Vero_Group') is reopened.
	 *
	 * @param leadIds Ids of the leads to reopen.
	 */
	@InvocableMethod(Label='Reopen Leads' Description='Reopen leads passed in and reassign based on active assignment rule.')
	public static void reopenLeads(List<Id> leadIds) {
		try {
			if (leadIds != null && leadIds.size() > 0 && isCurrentUserLeadVerificationTeamMember) {
				// dml options to be passed in to update operation to trigger assignment rule on update.
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule = true;

				Map<Id,Lead> leads = ((LeadsSelector)LeadsSelector.newInstance().setFieldOverrides(new Set<SObjectField>{
						Lead.Id, Lead.RequeueAttempts__c
				})).selectById(new Set<Id>(leadIds));

				List<Lead> updatableLeads = new List<Lead>();
				for (Lead lead: leads.values()) {
					Lead updatable = getUpdatableLead(lead);
					updatable.setOptions(dmo);
					updatableLeads.add(updatable);
				}

				if (!updatableLeads.isEmpty()) {
					List<Database.SaveResult> saveResults = ApplicationDatabase.getInstance().dmlUpdate(updatableLeads, false);
					ApplicationLogger.getInstance().logFailedDatabaseResults(saveResults, 'Sales', ReopenDisqualifiedLeadsInvocable.class.getName(),
							'reopenLeads(InvocableMethod)', '', ApplicationLogger.LoggingLevel.ERROR);
				}
			}

		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', ReopenDisqualifiedLeadsInvocable.class.getName(),
					'reopenLeads(InvocableMethod)', '', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Returns updatable lead record in 'New' status.
	 * @param lead existing lead record
	 *
	 * @return lead record instance containing necessary updates.
	 */
	private static Lead getUpdatableLead(Lead lead) {
		Lead updatable = new Lead(Id=lead.Id);
		updatable.Status = 'New';
		updatable.Disqualified_Lead_Reason__c = null;
		updatable.Lead_Converted_or_Disqualified_Time__c = null;
		updatable.RequeueAttempts__c = lead.RequeueAttempts__c == null ? 1 : lead.RequeueAttempts__c+1;
		return updatable;
	}

}