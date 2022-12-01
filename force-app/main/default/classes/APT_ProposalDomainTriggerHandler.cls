/***
 * @description Domain wrapper class for Proposals
 * @author Ken McGuire
 * @date 2022-12-01
 * @group Domain
 * @tag APT_ProposalDomain
 * @domain Apttus_Proposal__Proposal__c
 * @test APT_ProposalDomainTriggerHandler_Test
 * @changelog
 * 22022-12-01- Ken McGuire - Created.
 */
public with sharing class APT_ProposalDomainTriggerHandler extends ApplicationDomainTriggerHandler  {
    
    public static APT_ProposalDomainTriggerHandler newInstance() {
        return (APT_ProposalDomainTriggerHandler)Application.Utilities.newInstance(APT_ProposalDomainTriggerHandler.class);
    }

    public override SObjectType getSObjectType() {
        return Apttus_Proposal__Proposal__c.SObjectType;
    }

    public override List<Type> registerDomains() {
        return new List<Type>{
            APT_ProposalDomain.class
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
            Apttus_Proposal__Proposal__c.SObjectType, 
            Apttus_Proposal__Proposal__Share.SObjectType
        };
    }
}