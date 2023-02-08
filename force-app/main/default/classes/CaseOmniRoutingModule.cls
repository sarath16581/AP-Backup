/*** 
 * @description
 * This is related to SSSW and StarTrack cases.
 * a) Updates the value of OmniRoutingSecondaryPriority field for cases that are assigned or routed to an Omni queue.
 * b) Assign Case to Preferred Agent. For Cases moving from a non-Omni to an Omni Queue, generate a PendingServiceRouting with a Preferred User if Case has existing AgentWork
 * c) Clears PSRs that were manually inserted for Preferred Agent 
 * d) Reset a Case flag BypassPreferredAgent
 * 
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * 
 * @author George Nguyen
 * @date 2022-10-30
 * @group Domain
 * @domain Routing 
 * @changelog
 * 2022-10-30	George Nguyen	Created
 * 2022-12-06 - Noel Lim 		Added method assignToPreferredAgent
 * 2022-12-21 - George Nguyen	Added method resetBypassPreferredAgentFlag
 * 2023-01-25	Noel Lim		Added method filterToApplicableCase
 * 2023-02-06	Noel Lim		Added method clearPreferredAgentPSRs 
 */

public inherited sharing class CaseOmniRoutingModule extends ApplicationDomain.Module  {

	private static Set<Id> allValidRecordTypes{
		get {
			if(allValidRecordTypes == null){
				allValidRecordTypes = new Set<Id>();
				allValidRecordTypes.addAll(new RecordTypesSelector().selectByDeveloperNameLike('Case', 'SSSW').keySet());
				allValidRecordTypes.addAll(new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack').keySet());
			}
			return allValidRecordTypes;
		}
		private set;
	}

	private Map<Id, Group> omniQueues {
		get {
			if(omniQueues == null) {
				omniQueues = GroupsSelector.newInstance().selectOmniQueues(new Set<Object>());
			}
			return omniQueues;
		}
		set;
	}
	
	public static CaseOmniRoutingModule newInstance() {
		return (CaseOmniRoutingModule)Application.Utilities.newInstance(CaseOmniRoutingModule.class);
	}

	// Setup which triggers this module should respond to
	public CaseOmniRoutingModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			List<Case> ssswOrStartrackCasesOnly = filterToApplicableCases((List<Case>) records);
			setOmniRoutingSecondaryPriority(ssswOrStartrackCasesOnly, null, uow);
			
		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CaseOmniRoutingModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			List<Case> ssswOrStartrackCasesOnly = filterToApplicableCases((List<Case>) records);
			setOmniRoutingSecondaryPriority(ssswOrStartrackCasesOnly, (Map<Id, Case>)existingRecords, uow);

			clearPreferredAgentPSRs(ssswOrStartrackCasesOnly, (Map<Id, Case>)existingRecords, uow);
			assignToPreferredAgent(ssswOrStartrackCasesOnly, (Map<Id, Case>)existingRecords, uow);
			resetBypassPreferredAgentFlag(ssswOrStartrackCasesOnly, (Map<Id, Case>)existingRecords, uow);

		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CaseOmniRoutingModule.class.getName(), 'onBeforeUpdate', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
	 * This method assigns a secondary routing priority value to the Case when it is assigned to an Omni queue
	 */
	private void setOmniRoutingSecondaryPriority(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){

		List<Case> validCases = new List<Case>();

		for(Case c : records) {
			// take only cases that have gone to an Omni Queue or have changed priority. 
			if(omniQueues.containsKey(c.OwnerId) == true && 
				((existingRecords == null && String.isBlank(c.Priority) == false) || 
				(existingRecords != null && 
					(c.OwnerId != existingRecords.get(c.Id).OwnerId || c.Priority != existingRecords.get(c.Id).Priority)))
			) {
				validCases.add(c);
			}
		}	
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(validCases, existingRecords == null ? true : false);
	}

	/*
	 * This method clears PSRs that were manually inserted for Preferred Agent when the Case is being assigned from the Preferred Agent Routing queue
	 */
	private void clearPreferredAgentPSRs(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){

		Id preferredAgentQueueId = OmniChannelService.getInstance().preferredAgentQueueId;
		Map<Id,Case> casesToCheck = new Map<Id,Case>();

		for(Case c : records) {
			// take only cases that have gone to an Omni Queue or have changed priority. 
			if(existingRecords.get(c.Id).OwnerId == preferredAgentQueueId &&
				c.OwnerId != preferredAgentQueueId){
				casesToCheck.put(c.Id, c);
			}
		}	
		
		if(casesToCheck.isEmpty() == false){
			List<PendingServiceRouting> deletablePsrRecords = new List<PendingServiceRouting>();
			List<PendingServiceRouting> psrRecords = PendingServiceRoutingSelector.newInstance().selectByWorkItemId(casesToCheck.keySet(), new Set<Object>());


			// check which psr records can actually deleted
			// we only want to do that if it hasn't already been pushed.
			// if it has been pushed then it's too late for us to do anything about and we need to let Omni do it's thing
			for(PendingServiceRouting psrRecord : psrRecords) {
				if(psrRecord.IsPushed == false
					&& psrRecord.IsPushAttempted == false) {
						deletablePsrRecords.add(psrRecord);
					}
			} 

			// remove all existing psr records for the work items here since we are creating new ones
			if(!deletablePsrRecords.isEmpty()) {
				uow.registerDeleted(deletablePsrRecords);
			}	
		}		
	}

	/*
	 * This method resets the Bypass Preferred Agent flag on the case if the owner on the case changed from a Queue to a User. 
	 */
	private void resetBypassPreferredAgentFlag(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){
		for(Case c: records) {
			if(c.OwnerId.getSobjectType() == User.getSObjectType() && existingRecords.get(c.Id).OwnerId.getSobjectType() == Group.getSobjectType()) {
				c.BypassPreferredAgent__c = false;
			}
		}
	}

	/*
	 * This method manually generates a PendingServiceRouting record to route a Case directly to an agent.
	 * It is done for Cases being routed to a Queue with a Routing Configuration (referred to as an Omni Queue), and the Case has an AgentWork that is accepted and an active User.
	 * Cases are moved to a Queue without a Routing Configuration to allow PendingServiceRouting to be inserted and not overridden by Salesforce.
	 * 
	 * @param records the list of updated or new records from the trigger.
	 * @param existingRecords a Map of the pre-update records from the trigger. 
	 * @param uow instance of UnitOfWork to flag records for DML operations
	 */
	private void assignToPreferredAgent(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){
		
		Id preferredAgentQueueId = OmniChannelService.getInstance().preferredAgentQueueId;
		if(String.isEmpty(preferredAgentQueueId) == false ) {

			Map<Id, Case> validCases = new Map<Id, Case>(); 	

			for (Case c : records) {

				Case oldCase = existingRecords?.get(c.Id);	

				if(c.BypassPreferredAgent__c == false 
					&& oldCase != null 
					&& c.OwnerId != oldCase.OwnerId
					&& c.PreferredAgentExpiry__c != null // this is set by the routing engine
					&& OmniChannelService.Cache.queuesWithRoutingConfig.containsKey(oldCase.OwnerId) == false // only consider if previous owner is not omni
					&& OmniChannelService.Cache.queuesWithRoutingConfig.containsKey(c.OwnerId) == true // omni queue check
				){
					validCases.put(c.Id, c);
				}
			}

			if(validCases.isEmpty() == false) {
				
				Map<Id, AgentWork> caseIdsVsAgentWorks = OmniChannelService.getInstance().getLatestAcceptedAgentWorkWithActiveUser(validCases.keySet());

				if(caseIdsVsAgentWorks.isEmpty() == false) {

					ServiceChannel sc = OmniChannelService.Cache.serviceChannels.get('Case_Channel');
					List<PendingServiceRouting> newPSRs = new List<PendingServiceRouting>();	

					for(Case csRec : validCases.values()) {
						if(caseIdsVsAgentWorks.containsKey(csRec.Id) == true) {
							
							//use the routing configuration of the Omni queue the Case was being routed to
							QueueRoutingConfig routingConfiguration = OmniChannelService.Cache.queuesWithRoutingConfig.get(csRec.OwnerId).routingConfiguration; 
							
							csRec.OwnerId = preferredAgentQueueId;

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
								SecondaryRoutingPriority = OmniChannelService.priorityMappingToSecondaryPriorityRange.get(csRec.Priority) //TODO:.... map from Service Channel config... good luck! SF stores the mapping as value index on the selected field (e.g. picklist values)
							));
						}
					}

					if(newPSRs.isEmpty() == false) {
						uow.registerNew(newPSRs);
					}
				}
			}
		}
	}

	/*
	 * This method returns a list of Case records that are related to StarTrack or SSSW
	 * @param caseRecords the list of Cases to filter
	 */
	private List<Case> filterToApplicableCases(List<Case> caseRecords){
		List<Case> filteredCases = new List<Case>();		
		
		for (Case c : caseRecords) {
			if(allValidRecordTypes.contains(c.RecordTypeId)){
				filteredCases.add(c);		
			}				
		}

		return filteredCases;
	}

}