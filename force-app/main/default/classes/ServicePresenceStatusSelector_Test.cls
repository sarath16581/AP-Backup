/**
 * @description
 *	A very simple selector class for ServicePresenceStatus
 * @author Paul Perry
 * @date 15/08/2024
 * @changelog
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

		ServicePresenceStatus result = ServicePresenceStatusSelector.newInstance()
			.selectByDeveloperName('Busy', null);

		System.assert(result != null, 'Expected result should contain at least 1 active status');
		Test.stopTest();
	}
}