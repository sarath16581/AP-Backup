/**
* @author Alvin.Z
* @date 2021-03-09
* @group Selector
* @tag Selector
* @tag Task SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-03-09 - Alvin Z - Created
*/
public virtual inherited sharing  class AccountTeamMembersSelector extends ApplicationSelector {
    public static AccountTeamMembersSelector newInstance() {
		return (AccountTeamMembersSelector)Application.Selectors.newInstance(AccountTeamMembersSelector.class);
	}
    public override SObjectType getSObjectType() {
		return AccountTeamMember.getSObjectType();
	}

    public virtual override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
            AccountTeamMember.Id, AccountTeamMember.TeamMemberRole, AccountTeamMember.AccountId
		};
	}
    /**
	 * @description Run a simple query to get records based on TeamMemberRole and AccountId
	 */
	public Map<Id, AccountTeamMember> selectByTeamRoleAndAccountIds(String teamMemberRole, Set<Id> accountIds, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);

        QueryBuilder.ConditionsManager conditions = qb.addConditions();

        if(!String.isBlank(String.valueOf(teamMemberRole))){
            conditions.add(new QueryBuilder.SimpleCondition(AccountTeamMember.TeamMemberRole + ' =: teamMemberRole'));
        }
        
        conditions.add(new QueryBuilder.SimpleCondition(AccountTeamMember.AccountId + ' in: accountIds'));
        
        String soql = conditions.endConditions().toSoqlString();
        System.debug('####sql####' + soql);
		return new Map<Id, AccountTeamMember>((List<AccountTeamMember>)Database.query(soql));
	}

    
}