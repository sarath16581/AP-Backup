/***
 * @author Madhusudhan
 * @date 2021-06-25
 * @group Tests
 * @domain Core
 * @description :Test Class covering CaseMilestonesSelector
 * @changelog
 */
@IsTest
private class CaseMilestonesSelector_Test {
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

		CaseMilestonesSelector selector = CaseMilestonesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(
			true,
			Pattern.compile('(?ism)\\bfrom CaseMilestone\\b').matcher(soql).find(),
			'Resulting query does not select from CaseMilestone: ' + soql
		);

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorIntegration() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Case> myCase = ApplicationTestDataFactory.getCases(1, false);
		myCase[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackDeliveryEnquiryRecordType;

		insert myCase;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseMilestonesSelector selector = CaseMilestonesSelector.newInstance();
		Map<Id, CaseMilestone> results = selector.selectByCase(new Set<Id>{ myCase[0].Id });

		Test.stopTest();

		// ensure the query is producing correct result
		// Milestones cannot be inserted in test class due to entitlement process
		System.assertEquals(0, results.size(), 'Expected result size of 0');
	}
}