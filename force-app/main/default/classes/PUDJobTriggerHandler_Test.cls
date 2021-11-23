/***
 * @description Test class for PUDJobTriggerHandler.
 * @author Ranjeewa Silva
 * @date 2021-08-17
 * @group Tests
 * @domain PUD
 * @changelog
 * 2021-08-17 - Ranjeewa Silva - Created.
 */
@IsTest
private class PUDJobTriggerHandler_Test {

	/**
	 * Bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		PUDJobTriggerHandler handler = new PUDJobTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(PUD_Job__c.SObjectType, handler.getSObjectType(), 'Expected PUD_Job__c sobject type');
		System.assertNotEquals(null, PUDJobTriggerHandler.getUnitOfWorkSObjectTypes(), 'Expected valid list of sobject types to be returned');
	}
}