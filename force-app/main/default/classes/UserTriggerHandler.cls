/***
 * @description Domain wrapper class for User
 * @author Nathan Franklin
 * @date 2022-08-24
 * @changelog
 * 2022-10-28	Naveen Rajanna	Included ConsumerUserDomain and added Contact to uowSobjectTypes
 */
public inherited sharing class UserTriggerHandler extends ApplicationDomainTriggerHandler {

	public override SObjectType getSObjectType() {
		return User.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
			LBPUserDomain.class,
			ConsumerUserDomain.class
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
			User.SObjectType,
			Contact.SObjectType
		};
	}

}
