/***
 * @author Paul Perry
 * @date 2023-04-24
 * @group Tests
 * @tag Selector
 * @tag HistoryTracking__mdt SObject
 * @domain Core
 * @description Test Class covering HistoryTrackingSelector
 * @changelog
 */
@IsTest
public with sharing class HistoryTrackingSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		Test.startTest();

		HistoryTrackingSelector selector = HistoryTrackingSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		// make sure there is RecordType.DeveloperName condition
		System.assertEquals(true, Pattern.compile('(?is)\\bFROM HistoryTracking__mdt\\b').matcher(soql).find(), 'Resulting query does not select from HistoryTracking__mdt');

		selector = HistoryTrackingSelector.newInstance();
		qb = selector.newQueryBuilder(new Set<Object>{ 'Membership__c' });
		soql = qb.toSoqlString();
		
		System.assertEquals(true, soql.contains('IsActive__c'), 'Condition hasn\'t been applied');
		System.assertEquals(true, soql.contains('Membership__c'), 'Condition hasn\'t been applied');

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {
		Test.startTest();

		HistoryTrackingSelector selector = HistoryTrackingSelector.newInstance(1);
		Map<Id, HistoryTracking__mdt> results = selector.selectByObjectApiNames(null);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}