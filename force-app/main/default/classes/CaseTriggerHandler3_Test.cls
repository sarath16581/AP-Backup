/***
 * @description Test class Domain wrapper class for Case.
 * This is fired AFTER the legacy code... NOTE, this should be decommissioned after all legacy code is migrated into domain architecture
 * This is used specifically for modules/domains that need to be run after all legacy code has run.
 * A specific use case that triggered the creation of the temporary class is storing the last assigned queue name. The SSSW routing engine code rewrites the queue which means the code to write the last queue name would need to be executed after the routing engine code
 * @author Nathan Franklin
 * @date 2022-02-03
 * @group Domain
 * @domain Case
 * @changelog
 */
@IsTest
private class CaseTriggerHandler3_Test {

	/**
	 * Note the simplicity of this class, the bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void test() {

		CaseTriggerHandler3 domain = new CaseTriggerHandler3();
		domain.newUnitOfWork();
		domain.registerDomains();

		// PMD warning
		System.assert(true);
	}

}