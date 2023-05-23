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
 * 2022-12-21	George Nguyen	Added method resetBypassPreferredAgentFlag
 * 2023-01-25	Noel Lim		Added method filterToApplicableCase
 * 2023-02-06	Noel Lim		Added method deletePSRsForCasesNotInPreferredAgentQueue 
 */

public inherited sharing class CaseOmniRoutingModule extends ApplicationDomain.Module  {

	// private static Set<Id> allSSSWOrStartrackRecordTypes{
	// 	get {
	// 		if(allSSSWOrStartrackRecordTypes == null){
	// 			allSSSWOrStartrackRecordTypes = new Set<Id>();
	// 			allSSSWOrStartrackRecordTypes.addAll(new RecordTypesSelector().selectByDeveloperNameLike('Case', 'SSSW').keySet());
	// 			allSSSWOrStartrackRecordTypes.addAll(new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack').keySet());
	// 		}
	// 		return allSSSWOrStartrackRecordTypes;
	// 	}
	// 	private set;
	// }

	// private static Set<Id> allSSSWRecordTypes{
	// 	get {
	// 		if(allSSSWRecordTypes == null){
	// 			allSSSWRecordTypes = new Set<Id>();
	// 			allSSSWRecordTypes.addAll(new RecordTypesSelector().selectByDeveloperNameLike('Case', 'SSSW').keySet());
	// 		}
	// 		return allSSSWRecordTypes;
	// 	}
	// 	private set;
	// }

	// private Map<Id, Group> omniQueues {
	// 	get {
	// 		if(omniQueues == null) {
	// 			omniQueues = GroupsSelector.newInstance().selectOmniQueues(new Set<Object>());
	// 		}
	// 		return omniQueues;
	// 	}
	// 	set;
	// }
	
	// public static CaseOmniRoutingModule newInstance() {
	// 	return (CaseOmniRoutingModule)Application.Utilities.newInstance(CaseOmniRoutingModule.class);
	// }

	// // Setup which triggers this module should respond to
	// public CaseOmniRoutingModule() {
	// 	getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	// }

	// public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
	// 	try {
			
	// 	} catch(Exception ex) {
	// 		ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CaseOmniRoutingModule.class.getName(), 'onBeforeInsert', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
	// 	}
	// }

	// public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
	// 	try {

	// 		List<Case> ssswCasesOnly = filterToSSSWCases((List<Case>) records);
	// 		deletePSRsForCasesNotInPreferredAgentQueue(ssswCasesOnly, (Map<Id, Case>)existingRecords);
	// 		resetBypassPreferredAgentFlag(ssswCasesOnly, (Map<Id, Case>)existingRecords, uow);

	// 	} catch(Exception ex) {
	// 		ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, CaseOmniRoutingModule.class.getName(), 'onBeforeUpdate', SSSWConstants.CASE_TRIGGER, ApplicationLogger.LoggingLevel.ERROR);
	// 	}
	// }

	// /*
	//  * This method clears PSRs that were manually inserted for Preferred Agent when the Case is being assigned from the Preferred Agent Routing queue
	//  * These scenarios include:            
	//  * 1. Case expires in Preferred Agent queue and is triggered to be routed out of that queue            
	//  * 2. Case is set to Closed (e.g. dataload, or customer triggers closure), the Case will be moved to the Omnichannel Closed Cases queue
	//  * 3. A user triggers a Reassign from the UI (exception case)
	//  * 4. Manually move Cases out of the Preferred Agent queue by dataloading a new Owner and Bypass Preferred Agent flag
	//  * 
	//  */
	// private void deletePSRsForCasesNotInPreferredAgentQueue(List<Case> records, Map<Id, Case> existingRecords){

	// 	Id preferredAgentQueueId = OmniChannelService.getInstance().preferredAgentQueueId;
	// 	Map<Id,Case> validCases = new Map<Id,Case>();

	// 	for(Case c : records) {
	// 		// take only cases that are moving out of the Preferred Agent queue
	// 		if(existingRecords.get(c.Id).OwnerId == preferredAgentQueueId &&
	// 			c.OwnerId != preferredAgentQueueId){

	// 			c.PreferredAgentExpiry__c = null; // blanking it out as it is no longer needed. 
	// 			validCases.put(c.Id, c);
	// 		}
	// 	}	
		
	// 	if(validCases.isEmpty() == false){
	// 		List<PendingServiceRouting> psrRecords = PendingServiceRoutingSelector.newInstance().selectByWorkItemId(validCases.keySet(), new Set<Object>());

	// 		if(!psrRecords.isEmpty()) {
	// 			ApplicationDatabase.getInstance().dmlDelete(psrRecords);
	// 		}	
	// 	}		
	// }

	// /*
	//  * This method resets the Bypass Preferred Agent flag on the case if the owner on the case changed from a Queue to a User. 
	//  */
	// private void resetBypassPreferredAgentFlag(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow){
	// 	for(Case c: records) {
	// 		if(c.OwnerId.getSobjectType() == User.getSObjectType() && existingRecords.get(c.Id).OwnerId.getSobjectType() == Group.getSobjectType()) {
	// 			c.BypassPreferredAgent__c = false;
	// 		}
	// 	}
	// }

	// /*
	//  * This method returns a list of Case records that are related to StarTrack or SSSW
	//  * @param caseRecords the list of Cases to filter
	//  */
	// private List<Case> filterToSSSWOrStartrackCases(List<Case> caseRecords){
	// 	List<Case> filteredCases = new List<Case>();		
		
	// 	for (Case c : caseRecords) {
	// 		if(allSSSWOrStartrackRecordTypes.contains(c.RecordTypeId)){
	// 			filteredCases.add(c);		
	// 		}				
	// 	}

	// 	return filteredCases;
	// }

	// /*
	//  * This method returns a list of Case records that are related to StarTrack or SSSW
	//  * @param caseRecords the list of Cases to filter
	//  */
	// private List<Case> filterToSSSWCases(List<Case> caseRecords){
	// 	List<Case> filteredCases = new List<Case>();		
		
	// 	for (Case c : caseRecords) {
	// 		if(allSSSWRecordTypes.contains(c.RecordTypeId)){
	// 			filteredCases.add(c);		
	// 		}				
	// 	}

	// 	return filteredCases;
	// }

}