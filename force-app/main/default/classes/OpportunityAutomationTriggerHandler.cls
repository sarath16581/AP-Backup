/**
 * @description Opportunity trigger handler to execute all the registered ApplicationModule's
 * @author Boris Bachovski
 * @date 2023-06-21
 * @changelog
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
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution. 
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				Opportunity.SObjectType
		};
	}	
}