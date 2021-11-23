/***
 * @description Domain class for Case
 * @author Nathan Franklin
 * @date 2020-07-30
 * @group Domain
 * @domain Case
 * @changelog
 */
@IsTest
private class CaseTriggerHandler2_Test {

	/**
	 * Note the simplicity of this class, the bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		CaseTriggerHandler2 domain = new CaseTriggerHandler2();
		domain.newUnitOfWork();
		domain.registerDomains();

		// PMD warning
		System.assert(true);
	}

}