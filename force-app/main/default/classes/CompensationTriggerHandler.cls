/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Hasantha Liyanage
 * @date 2023-07-10
 * @changelog
 */

public with sharing class CompensationTriggerHandler extends ApplicationTriggerHandler {

    public override void registerModules() {
        registerModule(CompensationUtilityModule.class);
    }

    public override ApplicationUnitOfWork newUnitOfWork() {
        return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
    }

    public override SObjectType getSObjectType() {
        return Compensation__c.SObjectType;
    }

    public static List<SObjectType> getUnitOfWorkSObjectTypes() {
        return new List<SObjectType>{
                Case.SObjectType,
                Article__c.SObjectType,
                Compensation__c.SObjectType
        };
    }
}