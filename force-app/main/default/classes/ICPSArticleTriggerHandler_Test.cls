/***
 * @description test class for ICPSArticleTriggerHandler
 * @author Harry Wang
 * @date 2022-07-08
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-07-08 - Harry Wang - Created
 */
@IsTest
private class ICPSArticleTriggerHandler_Test {
	/**
	* Note the simplicity of this class, the bulk of the tests are handled in the Core class
	*/
	@IsTest
	private static void test() {

		ICPSArticleTriggerHandler domain = ICPSArticleTriggerHandler.getInstance();
		ApplicationUnitOfWork appUOW = domain.newUnitOfWork();
		List<Type> types = domain.registerDomains();

		System.assert(appUOW != null, 'ApplicationUnitOfWork initiated');
		System.assertEquals(new List<Type>{ICPSArticleDomain.class}, types, 'Expected ICPSArticleDomain class type returned');
	}
}