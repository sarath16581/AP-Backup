/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : Test class for Membership Contact Trigger Handler
* @changelog :
*/

@isTest
private class MembershipContactTriggerHandler_Test {

    @IsTest
	private static void main() {

		MembershipContactTriggerHandler handler = new MembershipContactTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertNotEquals(null, handler.registerDomains(), 'Expected valid list of domain types to be returned');
		System.assertEquals(MembershipContact__c.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
    
    }
    
}