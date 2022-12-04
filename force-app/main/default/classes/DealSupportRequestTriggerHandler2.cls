public with sharing class DealSupportRequestTriggerHandler2 extends ApplicationDomainTriggerHandler {
    
	public override SObjectType getSObjectType() {
		return Deal_Support_Request__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
			DealSupportRequestGenericDomain.class
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
            Deal_Support_Request__c.SObjectType,
			Deal_Support_Request__Share.SObjectType,
			DealSupportRequestMilestone__c.SObjectType
		};
	}
}