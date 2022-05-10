/***
 * @description Domain wrapper class for Case
 * @author Nathan Franklin
 * @date 2020-07-30
 * @group Domain
 * @domain Case
 * @changelog
 * Madhusudhan - 7th June 2021, Added StarTrackSupportCasesDomain - PBRP
 * Madhusudhan - 23rd June 2021, Added SObjectTypes(Task,CaseMilestone,AuthorisedContacts__c) in getUnitOfWorkSObjectTypes - PBRP
 * Ashapriya Gadi - 7th Dec 2021, Added CasesDomain for SMWD-320
 */

public inherited sharing class CaseTriggerHandler2 extends ApplicationDomainTriggerHandler {
	
	public override SObjectType getSObjectType() {
		return Case.SObjectType;
	}
	
	public override List<Type> registerDomains() {
		return new List<Type>{
				MyCustomerCasesDomain.class,
				//Added by madhusudhan | PBRP
				StarTrackSupportCasesDomain.class
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
				Case.SObjectType,
				Article__c.SObjectType,
				Task.SObjectType,
				CaseMilestone.SObjectType,
				AuthorisedContacts__c.SObjectType
		};
	}

}