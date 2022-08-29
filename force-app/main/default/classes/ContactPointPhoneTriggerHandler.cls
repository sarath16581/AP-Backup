/***
 * @description Domain wrapper class for ContactPointPhone
 * @author George Nguyen
 * @date 2021-08-12
 * @group Domain
 * @tag ContactDomain
 * @domain ContactPoint
 * @Test ContactPointPhoneDomainTrgrHdlr_Test
 * @changelog
 * 2022-05-30 - George Nguyen - Created.
 */
public inherited sharing class ContactPointPhoneTriggerHandler extends ApplicationDomainTriggerHandler {
	public static ContactPointPhoneTriggerHandler newInstance() {
		return (ContactPointPhoneTriggerHandler) Application.Utilities.newInstance(ContactPointPhoneTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return ContactPointPhone.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{ ContactPointPhoneDomain.class };
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
		return new List<SObjectType>{ Contact.SObjectType, ContactPointPhone.SObjectType };
	}
}