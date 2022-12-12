/***
 * @description Domain wrapper class for Case.
 * This is fired AFTER the legacy code... NOTE, this should be decommissioned after all legacy code is migrated into domain architecture
 * This is used specifically for modules/domains that need to be run after all legacy code has run.
 * A specific use case that triggered the creation of the temporary class is storing the last assigned queue name. The SSSW routing engine code rewrites the queue which means the code to write the last queue name would need to be executed after the routing engine code
 * @author Nathan Franklin
 * @date 2022-02-03
 * @group Domain
 * @domain Case
 * @changelog
 * 2022-12-12 - Noel Lim - added PendingServiceRouting.SObjectType in getUnitOfWorkSObjectTypes()
 */
public inherited sharing class CaseTriggerHandler3 extends ApplicationDomainTriggerHandler {

	public override SObjectType getSObjectType() {
		return Case.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{
				//Added by Asha
				CasesDomain.class
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
				AuthorisedContacts__c.SObjectType,
				PendingServiceRouting.SObjectType
		};
	}

}