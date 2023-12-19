/**
 * @author Ranjeewa Silva
 * @description Test Class covering SalesTeamSegmentsSelector
 * @date 2023-12-14
 * @changelog
 * 2023-12-14 - Ranjeewa Silva - Created
 */
@IsTest
private class SalesTeamSegmentsSelector_Test {

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

		SalesTeamSegmentsSelector selector = SalesTeamSegmentsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Sales_Team_Segment__c\\b').matcher(soql).find(), 'Resulting query does not select from Sales_Team_Segment__c: ' + soql);

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

		SalesTeamSegmentsSelector selector = SalesTeamSegmentsSelector.newInstance(0, new Set<SObjectField>{
				Sales_Team_Segment__c.Id, Sales_Team_Segment__c.CreditPersonCode__c
		});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)CreditPersonCode__c.*?\\bfrom Sales_Team_Segment__c\\b').matcher(soql).find(), 'Resulting query does not select CreditPersonCode__c: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)Name.*?\\bfrom Sales_Team_Segment__c\\b').matcher(soql).find(), 'Resulting query selects Name but should not: ' + soql);

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Sales_Team_Segment__c salesTeamSegment = ApplicationTestDataFactorySales.getSalesTeamSegments(1, false)[0];
		insert(salesTeamSegment);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<Sales_Team_Segment__c> results = SalesTeamSegmentsSelector.newInstance(1).selectByName(new Set<String>{salesTeamSegment.Name});
		Assert.areEqual(1, results.size(), 'Expected only one record to be returned, but got : ' + results.size());
		Assert.areEqual(salesTeamSegment.Id, results[0].Id, 'Expected sales team segment not returned.');

		Test.stopTest();
	}
}