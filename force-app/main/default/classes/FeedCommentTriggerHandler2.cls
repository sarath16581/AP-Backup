/***
 * @description Trigger handler for FeedComment using the domain based approach
 * @author Mahesh Parvathaneni
 * @date 04/04/2023
 * @changelog
 */
public inherited sharing class FeedCommentTriggerHandler2 extends ApplicationDomainTriggerHandler {
	public static FeedCommentTriggerHandler2 newInstance() {
		return (FeedCommentTriggerHandler2) Application.Utilities.newInstance(FeedCommentTriggerHandler2.class);
	}

	public override SObjectType getSObjectType() {
		return FeedComment.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
			FeedCommentCaseInvestigationDomain.class
		};
	}

	/**
	* Unit of work that encapsulates all the required objects for each domain within this SObject
	* @return unit or work instance
	*/
	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			FeedComment.SObjectType,
			CaseInvestigation__c.SObjectType
		};
	}
}