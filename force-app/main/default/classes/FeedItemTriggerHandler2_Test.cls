/***
 * @description Test class for FeedItemTriggerHandler2.
 * @author Dattaraj Deshmukh
 * @date 2022-12-08
 * @group Tests
 * @domain Generic
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created.
 */
@IsTest
private class FeedItemTriggerHandler2_Test {

	/**
	 * Bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		FeedItemTriggerHandler2 handler = new FeedItemTriggerHandler2();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(FeedItem.SObjectType, handler.getSObjectType(), 'Expected FeedItem sobject type');
		System.assertNotEquals(null, FeedItemTriggerHandler2.getUnitOfWorkSObjectTypes(), 'Expected valid list of sobject types to be returned');
	}
}
