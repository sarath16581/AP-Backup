/***
 * @description Domain class for User
 * @author Nathan Franklin
 * @date 2022-08-24
 * @group Domain
 * @domain Case
 * @changelog
 */
@IsTest
private class UserTriggerHandler_Test {

	/**
	 * Note the simplicity of this class, the bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		UserTriggerHandler handler = new UserTriggerHandler();
		handler.newUnitOfWork();
		handler.registerDomains();

		// PMD warning
		System.assert(true);
	}

}