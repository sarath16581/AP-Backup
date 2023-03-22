/**
 * @description Test Class covering ThirdPartyAccountLinksSelector
 * @author Nathan Franklin
 * @date 2023-03-21
 * @changelog
 */
@IsTest
private class PermissionSetAssignmentsSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {

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

		PermissionSetAssignmentsSelector selector = PermissionSetAssignmentsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom PermissionSetAssignment\\b').matcher(soql).find(), 'Resulting query does not select from PermissionSetAssignment: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		PermissionSetAssignmentsSelector selector = PermissionSetAssignmentsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PermissionSetAssignmentsSelector.Options.WITH_USER});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Assignee\\..*?\\bfrom PermissionSetAssignment\\b').matcher(soql).find(), 'Resulting query does not select User fields: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
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

		PermissionSetAssignmentsSelector selector = PermissionSetAssignmentsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				PermissionSetAssignment.SObjectType => new Set<SObjectField>{PermissionSetAssignment.PermissionSetId},
				User.SObjectType => new Set<SObjectField>{User.Username}
		});
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PermissionSetAssignmentsSelector.Options.WITH_USER});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Assignee\\..*?\\bfrom PermissionSetAssignment\\b').matcher(soql).find(), 'Resulting query does not select User fields: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Assignee\\.Username.*?\\bfrom PermissionSetAssignment\\b').matcher(soql).find(), 'Resulting query does not select User.Username: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Assignee\\.Email.*?\\bfrom PermissionSetAssignment\\b').matcher(soql).find(), 'Resulting query selects User.Email but should not: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)PermissionSetId.*?\\bfrom PermissionSetAssignment\\b').matcher(soql).find(), 'Resulting query does not select PermissionSetId: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)IsActive.*?\\bfrom PermissionSetAssignment\\b').matcher(soql).find(), 'Resulting query selects IsActive but should not: ' + soql);

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure that the query actually runs. There will be no data returned, however this ensure that the query does not error
	 */
	@IsTest
	private static void testSelectorSearchAllIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		List<PermissionSetAssignment> assignments = [SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment ORDER BY SystemModstamp DESC LIMIT 2];
		Set<Id> assignmentIds = new Map<Id, PermissionSetAssignment>(assignments).keySet();
		
		Set<Id> assigneeIds = new Set<Id>();
		for(PermissionSetAssignment assignment : assignments) {
			assigneeIds.add(assignment.AssigneeId);
		}

		Set<Id> permissionSetIds = new Set<Id>();
		Set<String> permissionSetNames = new Set<String>();
		for(PermissionSetAssignment assignment : assignments) {
			permissionSetIds.add(assignment.PermissionSetId);
			permissionSetNames.add(assignment.PermissionSet.Name);
		}

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		PermissionSetAssignmentsSelector selector = PermissionSetAssignmentsSelector.newInstance();
		List<PermissionSetAssignment> results = selector.selectById(assignmentIds);
		System.assertEquals(assignmentIds.size(), results.size());

		selector = PermissionSetAssignmentsSelector.newInstance();
		results = selector.selectByAssignee(assigneeIds);
		Set<Id> foundAssignees = new Set<Id>();
		for(PermissionSetAssignment assignment : results) {
			foundAssignees.add(assignment.AssigneeId);
		}
		System.assertEquals(assigneeIds.size(), foundAssignees.size());

		selector = PermissionSetAssignmentsSelector.newInstance(1);
		results = selector.selectByPermissionSet(permissionSetIds);
		System.assertEquals(1, results.size());

		Map<String, Object> params = new Map<String, Object>{
			'assigneeIds' => assigneeIds,
			'permissionSetIds' => permissionSetIds,
			'permissionSetNames' => permissionSetNames
		};
		selector = PermissionSetAssignmentsSelector.newInstance();
		results = selector.search(params, true);
		System.assertNotEquals(0, results.size());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureSearchMethodProducesCorrectString() {

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

		Map<String, Object> searchParams;

		PermissionSetAssignmentsSelector selector = PermissionSetAssignmentsSelector.newInstance(1);

		searchParams = new Map<String, Object>{
			'assigneeIds' => '005000000000000000',
			'permissionSetIds' => '0PS000000000000000',
			'permissionSetNames' => 'NathansPermissionSet1'
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bAssigneeId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit AssigneeId: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bPermissionSetId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit PermissionSetId: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bPermissionSet\\.Name\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit PermissionSet.Name: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'assigneeIds' => new Set<Id>{'005000000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bAssigneeId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit AssigneeId: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bPermissionSetId\\s+In\\b').matcher(soql).find(), 'Resulting query limits PermissionSetId... it should not: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bPermissionSet\\.Name\\s+In\\b').matcher(soql).find(), 'Resulting query limits PermissionSet.Name... it should not: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'permissionSetIds' => new Set<Id>{'0PS000000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bAssigneeId\\s+In\\b').matcher(soql).find(), 'Resulting query limits AssigneeId... it should not: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bPermissionSetId\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit PermissionSetId: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bPermissionSet\\.Name\\s+In\\b').matcher(soql).find(), 'Resulting query limits PermissionSet.Name... it should not: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'permissionSetNames' => new Set<String>{'NathansPermissionSet1'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bAssigneeId\\s+In\\b').matcher(soql).find(), 'Resulting query limits AssigneeId... it should not: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bPermissionSetId\\s+In\\b').matcher(soql).find(), 'Resulting query limits PermissionSetId... it should not: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bPermissionSet\\.Name\\s+In\\b').matcher(soql).find(), 'Resulting query does not limit PermissionSet.Name: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, true);

		searchParams = new Map<String, Object>{
			'assigneeIds' => '005000000000000000',
			'permissionSetIds' => '0PS000000000000000',
			'permissionSetNames' => 'NathansPermissionSet1'
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from PermissionSetAssignment\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not limit by ANY: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, false);

		Test.stopTest();

	}
}