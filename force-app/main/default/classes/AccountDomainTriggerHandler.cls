/***
 * @description Domain wrapper class for Person Account
 * @author George Nguyen
 * @date 2021-08-12
 * @group Domain
 * @tag AccountDomain
 * @domain Account
 * @Test AccountDomainTriggerHandler_Test
 * @changelog
 * 2022-05-30 - George Nguyen - Created.
 * 2022-09-29 - Noel Lim - Updated - relabelled from PersonAccountDomain to AccountDomain
 * 2022-11-09 - Harry Wang - Updated - included BusinessAccountDomain in registerDomains method
 * 2023-01-19 - Ranjeewa Silva - Added support for additional sobject types in unit of work
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
                AccountDomain.class,
				BusinessAccountDomain.class
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
			ContactPointAddress.SObjectType,
			// support <SObject>__Share types on child objects of Account to handle Apex managed sharing required for
			// sharing child records with members of the sales team based on the sales team type (e.g. Direct, Intermediary, Holding)
			APR__Share.SObjectType,
			Apttus__APTS_Agreement__Share.SObjectType,
			Apttus_Proposal__Proposal__Share.SObjectType,
			APT_SAP_Contracts__Share.SObjectType,
			Deal_Support_Request__Share.SObjectType
		};
	}
}