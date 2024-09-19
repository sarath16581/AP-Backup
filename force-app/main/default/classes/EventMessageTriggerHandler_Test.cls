/***
 * @description Test class for EventMessageTriggerHandler
 * @author Ranjeewa Silva
 * @date 2024-08-27
 * @changelog
 */
@IsTest
private class EventMessageTriggerHandler_Test {

	/**
	 * This class does not do much and all the logic sits in modules. We just need a single test for coverage.
	 */
	@IsTest
	private static void testForCoverage() {
		EventMessageTriggerHandler handler = new EventMessageTriggerHandler();
		handler.registerModules();
		Assert.isNotNull(handler.newUnitOfWork(), 'Expected a valid unit of work');
		Assert.areEqual(EventMessage__c.SObjectType, handler.getSObjectType());
	}
}