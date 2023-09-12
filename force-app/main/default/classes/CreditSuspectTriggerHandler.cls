/***
 * @description Domain wrapper class for CreditSuspect object
 * @group Domain
 * @tag CreditSuspectDomain
 * @domain CreditSuspect
 */
public inherited sharing class CreditSuspectTriggerHandler extends ApplicationDomainTriggerHandler {

	public static CreditSuspectTriggerHandler newInstance() {
		return (CreditSuspectTriggerHandler) Application.Utilities.newInstance(CreditSuspectTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return CreditSuspect__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{ 
			CreditSuspectDomain.class 
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
			CreditSuspect__c.SObjectType
		};
	}
}