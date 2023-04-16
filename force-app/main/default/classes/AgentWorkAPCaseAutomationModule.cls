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
 * 2023-03-31 - Noel Lim - Updated processUserResponseToOmniPush method to
 *							a) implement 2 registerDirty() calls
 *							b) new method populateCaseField
 * 2023-04-13 - Noel Lim - Updated:
 * 							a) class name from APCaseAgentWorkPreferredAgentModule to AgentWorkAPCaseAutomationModule
 * 							b) generate Status Tracking records on Accept
 * 
 */
public inherited sharing class AgentWorkAPCaseAutomationModule extends ApplicationDomain.Module {
	public static AgentWorkAPCaseAutomationModule newInstance() {
		return (AgentWorkAPCaseAutomationModule) Application.Utilities.newInstance(AgentWorkAPCaseAutomationModule.class);
	}

	// Setup which trigger events this module should respond to
	public AgentWorkAPCaseAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate().enableAfterUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			populateCaseField((List<AgentWork>) records, uow);			
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, AgentWorkAPCaseAutomationModule.class.getName(), 'onBeforeInsert', 'AgentWork', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			populateCaseField((List<AgentWork>) records, uow);			
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, AgentWorkAPCaseAutomationModule.class.getName(), 'onBeforeUpdate', 'AgentWork', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			processUserResponseToOmniPush((List<AgentWork>) records, (Map<Id, AgentWork>) existingRecords, uow);	
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, AgentWorkAPCaseAutomationModule.class.getName(), 'onAfterUpdate', 'AgentWork', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
	 * This method populates the AgentWork lookup field Case if the AgentWork is for a Case record.
	 * 
	 * @param records the list of updated or new records from the trigger. 
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 */
	private void populateCaseField(List<AgentWork> records, ApplicationUnitOfWork uow){
		for(AgentWork aw: records) {
			if(aw.Case__r == null && aw.WorkItemId.getSobjectType() == Case.SObjectType){
				aw.Case__c = aw.WorkItemId;
			}
		}
	}
	
	/**
	 * This method performs logic when the Agent responds to an Omni push. 
	 * 
	 * OTB behaviour when Omni pushes a Case to an Agent is to change the Case Owner to the Agent, and NO Case trigger is fired.
	 * So we manually perform logic that otherwise will not be triggered - when Owner changes, Status Tracking records are created
	 * 
	 * Another OTB logic is that when an AgentWork is for a Preferred User, on Decline the Case will stay with the Agent as OriginalGroupId will be empty.
	 * So we manually route the case back.
	 * 
	 * Below are the responses processed:
	 * - Accept
	 * - Decline
	 * - Decline On Push Timeout
	 * - Unavailable (when User sets their Omni Status to Offline or closes the console).
	 * 
	 * In principle, the same logic is applied for Decline, Decline On Push Timeout, and Unavailable.
	 *
	 * 2 registerDirty calls are needed due to different registered fields to update (1 for Cases Accepted and 1 for Cases Declined)
	 * 
	 */
	private void processUserResponseToOmniPush(List<AgentWork> records, Map<Id, AgentWork> existingRecords, ApplicationUnitOfWork uow){
		
		List<Case> casesAccepted = new List<Case>();
		Map<Id,Id> caseSourceOwner = new Map<Id,Id>();
		
		Set<Id> caseIdsForTrackingLogic = new Set<Id>();
		Map<Id,Case> casesForTrackingLogic = new Map<Id,Case>();
		Map<Id,Case> oldCasesForTrackingLogic = new Map<Id,Case>();

		Set<Id> caseIdsToReroute = new Set<Id>();
		List<Case> casesRerouted = new List<Case>();
		Id caseSourceOwnerId;

		Map<Id, Case> casesToQuery = new Map<Id, Case>();

		for(AgentWork aw: records) {
			if(aw.Status != existingRecords.get(aw.Id).Status) {

				if( SSSWConstants.OMNI_AGENTWORK_STATUS_OPENED.equalsIgnoreCase(aw.Status) &&
					(existingRecords == null || ( existingRecords != null && aw.Status != existingRecords.get(aw.Id).Status)) 
				) { 
					casesAccepted.add(new Case(
						Id = aw.WorkItemId, 
						BypassPreferredAgent__c = false, 
						AllocateToQueue__c = false,
						Bypass_Data_enforcement__c = true,
						PreferredAgentExpiry__c = null //needs to be cleared so that in the future, the routing engine can stamp a new value
					));

					caseSourceOwnerId = aw.OriginalGroupId != null ? aw.OriginalGroupId  : aw.PreferredUserId != null ? OmniChannelService.getInstance().preferredAgentQueueId : null; //As this module only handles AP Cases, AgentWork with Preferred User can be safely assumed to come from the SSSW Preferred Agent queue
					
					if(caseSourceOwnerId != null){ //AgentWork from 'Transfers to a User' will not have an OriginalGroupId
						caseIdsForTrackingLogic.add(aw.WorkItemId); 
						caseSourceOwner.put(aw.WorkItemId,caseSourceOwnerId);
					}

				// On Decline, OTB behaviour for AgentWork with a PreferredUserId (i.e. no OriginalGroupId) is to keep Case Owner as the Agent.
				// We need to manually route the Case back to an Omni queue so it can be assigned to another Agent.
				} else if(aw.PreferredUserId != null && 
					(SSSWConstants.OMNI_AGENTWORK_STATUS_DECLINED.equalsIgnoreCase(aw.Status) 
					|| SSSWConstants.OMNI_AGENTWORK_STATUS_DECLINED_ONPUSHTIMEOUT.equalsIgnoreCase(aw.Status)
					|| SSSWConstants.OMNI_AGENTWORK_STATUS_UNAVAILABLE.equalsIgnoreCase(aw.Status) ) &&
					(existingRecords == null || ( existingRecords != null && aw.Status != existingRecords.get(aw.Id).Status))
				) { 
					caseIdsToReroute.add(aw.WorkItemId);
				}
			}
		}

		if(caseIdsForTrackingLogic.isEmpty() == false || caseIdsToReroute.isEmpty() == false){
			Set<Id> casesIdsToQuery = new Set<Id>(caseIdsForTrackingLogic);
			casesIdsToQuery.addAll(caseIdsToReroute);

			Set<SObjectField> caseFieldsToQuery = new Set<SObjectField>(SSSW_Routing.caseFieldsForRouting);
			caseFieldsToQuery.addAll(CaseTrackingHelper.caseFieldsForTracking);

			casesToQuery = SSSWCasesSelector.newInstance(caseFieldsToQuery).selectById(casesIdsToQuery); 
		}

		if(caseIdsForTrackingLogic.isEmpty() == false && casesToQuery.isEmpty() == false){	
			for(Id csId : caseIdsForTrackingLogic){
				if(casesToQuery.containsKey(csId)){
					casesForTrackingLogic.put(csId, casesToQuery.get(csId));
				}
			}

			for(Case csRec : casesForTrackingLogic.values()){
				if(caseSourceOwner != null && caseSourceOwner.containsKey(csRec.Id)){
					oldCasesForTrackingLogic.put(csRec.Id, new Case(
						Id = csRec.Id, 
						OwnerId = caseSourceOwner?.get(csRec.Id),
						Status = csRec.Status
					));
				} else {
					casesForTrackingLogic.remove(csRec.Id);
				}				
			}
		}

		if(caseIdsToReroute.isEmpty() == false && casesToQuery.isEmpty() == false){
			Map<Id,Case> casesToReroute = new Map<Id,Case>();
			for(Id csId : caseIdsToReroute){
				if(casesToQuery.containsKey(csId)){
					casesToReroute.put(csId, casesToQuery.get(csId));
				}
			}

			casesRerouted = routeDeclinedCases(casesToReroute).values();
		}

		if(casesAccepted.isEmpty() == false) {
			uow.registerDirty(casesAccepted, new List<SObjectField>{ Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c, Case.Bypass_Data_enforcement__c }, AgentWorkAPCaseAutomationModule.class.getName());
		}

		if(casesForTrackingLogic.isEmpty() == false && oldCasesForTrackingLogic.isEmpty() == false){
			CaseTrackingHelper trackingUtility = new CaseTrackingHelper();
			trackingUtility.updateCaseStatusTracking(casesForTrackingLogic.values(), oldCasesForTrackingLogic); //manually call Status Tracking logic, as OTB Omni push behaviour changes the Case Owner to the Agent, but did not generate a Case trigger execution 
			CaseTrackingHelper.isSetStatusTrackRecursive = false; //set it back to false as the Case trigger execution from this may have e.g. Owner or Status changes that requires further Status Tracking to be generated
		}	

		if(casesRerouted.isEmpty() == false) {
			uow.registerDirty(casesRerouted, new List<SObjectField>{ Case.OwnerId, Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c, Case.Bypass_Data_enforcement__c }, AgentWorkAPCaseAutomationModule.class.getName());
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
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, AgentWorkAPCaseAutomationModule.class.getName(), 'rerouteCases', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}

		return casesRerouted;
	}
}