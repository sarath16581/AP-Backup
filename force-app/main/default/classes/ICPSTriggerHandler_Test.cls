/***
 * @description test class for ICPSTriggerHandler
 * @author Harry Wang
 * @date 2022-06-21
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-06-21 - Harry Wang - Created
 */
@IsTest
private class ICPSTriggerHandler_Test {
	/**
	* Note the simplicity of this class, the bulk of the tests are handled in the Core class
	*/
	@IsTest
	private static void test() {

		ICPSTriggerHandler domain = new ICPSTriggerHandler();
		ApplicationUnitOfWork appUOW = domain.newUnitOfWork();
		List<Type> types = domain.registerDomains();

		System.assert(appUOW != null, 'ApplicationUnitOfWork initiated');
		System.assertEquals(new List<Type>{ICPSDomain.class}, types, 'Expected ICPSDomain class type returned');
	}
}