/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @author Nathan Franklin
 * @date 2023-06-12
 * @changelog
 */
public inherited sharing class CaseAutomationTriggerHandler extends ApplicationTriggerHandler {
    
	public override SObjectType getSObjectType() {
        return Case.SObjectType;
    }

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override List<Type> registerModules() {
        return new List<Type>{
            
			// all of the old case execution logic which hasn't been uplifted yet
			CaseLegacyAutomationModule.class

        };
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