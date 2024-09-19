/**
 * @description Trigger handler on EventMessage__c to execute all the registered ApplicationModule's.
 * @author Ranjeewa Silva
 * @date 2024-08-27
 * @changelog
 */
public inherited sharing class EventMessageTriggerHandler extends ApplicationTriggerHandler {

	public override void registerModules() {
		// all of the old event message automation logic which hasn't been uplifted yet
		registerModule(EventMessageLegacyAutomationModule.class);

		// automation for classic MyCustomer cases (moved over from workflow rules)
		registerModule(EventMessageMyCustomerCaseAutoModule.class);

		// automation for unified cases on receiving Event Messages on impacted articles linked to the case
		registerModule(EventMessageUnifiedCaseAutomationModule.class);
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public override SObjectType getSObjectType() {
		return EventMessage__c.SObjectType;
	}

	@TestVisible private static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				Case.SObjectType
		};
	}
}