/**
 * @description
 * Domain Module to handle AgentWork object functionality for AP
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain APAgentWork
 * @changelog
 * 2023-02-16 - George Nguyen - Created.
 *
 */
public inherited sharing class APCaseAgentWorkPreferredAgentModule extends ApplicationDomain.Module {
	public static APCaseAgentWorkPreferredAgentModule newInstance() {
		return (APCaseAgentWorkPreferredAgentModule) Application.Utilities.newInstance(APCaseAgentWorkPreferredAgentModule.class);
	}

	// Setup which trigger events this module should respond to
	public APCaseAgentWorkPreferredAgentModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		resetPreferredAgentBypassFlag((List<AgentWork>) records, (Map<Id, AgentWork>) existingRecords, uow);
	}
	
	/*
	* This method is used to reset the BypassPreferredAgent__c on the case. This is a workaround for scenarios when Omni assigns the case to an agent - no triggers are firing. 
	*/
	private void resetPreferredAgentBypassFlag(List<AgentWork> records, Map<Id, AgentWork> existingRecords, ApplicationUnitOfWork uow){
		List<Case> casesToUpdate = new List<Case>();
		for(AgentWork aw: records) {
			if(aw.Status != existingRecords.get(aw.Id).Status && aw.Status == 'Opened') {
				casesToUpdate.add(new Case(Id = aw.WorkItemId, BypassPreferredAgent__c = false));
			}
		}

		if(casesToUpdate.isEmpty() == false) {
			uow.registerDirty(casesToUpdate, new List<SObjectField>{ Case.BypassPreferredAgent__c }, true, APCaseAgentWorkPreferredAgentModule.class.getName());
		}
	}
}