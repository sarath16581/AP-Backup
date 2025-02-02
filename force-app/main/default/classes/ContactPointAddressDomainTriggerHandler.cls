/***
 * @description Domain wrapper class for ContactPointAddress
 * @author George Nguyen
 * @date 2021-08-12
 * @group Domain
 * @tag ContactDomain
 * @domain ContactPoint
 * @Test ContactPointAddressDomainTrgrHdlr_Test
 * @changelog
 * 2022-05-30 - George Nguyen - Created.
 */
public with sharing class ContactPointAddressDomainTriggerHandler extends ApplicationDomainTriggerHandler  {

	public static ContactPointAddressDomainTriggerHandler newInstance() {
		return (ContactPointAddressDomainTriggerHandler)Application.Utilities.newInstance(ContactPointAddressDomainTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return ContactPointAddress.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
            ContactPointAddressDomain.class
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
			Contact.SObjectType,ContactPointAddress.SObjectType
		};
	}
}