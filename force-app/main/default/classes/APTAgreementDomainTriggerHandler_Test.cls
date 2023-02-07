/**
* @description Provides test coverage for APTProposalDomainTriggerHandler
* @author Ken McGuire
* @group Domains
* @domain Apttus__APTS_Agreement__c
* @changelog
* 2022-12-05 - Ken McGuire - Created
*/
@isTest
private class APTAgreementDomainTriggerHandler_Test{
    @IsTest
    private static void testAPTAgreementDomainTriggerHandler() {

        APTAgreementDomainTriggerHandler handler = APTAgreementDomainTriggerHandler.newInstance();

        System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
        System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
        System.assertEquals(Apttus__APTS_Agreement__c.SObjectType, handler.getSObjectType(), 'Expected agreement sobject type');
        List<SObjectType> uowObjectTypes = APTAgreementDomainTriggerHandler.getUnitOfWorkSObjectTypes();
        System.assert(uowObjectTypes.contains(Apttus__APTS_Agreement__c.SObjectType), 'Expected valid list of sobject types to be returned');
        System.assert(uowObjectTypes.contains(Apttus__APTS_Agreement__Share.SObjectType), 'Expected valid list of sobject types to be returned');
    }
    
}