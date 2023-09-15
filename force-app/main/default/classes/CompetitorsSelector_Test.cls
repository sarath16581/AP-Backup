/**
 * @description
 * Test class for CompetitorsSelector
 * @author Ranjeewa Silva
 * @group Tests
 * @changelog
 * 2023-08-08 - Ranjeewa Silva - Created
 */
@IsTest
private class CompetitorsSelector_Test {

	/**
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
		CompetitorsSelector selector = CompetitorsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Competitor__c\\b').matcher(soql).find(), 'Resulting query does not select from Competitor__c');

		//Test for field override
		selector = (CompetitorsSelector)CompetitorsSelector.newInstance(0).setFieldOverrides(new Set<SObjectField>{Competitor__c.Competitive_Advantage__c, Competitor__c.Id});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assert(Pattern.compile('(?ism)Competitive_Advantage__c.*?\\bfrom Competitor__c\\b').matcher(soql).find(), 'Resulting query does not select Competitive_Advantage__c field: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\AccountId__c\\b.*?\\bfrom Competitor__c\\b').matcher(soql).find(), 'Resulting selects AccountId__c but it shouldn\'t: ' + soql);

		Test.stopTest();
	}
}