/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactDomainTriggerHandler 
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class PersonAccountDomainTriggerHandler_Test {
    @IsTest
	private static void main() {

		PersonAccountDomainTriggerHandler handler = new PersonAccountDomainTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(Account.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(PersonAccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(Account.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(PersonAccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(User.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(PersonAccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(ContactPointPhone.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(PersonAccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(ContactPointEmail.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(PersonAccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(ContactPointAddress.SObjectType), 'Expected valid list of sobject types to be returned');

	}
}

