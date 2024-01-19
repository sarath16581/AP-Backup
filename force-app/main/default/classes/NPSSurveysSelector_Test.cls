/***
 * @author Steve L.
 * @date 2023-11-20
 * @group Tests
 * @tag Selector
 * @tag NPSSurveys SObject
 * @domain Core
 * @description Test Class covering NPSSurveysSelector
 * @changelog
 * 2023-07-15- Steve L - Created
 * 2023-11-20- Steve L - added test for selectByCaseId
 */

@IsTest
private class NPSSurveysSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

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

		NPSSurveysSelector selector = NPSSurveysSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom NPSSurvey__c\\b').matcher(soql).find(), 'Resulting query does not select from Event');

		Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorSpecificMethods() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Case testCase = TestDataProvider.createTestCase();
		insert testCase;

		NPSSurvey__c survey = new NPSSurvey__c();
		survey.Case__c = testCase.Id;
		insert survey;

		Test.startTest();

		NPSSurveysSelector selector = NPSSurveysSelector.newInstance();
		List<NPSSurvey__c> surveys = selector.selectByCaseId(new Set<Id>{testCase.Id});
		System.assertEquals(1, surveys.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}