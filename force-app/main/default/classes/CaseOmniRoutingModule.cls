/*** 
 * @description
 * Updates the value of OmniRoutingSecondaryPriority field for cases that are assigned or routed to an Omni queue.
 * This is related to SSSW and StarTrack cases.
 * 
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * 
 * @author George Nguyen
 * @date 2022-10-30
 * @group Domain
 * @domain Routing 
 * @changelog
 * 2022-10-30	George Nguyen	Created
 * 2023-01-25	Noel Lim		Updated - added filterToApplicableCases() to filter to SSSW and StarTrack recordtypes only
 * 2023-02-06	Noel Lim		Updated - added clearPreferredAgentPSRs() to clear PSRs that were manually inserted for Preferred Agent 
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