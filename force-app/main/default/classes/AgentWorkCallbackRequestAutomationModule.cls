/**
 * @description Module that wraps legacy code which hasn't been uplifted yet for the AgentWork automation on Callback_Request__c
 * @test AgentWorkCBRequestAutomationModule_Test
 * @author Ranjeewa Silva
 * @date 2024-07-22
 * @changelog
 */

public inherited sharing class AgentWorkCallbackRequestAutomationModule extends ApplicationModule {

	public AgentWorkCallbackRequestAutomationModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		/*
		* NOTE: This is existing method. It should be uplifted to the framework.
		*/
		AgentWorkTriggerHandler.assignDeclinedRemindersToQueue((List<AgentWork>)(existingRecords.values()), (List<AgentWork>)records);
	}
}