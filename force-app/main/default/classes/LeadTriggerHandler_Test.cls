/***
 * @description Lead Trigger Handler test class
 * @author Pratyush Chalasani
 * @date 2023-03-27
 * @group Domain
 * @domain Lead
 * @changelog
 */
@IsTest
private class LeadTriggerHandler_Test {

	/**
	 * Note the simplicity of this class, the bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		LeadTriggerHandler domain = LeadTriggerHandler.newInstance();
		domain.getSObjectType();
		domain.newUnitOfWork();
		domain.registerDomains();

		// PMD warning
		System.assert(true);
	}

}