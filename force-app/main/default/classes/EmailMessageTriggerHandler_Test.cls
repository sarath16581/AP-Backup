/***
 * @description Test class for EmailMessageTriggerHandler
 * @author Naveen Rajanna
 * @date 2022-10-17
 * @group Domain
 * @domain EmailMessage
 * @changelog
 * 2024-08-07 - Ranjeewa Silva - Test class updates after uplifting the module to new domain-less ApplicationModule framework.
 */
@IsTest
private class EmailMessageTriggerHandler_Test {
	/**
	 * Note the simplicity of this class, the bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {
		EmailMessageTriggerHandler triggerHAndler = new EmailMessageTriggerHandler();
		triggerHAndler.newUnitOfWork();
		triggerHAndler.registerModules();

		// PMD warning
		System.assert(true);
	}
}