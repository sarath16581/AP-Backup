/*
 * @date 2020-10-27
 * @group Opportunities
 * @tag OpportunitySplit
 * @domain Core
 * @description update Opportunity Team Member Role in System Context as Opportunity Owner change does not allow
 *              to update the Team Member role in previous owner context
 * @changelog
 * 2020-10-27 - arjun.singh@auspost.com.au - Created
 */
public without sharing class OpportunitySplitRoleUpdate {

    public static void updateTeamMemberRoleInSystemContext(List<OpportunityTeamMember> teamMemberList){        
        ApplicationDatabase.getInstance().dmlUpdate(teamMemberList);                        
    }
}