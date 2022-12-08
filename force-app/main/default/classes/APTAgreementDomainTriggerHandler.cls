/***
 * @description Domain wrapper class for Proposals
 * @author Ken McGuire
 * @date 2022-12-01
 * @group Domain
 * @tag APTAgreementDomain
 * @domain Apttus__APTS_Agreement__c
 * @test APTAgreementDomainTriggerHandler_Test
 * @changelog
 * 22022-12-01- Ken McGuire - Created.
 */
public with sharing class APTAgreementDomainTriggerHandler extends ApplicationDomainTriggerHandler  {
    
    public static APTAgreementDomainTriggerHandler newInstance() {
        return (APTAgreementDomainTriggerHandler)Application.Utilities.newInstance(APTAgreementDomainTriggerHandler.class);
    }

    public override SObjectType getSObjectType() {
        return Apttus__APTS_Agreement__c.SObjectType;
    }

    public override List<Type> registerDomains() {
        return new List<Type>{
            APTAgreementDomain.class
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
            Apttus__APTS_Agreement__c.SObjectType, 
            Apttus__APTS_Agreement__Share.SObjectType
        };
    }
}