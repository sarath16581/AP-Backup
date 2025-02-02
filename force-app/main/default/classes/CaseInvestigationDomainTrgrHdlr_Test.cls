/**
 * @description       : This is a test class for the CaseInvestigationDomainTriggerHandler
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2023-01-25 - Dattaraj Deshmukh - Added assert to check Case.SObjecType is returned. 
 **/
@IsTest
public with sharing class CaseInvestigationDomainTrgrHdlr_Test {
	@isTest
    private static void main() {

		CaseInvestigationDomainTriggerHandler handler = CaseInvestigationDomainTriggerHandler.newInstance();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(CaseInvestigation__c.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(CaseInvestigationDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(CaseInvestigation__c.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(CaseInvestigationDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(Case.SObjectType), 'Expected valid list of sobject types to be returned');
	}
}