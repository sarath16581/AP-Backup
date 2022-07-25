/***
 * @description Domain wrapper class for Contact
 * @author George Nguyen
 * @date 2021-08-12
 * @group Domain
 * @tag ContactDomain
 * @domain Contact
 * @changelog
 * 2022-05-30 - George Nguyen - Created.
 */
public with sharing class ContactDomainTriggerHandler extends ApplicationDomainTriggerHandler  {
    
	public override SObjectType getSObjectType() {
		return Contact.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
            ContactDomain.class
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
            Contact.SObjectType
		};
	}
}