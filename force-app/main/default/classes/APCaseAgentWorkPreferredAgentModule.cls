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
			if(aw.Status != existingRecords.get(aw.Id).Status) {
				if(aw.Status == 'Opened') {
					casesToUpdate.add(new Case(
						Id = aw.WorkItemId, 
						BypassPreferredAgent__c = false, 
						AllocateToQueue__c = false,
						PreferredAgentExpiry__c = null //needs to be cleared so that in the future, the routing engine can stamp a new value
					));

				// If the PSR was created PreferredUserId (i.e. manualy created) and it was declined by the agent (manually or timed out) then bypass the preferred agent logic and push via gen pop omni
				} else if(aw.PreferredUserId != null && (aw.Status == 'Declined' || aw.Status == 'DeclinedOnPushTimeout')) { 
					casesToUpdate.add(new Case(
						Id = aw.WorkItemId, 
						BypassPreferredAgent__c = true, 
						AllocateToQueue__c = true,
						PreferredAgentExpiry__c = null //needs to be cleared so that in the future, the routing engine can stamp a new value
					));
				}
			}
		}

		if(casesToUpdate.isEmpty() == false) {
			uow.registerDirty(casesToUpdate, new List<SObjectField>{ Case.BypassPreferredAgent__c, Case.AllocateToQueue__c }, true, APCaseAgentWorkPreferredAgentModule.class.getName());
		}
	}
}