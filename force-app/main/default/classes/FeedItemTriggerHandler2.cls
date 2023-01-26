/***
 * @description Domain wrapper class for FeedItem
 * @author Dattaraj Deshmukh
 * @date 23/11/2022
 * @group Domain
 * @tag FeedItem
 * @domain Generic
 * @changelog
 * 23/11/2022 - Dattaraj Deshmukh - Created.
 */
public inherited sharing class FeedItemTriggerHandler2 extends ApplicationDomainTriggerHandler {
	
	public override SObjectType getSObjectType() {
		return FeedItem.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
			FeedItemCaseInvestigationDomain.class
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
			FeedItem.SObjectType,
			CaseInvestigation__c.SObjectType
		};
	}
}