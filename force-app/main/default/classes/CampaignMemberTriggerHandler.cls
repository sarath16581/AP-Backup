/***
 * @description Domain wrapper class for Case
 * @author Mathew Jose
 * @date 2021-12-15
 * @group Domain
 * @domain CampaignMember
 * @changelog
 */
public with sharing class CampaignMemberTriggerHandler extends ApplicationDomainTriggerHandler {

    public override SObjectType getSObjectType() {
		return CampaignMember.SObjectType;
	}
	
	public override List<Type> registerDomains() {
		return new List<Type>{
            CampaignMembersDomain.class
		};
	}
	
	/**
	 * Unit of work that encapsulates all the required objects for each domain within this SObject
	 */
	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}
	
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
                CampaignMember.SObjectType,
                CampaignContactAssignment__c.SObjectType,
				Task.SObjectType			
		};
	}
}