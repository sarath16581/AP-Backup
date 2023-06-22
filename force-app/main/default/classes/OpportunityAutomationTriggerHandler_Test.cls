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
		ApplicationUnitOfWork uow = handler.newUnitOfWork();

		handler.registerModules();

		System.Assert(Opportunity.SObjectType == handler.getSObjectType());
	}
}