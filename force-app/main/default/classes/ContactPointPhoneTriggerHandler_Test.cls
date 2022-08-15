/***
 * @author George Nguyen
 * @date 2022-05-25
 * @domain Core
 * @description Test class for ContactPointPhoneTriggerHandler 
 * @changelog
 * 2022-05-25 - George Nguyen - Created
 */
@IsTest
public with sharing class ContactPointPhoneTriggerHandler_Test {
    @IsTest
	private static void main() {

		ContactPointPhoneTriggerHandler handler = new ContactPointPhoneTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(ContactPointPhone.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assertNotEquals(null, ContactPointPhoneTriggerHandler.getUnitOfWorkSObjectTypes(), 'Expected valid list of sobject types to be returned');
	}
}
