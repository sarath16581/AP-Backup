/***
 * @description Domain wrapper class for Person Account
 * @author George Nguyen
 * @date 2021-08-12
 * @group Domain
 * @tag AccountDomain
 * @domain Account
 * @changelog
 * 2022-05-30 - George Nguyen - Created.
 * 2022-09-29 - Noel Lim - Updated - relabelled from PersonAccountDomain to AccountDomain
 */
public with sharing class AccountDomainTriggerHandler extends ApplicationDomainTriggerHandler  {
    
	public static AccountDomainTriggerHandler newInstance() {
		return (AccountDomainTriggerHandler)Application.Utilities.newInstance(AccountDomainTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return Account.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
            AccountDomain.class
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
            Account.SObjectType, 
			User.SObjectType,
			ContactPointPhone.SObjectType,
			ContactPointEmail.SObjectType,
			ContactPointAddress.SObjectType
		};
	}
}