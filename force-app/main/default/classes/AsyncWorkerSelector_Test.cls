/**
 * @description
 * Test class covering AsyncWorkerSelector
 *
 * @author Nathan Franklin
 * @date 2020-09-01
 * @group Tests
 * @changelog
 */
@IsTest
public with sharing class AsyncWorkerSelector_Test {
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

		AsyncWorkerSelector selector = AsyncWorkerSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(
			true,
			Pattern.compile('(?ism)\\bfrom asyncworker__c\\b').matcher(soql).find(),
			'Resulting query does not select from AsyncWorker__c'
		);

		selector = AsyncWorkerSelector.newInstance(0, new Set<SObjectField>{ AsyncWorker__c.ClassType__c, AsyncWorker__c.Id });
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?ism)ClassType__c.*?\\bfrom AsyncWorker__c\\b').matcher(soql).find(),
			'Resulting query does not select ClassType__c field: ' + soql
		);

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

		List<AsyncWorker__c> workers = new List<AsyncWorker__c>{ new AsyncWorker__c(Processing__c = false) };
		insert workers;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AsyncWorkerSelector selector = AsyncWorkerSelector.newInstance();
		List<AsyncWorker__c> results = selector.selectById(new Set<Id>{ workers[0].Id });
		System.assertEquals(1, results.size(), 'Result count was wrong');

		Test.stopTest();
	}
}
