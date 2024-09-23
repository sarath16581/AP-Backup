/**
* @author Paul Perry
* @date 15/08/2024
* @group Tests
* @tag Selector
* @tag ServicePresenceStatus SObject
* @description
*	A very simple selector class for ServicePresenceStatus
*/
@IsTest
private with sharing class ServicePresenceStatusSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilder() {
		Test.startTest();

		ServicePresenceStatusSelector selector = ServicePresenceStatusSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assert(
			soql.contains('FROM ServicePresenceStatus'),
			'Resulting query does not select from ServicePresenceStatus object'
		);

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is querying the correct output including related fields
	 */
	@IsTest
	private static void testEnsureSelectorOutput() {
		final String systemSource = 'Genesys';
		
		Test.startTest();

		List<ServicePresenceStatus> results = ServicePresenceStatusSelector.newInstance().selectActiveStatuses();

		System.assert(!results.isEmpty(), 'Expected result should contain at least 1 active status');
		Test.stopTest();
	}
}