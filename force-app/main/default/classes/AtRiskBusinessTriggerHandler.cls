/***
 * @description Trigger handler class for At_Rick_Business__c
 * @author Pratyush Chalasani
 * @group TriggerHandler
 * @tag handler
 * @domain AtRiskBusiness
 * @changelog
 * 2023-04-21 - Pratyush Chalasani - Created
 */
public class AtRiskBusinessTriggerHandler extends ApplicationDomainTriggerHandler {

	public static AtRiskBusinessTriggerHandler newInstance() {
		return (AtRiskBusinessTriggerHandler) Application.Utilities.newInstance(AtRiskBusinessTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return At_Risk_Business__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{ 
			AtRiskBusinessDomain.class 
		};
	}

	/**
	 * Unit of work that encapsulates all the required objects for each domain within this SObject
	 *
	 * @return unit or work instance
	 */
	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ 
			At_Risk_Business__c.SObjectType
		};
	}
}