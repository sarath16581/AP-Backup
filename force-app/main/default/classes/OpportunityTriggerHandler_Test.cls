/***
 * @description Test class for OpportunityTriggerHandler.
 * @author Ranjeewa Silva
 * @date 2023-05-18
 * @group Tests
 * @domain Core
 * @changelog
 * 2023-05-18 - Ranjeewa Silva - Created.
 */
@IsTest
private class OpportunityTriggerHandler_Test {

	/**
	 * Bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		OpportunityTriggerHandler handler = new OpportunityTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(Opportunity.SObjectType, handler.getSObjectType(), 'Expected Opportunity sobject type');
		System.assertNotEquals(null, OpportunityTriggerHandler.getUnitOfWorkSObjectTypes(), 'Expected valid list of sobject types to be returned');
	}
}