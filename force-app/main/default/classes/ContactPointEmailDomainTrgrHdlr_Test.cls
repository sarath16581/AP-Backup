/**
 * @description       : This is a test class for the ContactPointEmailDomainTiggerHandler
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-22-2022
 * @last modified by  : Sreenish Krishnan
**/
@IsTest
public with sharing class ContactPointEmailDomainTrgrHdlr_Test {
	@isTest
    private static void main() {

		ContactPointEmailDomainTriggerHandler handler = new ContactPointEmailDomainTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(ContactPointEmail.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(ContactPointEmailDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(Contact.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(ContactPointEmailDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(ContactPointEmail.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(ContactPointEmailDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(User.SObjectType), 'Expected valid list of sobject types to be returned');
	}
}
