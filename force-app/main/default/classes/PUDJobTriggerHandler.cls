/***
 * @description Domain wrapper class for PUD Job
 * @author Ranjeewa Silva
 * @date 2021-08-12
 * @group Domain
 * @tag PUD_Job__c
 * @domain PUD
 * @changelog
 * 2021-08-12 - Ranjeewa Silva - Created.
 */

public inherited sharing class PUDJobTriggerHandler extends ApplicationDomainTriggerHandler {

	public override SObjectType getSObjectType() {
		return PUD_Job__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
				PUDJobsDomain.class
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
				PUD_Job__c.SObjectType
		};
	}
}