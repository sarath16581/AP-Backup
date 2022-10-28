/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactDomainTriggerHandler 
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 * 2022-09-29 - Noel Lim - Updated - relabelled from PersonAccountDomain to AccountDomain
 */
@IsTest
public with sharing class AccountDomainTriggerHandler_Test {
    @IsTest
	private static void main() {

		AccountDomainTriggerHandler handler = new AccountDomainTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(Account.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(AccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(Account.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(AccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(User.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(AccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(ContactPointPhone.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(AccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(ContactPointEmail.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(AccountDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(ContactPointAddress.SObjectType), 'Expected valid list of sobject types to be returned');

	}
}