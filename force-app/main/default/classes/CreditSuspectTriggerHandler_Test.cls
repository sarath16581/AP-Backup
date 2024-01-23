/**
 * @author Paul Perry
 * @domain Core
 * @description Test class for CreditSuspectTriggerHandler 
 **/
@isTest
public class CreditSuspectTriggerHandler_Test {

	@isTest
	private static void main() {
		CreditSuspectTriggerHandler handler = new CreditSuspectTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(CreditSuspect__c.SObjectType, handler.getSObjectType(), 'Expected the correct sobject type');
		System.assert(CreditSuspectTriggerHandler.getUnitOfWorkSObjectTypes().contains(CreditSuspect__c.SObjectType), 'Expected valid list of sobject types to be returned');
	}    
}