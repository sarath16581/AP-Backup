/***
 * @description Trigger handler class for At_Rick_Business__c
 * @author Pratyush Chalasani
 * @group TriggerHandler
 * @tag handler
 * @domain AtRiskBusiness
 * @changelog
 * 2023-04-21 - Pratyush Chalasani - Created
 */
public class AtRiskBusinessTriggerHandler extends ApplicationTriggerHandler {
	public override SObjectType getSObjectType() {
		return At_Risk_Business__c.SObjectType;
	}

	public override void registerModules() {
		registerModule(AtRiskBusinessModule.class);
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ 
			At_Risk_Business__c.SObjectType
		};
	}
}