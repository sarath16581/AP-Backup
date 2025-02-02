/**
* @description Provides test coverage for APTProposalDomainTriggerHandler
* @author Ken McGuire
* @group Domains
* @domain Apttus_Proposal__Proposal__c
* @changelog
* 2022-12-01 - Ken McGuire - Created
*/
@isTest
private class APTProposalDomainTriggerHandler_Test{
    @IsTest
    private static void testAPTProposalDomainTriggerHandler() {

        APTProposalDomainTriggerHandler handler = APTProposalDomainTriggerHandler.newInstance();

        System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
        System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
        System.assertEquals(Apttus_Proposal__Proposal__c.SObjectType, handler.getSObjectType(), 'Expected proposal sobject type');
        List<SObjectType> uowObjectTypes = APTProposalDomainTriggerHandler.getUnitOfWorkSObjectTypes();
        System.assert(uowObjectTypes.contains(Apttus_Proposal__Proposal__c.SObjectType), 'Expected valid list of sobject types to be returned');
        System.assert(uowObjectTypes.contains(Apttus_Proposal__Proposal__Share.SObjectType), 'Expected valid list of sobject types to be returned');
    }
    
}