/***
 * @author Harry Wang
 * @date 2022-06-30
 * @description trigger handler class for ICPS Article
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-06-30 - Harry Wang - Created
 */

public inherited sharing class ICPSArticleTriggerHandler extends ApplicationDomainTriggerHandler {

	public override SObjectType getSObjectType() {
		return ICPSArticle__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
				ICPSArticleDomain.class
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
				ICPSArticle__c.SObjectType,
				ICPS__c.SObjectType
		};
	}
}