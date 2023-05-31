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
		QueryBuilder qb = selector.newQueryBuilder(new List<String>());
		String soql = qb.toSoqlString();

		// make sure there is RecordType.DeveloperName condition
		System.assertEquals(true, Pattern.compile('(?is)\\bFROM HistoryTracking__mdt\\b').matcher(soql).find(), 'Resulting query does not select from HistoryTracking__mdt');

		selector = HistoryTrackingSelector.newInstance();
		qb = selector.newQueryBuilder(new List<String>{ 'Membership__c' });
		soql = qb.toSoqlString();
		System.debug(soql);
		System.assert(soql.indexOf('IsActive__c = true') > 0, 'Condition hasn\'t been applied');
		System.assert(soql.indexOf('ObjectName__c IN') > 0, 'Condition hasn\'t been applied');

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {
		Test.startTest();

		HistoryTrackingSelector selector = HistoryTrackingSelector.newInstance(1);
		Map<Id, HistoryTracking__mdt> results = selector.selectByObjectApiNames(new List<String>());
		System.assert(
            results != null && results.size() <= 1,
            'Expected results array with size <= 1'
       	);

		Test.stopTest();
	}
}