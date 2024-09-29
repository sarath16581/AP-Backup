/**
 * @author Seth Heang
 * @group Tests
 * @tag Selector
 * @tag CaseTeamMember SObject
 * @domain Core
 * @description Test class for CaseTeamMembersSelector
 * @changelog
 * 2024-09-06 - Seth Heang - Created
 */
@IsTest(IsParallel=true)
private class CaseTeamMembersSelectorTest {
	@IsTest
	private static void queryFromCorrectObjectWithCorrectFields() {
		CaseTeamMembersSelector selector = CaseTeamMembersSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?is)\\bfrom CaseTeamMember\\b').matcher(soql).find(), 'Query from CaseTeamMember object');
		Assert.areEqual(true, Pattern.compile('\\b' + String.valueOf(CaseTeamMember.Id) + '\\b').matcher(soql).find(), 'Field ' + String.valueOf(CaseTeamMember.Id) + ' does not exist in query');
		Assert.areEqual(true, Pattern.compile('\\b' + String.valueOf(CaseTeamMember.ParentId) + '\\b').matcher(soql).find(), 'Field ' + String.valueOf(CaseTeamMember.ParentId) + ' does not exist in query');
		Assert.areEqual(true, Pattern.compile('\\b' + String.valueOf(CaseTeamMember.MemberId) + '\\b').matcher(soql).find(), 'Field ' + String.valueOf(CaseTeamMember.MemberId) + ' does not exist in query');
		Assert.areEqual(true, Pattern.compile('\\b' + String.valueOf(CaseTeamMember.TeamRoleId) + '\\b').matcher(soql).find(), 'Field ' + String.valueOf(CaseTeamMember.TeamRoleId) + ' does not exist in query');
	}

	@IsTest
	static void selectWithTheCorrectQueryAttributes() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseTest = ApplicationTestDataFactory.getCases(1, true)[0];
		Id unifiedRoleId = ApplicationTestDataFactoryCase.caseTeamRoleUnifiedAgent;
		Id memberId = UserInfo.getUserId();

		// =====================================
		// Testing
		// =====================================
		CaseTeamMembersSelector selector = CaseTeamMembersSelector.newInstance();
		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(CaseTeamMembersSelector.class, qa);
		selector.selectByCaseIdAndMemberIdAndTeamRoleId(
				new Set<Id>{ caseTest.Id },
				new Set<Id>{ memberId},
				new Set<Id>{ unifiedRoleId }
		);
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\b' + CaseTeamMember.ParentId + ' in :caseIds\\b').matcher(queryString).find(), 'Filters by ParentId in query but Ids does not exist: ' + queryString);
		System.assertEquals(true, Pattern.compile('\\b' + CaseTeamMember.MemberId + ' in :memberId\\b').matcher(queryString).find(), 'Filters by MemberId in query but Ids does not exist: ' + queryString);
		System.assertEquals(true, Pattern.compile('\\b' + CaseTeamMember.TeamRoleId + ' in :teamRoleId\\b').matcher(queryString).find(), 'Filters by TeamRoleId in query but Ids does not exist: ' + queryString);
	}

	 /**
	 * Test: Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseTeamMembersSelector selector = CaseTeamMembersSelector.newInstance(new Set<SObjectField>{CaseTeamMember.ParentId, CaseTeamMember.MemberId, CaseTeamMember.TeamRoleId});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)\\bParentId\\b.*?\\bfrom CaseTeamMember\\b').matcher(soql).find(), 'Resulting query does not select ParentId field: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)\\bMemberId\\b.*?\\bfrom CaseTeamMember\\b').matcher(soql).find(), 'Resulting query does not select MemberId field: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)\\bTeamRoleId\\b.*?\\bfrom CaseTeamMember\\b').matcher(soql).find(), 'Resulting query does not select TeamRoleId field: ' + soql);

		Test.stopTest();
	}
}