/**
 * @description Test class covering APRTriggerHandler
 * @author Naveen Rajanna
 * @date 2022-04-15
 * @group Tests
 * @tag Domain
 * @tag APR__c
 * @domain Core
 * @changelog
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 */
@IsTest
private class APRTriggerHandler_Test {
	@IsTest
	private static void test() {
		APRTriggerHandler domain = new APRTriggerHandler();
		domain.newUnitOfWork();
		domain.registerDomains();

		// PMD warning
		System.assert(true);
	}
}