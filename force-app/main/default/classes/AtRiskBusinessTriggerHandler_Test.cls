/***
 * @description Test for Trigger handler class for At_Rick_Business__c
 * @author Pratyush Chalasani
 * @group TriggerHandler
 * @tag handler
 * @domain AtRiskBusiness
 * @changelog
 * 2023-04-21 - Pratyush Chalasani - Created
 */
@isTest
private with sharing class AtRiskBusinessTriggerHandler_Test {

	@IsTest
	private static void main() {

		AtRiskBusinessTriggerHandler handler = new AtRiskBusinessTriggerHandler();

		handler.registerModules();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(At_Risk_Business__c.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(AdjustmentTriggerHandler.getUnitOfWorkSObjectTypes().contains(Adjustment__c.At_Risk_Business__c), 'Expected valid list of sobject types to be returned');
	}
}