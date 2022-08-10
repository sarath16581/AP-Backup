/***
 * @description Test class for PUDContainerTriggerHandler.
 * @author Dattaraj Deshmukh
 * @date 2022-07-25
 * @group Tests
 * @domain PUD
 * @changelog
 * 2022-07-25 - Dattaraj Deshmukh - Created.
 */
@IsTest
private class PUDContainerTriggerHandler_Test {
    
    /**
	 * Bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		PUDContainerTriggerHandler handler = new PUDContainerTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(PUD_Container__c.SObjectType, handler.getSObjectType(), 'Expected PUD_Container__c sobject type');
		System.assertNotEquals(null, PUDContainerTriggerHandler.getUnitOfWorkSObjectTypes(), 'Expected valid list of sobject types to be returned');
	}
}