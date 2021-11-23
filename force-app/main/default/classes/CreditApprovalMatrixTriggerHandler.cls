/***
 * @description Domain wrapper class for Credit Approval Matrix
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @group Domain
 * @tag CreditApprovalMatrix__c, Core
 * @domain Core
 * @changelog
 * 2021-05-13 - Ranjeewa Silva - Created.
 */

public with sharing class CreditApprovalMatrixTriggerHandler extends ApplicationDomainTriggerHandler  {

    public override SObjectType getSObjectType() {
        return CreditApprovalMatrix__c.SObjectType;
    }

    public override List<Type> registerDomains() {
        return new List<Type>{
                CustomerResCreditApprovalMatrixDomain.class
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
                CreditApprovalMatrix__c.SObjectType,
                Credit_Approval__c.SObjectType
        };
    }

}