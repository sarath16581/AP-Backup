/**
 * @description Opportunity trigger handler to execute all the registered ApplicationModule's
 * @author Boris Bachovski
 * @date 2023-06-21
 * @changelog
 * 2023-08-22 - Ranjeewa Silva - Register new modules OpportunitySalesPipelineModule and OpportunityContributionSplitsModule
 * 2024-05-24 - Ranjeewa Silva - Register module for creating tasks to sales manager and account manager on opportunity assignment.
 */
public inherited sharing class OpportunityAutomationTriggerHandler extends ApplicationTriggerHandler {
    public override SObjectType getSObjectType() {
        return Opportunity.SObjectType;
    }

    public override ApplicationUnitOfWork newUnitOfWork() {
        return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
    }   

    public override void registerModules() {
        // Lead Seeker Module
        registerModule(OpportunityLeadSeekerModule.class);
        // automation to assign contribution splits to specialist sales teams on creation and retain splits on opportunity transfer
        registerModule(OpportunityContributionSplitsModule.class);
        // automation specific to sales pipeline based on stage
        registerModule(OpportunitySalesPipelineModule.class);
        // create tasks related to opportunity and assign to opportunity owner
        registerModule(OpportunityOwnerTasksModule.class);
    }

    /**
     * This defines a list of objects that may be 'touched' during module execution. 
     * It also defines the order in which the work will be committed
     */
    public static List<SObjectType> getUnitOfWorkSObjectTypes() {
        return new List<SObjectType>{
                Opportunity.SObjectType,
                Account.SObjectType,
                OpportunitySplit.SObjectType,
                Task.SObjectType
        };
    }   
}