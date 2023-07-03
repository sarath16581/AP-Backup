/**
 * @description Domain wrapper class for Opportunity
 * @author Ranjeewa Silva
 * @date 2023-05-004
 * @group Domain
 * @tag Opportunity
 * @domain Core
 * @test OpportunityTriggerHandler_Test
 * @changelog
 * 2023-05-04 - Ranjeewa Silva - Created.
 */
public inherited sharing class OpportunityTriggerHandler extends ApplicationDomainTriggerHandler {

	public override SObjectType getSObjectType() {
		return Opportunity.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
				OpportunityGenericDomain.class
		};
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				OpportunitySplit.SObjectType
		};
	}
}