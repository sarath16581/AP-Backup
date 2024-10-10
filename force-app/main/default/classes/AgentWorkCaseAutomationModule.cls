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
 * 2023-03-31 - Noel Lim - Updated processUserResponseToOmniPush method to:
 *							a) implement 2 registerDirty() calls
 *							b) new method populateCaseField
 * 2023-04-13 - Noel Lim - Updated:
 * 							a) class name from APCaseAgentWorkPreferredAgentModule to AgentWorkAPCaseAutomationModule
 * 							b) generate Status Tracking records on Accept
 * 2023-05-24 - Nathan Franklin - Change rerouting of declined cases logic
 * 2024-07-19 - Ranjeewa Silva - Uplifted to new ApplicationModule framework and use CasesSelector to query cases as
 *							   Unified cases are also handled in this module.
 */
public inherited sharing class AgentWorkCaseAutomationModule extends ApplicationModule {

	// case record types in scope for the automation delivered by this module.
	// previously filtering was applied in domain class.
	private Set<Id> caseRecordTypesInScope {
		get {
			if (caseRecordTypesInScope == null) {
				caseRecordTypesInScope = RecordTypesSelector.newInstance().selectByDeveloperNamesLike('Case', new Set<String>{'SSSW', 'Unified'}).keySet();
			}
			return caseRecordTypesInScope;
		}
		set;
	}

	// case record types that supports status tracking.
	private Set<Id> caseRecordTypesForStatusTracking {
		get {
			if (caseRecordTypesForStatusTracking == null) {
				caseRecordTypesForStatusTracking = RecordTypesSelector.newInstance().selectByDeveloperNameLike('Case', 'SSSW').keySet();
			}
			return caseRecordTypesForStatusTracking;
		}
		set;
	}

	// Setup which trigger events this module should respond to
	public AgentWorkCaseAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			populateCaseField((List<AgentWork>) records, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, AgentWorkCaseAutomationModule.class.getName(), 'onBeforeInsert', 'AgentWork', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			processUserResponseToOmniPush((List<AgentWork>) records, (Map<Id, AgentWork>) existingRecords, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, AgentWorkCaseAutomationModule.class.getName(), 'onAfterUpdate', 'AgentWork', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
	 * This method populates the AgentWork lookup field Case if the AgentWork is for a Case record.
	 *
	 * @param records the list of updated or new records from the trigger.
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 */
	private void populateCaseField(List<AgentWork> records, ApplicationUnitOfWork uow){
		String source = 'AgentWorkCaseAutomationModule.populateCaseField';

		Map<SObjectType, Set<Id>> mappedObjectTypeAndIds = new Map<SObjectType, Set<Id>>();
		List<AgentWork> qualifiedAgentWorkRecords = new List<AgentWork>();

		for(AgentWork aw: records) {
			SObjectType objType = aw.WorkItemId.getSobjectType();
			if(objType == Case.SObjectType){
				aw.Case__c = aw.WorkItemId;
			}
			
			// Mapping SObject types to work item ids
			if(UnifiedInteractionService.MAPPED_CASE_FIELDS.containsKey(objType) == true) {
				if(mappedObjectTypeAndIds.containsKey(objType) == false) {
					mappedObjectTypeAndIds.put(objType, new Set<Id>());
				}

				mappedObjectTypeAndIds.get(objType).add(aw.WorkItemId);
				qualifiedAgentWorkRecords.add(aw);
			}
		}

		if(mappedObjectTypeAndIds.isEmpty() == false && qualifiedAgentWorkRecords.isEmpty() == false) {
			Map<Id, SObject> workItems = UnifiedInteractionService.getInstance().retrieveInteractionRecords(mappedObjectTypeAndIds);
			UnifiedInteractionService.getInstance().populateCaseFieldOnAgentWorks(workItems, qualifiedAgentWorkRecords, uow, source);
		}
	}

	/**
	 * This method performs logic when the Agent responds to an Omni push.
	 *
	 * OTB behaviour when Omni pushes a Case to an Agent is to change the Case Owner to the Agent, and NO Case trigger is fired.
	 * So we manually perform logic that otherwise will not be triggered - when Owner changes, Status Tracking records are created
	 *
	 * Another OTB logic is that when an AgentWork is for a Preferred User, on Decline the Case will stay with the Agent as OriginalGroupId will be empty.
	 * We need the Case to go back to Omni queues, so we manually run logic to route the case.
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

		Set<Id> acceptedCaseIds = new Set<Id>();
		Map<Id,Case> casesForTrackingLogic = new Map<Id,Case>();
		Map<Id,Case> oldCasesForTrackingLogic = new Map<Id,Case>();

		Set<Id> declinedCaseIds = new Set<Id>();

		for (AgentWork aw: records) {
			if (existingRecords == null || (existingRecords != null && aw.Status != existingRecords.get(aw.Id).Status)) {

				if (SSSWConstants.OMNI_AGENTWORK_STATUS_OPENED.equalsIgnoreCase(aw.Status)) {

					acceptedCaseIds.add(aw.WorkItemId);

				} else if (aw.PreferredUserId != null
						&& (SSSWConstants.OMNI_AGENTWORK_STATUS_DECLINED.equalsIgnoreCase(aw.Status)
								|| SSSWConstants.OMNI_AGENTWORK_STATUS_DECLINED_ONPUSHTIMEOUT.equalsIgnoreCase(aw.Status)
								|| SSSWConstants.OMNI_AGENTWORK_STATUS_UNAVAILABLE.equalsIgnoreCase(aw.Status))) {
					// on Decline, OTB behaviour for AgentWork with a PreferredUserId (i.e. no OriginalGroupId) is to keep Case Owner as the Agent.
					// need to manually route the Case back to an Omni queue so it can be assigned to another Agent.
					declinedCaseIds.add(aw.WorkItemId);
				}
			}
		}

		// from the case records with accepted or declined AgentWork records, we need to filter out records not in
		// scope for this automation. only 'SSSW' and 'Unified' case records are in scope for this automation (see 'caseRecordTypesInScope')
		Map<Id, Case> processableCases = new Map<Id, Case>();

		// passing both Sets together for 1 Case Selector call
		if (!acceptedCaseIds.isEmpty() || !declinedCaseIds.isEmpty()) {
			Set<Id> casesIdsToQuery = new Set<Id>(acceptedCaseIds);
			casesIdsToQuery.addAll(declinedCaseIds);

			Set<SObjectField> caseFieldsToQuery = new Set<SObjectField>(SSSW_Routing.caseFieldsForRouting);
			caseFieldsToQuery.addAll(CaseTrackingHelper.caseFieldsForTracking);
			caseFieldsToQuery.add(Case.Comment__c); // for routing debugging

			processableCases = new Map<Id, Case>(CasesSelector.newInstance(caseFieldsToQuery).search(new Map<String, Object>{
					'caseIds' => casesIdsToQuery,
					'recordTypeIds' => caseRecordTypesInScope
			}, true));
		}

		if (!acceptedCaseIds.isEmpty() && !processableCases.isEmpty()) {
			// we have accepted agent work on case records in scope for this automation. routing related system fields
			// has to be reset on these cases.
			// if status tracking is required for case record type we also need to ensure status tracking is invoked.
			List<Case> updatableCases = new List<Case>();
			for (Id csId : acceptedCaseIds) {
				Case caseRecord = processableCases.get(csId);
				if (caseRecord != null) {
					// reset system fields related to case routing, so that routing engine will run in future.
					updatableCases.add(new Case(
							Id = csId,
							BypassPreferredAgent__c = false,
							AllocateToQueue__c = false,
							Bypass_Data_enforcement__c = true,
							PreferredAgentExpiry__c = null //needs to be cleared so that in the future, the routing engine can stamp a new value
					));

					// check if this case record should generate status tracking
					if (caseRecordTypesForStatusTracking.contains(caseRecord.RecordTypeId)) {
						// found a case to generate Status Tracking
						casesForTrackingLogic.put(csId, caseRecord);
					}
				}
			}

			for(Case csRec : casesForTrackingLogic.values()){
				oldCasesForTrackingLogic.put(csRec.Id, new Case(
						Id = csRec.Id,
						OwnerId = null, // purpose of setting this OwnerId is ONLY to trigger StatusTracking logic that there is an Owner change. Status Tracking logic does not use this Owner Id to set the Previous_Owner_Id__c value, it references the previous Status Tracking record
						Status = csRec.Status
				));
			}

			if(!updatableCases.isEmpty()) {
				uow.registerDirty(updatableCases, new List<SObjectField>{ Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c, Case.Bypass_Data_enforcement__c }, AgentWorkCaseAutomationModule.class.getName());
			}
		}

		if (!casesForTrackingLogic.isEmpty() && !oldCasesForTrackingLogic.isEmpty()) {
			CaseTrackingHelper trackingUtility = new CaseTrackingHelper();

			// manually call Status Tracking logic, as OTB Omni push behaviour changes the Case Owner to the Agent, but did not generate a Case trigger execution
			trackingUtility.updateCaseStatusTracking(casesForTrackingLogic.values(), oldCasesForTrackingLogic);

			// set it back to false as the Case trigger execution from this may have e.g. Owner or Status changes that requires further Status Tracking to be generated
			CaseTrackingHelper.isSetStatusTrackRecursive = false;
		}


		// cases where AgentWork is declined need to be re-routed.
		if (!declinedCaseIds.isEmpty() && !processableCases.isEmpty()) {
			Map<Id,Case> casesToReroute = new Map<Id,Case>();
			for(Id csId : declinedCaseIds){
				if(processableCases.containsKey(csId)){
					casesToReroute.put(csId, processableCases.get(csId));
				}
			}

			// we must manually call the routing engine and apply the OwnerId directly
			// using the Case.AllocateToQueue__c = true approach is not an option, because currently the Case Owner is an Agent and there is logic that prevent routing for Open Cases owned by an Agent
			routeDeclinedCases(casesToReroute, uow);
		}
	}

	/**
	 * Mark the declined cases for allocation (just for preferred agent routing)
	 */
	private void routeDeclinedCases(Map<Id, Case> cases, ApplicationUnitOfWork uow) {

		List<Case> casesRerouted = new List<Case>();

		// NOTE The try/catch block is a fail safe, to catch this error here will ensure the routing errors do not cause the whole transaction to fail
		try {

			// the routing rules have been rerun and the newly set owner id will be added to the case
			for(Case csRec : cases.values()) {

				casesRerouted.add(new Case(
						Id = csRec.Id,
						Bypass_Data_enforcement__c = true,
						BypassPreferredAgent__c = true,
						AllocateToQueue__c = true, // Unit of Work expects this to be populated
						PreferredAgentExpiry__c = null // needs to be cleared so that in the future, the routing engine can stamp a new value
				));
			}

			// flag the declined cases to bypass eligibility checks when rerouting cases in the trigger
			// this only works if the routing is triggered in the same transaction as this
			CaseRoutingService.getInstance().addCaseBypassToRoutingEligibility(cases.keySet(), 'agent work declined by user: ' + UserInfo.getUserId());

			uow.registerDirty(casesRerouted, new List<SObjectField>{ Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c, Case.Bypass_Data_enforcement__c }, AgentWorkCaseAutomationModule.class.getName());

		} catch(Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, AgentWorkCaseAutomationModule.class.getName(), 'rerouteCases', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}
}