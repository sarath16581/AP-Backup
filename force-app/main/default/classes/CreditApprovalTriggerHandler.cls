/***
 * @description Domain wrapper class for Credit Approval. Initial version in 2017 has been refactored to align with Domain pattern.
 * @author Ranjeewa Silva
 * @date 2021-05-13
 * @group Domain
 * @tag Credit_Approval__c, Core
 * @domain Core
 * @changelog
 * 2017-06-06 - Bharat P - Initial Version - Handles calls from Credit Approval Trigger
 * 2021-05-13 - Ranjeewa Silva - Refactored to align with Domain pattern. Removed code that populated Approval_Submission__c and
 *                               Approval_Workflow__c as these objects are no longer in use with the new credit approvals model.
 */

public without sharing class CreditApprovalTriggerHandler extends ApplicationDomainTriggerHandler {

    public override SObjectType getSObjectType() {
        return Credit_Approval__c.SObjectType;
    }

    public override List<Type> registerDomains() {
        return new List<Type>{
                CustomerResCreditApprovalsDomain.class
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
                Credit_Approval__c.SObjectType
        };
    }
}