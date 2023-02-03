/**
* @description Provides test coverage for APTSAPContractsDomainTriggerHandler
* @author Ken McGuire
* @group Domains
* @domain APT_SAP_Contracts__c
* @changelog
* 2022-12-01 - Ken McGuire - Created
*/
@isTest
private class APTSAPContractsDomainTriggerHandler_Test{
    @IsTest
	private static void testAPTSAPContractsDomainTriggerHandler() {

		APTSAPContractsDomainTriggerHandler handler = APTSAPContractsDomainTriggerHandler.newInstance();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(APT_SAP_Contracts__c.SObjectType, handler.getSObjectType(), 'Expected SAP Contract sobject type');
        List<SObjectType> uowObjectTypes = APTSAPContractsDomainTriggerHandler.getUnitOfWorkSObjectTypes();
		System.assert(uowObjectTypes.contains(APT_SAP_Contracts__c.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(uowObjectTypes.contains(APT_SAP_Contracts__Share.SObjectType), 'Expected valid list of sobject types to be returned');
	}
    
}