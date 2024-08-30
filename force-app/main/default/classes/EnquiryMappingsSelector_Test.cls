/***
 * @author Nathan Franklin
 * @date 2020-07-30
 * @group Tests
 * @tag Selector
 * @tag Case
 * @domain Core
 * @description Test Class covering EnquiryMappingsSelector
 * @changelog
 * 2024.06.17 Raghav Ravipati Added test method to test selectBySAPKeyAndMappingModel method
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

		List<MiniCaseFieldMapping__c> mappings = ApplicationTestDataFactoryCase.getEnquiryTypeMappings(false);
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

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectBySAPKeyAndMappingModel() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<MiniCaseFieldMapping__c> mappings = ApplicationTestDataFactoryCase.getEnquiryTypeMappings(false);
		mappings[0].MappingModel__c = 'Classic';
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
		List<MiniCaseFieldMapping__c> results = selector.selectBySAPKeyAndMappingModel(new Set<String>{'eParceleParcel Standard', 'StarTrackST Next Flight', 'Express PostExpress Post Medium'}, new Set<String>{ 'Classic' });
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();

	}
}