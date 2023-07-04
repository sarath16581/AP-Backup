/**
 * Date            Version          Owner               Desription
 * 29-Mar-17        1.0             Adrian A            Test class for AdjustmentTriggerHandler
 * 2023-06-30       2.0             Pratyush Chalasani  Refactored into new framework
 */
@isTest
private with sharing class AdjustmentTriggerHandlerTest {

	@IsTest
	private static void main() {

		AdjustmentTriggerHandler handler = new AdjustmentTriggerHandler();

		handler.registerModules();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(Adjustment__c.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(AdjustmentTriggerHandler.getUnitOfWorkSObjectTypes().contains(Adjustment__c.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(AdjustmentTriggerHandler.getUnitOfWorkSObjectTypes().contains(Disputed_Item__c.SObjectType), 'Expected valid list of sobject types to be returned');
		System.assert(AdjustmentTriggerHandler.getUnitOfWorkSObjectTypes().contains(Credit_Approval__c.SObjectType), 'Expected valid list of sobject types to be returned');
	}
}