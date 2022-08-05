/***
 * @author Harry Wang
 * @date 2022-06-21
 * @description trigger handler class for ICPS
 * @group Domain
 * @domain ICPS
 * @changelog
 * 2022-06-21 - Harry Wang - Created
 */

public inherited sharing class ICPSTriggerHandler extends ApplicationDomainTriggerHandler {

	public static ICPSTriggerHandler getInstance() {
		return (ICPSTriggerHandler)Application.Utilities.getInstance(ICPSTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return ICPS__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
				ICPSDomain.class
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
				ICPS__c.SObjectType
		};
	}
}