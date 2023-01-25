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
 * 2023-01-25	Noel Lim		Updated - add filtering logic to SSSW and StarTrack recordtypes only
 */

public inherited sharing class CaseOmniRoutingModule extends ApplicationDomain.Module  {

	private static Set<Id> validSSSWRecTypes;


	private Set<Id> ssswRecordTypeIds {
		get {
			if(ssswRecordTypeIds == null){
				ssswRecordTypeIds =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
			}
			return ssswRecordTypeIds;
		}
		private set;
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
			List<Case> validCases = new List<Case>();
			
			for(Case c : (List<Case>) filterToStarTrackOrSSSWCases(records)) {
				if(omniQueues.containsKey(c.OwnerId) == true && String.isBlank(c.Priority) == false) {
					validCases.add(c);
				}
			}
			OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(validCases, true);

		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CaseOmniRoutingModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			Map<Id, Case> oldCases = (Map<Id, Case>)existingRecords;
			List<Case> validCases = new List<Case>();
			for(Case c : (List<Case>) filterToStarTrackOrSSSWCases(records)) {
				// take only cases that have gone to an Omni Queue or have changed priority. 
				if(omniQueues.containsKey(c.OwnerId) == true && (c.OwnerId != oldCases.get(c.Id).OwnerId || c.Priority != oldCases.get(c.Id).Priority)) {
					validCases.add(c);
				}
			}		
			OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(validCases, false);

		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CaseOmniRoutingModule.class.getName(), 'onBeforeUpdate', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/*
	 * This method returns a list of Case records that are related to StarTrack or SSSW
	 * @param caseRecords the list of Cases to filter to SSSW only
	 */
	private List<SObject> filterToStarTrackOrSSSWCases(List<SObject> caseRecords){
		List<SObject> filteredCases = new List<SObject>();
		
		for (Case c : (List<Case>) caseRecords) {
			if(Utility.isValidRecordType(ssswRecordTypeIds,c.RecordTypeId) || c.StarTrack_RecordType__c){
				filteredCases.add(c);				
			}				
		}

		return filteredCases;
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

}