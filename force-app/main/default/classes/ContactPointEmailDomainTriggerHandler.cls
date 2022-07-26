/**
 * @description       : This is a Domain Trigger Handler class for ContactPoint Email
 * @author            : Sreenish Krishnan
 * @domain            : Connected Customer
 * @last modified on  : 07-20-2022
 * @last modified by  : Sreenish Krishnan
 **/
public inherited sharing class ContactPointEmailDomainTriggerHandler extends ApplicationDomainTriggerHandler {
	public override SObjectType getSObjectType() {
		return ContactPointEmail.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{ ContactPointEmailDomain.class };
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ Contact.SObjectType, ContactPointEmail.SObjectType };
	}
}