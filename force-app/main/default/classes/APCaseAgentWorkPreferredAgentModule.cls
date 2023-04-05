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
 * 2023-03-31 - Noel Lim - Updated processUserResponseForPreferredAgent method to
 							 a) implement 2 registerDirty() calls
							 b) generate Status Tracking records on Accept
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
		try {
			processUserResponseForPreferredAgent((List<AgentWork>) records, (Map<Id, AgentWork>) existingRecords, uow);
			
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, APCaseAgentWorkPreferredAgentModule.class.getName(), 'onAfterUpdate', 'AgentWork', ApplicationLogger.LoggingLevel.ERROR);
		}
	}
	
	/*
	* This method performs logic relating to PreferredAgent based on the User's response to the Omni push. Below are the responses processed:
	* - Accept
	* - Decline
	* - Decline On Push Timeout
	* - Unavailable (when User sets their Omni Status to Offline or closes the console).
	*
	* 2 registerDirty calls are needed due to different registered fields to update.
	* Status Tracking records need to be generated manually on Accept because when Omni pushes a Case, it updates the Case Owner to an Agent but no Case triggers are fired.
	*/
	private void processUserResponseForPreferredAgent(List<AgentWork> records, Map<Id, AgentWork> existingRecords, ApplicationUnitOfWork uow){
		
		Set<Id> caseIdsAccepted = new Set<Id>();
		List<Case> casesAccepted = new List<Case>();
		Map<Id,Id> caseSourceOmniQueue = new Map<Id,Id>();
		
		List<Case> casesForTrackingLogic = new List<Case>();
		Map<Id,Case> oldCasesForTrackingLogic = new Map<Id,Case>();

		Set<Id> caseIdsToReroute = new Set<Id>();
		List<Case> casesToReroute = new List<Case>();

		for(AgentWork aw: records) {
			if(aw.Status != existingRecords.get(aw.Id).Status) {
				if(SSSWConstants.OMNI_AGENTWORK_STATUS_OPENED.equalsIgnoreCase(aw.Status)) {
					casesAccepted.add(new Case(
						Id = aw.WorkItemId, 
						BypassPreferredAgent__c = false, 
						AllocateToQueue__c = false,
						PreferredAgentExpiry__c = null //needs to be cleared so that in the future, the routing engine can stamp a new value
					));
					caseIdsAccepted.add(aw.WorkItemId);
					caseSourceOmniQueue.put(aw.WorkItemId,aw.OriginalGroupId);

				// AgentWork with a PreferredUserId (i.e. no OriginalGroupId) will remain with the User on Decline.
				// We need to manually route the Case back to an Omni queue so it can be assigned to another Agent.
				} else if(aw.PreferredUserId != null && 
					(SSSWConstants.OMNI_AGENTWORK_STATUS_DECLINED.equalsIgnoreCase(aw.Status) 
					|| SSSWConstants.OMNI_AGENTWORK_STATUS_DECLINED_ONPUSHTIMEOUT.equalsIgnoreCase(aw.Status) 
					|| SSSWConstants.OMNI_AGENTWORK_STATUS_UNAVAILABLE.equalsIgnoreCase(aw.Status) )) { 
					caseIdsToReroute.add(aw.WorkItemId);
				}
			}
		}

		if(caseIdsAccepted.isEmpty() == false){
			
			Map<Id, Case> cases = SSSWCasesSelector.newInstance(new Set<SObjectField>{Case.OwnerId,Case.Status,Case.RecordTypeId,Case.Network__c,Case.NetworkComments__c,Case.Network_Response__c}).selectById(caseIdsAccepted); //Case Owner will be the Agent
			casesForTrackingLogic.addAll(cases.values());

			for(Case csRec : casesForTrackingLogic){
				oldCasesForTrackingLogic.put(csRec.Id, new Case(
					Id = csRec.Id, 
					OwnerId = caseSourceOmniQueue.get(csRec.Id),
					Status = csRec.Status
				));
			}
		}
		if(casesAccepted.isEmpty() == false) {
			uow.registerDirty(casesAccepted, new List<SObjectField>{ Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c }, true, APCaseAgentWorkPreferredAgentModule.class.getName());
			
			CaseTrackingHelper trackingUtility = new CaseTrackingHelper();
			trackingUtility.updateCaseStatusTracking(casesForTrackingLogic, oldCasesForTrackingLogic);
		}

		if(caseIdsToReroute.isEmpty() == false){
			
			Map<Id, Case> cases = SSSWCasesSelector.newInstance(new Set<SObjectField>(SSSW_Routing.caseFieldsForRouting)).selectById(caseIdsToReroute);

			//Apply Case routing directly by assigning the OwnerId, instead of setting Case.AllocateToQueue__c = true. 
			//This is necessary as there is logic in CaseCommonUtility.routeCase() that prevents routing of open Cases assigned to a User.
			casesToReroute.addAll(routeDeclinedCases(cases).values());
		}
		if(casesToReroute.isEmpty() == false) {
			uow.registerDirty(casesToReroute, new List<SObjectField>{ Case.OwnerId, Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c }, true, APCaseAgentWorkPreferredAgentModule.class.getName());
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
					Bypass_Data_enforcement__c = true,
					BypassPreferredAgent__c = true, 
					AllocateToQueue__c = false, //Unit of Work expects this to be populated
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