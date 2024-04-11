/**
 * @description Opportunity trigger handler to execute all the registered ApplicationModule's
 * @author Boris Bachovski
 * @date 2023-06-21
 * @changelog
 * 2023-08-22 - Ranjeewa Silva - Register new modules OpportunitySalesPipelineModule and OpportunityContributionSplitsModule
 * 2024-01-15	- Ken Mcguire - Register module for generating grouped revenue schedules. 
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
        // create Grouped Revenue Schedules
		registerModule(OpportunityRevenueScheduleModule.class);
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution. 
	 * It also defines the order in which the work will be committed
	 * The GroupedAccountProductRevenue data object must preceed
	 * the GroupedRevenueSchedule data object because the latter has a lookup to the former. 
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				Opportunity.SObjectType,
				OpportunitySplit.SObjectType,
                GroupedAccountProductRevenue__c.SObjectType, 
                GroupedRevenueSchedule__c.SObjectType,
				OpportunityLineItem.SObjectType
		};
	}	
}