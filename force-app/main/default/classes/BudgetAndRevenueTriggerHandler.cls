/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Ken McGuire
 * @date 2023-30-10
 * @changelog
 */
public inherited sharing class BudgetAndRevenueTriggerHandler extends ApplicationTriggerHandler {
    public override void registerModules() {
        registerModule(BudgetAndRevenueModule.class);
    }
    
    public override SObjectType getSObjectType() {
        return Case.SObjectType;
    }
    
    public override ApplicationUnitOfWork newUnitOfWork() {
        return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
    }
    
    public static List<SObjectType> getUnitOfWorkSObjectTypes() {
        return new List<SObjectType>{
            GroupedAccountProductRevenue__c.SObjectType
        };
    }
}