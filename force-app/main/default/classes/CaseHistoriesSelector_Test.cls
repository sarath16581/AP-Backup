/**
* @author SteveL
* @date 2024-09-10
* @group Tests
* @tag Selector
* @description A very simple selector test class 
* @changelog
* 2024-09-10 - SteveL - Created
* */

@IsTest
private class CaseHistoriesSelector_Test {
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

		CaseHistoriesSelector selector = CaseHistoriesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom CaseHistory\\b').matcher(soql).find(), 'Resulting query does not select from CaseHistory');

		CaseHistoriesSelector selector1 = CaseHistoriesSelector.newInstance(1);
		QueryBuilder qb1 = selector1.newQueryBuilder();
		String soql1 = qb1.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');

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

		CaseHistoriesSelector selector = CaseHistoriesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{CaseHistoriesSelector.Options.WITH_CASE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Case\\..*?\\bfrom CaseHistory\\b').matcher(soql).find(), 'Resulting query does not select Case fields');

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
		MockUtility.disableTriggerExecution();

		List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', false);
		cases.get(0).Type = GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_GENERAL_ENQUIRY;
		insert cases;

		cases.get(0).Type = GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_INVESTIGATION;
		update cases;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseHistoriesSelector selector = CaseHistoriesSelector.newInstance(2);
		Map<Id, CaseHistory> results = selector.selectCaseHistoriesByTypeAndCaseIds(new Set<Object>(), new Set<Id>{cases.get(0).Id}, GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_INVESTIGATION);
		System.assertEquals(0, results.size(), 'No History record can be created in test context, expecting result size of 0');

		Test.stopTest();

	}
}