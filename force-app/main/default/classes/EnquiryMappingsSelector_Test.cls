/***
 * @author Nathan Franklin
 * @date 2020-07-30
 * @group Tests
 * @tag Selector
 * @tag Case
 * @domain Core
 * @description Test Class covering EnquiryMappingsSelector
 * @changelog
 */
@IsTest
private class EnquiryMappingsSelector_Test {

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

		EnquiryMappingsSelector selector = EnquiryMappingsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom MiniCaseFieldMapping__c\\b').matcher(soql).find(), 'Resulting query does not select from MiniCaseFieldMapping__c');

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

		List<MiniCaseFieldMapping__c> mappings = ApplicationTestDataFactory.getEnquiryTypeMappings(false);
		insert mappings;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EnquiryMappingsSelector selector = EnquiryMappingsSelector.newInstance();
		Map<Id, MiniCaseFieldMapping__c> results = selector.selectBySAPKey(new Set<String>{'eParceleParcel Standard'});
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();

	}
}