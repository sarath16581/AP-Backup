/***
 * @author Hasantha Liyanage
 * @date 2024-02-23
 * @domain Core
 * @description Test class for AdobeSignAgreementTriggerHandler
 * @changelog
 ***/

@IsTest
private class AdobeSignAgreementTriggerHandler_Test {
	@IsTest
	private static void main() {

		AdobeSignAgreementTriggerHandler handler = new AdobeSignAgreementTriggerHandler();
		handler.registerModules();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(echosign_dev1__SIGN_Agreement__c.SObjectType, handler.getSObjectType(), 'Expected echosign_dev1__SIGN_Agreement__c sobject type');

	}
}