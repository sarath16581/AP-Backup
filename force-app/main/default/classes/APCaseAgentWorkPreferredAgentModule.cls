/**
 * @description
 * Domain Module to handle AgentWork object functionality for AP
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author George Nguyen
 * @group Domain
 * @domain APAgentWork
 * @changelog
 * 2023-02-16 - George Nguyen - Created.
 * 2023-03-18 - Noel Lim - Updated routing logic, to directly assign the routed Queue as the Owner.
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
		processUserResponseForPreferredAgent((List<AgentWork>) records, (Map<Id, AgentWork>) existingRecords, uow);
	}
	
	/*
	* This method performs logic relating to PreferredAgent based on the User's response to the Omni push. Below are the responses processed:
	* - Accept
	* - Decline
	* - Decline On Push Timeout
	* - Unavailable (when User sets their Omni Status to Offline or closes the console).
	*/
	private void processUserResponseForPreferredAgent(List<AgentWork> records, Map<Id, AgentWork> existingRecords, ApplicationUnitOfWork uow){
		List<Case> casesToUpdate = new List<Case>();
		Set<Id> caseIdsToReroute = new Set<Id>();

		for(AgentWork aw: records) {
			if(aw.Status != existingRecords.get(aw.Id).Status) {
				if(aw.Status == 'Opened') {
					casesToUpdate.add(new Case(
						Id = aw.WorkItemId, 
						BypassPreferredAgent__c = false, 
						AllocateToQueue__c = false,
						PreferredAgentExpiry__c = null //needs to be cleared so that in the future, the routing engine can stamp a new value
					));

				// AgentWork with a PreferredUserId (i.e. no OriginalGroupId) will remain with the User on Decline.
				// We need to manually route the Case back to an Omni queue so it can be assigned to another Agent.
				} else if(aw.PreferredUserId != null && (aw.Status == 'Declined' || aw.Status == 'DeclinedOnPushTimeout' || aw.Status == 'Unavailable')) { 
					caseIdsToReroute.add(aw.WorkItemId);
				}
			}
		}

		if(caseIdsToReroute.isEmpty() == false){
			
			Map<Id, Case> cases = SSSWCasesSelector.newInstance(new Set<SObjectField>(SSSW_Routing.caseFieldsForRouting)).selectById(caseIdsToReroute);

			//Apply Case routing directly by assigning the OwnerId, instead of setting Case.AllocateToQueue__c = true. 
			//This is necessary as there is logic in CaseCommonUtility.routeCase() that prevents routing of open Cases assigned to a User.
			casesToUpdate.addAll(routeDeclinedCases(cases).values());
		}

		if(casesToUpdate.isEmpty() == false) {
			uow.registerDirty(casesToUpdate, new List<SObjectField>{ Case.OwnerId, Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c}, true, APCaseAgentWorkPreferredAgentModule.class.getName());
		}
	}

	/**
	 * Apply routing logic to Cases directly by assigning the OwnerId, and set Case values to bypass Preferred Agent Routing 
	 * 
	 * @param - Map of all cases
	 * @return - Map of cases that were re-routed, as new case records
	 */
	private Map<Id, Case> routeDeclinedCases(Map<Id, Case> cases) {
		// NOTE The try/catch block is a fail safe, to catch this error here will ensure the routing errors do not cause the whole transaction to fail
		Map<Id, Case> casesRerouted = new Map<Id, Case>();

		try {			
			for (Case csRec : cases.values()) {				
				csRec.AllocateToQueue__c = true; //manually set to trigger routing logic
			}
			
			SSSW_Routing.assignCasesAndDescription(cases.values(), null, false, true, true);

			// the routing rules have been rerun and the newly set owner id will be added to the case
			for(Case csRec : cases.values()) {

				casesRerouted.put(csRec.Id,new Case(
					Id = csRec.Id, 
					OwnerId = csRec.OwnerId,
					BypassPreferredAgent__c = true, 
					PreferredAgentExpiry__c = null //needs to be cleared so that in the future, the routing engine can stamp a new value
				));
			}				
		
		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, APCaseAgentWorkPreferredAgentModule.class.getName(), 'rerouteCases', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}

		return casesRerouted;
	}
}