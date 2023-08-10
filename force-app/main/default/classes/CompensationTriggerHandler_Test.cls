/***
 * @author Hasantha Liyanage
 * @date 2023-07-25
 * @domain Core
 * @description Test class for CompensationTriggerHandler
 * @changelog
 * 2023-07-25 - Hasantha Liyanage - Created
 */
@IsTest
private class CompensationTriggerHandler_Test {
    @IsTest
    private static void main() {

        CompensationTriggerHandler handler = new CompensationTriggerHandler();
        handler.registerModules();

        System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
        System.assertEquals(Compensation__c.SObjectType, handler.getSObjectType(), 'Expected Compensation__c sobject type');
        System.assert(CompensationTriggerHandler.getUnitOfWorkSObjectTypes().contains(Case.SObjectType), 'Expected valid list of sobject types to be returned');
        System.assert(CompensationTriggerHandler.getUnitOfWorkSObjectTypes().contains(Article__c.SObjectType), 'Expected valid list of sobject types to be returned');
        System.assert(CompensationTriggerHandler.getUnitOfWorkSObjectTypes().contains(Compensation__c.SObjectType), 'Expected valid list of sobject types to be returned');

    }
}