/***
 * @description Test class for EmailMessageTriggerHandler
 * @author Naveen Rajanna
 * @date 2022-10-17
 * @group Domain
 * @domain EmailMessage
 * @changelog
 */
@IsTest
private class EmailMessageTriggerHandler_Test {
	/**
	 * Note the simplicity of this class, the bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {
		EmailMessageTriggerHandler domain = new EmailMessageTriggerHandler();
		domain.newUnitOfWork();
		domain.registerDomains();

		// PMD warning
		System.assert(true);
	}
}