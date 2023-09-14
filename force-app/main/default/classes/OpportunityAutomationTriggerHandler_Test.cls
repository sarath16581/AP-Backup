/***
 * @description Test class for OpportunityAutomationTriggerHandler
 * @author Boris Bachovski
 * @date 2023-06-21
 * @changelog
 */
@IsTest
private class OpportunityAutomationTriggerHandler_Test {
	
	@IsTest
	private static void testForCoverage() {
		OpportunityAutomationTriggerHandler handler = new OpportunityAutomationTriggerHandler();
		handler.registerModules();
		
		System.assert(Opportunity.SObjectType == handler.getSObjectType());
		System.assert(handler.newUnitOfWork() != null, 'Expected a valid unit of work instance, but got null');
	}
}