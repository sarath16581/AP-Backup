/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactPointAddressDomainTriggerHandler 
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class ContactPointAddressDomainTrgrHdlr_Test {

	/*
    * this test will check and make sure that the properties return the correct SObject type and the UoW contains the correct SObject type to handle. 
    */
    @IsTest
	private static void main() {

		ContactPointAddressDomainTriggerHandler handler = new ContactPointAddressDomainTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(ContactPointAddress.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(ContactPointAddressDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(Contact.SObjectType), 'Expected valid sobject types to be returned');
		System.assert(ContactPointAddressDomainTriggerHandler.getUnitOfWorkSObjectTypes().contains(ContactPointAddress.SObjectType), 'Expected valid sobject types to be returned');
	}
}
