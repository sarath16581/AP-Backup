/***
 * @description Domain wrapper class for Case
 * @author Ashapriya Gadi
 * @date 2021-12-15
 * @group Domain
 * @domain CampaignContactAssignment__c
 * @changelog
 */

public inherited sharing class CampaignContactAssignmentTriggerHandler extends ApplicationDomainTriggerHandler {
	
	public override SObjectType getSObjectType() {
		return CampaignContactAssignment__c.SObjectType;
	}
	
	public override List<Type> registerDomains() {
		return new List<Type>{
				CampaignContactAssignmentsDomain.class
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
				CampaignContactAssignment__c.SObjectType,
				Account.SObjectType,
				Task.SObjectType,
				Campaign.SObjectType,
                CampaignMember.SObjectType			
		};
	}
}