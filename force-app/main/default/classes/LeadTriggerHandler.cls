/***
 * @description Domain wrapper class for BG Standard Leads
 * @author Pratyush Chalasani  
 * @date 2023-03-27
 * @group Domain
 * @tag BGStandardLeadDomain
 * @domain Lead
 * @Test LeadTriggerHandler_Test
 * @changelog
 * 2023-03-27 - Pratyush Chalasani - (SF-621) Created
 */
public inherited sharing class LeadTriggerHandler extends ApplicationDomainTriggerHandler  {
	public static LeadTriggerHandler newInstance() {
		return (LeadTriggerHandler)Application.Utilities.newInstance(LeadTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return Lead.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
			BGStandardLeadDomain.class
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
			Lead.SObjectType
		};
	}
}