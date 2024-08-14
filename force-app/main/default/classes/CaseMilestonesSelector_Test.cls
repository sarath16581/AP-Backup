/***
 * @author Madhusudhan
 * @date 2021-06-25
 * @group Tests
 * @domain Core
 * @description :Test Class covering CaseMilestonesSelector
 * @changelog
 * 2022-02-22 - Naveen Rajanna - REQ2723199	Added tests for FILTER_VIOLATED selector and selectByIdsWithParentStarTrackCase method
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

		qb = selector.newQueryBuilder(new Set<Object>{CaseMilestonesSelector.Options.FILTER_VIOLATED});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom CaseMilestone\\b.*?IsViolated\\s*?=\\s*?true\\b').matcher(soql).find(), 'Resulting query did not filter IsViolated');
		
		qb = selector.newQueryBuilder(new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_VIOLATED});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom CaseMilestone\\b.*?IsViolated\\s*?=\\s*?false\\b').matcher(soql).find(), 'Resulting query did not filter IsViolated');
		
		qb = selector.newQueryBuilder(new Set<Object>{CaseMilestonesSelector.Options.FILTER_COMPLETED});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom CaseMilestone\\b.*?IsCompleted\\s*?=\\s*?true\\b').matcher(soql).find(), 'Resulting query did not filter IsViolated');
		
		qb = selector.newQueryBuilder(new Set<Object>{CaseMilestonesSelector.Options.FILTER_NOT_COMPLETED});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom CaseMilestone\\b.*?IsCompleted\\s*?=\\s*?false\\b').matcher(soql).find(), 'Resulting query did not filter IsViolated');

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

		List<CaseMilestone> results2 = selector.selectByCaseAndMilestoneNames(new Set<Id>{myCase[0].Id}, new Set<String>{StarTrack_Constants.CASEMILESTONE_CUST_FIRST_RESP}, new Set<Object>{CaseMilestonesSelector.Options.FILTER_VIOLATED});

		Test.stopTest();

		// ensure the query is producing correct result
		// Milestones cannot be inserted in test class due to entitlement process
		System.assertEquals(0, results.size(), 'Expected result size of 0');
		System.assertEquals(0, results2.size(), 'Expected result size of 0');
	}
}