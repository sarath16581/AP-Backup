/***
 * @description Domain wrapper class for Proposals
 * @author Ken McGuire
 * @date 2022-12-01
 * @group Domain
 * @tag APT_ProposalDomain
 * @domain Apttus_Proposal__Proposal__c
 * @test APTProposalDomainTriggerHandler_Test
 * @changelog
 * 22022-12-01- Ken McGuire - Created.
 */
public with sharing class APTProposalDomainTriggerHandler extends ApplicationDomainTriggerHandler  {
    
    public static APTProposalDomainTriggerHandler newInstance() {
        return (APTProposalDomainTriggerHandler)Application.Utilities.newInstance(APTProposalDomainTriggerHandler.class);
    }

    public override SObjectType getSObjectType() {
        return Apttus_Proposal__Proposal__c.SObjectType;
    }

    public override List<Type> registerDomains() {
        return new List<Type>{
            APTProposalGenericDomain.class
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