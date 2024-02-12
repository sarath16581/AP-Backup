/***
 * @author Ken McGuire
 * @description Test class for BudgetAndRevenueTriggerHandler
 * @changelog
 * 2/11/2023 created
 */
@IsTest
private class BudgetAndRevenueTriggerHandler_Test{
	@IsTest
	private static void main() {
		BudgetAndRevenueTriggerHandler handler = new BudgetAndRevenueTriggerHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(Case.SObjectType, handler.getSObjectType(), 'Expected Contact sobject type');
		System.assert(BudgetAndRevenueTriggerHandler.getUnitOfWorkSObjectTypes().contains(GroupedAccountProductRevenue__c.SObjectType), 'Expected valid list of sobject types to be returned');
	}
}