/*** 
 * @description
 * Class to handle all case routing low level functions
 * Will eventually consolidate all routing capability
 * 
 * @author Nathan Franklin
 * @date 2023-05-17
 * @test CaseRoutingService_Test, AgentWorkAPCaseAutomationModule_Test
 * @changelog
 * 2023-07-25 - Nathan Franklin - Change to force routing for all cases moving from closed -> open 
 * 2023-08-07 - Nathan Franklin - Change to force routing for all cases moving from closed -> open (excluded certain scenarios)
 */
public inherited sharing class CaseRoutingService {

	// temporary
	public static Boolean isParentCaseUpdateRecursive = false;

	private static final String ROUTING_TRUE = 'true';
	private static final String ROUTING_FALSE = 'false';
	
	private Set<Id> validRecTypes {
		get {
			if(validRecTypes == null) {
				// get all valid record types for the SSSW functionality
				validRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
			}
			return validRecTypes;
		}
		private set;
	}

	private Set<Id> socialAndSsswRecordTypeIds {
		get {
			if(socialAndSsswRecordTypeIds == null) {
				// Get social Record types
				Set<Id> socialRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()), 'Social');
				socialAndSsswRecordTypeIds = new Set<Id>(validRecTypes);
				socialAndSsswRecordTypeIds.addAll(socialRecTypes);
			}
			return socialAndSsswRecordTypeIds;
		}
		private set;
	}

	private Map<Id, Group> omniGroups {
		get {
			if(omniGroups == null) {
				omniGroups = GroupsSelector.newInstance().selectOmniQueues(new Set<Object>());
			}
			return omniGroups;
		}
		private set;
	}

	/**
	 * This tracks any cases were eligibility logic for routing should be bypassed
	 * This is useful when the case is in an invalid state but it should still be routed
	 * One example of this is when a case is declined when setup for preferred agent routing....
	 * The case ownership will be with an individual, the case will be open which means it's in an invalid state for routing
	 * Adding the case to this variable allows us to bypass logic checks and still allow the case to be rerouted (ASSUMING THE AllocateToQueue__c field is set to true)
	 * NOTE: This only works if used within the same transaction that routing is processed (Example AgentWork trigger updates case which handles routing)
	 */
	public Map<Id, String> caseRoutingEligibilityBypass = new Map<Id, String>();

	public static CaseRoutingService getInstance() {
		return (CaseRoutingService)Application.Utilities.getInstance(CaseRoutingService.class);
	}

	/**
	 * Mark a case for eligibility bypass when deciding to route or not
	 */
	public void addCaseBypassToRoutingEligibility(Id caseId, String reason) {
		addCaseBypassToRoutingEligibility(new Set<Id>{caseId}, reason);
	}

	/**
	 * Mark a case for eligibility bypass when deciding to route or not
	 */
	public void addCaseBypassToRoutingEligibility(Set<Id> caseIds, String reason) {
		for(Id caseId : caseIds) {
			caseRoutingEligibilityBypass.put(caseId, reason);
		}
	}

	public void removeCaseBypassToRoutingEligibility(Id caseId) {
		caseRoutingEligibilityBypass.keySet().remove(caseId);
	}

	public Boolean isCaseRoutingEligibilityBypassed(Id caseId) {
		return caseId != null && caseRoutingEligibilityBypass.keySet().contains(caseId);
	}

	/**
	 * Handles all case routing logic for AP CC cases (omni, preferred agent routing, routing eligibility, omni priority etc...)
	 * NOTE: This method also handles secondary routing priority calculation for ST cases too
	 */
	public void routeCase(List<Case> caseList, Map<Id,Case> oldMap, Boolean isInsert){
		try{

			Application.Profiler.start('routing');

			List<Case> possibleProcessableRecords = new List<Case>();
			for(Case csRec : caseList) {
				// Check if it is SSSW record type or Social record type.
				if(Utility.isValidRecordType(socialAndSsswRecordTypeIds, csRec.RecordTypeId)) {
					possibleProcessableRecords.add(csRec);
				}
			}

			///////////////////// Check whether cases need routing
			//Application.Profiler.start('maybeRouteCase');
			maybeRouteCase(possibleProcessableRecords, oldMap, isInsert);
			//Application.Profiler.stop('maybeRouteCase');

			///////////////////// If case is closed and in omni queue, we need to move it
			//Application.Profiler.start('maybeMoveClosedOmniCases');
			maybeMoveClosedOmniCases(possibleProcessableRecords, oldMap);
			//Application.Profiler.stop('maybeMoveClosedOmniCases');

			///////////////////// Remove preferred PSR if case goes back to omni queue
			// NOTE: It's possible this could be refactored to only delete a PAR PSR if the case will not return to PAR PSR
			//			For now, we delete (if needed) as it gives us the opportunity to recreate with updated settings (again, if needed)
			//Application.Profiler.start('maybeRemovePendingServiceRoutingPreferredAgentRecords');
			maybeRemovePendingServiceRoutingPreferredAgentRecords(possibleProcessableRecords, oldMap, isInsert);
			//Application.Profiler.stop('maybeRemovePendingServiceRoutingPreferredAgentRecords');

			///////////////////// Check whether secondary routing priority needs to be recalculated (if owner/priorty fields have changed)
			///////////////////// NOTE: This is applicable for both AP and ST cases
			//Application.Profiler.start('maybeRecalculateSecondaryRoutingPriority');
			maybeRecalculateSecondaryRoutingPriority(caseList, oldMap);
			//Application.Profiler.stop('maybeRecalculateSecondaryRoutingPriority');

			///////////////////// Check whether there are actions to be taken for preferred agent routing
			//Application.Profiler.start('maybeOverrideWithPreferredAgentRouting');
			maybeOverrideWithPreferredAgentRouting(possibleProcessableRecords, oldMap);
			//Application.Profiler.stop('maybeOverrideWithPreferredAgentRouting');

			///////////////////// Anytime an case is assigned to a user we reset all of the preferred agent bypasses
			//Application.Profiler.start('maybeResetPreferredAgentBypasses');
			maybeResetPreferredAgentBypasses(possibleProcessableRecords, oldMap);
			//Application.Profiler.stop('maybeResetPreferredAgentBypasses');

			Application.Profiler.stop('routing');
		}
		catch(Exception exp){
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseRoutingService.class.getName(), SSSWConstants.METH_INSERT_MILESTONES,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * Checks whether the case can be routed
	 * Even if its been marked for routing we still may prevent it based on the logic here
	 */
	@TestVisible
	private void maybeRouteCase(List<Case> caseList, Map<Id, Case> oldMap, Boolean isInsert) {
		Set<String> closedStatuses = Utility.getCaseClosedStatus();
		OmniChannelService omniService = OmniChannelService.getInstance();
		QM__c queueSettings = QM__c.getInstance();

		// if a case has been moved into these queues on reopening, then routing should be ignored!
		Set<Id> excludedForceRoutingOnReopenQueues = new Set<Id>();
		if(queueSettings != null && !String.isEmpty(queueSettings.AwaitingCustomerQueue__c)) {
			excludedForceRoutingOnReopenQueues.add((Id)queueSettings.AwaitingCustomerQueue__c);
		}
		if(queueSettings != null && !String.isEmpty(queueSettings.NetworkQueueId__c)) {
			excludedForceRoutingOnReopenQueues.add((Id)queueSettings.NetworkQueueId__c);
		}

		List<Case> casesTobeRouted = new List<Case>();
		Map<Id,String> caseOriginKeyMap = new Map<Id,String>(); // map of case id and case key with origin
		Map<Id,String> caseNoOriginKeyMap = new Map<Id,String>();	// map of case id and case key without origin

		String routingContext = 'ssswroutecase';
		Set<SObjectField> routingMonitoredFields = new Set<SObjectField>{Case.Status, Case.Network__c, Case.Description, Case.AllocateToQueue__c};
		List<ApplicationRecursion.RecordState> routingChangedRecords = ApplicationRecursion.getInstance().getProcessableRecords(routingContext, caseList, oldMap, routingMonitoredFields);

		for(ApplicationRecursion.RecordState recordState : routingChangedRecords){
			Case csRec = (Case)recordState.record;
			Set<SObjectField> changedFields = recordState.changedFields;
			Map<String, Object> previousState = recordState.previousState;	// get old values of case
			
			// verify if network or description is null & case is set for queue allocation

			// if the case is already in the preferred agent queue and the queue timeout hasn't been reached then we do not allow the case to be reallocated (unless BypassPreferredAgent__c is set)
			if(csRec.AllocateToQueue__c && csRec.OwnerId == omniService.preferredAgentQueueId && 
					csRec.PreferredAgentExpiry__c != null && csRec.PreferredAgentExpiry__c > Datetime.now() &&
					csRec.BypassPreferredAgent__c == false) {

				if(!isCaseRoutingEligibilityBypassed(csRec.Id)) {
					csRec.AllocateToQueue__c = false;

					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'routing bypassed: unexpired preferred agent entry');
				} else {
					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'routing forced: ' + caseRoutingEligibilityBypass.get(csRec.Id));
					removeCaseBypassToRoutingEligibility(csRec.Id);
				}
			}

			// do not reallocate permanent closed cases
			if(csRec.AllocateToQueue__c && csRec.Permanent_Close__c) {

				if(!isCaseRoutingEligibilityBypassed(csRec.Id)) {
					csRec.AllocateToQueue__c = false;

					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'routing bypassed: permanently closed');
				} else {
					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'routing forced: ' + caseRoutingEligibilityBypass.get(csRec.Id));
					removeCaseBypassToRoutingEligibility(csRec.Id);
				}
			}

			// do not reallocate cases waiting for routing to resolve
			// this would be because the routing engine needs attributes from integration callouts (like article) in order to resolve
			// in this scenario the routing rules are manually applied after the integration has completed its callout
			// look at MyCustomerCaseArticlesModule
			if(csRec.AllocateToQueue__c && csRec.OwnerId == omniService.omniHoldingQueueId) {

				if(!isCaseRoutingEligibilityBypassed(csRec.Id)) {
					csRec.AllocateToQueue__c = false;

					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'routing bypassed: case in routing holding queue');
				} else {
					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'routing forced: ' + caseRoutingEligibilityBypass.get(csRec.Id));
					removeCaseBypassToRoutingEligibility(csRec.Id);
				}
			}

			// do not reassign if the agent is already working on the case
			// this would occur when, for example, a customer response triggers the case to route and assigning the case away from the agent. 
			// >> Note that Closed cases with an agent should be allowed to route. <<
			if(csRec.AllocateToQueue__c && !isInsert &&
					csRec.Case_Owner_User_Profile_Name__c == SSSWConstants.SSSW_AGENT_PROFILE && //This logic relies on User Profile and needs to be assessed at a future date and refactored. 1 refactor option is to prevent case routing if i) User's License is not a Guest User (for cases created from Portals) ii) User is not System Support (cases created from email-to-case)
					!closedStatuses.contains(csRec.Status) && // case is not currently closed
					!closedStatuses.contains(String.valueOf(previousState.get('Status'))) //Closed Cases assigned to an Agent that receives a Customer or Network email needs to route. However Workflow Rules updates the Status from Closed before this logic runs, so we also need to check oldCase value was not Closed
					) {

				if(!isCaseRoutingEligibilityBypassed(csRec.Id)) {
					csRec.AllocateToQueue__c = false;

					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'routing bypassed: case owned by agent and not closed');
				} else {
					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'routing forced: ' + caseRoutingEligibilityBypass.get(csRec.Id));
					removeCaseBypassToRoutingEligibility(csRec.Id);
				}
			}

			// Move eligible Closed Cases to the SSSW Closed Omni Queue
			// Note, this will only be whena  case is assigned to an Omni queue (omniGroups.containsKey)
			// we need to run this check after routing engine engine runs too 
			if (changedFields.contains(Case.Status) && 
					closedStatuses.contains(csRec.Status) &&
					!closedStatuses.contains(String.valueOf(previousState.get('Status'))) &&
					(omniGroups.containsKey(csRec.OwnerId) ||
						csRec.OwnerId == omniService.preferredAgentQueueId || csRec.OwnerId == queueSettings.NetworkQueueId__c)) {

				csRec.AllocateToQueue__c = false;
				csRec.OwnerId = omniService.omniClosedCaseQueueId;

				// debug messaging to inform admin of routing path
				populateRoutingDebug(csRec, 'routing bypassed: case was just closed');
				
			}

			// check if we are bypassing routing rules on creation
			if(csRec.AllocateToQueue__c && isInsert && csRec.ByPassRoutingRulesOnCreation__c) {
				csRec.AllocateToQueue__c = false;
				
				// debug messaging to inform admin of routing path
				populateRoutingDebug(csRec, 'routing bypassed on creation');
			}

			// We need to force route a case if it was previously closed and now opened
			if (!csRec.AllocateToQueue__c && changedFields.contains(Case.Status) && 
					!closedStatuses.contains(csRec.Status) && closedStatuses.contains(String.valueOf(previousState.get('Status'))) && 
					!excludedForceRoutingOnReopenQueues.contains(csRec.OwnerId)) {

				csRec.AllocateToQueue__c = true;

				// debug messaging to inform admin of routing path
				populateRoutingDebug(csRec, 'routing initiated: case reopened');
				
			}

			// case status was reset to New, so rerouting is triggered
			if(!csRec.AllocateToQueue__c && !isInsert && 
					changedFields.contains(Case.Status) && 'New'.equalsIgnoreCase(csRec.Status) && 
					(isCategoriesAndTypesPopulated(csRec) || isNotHlcAndCr(csRec))) {
				
				populateRoutingDebug(csRec, 'rerouting case moved to New');
				csRec.AllocateToQueue__c = true;

			}

			if( (csRec.Network__c == null && changedFields.contains(Case.Network__c)) ||
					(String.isBlank(csRec.Description) && changedFields.contains(Case.Description)) ||
					csRec.AllocateToQueue__c) { // && changedFields.contains(Case.AllocateToQueue__c) // HMM? Checking for changedFields for AllocateToQueue will not take into account changes to the field above
				
				setCaseKeyMap(csRec,caseOriginKeyMap,caseNoOriginKeyMap);   // set case key maps

				casesTobeRouted.add(csRec);
			}
		}

		if(!casesTobeRouted.isEmpty()){
			System.debug('casesTobeRouted--->'+casesTobeRouted+'<--oldMap-->'+oldMap);
			SSSW_Routing.assignCasesAndDescription(casesTobeRouted, oldMap, isInsert);
			System.debug('casesRouted--->'+casesTobeRouted+'<--oldMap-->'+oldMap);
		}

		// reset the recursion state to ensure changes we have made in the routing engine won't retrigger on next pass (if there is one)
		ApplicationRecursion.getInstance().updateRecordState(routingContext, routingChangedRecords, routingMonitoredFields);
	}

	/**
	 * When a case has been closed and it's in an omni queue, we need to move it to the closed omni cases queue
	 * This could happen anywhere, either a manual update to the ownerid field, workflow, or the result of the routing engine
	 * We put this logic outside the routing engine since we don't know where an update might occur
	 */
	@TestVisible
	private void maybeMoveClosedOmniCases(List<Case> caseList, Map<Id, Case> oldMap) {
		OmniChannelService omniService = OmniChannelService.getInstance();
		Set<String> closedStatuses = Utility.getCaseClosedStatus();
		String context = 'apccmaybemoveclosedomnicases';
		Set<SObjectField> monitoredFields = new Set<SObjectField>{Case.Status, Case.OwnerId};
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, caseList, oldMap, monitoredFields);

		for(ApplicationRecursion.RecordState recordState : changedRecords) {
			Case csRec = (Case)recordState.record;
			Set<SObjectField> changedFields = recordState.changedFields;
			Map<String, Object> previousState = recordState.previousState;

			// check if the owner was changed to an omni group or the status was changed and the case is closed
			// make sure the case does not stay in the omni queue
			if((changedFields.contains(Case.OwnerId) || 
						(changedFields.contains(Case.Status) && !closedStatuses.contains(String.valueOf(previousState.get('Status'))))) && 
					omniGroups.containsKey(csRec.OwnerId) &&
					closedStatuses.contains(csRec.Status)) {
				
				csRec.OwnerId = omniService.omniClosedCaseQueueId;

				// debug messaging to inform admin of routing path
				populateRoutingDebug(csRec, 'owner reset to closed queue');

			}
		}

		// reset the recursion state to ensure changes we have made in the routing engine won't retrigger on next pass (if there is one)
		ApplicationRecursion.getInstance().updateRecordState(context, changedRecords, monitoredFields);
	}

	/**
	 * When a case changes owner and the new owner is an omni queue or when a case is newly closed
	 * We need to make sure there are no preferred agent psr records that still exist
	 * This scenario could be either where a case may have been sitting in the preferred agent queue and expired and moved back into an omni queue or its simply just been updated to closed
	 */
	@TestVisible
	private void maybeRemovePendingServiceRoutingPreferredAgentRecords(List<Case> caseList, Map<Id, Case> oldMap, Boolean isInsert) {
		if(!isInsert) {
			OmniChannelService omniService = OmniChannelService.getInstance();
			Set<String> closedCaseStatuses = Utility.getCaseClosedStatus();
			Map<Id, Case> processableCases = new Map<Id, Case>();
			Map<Id, String> psrRemovalReason = new Map<Id, String>();
			String context = 'apccmaybeRemovePendingServiceRoutingPreferredAgentRecords';
			Set<SObjectField> monitoredFields = new Set<SObjectField>{Case.OwnerId, Case.Status};
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, caseList, oldMap, monitoredFields);
	
			for(ApplicationRecursion.RecordState recordState : changedRecords) {
				Case csRec = (Case)recordState.record;
				Set<SObjectField> changedFields = recordState.changedFields;
				Map<String, Object> previousState = recordState.previousState;

				if(changedFields.contains(Case.OwnerId) && csRec.OwnerId != omniService.preferredAgentQueueId) {
					// if the owner is not preferred agent queue then we need to make sure we tidy up any PSR records for preferred agent routing that have manually been created
					//	Scenarios:
					//		1. Owner is manually updated
					//		2. Case is pushed to sometype of holding/closed queue from PAR queue
					//		3. Case is reassigned
					//		4. Case is overtaken in some way
					// NOTE: Important!!!! When Omni channel first attempts a push to a user, the OwnerId field is updated but the Case/AgentWork/PendingServiceRouting triggers are NOT fired
					//						In this scenario, this block is NEVER hit!
					processableCases.put(csRec.Id, csRec);
					psrRemovalReason.put(csRec.Id, 'owner changed');
				} else if(changedFields.contains(Case.Status) && closedCaseStatuses.contains(csRec.Status) && !closedCaseStatuses.contains(String.valueOf(previousState.get('Status')))) {
					processableCases.put(csRec.Id, csRec);
					psrRemovalReason.put(csRec.Id, 'case was closed');
				}
			}

			if(!processableCases.isEmpty()) {

				// TODO confirm, does this need to go into without sharing????
				List<PendingServiceRouting> preferredAgentPSRs = PendingServiceRoutingSelector.newInstance(0, new Set<SObjectField>{PendingServiceRouting.Id, PendingServiceRouting.WorkItemId}).search(new Map<String, Object>{
					'workItemIds' => processableCases.keySet(),
					'isPreferredUserRequiredOnly' => true
				}, true);

				if(!preferredAgentPSRs.isEmpty()) {
					WithoutSharingDataAccessHelper innerClassWithoutSharing = new WithoutSharingDataAccessHelper();
					innerClassWithoutSharing.deletePSRs(preferredAgentPSRs); // execute DMLs for system objects in without sharing context

					for(PendingServiceRouting preferredAgentPSR : preferredAgentPSRs) {
						// debug messaging to inform admin of routing path
						populateRoutingDebug(processableCases.get(preferredAgentPSR.WorkItemId), 'PAR psr removed: ' + psrRemovalReason.get(preferredAgentPSR.WorkItemId));
					}
				}

			}

			// reset the recursion state to ensure changes we have made in the routing engine won't retrigger on next pass (if there is one)
			ApplicationRecursion.getInstance().updateRecordState(context, changedRecords, monitoredFields);
			
		}
	}

	/**
	 * If the case belongs to an omni queue after routing has finished, then we need to calculate the secondary priroty to ensure Omni handles the prioritisation properly
	 */
	@TestVisible
	private void maybeRecalculateSecondaryRoutingPriority(List<Case> caseList, Map<Id, Case> oldMap) {
		List<Case> recalcPriorityCases = new List<Case>();
		String priorityContext = 'ssswroutecasepriority';
		Set<SObjectField> routingPriorityMonitoredFields = new Set<SObjectField>{Case.OwnerId, Case.Priority};
		List<ApplicationRecursion.RecordState> routingPriorityChangedRecords = ApplicationRecursion.getInstance().getProcessableRecords(priorityContext, caseList, oldMap, routingPriorityMonitoredFields);

		for(ApplicationRecursion.RecordState recordState : routingPriorityChangedRecords){
			Case csRec = (Case)recordState.record;
			Set<SObjectField> changedFields = recordState.changedFields;
			Map<String, Object> previousState = recordState.previousState;	// get old values of case

			if(OmniChannelService.Cache.queuesWithRoutingConfig.containsKey(csRec.OwnerId)) {
				recalcPriorityCases.add(csRec);
			}

		}

		if(!recalcPriorityCases.isEmpty()) {
			OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(recalcPriorityCases, oldMap == null ? true : false);
		}

		// reset the recursion state to ensure changes we have made in the routing engine won't retrigger on next pass (if there is one)
		ApplicationRecursion.getInstance().updateRecordState(priorityContext, routingPriorityChangedRecords, routingPriorityMonitoredFields);
	}

	/**
	 * Checks to see if we need to override the current owner with preferred agent routing
	 * This would be if the current owner that was just assigned was an omni queue and we aren't bypassing preferred agent routing
	 */
	@TestVisible
	private void maybeOverrideWithPreferredAgentRouting(List<Case> caseList, Map<Id, Case> oldMap) {
		Set<String> closedStatuses = Utility.getCaseClosedStatus();

		//The logic below is positioned here instead of in a Domain Module to keep all logic related Case Owner in one place and in the same sequence in Apex execution
		//Placed after the routing engine to ensure the to-be Queue is available for the logic below
		Map<Id,Case> casesPreferredAgentRouting = new Map<Id,Case>();
		String context = 'ssswpreferredagentroutingcases';
		Set<SObjectField> monitoredFields = new Set<SObjectField>{Case.OwnerId, Case.Status};
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, caseList, oldMap, monitoredFields);
		
		for(ApplicationRecursion.RecordState recordState : changedRecords){
			Case csRec = (Case)recordState.record;
			Set<SObjectField> changedFields = recordState.changedFields;

			// get previous state of record from last run
			Map<String, Object> previousState = recordState.previousState;
				
			Case oldCase = oldMap != null ? oldMap.get(csRec.Id) : null;	// get old values of case		

			//Move eligible Closed Cases to the SSSW Closed Omni Queue
			if(oldCase != null && //mean this is not an insert scenario
					changedFields.contains(Case.OwnerId) && // owner was changed in this
					omniGroups.containsKey(csRec.OwnerId) //&& // the new queue is an omni managed queue (this can be overriden with preferred agent routing if needed)
					// //!OmniChannelService.Cache.queuesWithRoutingConfig.containsKey((Id)previousState.get('OwnerId')) && // if the previous owner
					// csRec.BypassPreferredAgent__c == false &&
					// csRec.PreferredAgentExpiry__c != null && csRec.PreferredAgentExpiry__c > Datetime.now()
					) {
			
				if(closedStatuses.contains(csRec.Status)) {
					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'preferred agent bypassed: case is already closed');
				} else if(csRec.BypassPreferredAgent__c == false && csRec.PreferredAgentExpiry__c != null && csRec.PreferredAgentExpiry__c > Datetime.now()) {
					// only allow a case to be overrriden since it's still open, and the preferred agent timeout hasn't expired
					casesPreferredAgentRouting.put(csRec.Id, csRec); 
				} else if(csRec.BypassPreferredAgent__c == true || (csRec.PreferredAgentExpiry__c != null && csRec.PreferredAgentExpiry__c < Datetime.now())) {
					// debug messaging to inform admin of routing path
					populateRoutingDebug(csRec, 'preferred agent bypassed: bypass: ' + String.valueOf(csRec.BypassPreferredAgent__c) + ': expired: ' + String.valueOf(csRec.PreferredAgentExpiry__c < Datetime.now()));
				}
			}
		}

		if(casesPreferredAgentRouting.isEmpty() == false) {
			processPreferredAgent(casesPreferredAgentRouting); 
		}

		// reset the recursion state to ensure changes we have made in the routing engine won't retrigger on next pass (if there is one)
		ApplicationRecursion.getInstance().updateRecordState(context, changedRecords, monitoredFields);
	}

	/**
	 * When case moves out of the preferred agent queue, we need to reset the preferred agent settings to get it ready for next time it might be needed
	 * NOTE: There are some exceptions to this, like if the case subsuquently is assigned to the routing holding queue.
	 * Additionally, when a case is closed we also remove the bypass settings
	 */
	@TestVisible
	private void maybeResetPreferredAgentBypasses(List<Case> caseList, Map<Id, Case> oldMap) {
		OmniChannelService omniService = OmniChannelService.getInstance();

		Set<String> closedCaseStatuses = Utility.getCaseClosedStatus();
		String context = 'apccresetpreferredagent';
		Set<SObjectField> monitoredFields = new Set<SObjectField>{Case.OwnerId, Case.Status};
		List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, caseList, oldMap, monitoredFields);

		Set<Id> excludedQueuesForByPassReset = new Set<Id>{
			omniService.preferredAgentQueueId,
			omniService.omniHoldingQueueId
		};
		
		for(ApplicationRecursion.RecordState recordState : changedRecords){
			Case csRec = (Case)recordState.record;
			Set<SObjectField> changedFields = recordState.changedFields;

			// get previous state of record from last run
			Map<String, Object> previousState = recordState.previousState;

			// (changedFields.contains(Case.OwnerId) && csRec.OwnerId.getSobjectType() == User.getSObjectType() && 
			// 			previousState.get('OwnerId') != null && ((Id)previousState.get('OwnerId')).getSobjectType() == Group.getSobjectType()) ||

			if((changedFields.contains(Case.OwnerId) && (Id)previousState.get('OwnerId') == omniService.preferredAgentQueueId && !excludedQueuesForByPassReset.contains(csRec.OwnerId)) ||
						(changedFields.contains(Case.Status) && closedCaseStatuses.contains(csRec.Status) && !closedCaseStatuses.contains(String.valueOf(previousState.get('Status')))
					)) {

				csRec.BypassPreferredAgent__c = false;
				csRec.PreferredAgentExpiry__c = null;
			}
		}

		// reset the recursion state to ensure changes we have made in the routing engine won't retrigger on next pass (if there is one)
		ApplicationRecursion.getInstance().updateRecordState(context, changedRecords, monitoredFields);
	}

	/**
	 * @description	   This method returns the sssw routing records for the case combination
	* @param			 caseKeys - Set<String>
	* @return			Map<String,SSSWRouting__c>
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	//  private static Map<String,SSSWRouting__c> getSSSWRoutings(Set<String> caseKeys){
	//	 Map<String,SSSWRouting__c> routingMap = new Map<String,SSSWRouting__c>();
	//	 Integer rowLimit = (Limits.getLimitQueryRows() - Limits.getQueryRows());	// get dynamic query row limit
	//	 for(SSSWRouting__c routing : [SELECT Network__c,CaseKey__c,ExcludeFromNPS__c,DefaultCaseDetails__c,Queue_ID__c,AutoEscalate__c
	//									 FROM SSSWRouting__c WHERE CaseKey__c IN: caseKeys ORDER BY CaseKey__c LIMIT : rowLimit]){
	//		 routingMap.put(routing.CaseKey__c,routing);
	//	 }
	//	 return routingMap;
	// } 

	/**
	 * @description	   This method checked the child case for 'Network Responded' and 'Customer Responded' and updated the
						parent status to 'child case updated' and again runs it to route - set 'allocate to queue' flag
	* @param			 (List<Case> childCases
	* @return			NA
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	@TestVisible
	public void updateParentForRouting(List<Case> childCases, Map<Id,Case> oldMapCases){
		try {
			// Listing of the variables we're monitoring for change
			List<Case> parentCaseUpd = new List<Case>();
			OmniChannelService omniService = OmniChannelService.getInstance();
			Set<String> closedCaseStatuses = Utility.getCaseClosedStatus();
			String context = 'ssswparentroutingupdatecontext';
			Set<SObjectField> monitoredFields = new Set<SObjectField>{Case.Status};
			List<ApplicationRecursion.RecordState> changedRecords = ApplicationRecursion.getInstance().getProcessableRecords(context, childCases, oldMapCases, monitoredFields);
			
			for(ApplicationRecursion.RecordState recordState : changedRecords) {
				Case csRec = (Case)recordState.record;
				Set<SObjectField> changedFields = recordState.changedFields;

				// get previous state of record from last run
				Map<String, Object> previousState = recordState.previousState;

				if(csRec.ParentId != null && (changedFields.contains(Case.Status) && (SSSWConstants.STAT_NETWORK_RESPONDED.equalsIgnoreCase(csRec.Status) || 
																						SSSWConstants.STAT_CUSTOMER_RESPONDED.equalsIgnoreCase(csRec.Status)))) {
					
					//if yes, update the parent and send for routing
					parentCaseUpd.add(new Case(Id = csRec.ParentId, Status = SSSWConstants.STAT_CHILD_CASE_UPDATE, AllocateToQueue__c = true));

				}
			}

			if(!parentCaseUpd.isEmpty()) {
				//if any parent cases avaialable, update them.
				ApplicationDatabase.getInstance().dmlUpdate(parentCaseUpd);
			}

			//NOTE: This is not needed here since we aren't updating the status of the current case (and that is the only field we are monitoring)
			// reset the recursion state to ensure changes we have made won't retrigger on next pass (if there is one)
			//ApplicationRecursion.getInstance().updateRecordState(preferredAgentRoutingContext, preferredAgentRoutingChangedRecords, preferredAgentRoutingMonitoredFields);

		}
		catch(Exception exp) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP,
													CaseRoutingService.class.getName(), SSSWConstants.METH_PARENT_ROUTING,
													SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * Checks if Case ProductCategory__c, ProductSubCategory__c, EnquirySubType__c, Type are populated
	 *
	 * @param newCase Updated Case coming to Trigger
	 *
	 * @return if ALL of them have a value
	 */
	private Boolean isCategoriesAndTypesPopulated(Case newCase){
		return (!(newCase.ProductCategory__c == '' || newCase.ProductCategory__c == null ) &&
				!(newCase.ProductSubCategory__c == '' || newCase.ProductSubCategory__c == null) &&
				!(newCase.EnquirySubType__c == '' || newCase.EnquirySubType__c == null) &&
				!(newCase.Type == '' || newCase.Type == null));
	}

	/**
	 * Checks if not a High Level Complaints Case and neither a Customer Recovery Case
	 *
	 * @param newCase Updated Case coming to Trigger
	 *
	 * @return if ALL of them are false
	 */
	private Boolean isNotHlcAndCr(Case newCase){
		return ((!newCase.IsHLC__c || newCase.IsHLC__c == null) &&
				(!newCase.IsCR__c || newCase.IsCR__c == null));
	}

	/**
	 * @description	   This method sets key value pair of case & routing key
	* @param			 csRec - Case, caseOriginKeyMap - Map<Id,String>, caseNoOriginKeyMap - Map<Id,String>
	* @return			void
	* @throws			Method might throw exception which is handled by Try-Catch block
	*/
	private void setCaseKeyMap(Case csRec,Map<Id,String> caseOriginKeyMap,Map<Id,String> caseNoOriginKeyMap){
		String keyWithOrigin = SSSWConstants.EMPTY_SPACE ;
		String keyWithOutOrigin = SSSWConstants.EMPTY_SPACE ;
		keyWithOrigin = String.isNotBlank(csRec.ProductCategory__c) ? (keyWithOrigin + csRec.ProductCategory__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(csRec.ProductSubCategory__c) ? (keyWithOrigin + csRec.ProductSubCategory__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(csRec.Type) ? (keyWithOrigin + csRec.Type) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(csRec.EnquirySubType__c) ? (keyWithOrigin + csRec.EnquirySubType__c) : keyWithOrigin;
		keyWithOrigin = String.isNotBlank(csRec.Customer_Type__c) ? (keyWithOrigin + csRec.Customer_Type__c) : keyWithOrigin;
		keyWithOrigin = (csRec.IsNewForRouting__c != null && csRec.IsNewForRouting__c) ?
							(keyWithOrigin + ROUTING_TRUE) : (keyWithOrigin + ROUTING_FALSE);

		keyWithOutOrigin = keyWithOrigin ;

		keyWithOrigin = String.isNotBlank(csRec.Origin) ? (keyWithOrigin + csRec.Origin) : keyWithOrigin;

		caseOriginKeyMap.put(csRec.Id,keyWithOrigin);
		caseNoOriginKeyMap.put(csRec.Id,keyWithOutOrigin);
	}

	public void populateRoutingDebug(Case caseRecord, String debugMessage) {
		populateRoutingDebug(caseRecord, debugMessage, false);
	}

	public void populateRoutingDebug(Case caseRecord, String debugMessage, Boolean overrideValue) {
		debugMessage = Datetime.now().formatGMT('YYYY-MM-dd HH:mm:ss') + ': ' + debugMessage;
		if(!overrideValue) {
			debugMessage += (!String.isEmpty(caseRecord.Comment__c) ? '\n' + caseRecord.Comment__c : '');
		}
		caseRecord.Comment__c = debugMessage.left(2048);
	}

	/*
	* Generate a PendingServiceRouting record with the PreferredUserId value set to a previous User, based on the Case's existing AgentWork records.
	* All the cases entering this method are in Omni queues and are eligible for Preferred agent (assuming a valid agent is available)
	* The Case's AgentWork record must have been accepted and have an active User as a final criteria before PSRs are generated
	* Cases are assigned to a Queue without a Routing Configuration to allow PendingServiceRouting to be inserted and not overridden by Salesforce.
	*/
	@TestVisible
	private void processPreferredAgent(Map<Id,Case> casesPreferredAgentRouting) {

		OmniChannelService omniService = OmniChannelService.getInstance();

		Map<Id, AgentWork> caseIdsVsAgentWorks = omniService.getCaseIdsWithLatestAcceptedAgentWorks(casesPreferredAgentRouting.keySet());
		Set<Id> userIds = new Set<Id>();
		for(AgentWork aw: caseIdsVsAgentWorks.values()) {
			userIds.add(aw.UserId);
		}

		Set<Id> qualifiedAsPreferredAgentUserIds = omniService.getUserIdsWithPreferredAgentSkills(userIds);

		// loop through to get all the eligible cases and check whether there is an existing PSR record 
		// we may need to delete it since there can only ever be a single PSR record
		Map<Id, Id> casesWithPSRRecord = new Map<Id, Id>();
		List<PendingServiceRouting> existingPSRRecords = PendingServiceRoutingSelector.newInstance(0, new Set<SObjectField>{PendingServiceRouting.Id, PendingServiceRouting.WorkItemId}).selectByWorkItemId(casesPreferredAgentRouting.keySet(), new Set<Object>());
		for(PendingServiceRouting psrRecord : existingPSRRecords) {
			casesWithPSRRecord.put(psrRecord.WorkItemId, psrRecord.Id);
		}

		if(caseIdsVsAgentWorks.isEmpty() == false) {

			ServiceChannel sc = OmniChannelService.Cache.serviceChannels.get('Case_Channel');
			List<PendingServiceRouting> newPSRs = new List<PendingServiceRouting>();
			List<PendingServiceRouting> deletablePSRs = new List<PendingServiceRouting>();

			for(Case csRec : casesPreferredAgentRouting.values()) {
				// check if there is an AgentWork record AND if the user of the agent work qualifies for Preferred Agent assignment

				if(caseIdsVsAgentWorks.containsKey(csRec.Id) == true && qualifiedAsPreferredAgentUserIds.contains(caseIdsVsAgentWorks.get(csRec.Id).UserId) == true) {
					
					//use the routing configuration of the Omni queue the Case was being routed to
					QueueRoutingConfig routingConfiguration = OmniChannelService.Cache.queuesWithRoutingConfig.get(csRec.OwnerId).routingConfiguration; 

					//PushTimeout cannot be set when IsPreferredUserRequired is set
					newPSRs.add(new PendingServiceRouting(
						PreferredUserId = caseIdsVsAgentWorks.get(csRec.Id).UserId,
						IsPreferredUserRequired = true,
						CapacityPercentage = routingConfiguration.CapacityPercentage, 
						CapacityWeight = routingConfiguration.CapacityWeight, 
						DropAdditionalSkillsTimeout = routingConfiguration.DropAdditionalSkillsTimeout,
						RoutingModel = routingConfiguration.RoutingModel, 
						RoutingPriority = routingConfiguration.RoutingPriority, 
						CustomRequestedDateTime = csRec.CreatedDate, 
						WorkItemId = csRec.Id,
						IsReadyForRouting = true,
						RoutingType = 'SkillsBased', 
						ServiceChannelId = sc.Id,
						SecondaryRoutingPriority = OmniChannelService.getInstance().calculateSecondaryPriority(csRec.Priority, csRec.CreatedDate) //TODO:.... map from Service Channel config... good luck! SF stores the mapping as value index on the selected field (e.g. picklist values)
					));

					if(casesWithPSRRecord.get(csRec.Id) != null) {
						deletablePSRs.add(new PendingServiceRouting(Id = casesWithPSRRecord.get(csRec.Id)));
					}
					
				}
			}

			if(newPSRs.isEmpty() == false) {
				WithoutSharingDataAccessHelper innerClassWithoutSharing = new WithoutSharingDataAccessHelper();
				innerClassWithoutSharing.processPendingServiceRoutingRecords(newPSRs, deletablePSRs, casesPreferredAgentRouting); // execute DMLs for system objects in without sharing context	
			}
		}
	}

	/**
	 * Private inner class that elevates access privileges of the current user to query data and perform DMLs without being limited by
	 * sharing settings.
	 *
	 * IMPORTANT: Not intended for general use. Only for handling special scenarios where it is necessary to query data beyond
	 *			what the current user is allowed to see as per sharing.
	*			E.g. : Public Guest users submitting a case should be linked to existing contacts matching the email address on case.
	*/
	private without sharing class WithoutSharingDataAccessHelper {

		/**
		 * Insert PendingServiceRouting in a without sharing context - it is best practice to perform DML on system objects in this context 
		 *
		 * @param newPSRs list of PendingServiceRouting records to insert
		 * @param casesPreferredAgentRouting map of Case Ids and Case object that the PendingServiceRouting records are related to 
		 *
		 * @return Void
		 */
		private void processPendingServiceRoutingRecords(List<PendingServiceRouting> newPSRs, List<PendingServiceRouting> deletablePSRs, Map<Id,Case> casesPreferredAgentRouting){

			// we need to first delete 
			List<Database.DeleteResult> deletedList;
			if(!deletablePSRs.isEmpty()) {
				deletedList = ApplicationDatabase.getInstance().dmlDelete(deletablePSRs, false);	
			}

			// allow partial success for the insert, as some PSR insert may fail if a Case has an existing PSR already e.g. another inserted PSR has not been deleted
			List<Database.SaveResult> srList = ApplicationDatabase.getInstance().dmlInsert(newPSRs, false);
				
			if(srList.isEmpty() == false){
				for(Integer i=0;i<srList.size();i++){
					Database.SaveResult sr = srList.get(i);

					// assign the Case of successful PSRs to the Preferred Agent queue
					if (sr.isSuccess()){
						for(PendingServiceRouting newPSR : newPSRs){ 
							if(newPSR.Id != null && newPSR.Id == sr.getId()){
								casesPreferredAgentRouting.get(newPSR.WorkItemId).OwnerId = OmniChannelService.getInstance().preferredAgentQueueId; 
								// debug messaging to inform admin of routing path
								CaseRoutingService.getInstance().populateRoutingDebug(casesPreferredAgentRouting.get(newPSR.WorkItemId), 'preferred agent queue assigned');
							} else {
								// debug messaging to inform admin of routing path
								CaseRoutingService.getInstance().populateRoutingDebug(casesPreferredAgentRouting.get(newPSR.WorkItemId), 'preferred agent psr creation failed! there may not be a PSR record anymore!');
							}						
						}
					} else {
						for (Database.Error err : sr.getErrors()) {	
							System.debug('The following error has occurred on the DML Retry.');
							System.debug(err.getStatusCode() + ': ' + err.getMessage());
						}
					}					
				}		
				
				if(!deletablePSRs.isEmpty()) {
					// log any failed deleted to ensure we can monitor save errors (especially for checking routing failures)
					ApplicationLogger.getInstance().logFailedDatabaseResults(deletedList, SSSWConstants.SSSW_APP, CaseRoutingService.class.getName(), 'processPreferredAgent', '', ApplicationLogger.LoggingLevel.ERROR);
				}

				// log any failed inserts to ensure we can monitor save errors (especially for checking routing failures)
				ApplicationLogger.getInstance().logFailedDatabaseResults(srList, SSSWConstants.SSSW_APP, CaseRoutingService.class.getName(), 'processPreferredAgent', '', ApplicationLogger.LoggingLevel.ERROR);
			}	
		}

		private void deletePSRs(List<PendingServiceRouting> psrRecords) {
			List<Database.DeleteResult> deletedList = ApplicationDatabase.getInstance().dmlDelete(psrRecords, false);
			
			// log any failed deleted to ensure we can monitor save errors (especially for checking routing failures)
			ApplicationLogger.getInstance().logFailedDatabaseResults(deletedList, SSSWConstants.SSSW_APP, CaseRoutingService.class.getName(), 'deletePSRs', '', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

}