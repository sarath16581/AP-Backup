/**
 * @author Seth Heang
 * @date 2024-07-18
 * @group Selector
 * @tag Selector
 * @domain Core
 * @description A Selector Class for CaseTeamMember object
 * @changelog
 * 2024-09-03 - Seth Heang - Created
 */
public virtual inherited sharing class CaseTeamMembersSelector extends ApplicationSelector {

	/**
	 * Instantiate the CaseTeamMembersSelector and passed in fieldOverrides
	 * @param fieldOverrides NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 *						  This approach removes data consistency and prevents possible caching of results
	 * @return new instance of CaseTeamMembersSelector with setFieldOverrides
	 */
	public static CaseTeamMembersSelector newInstance(Set<SObjectField> fieldOverrides) {
		CaseTeamMembersSelector selector = (CaseTeamMembersSelector)Application.Selectors.newInstance(CaseTeamMembersSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	/**
	 * Instantiate a new instance of CaseTeamMembersSelector
	 * @return new instance of CaseTeamMembersSelector
	 */
	public static CaseTeamMembersSelector newInstance() {
		CaseTeamMembersSelector selector = (CaseTeamMembersSelector) Application.Selectors.newInstance(CaseTeamMembersSelector.class);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return CaseTeamMember.SObjectType;
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{ CaseTeamMember.Id, CaseTeamMember.ParentId, CaseTeamMember.MemberId, CaseTeamMember.TeamRoleId };
	}

	/**
	 * @description Run a simple query to get records based on Parent Case Id, Member Id and CaseTeamRold Id
	 * @param caseIds parent case Id of case team member
	 * @param memberId member Id of case team member
	 * @param teamRoleId team role Id of case team member
	 * @return List<CaseTeamMember>
	 */
	public virtual List<CaseTeamMember> selectByCaseIdAndMemberIdAndTeamRoleId(Set<Id> caseIds, Set<Id> memberId, Set<Id> teamRoleId) {
		return selectByCaseIdAndMemberIdAndTeamRoleId(caseIds, memberId, teamRoleId, new Set<Object>());
	}

	/**
	 * @description Run a simple query to get records based on Parent Case Id, Member Id and CaseTeamRold Id
	 * @param caseIds parent case Id of case team member
	 * @param memberId member Id of case team member
	 * @param teamRoleId team role Id of case team member
	 * @param selectorOptions specify the related objects that need to be retrieved with case team member
	 * @return List<CaseTeamMember>
	 */
	public virtual List<CaseTeamMember> selectByCaseIdAndMemberIdAndTeamRoleId(Set<Id> caseIds, Set<Id> memberId, Set<Id> teamRoleId, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder();
		qb.addConditions()
				.add(new QueryBuilder.SimpleCondition(CaseTeamMember.ParentId + ' in :caseIds'))
				.add(new QueryBuilder.SimpleCondition(CaseTeamMember.MemberId + ' in :memberId'))
				.add(new QueryBuilder.SimpleCondition(CaseTeamMember.TeamRoleId + ' in :teamRoleId'))
				.endConditions();
		return (List<CaseTeamMember>) Database.query(qb.toSoqlString());
	}
}