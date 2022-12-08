/***
 * @description Domain wrapper class for SAP Contracts
 * @author Ken McGuire
 * @date 2022-11-10
 * @group Domain
 * @tag APTSAPContractsDomain
 * @domain APT_SAP_Contracts__c
 * @test APTSAPContractsDomainTriggerHandler_Test
 * @changelog
 * 22022-11-10- Ken McGuire - Created.
 */
public with sharing class APTSAPContractsDomainTriggerHandler extends ApplicationDomainTriggerHandler  {
    
	public static APTSAPContractsDomainTriggerHandler newInstance() {
		return (APTSAPContractsDomainTriggerHandler)Application.Utilities.newInstance(APTSAPContractsDomainTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return APT_SAP_Contracts__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
            APTSAPContractsDomain.class
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
            APT_SAP_Contracts__c.SObjectType, 
			APT_SAP_Contracts__Share.SObjectType
		};
	}
}