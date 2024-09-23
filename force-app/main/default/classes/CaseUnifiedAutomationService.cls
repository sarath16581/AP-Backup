/**
 * @description Service class for storing Unified Case related automation including below functionalities:
 * 				- Processing Case Closure
 * 				- Processing Case Reassignment
 * NOTE: Caller classes may pass in RecordWrapper and specify InvocationPoint enum to determine the entry point and the automation will handle appropriately.
 *
 * @author Seth Heang
 * @date 2024-07-18
 * @test CaseUnifiedAutomationServiceTest
 * @changelog
 * 2024-07-18 - Seth Heang - Created.
 * 2024-08-12 - Ranjeewa Silva - Updated case re-assignment to cater for email automation
 * 2024-08-23 - Seth Heang - Added PreferredAgentExpiry__c mapping to Reassigned Case Update
 * 2024-09-02 - Ranjeewa Silva - Updated case closure / reassignment to cater for scan event automation.
 */
public inherited sharing class CaseUnifiedAutomationService {
	@TestVisible private static final String REASSIGNMENT_REASON_OPT_OUT_AUTOMATION = 'Cannot autoclose due to opt out automations';
	@TestVisible private static final String REASSIGNMENT_REASON_MISSING_CUSTOMER_EMAIL = 'Cannot autoclose due to missing customer email';

	// Define an ENUM to identify the initial entry/invocation/caller.
	public enum InvocationPoint {
		MANUAL,
		ARTICLESAUTO,
		SCANAUTO,
		PROACTIVEAUTO,
		EMAILAUTO
	}

	@TestVisible private static final QM__c QUEUE_SETTINGS {
		get {
			if (QUEUE_SETTINGS == null) {
				QUEUE_SETTINGS = QM__c.getInstance();
			}
			return QUEUE_SETTINGS;
		}
		private set;
	}

	/**
	 * @description Retrieve all valid record types for unified cases, and save as a constant for repeated usage
	 */
	private static final List<RecordType> VALID_UNIFIED_CASE_RECORDTYPES {
		get {
			if (VALID_UNIFIED_CASE_RECORDTYPES == null) {
				VALID_UNIFIED_CASE_RECORDTYPES = new RecordTypesSelector().selectByDeveloperNamesLike('Case', new Set<String>{ 'Unified' }).values();
			}
			return VALID_UNIFIED_CASE_RECORDTYPES;
		}
		private set;
	}

	public static CaseUnifiedAutomationService getInstance() {
		return (CaseUnifiedAutomationService) Application.Utilities.getInstance(CaseUnifiedAutomationService.class);
	}

	/**
	 * @description Public getter method to get UnifiedInvestigationCaseRecordType
	 * @return Id
	 */
	public static Id getUnifiedInvestigationCaseRecordTypeId() {
		for (RecordType recType : VALID_UNIFIED_CASE_RECORDTYPES) {
			if (recType.DeveloperName.equalsIgnoreCase('UnifiedInvestigation')) {
				return recType.Id;
			}
		}
		return null;
	}

	/**
	 * @description Public getter method to get all valid unified case record type Ids
	 * @return Group
	 */
	public static Set<Id> getUnifiedCaseRecordTypeIds() {
		return new Map<Id, RecordType>(VALID_UNIFIED_CASE_RECORDTYPES).keySet();
	}

	public static Boolean isStarTrackCase(Case caseRecord) {
		return (caseRecord.ProductSubCategory__c?.containsIgnoreCase('StarTrack') ?? false);
	}

	/**
	 * @description	Handles all logics for Case Closure based on source Entry Point
	 * @param records
	 * @param entryPoint
	 * @param uow
	 */
	public void processForCaseClosure(List<RecordWrapper> records, InvocationPoint entryPoint, ApplicationUnitOfWork uow) {
		switch on entryPoint {
			when SCANAUTO {
				closeCasesScanEventAutomation(records, uow);
			} when PROACTIVEAUTO {
				closeCasesProactiveMonitoringAutomation(records, uow);
			}
		}
	}

	/**
	 * @description Close case and run common logic to update appropriate fields including sending email notification
	 * @param records
	 * @param uow
	 */
	private void closeCasesProactiveMonitoringAutomation(List<RecordWrapper> records, ApplicationUnitOfWork uow) {
		List<Case> caseClosureForUpdate = new List<Case>();
		for (RecordWrapper record : records) {
			caseClosureForUpdate.add(updateCaseForCaseClosure(record));
		}
		if (!caseClosureForUpdate.isEmpty()) {
			if (uow != null) {
				uow.registerDirty(caseClosureForUpdate, false, CaseUnifiedAutomationService.class.getName() + 'closeCasesAndUpdateCommonFields');
			} else {
				ApplicationDatabase.getInstance().dmlUpdate(caseClosureForUpdate);
			}

			// TODO: Dependency on other squad working on ApplicationEmailService framework
			// Below code will be soon be replaced to make use of ApplicationEmailService once that is ready
			// For testing purpose, the email message sent is hardcoded
			List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
			for (Case newCase : caseClosureForUpdate) {
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				mail.setToAddresses(new List<String>{ newCase.ContactEmail });
				if (newCase.ProductSubCategory__c.contains('StarTrack')) {
					mail.setSubject('TEST StarTrack Closure Email');
					mail.setPlainTextBody('StarTrack Email Closure Body');
				} else {
					mail.setSubject('TEST AusPost Closure Email');
					mail.setPlainTextBody('AusPost Email Closure Body');
				}
				mails.add(mail);
			}
			// Send the email
			Messaging.sendEmail(mails);
		}
	}

	/**
	 * @description Run logic to map case details for CaseClosure scenario with below assignments:
	 *				1. Set Status = Closed
	 *				2. Set Owner = SSSW Closed Omnichannel cases (ONLY IF the current owner is not an Individual Agent)
	 *				3. Set ClosedBySystem__c = True based on isClosedBySystem flag in recordWrapper
	 *				4. Set Root_cause__c = True based on newRootCause field in recordWrapper
	 *				5. Set ResolutionCode__c = True based on newResolutionCode flag in recordWrapper
	 * @param record
	 * @return Case
	 */
	private Case updateCaseForCaseClosure(RecordWrapper record) {
		Boolean currentOwnerIsNotAgent = !record.caseRecord.OwnerId.toString().startsWith('005');
		Case updatedCase = record.caseRecord;
		updatedCase.Status = SSSWConstants.CASE_STATUS_CLOSED;
		updatedCase.OwnerId = currentOwnerIsNotAgent ? QUEUE_SETTINGS.ClosedQueueId__c : record.caseRecord.OwnerId;
		updatedCase.ClosedBySystem__c = record.isClosedBySystem;
		updatedCase.Root_cause__c = record.newRootCause;
		updatedCase.ResolutionCode__c = record.newResolutionCode;
		return updatedCase;
	}

	/**
	 * @description Handles all logic for Case Reassignment based on source Entry Point
	 * @param records
	 * @param entryPoint
	 * @param uow
	 */
	public void processForCaseReassignment(List<RecordWrapper> records, InvocationPoint entryPoint, ApplicationUnitOfWork uow) {
		switch on entryPoint {
			when EMAILAUTO, SCANAUTO {
				reassignCases(records, uow);
			}
			when PROACTIVEAUTO {
				reassignCasesProactiveMonitoringAutomation(records, uow);
			}
		}
	}

	/**
	 * @description Reassign case and update appropriate fields for Proactive Monitoring Entry Point
	 * @param records
	 * @param uow
	 */
	private void reassignCasesProactiveMonitoringAutomation(List<RecordWrapper> records, ApplicationUnitOfWork uow) {
		List<Case> caseReassignmentForUpdate = new List<Case>();
		for (RecordWrapper record : records) {
			caseReassignmentForUpdate.add(updateCaseForCaseReassignment(record));
		}
		if (!caseReassignmentForUpdate.isEmpty()) {
			if (uow != null) {
				uow.registerDirty(caseReassignmentForUpdate, false, CaseUnifiedAutomationService.class.getName() + 'reassignCasesProactiveMonitoringAutomation');
			} else {
				ApplicationDatabase.getInstance().dmlUpdate(caseReassignmentForUpdate);
			}
		}
	}

	/**
	 * Reassign cases passed in for case reassignment automation.
	 *
	 * @param records list of record wrappers passed in
	 * @param uow unit of work instance
	 */
	private void reassignCases(List<RecordWrapper> records, ApplicationUnitOfWork uow) {

		// check case records passed in are eligible for reassignment.
		Set<Id> reassignableCaseIds = getReassignableCases(records);

		List<Case> updatableCases = new List<Case>();
		for (RecordWrapper wrapper: records) {
			Case updatable = new Case(Id=wrapper.caseRecord.Id);
			updatable.Status = SSSWConstants.CASE_STATUS_UPDATED;
			if (reassignableCaseIds.contains(wrapper.caseRecord.Id)) {
				// case is eligible for reassignment. update relevant fields.
				updatable.ReassignmentReason__c = wrapper.newReassignmentReason;
				updatable.OwnerId = QUEUE_SETTINGS?.UnifiedDefaultOmniQueueId__c;
				updatable.PreferredAgentExpiry__c = calculatePreferredAgentExpiry(wrapper);
				if (wrapper.caseRecord.IsClosed) {
					// case is currently closed and it's getting re-opened. we need to populate Case_Reopen_Date__c.
					updatable.Case_Reopen_Date__c = Datetime.now();
				}
				updatableCases.add(updatable);
			} else if (!SSSWConstants.CASE_STATUS_UPDATED.equalsIgnoreCase(wrapper.caseRecord.Status)) {
				// case is not reassignable. only need to update the case status to 'Updated'
				// this is needed only when current case status is something else.
				updatableCases.add(updatable);
			}
		}

		if (!updatableCases.isEmpty()) {
			// we have cases to update. register them with unit of work.
			uow.registerDirty(updatableCases, false, CaseUnifiedAutomationService.class.getName() + 'reassignCasesEmailAutomation');
		}
	}

	/**
	 * Check if case records passed in are eligible for reassignment. Case records should not be reassigned if the
	 * case records or one of it's child ContactRequest records are currently getting assigned by another process.
	 *
	 * Closed case records getting reopened due to automation are always eligible for reassignment.
	 * Open case records are eligible for reassignment if below conditions are true:
	 * - Case has no PendingServiceRouting records
	 * - Case has no AgentWork in 'Opened' / 'Assigned' status
	 * - Case record's child ContactRequest records have no PendingServiceRouting records
	 * - Case record's child ContactRequest records have no AgentWork in 'Opened' / 'Assigned' status
	 *
	 * @param recordWrappers case record wrappers
	 *
	 * @return set of case id's eligible for reassignment
	 */
	@TestVisible private Set<Id> getReassignableCases(List<RecordWrapper> recordWrappers) {

		Set<Id> results = new Set<Id>();

		// open cases map (key - case id, value - case record)
		Map<Id, Case> openCases = new Map<Id, Case>();
		// child contact request mappings (key - contact request id, value - parent case id)
		Map<Id, Id> childContactRequestsMapping = new Map<Id, Id>();
		for (RecordWrapper wrapper: recordWrappers) {
			if (wrapper.caseRecord.IsClosed) {
				// closed cases are reassignable. case need to be reassigned even when the closed case is currently assigned
				// to an agent.
				results.add(wrapper.caseRecord.Id);
			} else {
				// open cases are to be reassigned only if it is not currently with an agent or in the process of being
				// assigned to an agent by some other automation. both of the following conditions must be true for this to happen.
				// (a) there is no 'Open' or 'Assigned' AgentWork on Case or it's child contact requests.
				// (b) there is no PendingServiceRequest records for the Case or it's child contact requests.
				openCases.put(wrapper.caseRecord.Id, wrapper.caseRecord);
				for (ContactRequest contactRequest: wrapper.caseRecord.ContactRequests) {
					childContactRequestsMapping.put(contactRequest.Id, wrapper.caseRecord.Id);
				}
			}
		}

		if (!openCases.isEmpty()) {
			// start with the full set of open case ids
			Set<Id> reassignableCaseIds = new Set<Id>(openCases.keySet());
			// workout the cases with PSRs for the case record or one of it's child ContactRequests. remove these from re-assignable case ids set.
			reassignableCaseIds.removeAll(getCasesHavingPendingServiceRoutingRecords(openCases.keySet(), childContactRequestsMapping));
			//  workout the cases with AgentWork for the case record or one of it's child ContactRequests. remove these from re-assignable case ids set.
			reassignableCaseIds.removeAll(getCasesHavingActiveAgentWork(openCases.keySet(), childContactRequestsMapping));
			results.addAll(reassignableCaseIds);
		}
		return results;
	}

	/**
	 * Handle case closure for cases passed into the service from scan event automation entry point.
	 *
	 * @param records list of record wrappers passed in
	 * @param uow unit of work instance
	 */
	private void closeCasesScanEventAutomation(List<RecordWrapper> records, ApplicationUnitOfWork uow) {

		// determine if case records can be closed or reassigned.
		ClosureEligibilityResult closureEligibilityResult = determineCaseClosureEligibility(records);

		List<Case> updatableCases = new List<Case>();
		for (RecordWrapper wrapper: records) {
			Case updatable = new Case(Id=wrapper.caseRecord.Id);
			if (closureEligibilityResult.closableCasesIds.contains(wrapper.caseRecord.Id)) {
				// case is eligible for closure. update relevant fields.
				updatable.Status = SSSWConstants.CASE_STATUS_CLOSED;
				updatable.OwnerId = QUEUE_SETTINGS?.ClosedQueueId__c;
				updatable.ClosedBySystem__c = true;
				updatable.Root_cause__c = wrapper.newRootCause;
				updatable.ResolutionCode__c = wrapper.newResolutionCode;
				updatableCases.add(updatable);
				// TODO dependency on ApplicationEmailService feature. Implement logic to send email once the email templates
				// requirements are confirmed.
				// uow.queueEmailNotification(wrapper.caseRecord.Id, Case.SObjectType, 'TBD?');
			} else if (closureEligibilityResult.reassignableCasesIds.contains(wrapper.caseRecord.Id)) {
				// case is eligible for reassignment. update relevant fields.
				updatable.Status = SSSWConstants.CASE_STATUS_UPDATED;
				updatable.ReassignmentReason__c = wrapper.caseRecord.Exclude_Subscription_Automation__c ? REASSIGNMENT_REASON_OPT_OUT_AUTOMATION :
						String.isEmpty(wrapper.caseRecord.ContactEmail) ? REASSIGNMENT_REASON_MISSING_CUSTOMER_EMAIL : wrapper.newReassignmentReason;
				updatable.OwnerId = QUEUE_SETTINGS?.UnifiedDefaultOmniQueueId__c;
				updatable.PreferredAgentExpiry__c = calculatePreferredAgentExpiry(wrapper);
				updatableCases.add(updatable);
			} else if (!SSSWConstants.CASE_STATUS_UPDATED.equalsIgnoreCase(wrapper.caseRecord.Status)) {
				// case is not reassignable. only need to update the case status to 'Updated'
				// this is needed only when current case status is something else.
				updatable.Status = SSSWConstants.CASE_STATUS_UPDATED;
				updatableCases.add(updatable);
			}
		}

		if (!updatableCases.isEmpty()) {
			// we have cases to update. register them with unit of work.
			uow.registerDirty(updatableCases, false, CaseUnifiedAutomationService.class.getName() + 'closeCasesScanEventAutomation');
		}
	}


	/**
	 * Check if case records passed in are eligible for closure or reassignment.
	 *
	 * Case records should not be closed if below conditions are true:
	 * (a) Case has AgentWork in 'Opened' / 'Assigned' status
	 * (b) Case record's child ContactRequest records have no AgentWork in 'Opened' / 'Assigned' status
	 * (c) Exclude_Subscription_Automation__c=true on the case
	 * (d) ContactEmail is not available
	 *
	 * If case cannot be closed due to (c) or (d) above, check if the case can be reassigned. Case records should not be
	 * reassigned if below conditions are true:
	 * - Case has PendingServiceRouting records
	 * - Case has AgentWork in 'Opened' / 'Assigned' status
	 * - Case record's child ContactRequest records have PendingServiceRouting records
	 * - Case record's child ContactRequest records have AgentWork in 'Opened' / 'Assigned' status
	 *
	 * @param recordWrappers case record wrappers
	 *
	 * @return set of case id's eligible for closure and set of case id's eligible for reassignment
	 */
	@TestVisible private ClosureEligibilityResult determineCaseClosureEligibility(List<RecordWrapper> recordWrappers) {
		ClosureEligibilityResult results = new ClosureEligibilityResult();

		// cases map (key - case id, value - case record)
		Map<Id, Case> caseRecords = new Map<Id, Case>();

		// child contact request mappings (key - contact request id, value - parent case id)
		Map<Id, Id> childContactRequestsMapping = new Map<Id, Id>();
		for (RecordWrapper wrapper: recordWrappers) {
			// cases are to be closed only if they are currently not with an agent. there shouldn't be any 'Open' or
			// 'Assigned' AgentWork on Case or it's child contact requests for this to happen.
			caseRecords.put(wrapper.caseRecord.Id, wrapper.caseRecord);
			for (ContactRequest contactRequest: wrapper.caseRecord.ContactRequests) {
				childContactRequestsMapping.put(contactRequest.Id, wrapper.caseRecord.Id);
			}
		}

		if (!caseRecords.isEmpty()) {
			// identify case records with active AgentWork records (i.e. in 'Opened' and 'Assigned' status)
			Set<Id> casesWithActiveAgentWork = getCasesHavingActiveAgentWork(caseRecords.keySet(), childContactRequestsMapping);
			// identify case records with PendingServiceRouting records.
			Set<Id> casesWithPendingServiceRouting = getCasesHavingPendingServiceRoutingRecords(caseRecords.keySet(), childContactRequestsMapping);

			for (RecordWrapper wrapper: recordWrappers) {
				// case records are not eligible for closure in below scenarios:
				// 1. case record or one of the child contact requests has active AgentWork (i.e. status 'Opened' and 'Assigned').
				//	these cases are either with an agent already or assigned to an agent and waiting for agent to open the case.
				// 2. case record is excluded from automation (Exclude_Subscription_Automation__c=true). agents can set this
				//	flag on case record to prevent it from getting closed automatically. such cases are to be assigned to
				//	an agent when closure automation is triggered (e.g. receiving closure scan events).
				// 3. email address on the related contact record on case is blank. such cases are to be assigned to an agent
				//	when closure automation is triggered.
				if (!casesWithActiveAgentWork.contains(wrapper.caseRecord.Id)
						&& !wrapper.caseRecord.Exclude_Subscription_Automation__c
						&& String.isNotEmpty(wrapper.caseRecord.ContactEmail)) {
					results.closableCasesIds.add(wrapper.caseRecord.Id);
				} else if (!casesWithActiveAgentWork.contains(wrapper.caseRecord.Id)
						&& !casesWithPendingServiceRouting.contains(wrapper.caseRecord.Id)) {
					// case records not eligible for closure due to the above scenarios (2) and (3) above are evaluated
					// to see if they can be reassigned. such case records are not eligible for reassignment if there are
					// existing PendingServiceRouting records against the case or one of it's child contact requests. this
					// means the case is already getting reassigned and there is no need to reassign again.
					// case records not eligible for closure due to scenario (1) above are not eligible for reassignment
					// due to the same reason.
					results.reassignableCasesIds.add(wrapper.caseRecord.Id);
				}
			}
		}

		return results;
	}

	private class ClosureEligibilityResult {
		private Set<Id> closableCasesIds = new Set<Id>();
		private Set<Id> reassignableCasesIds = new Set<Id>();
	}


	/**
	 * Check case Ids and child contact request ids for existing PendingServiceRouting records. Return Case Ids where
	 * the Case or one of it's child contact requests have a PendingServiceRouting record.
	 *
	 * @param caseIds parent case Ids
	 * @param childContactRequestsMapping child contact request mappings (key - contact request id, value - parent case id)
	 *
	 * @return Case Ids where the Case or one of it's child contact requests have a PendingServiceRouting record.
	 */
	private Set<Id> getCasesHavingPendingServiceRoutingRecords(Set<Id> caseIds, Map<Id, Id> childContactRequestsMapping) {
		Set<Id> workItemIds = new Set<Id>(caseIds);
		workItemIds.addAll(childContactRequestsMapping.keySet());

		Set<Id> results = new Set<Id>();

		List<PendingServiceRouting> pendingServiceRoutings = PendingServiceRoutingSelector.newInstance().selectByWorkItemId(workItemIds, new Set<Object>());
		for (PendingServiceRouting psr: pendingServiceRoutings) {
			results.add(getCaseIdFromWorkItemId(psr.WorkItemId, caseIds, childContactRequestsMapping));
		}
		return results;
	}

	/**
	 * Check case Ids and child contact request ids for existing AgentWork records in 'Opened' or 'Assigned' status.
	 * Return Case Ids where the Case or one of it's child contact requests have AgentWork.
	 *
	 * @param caseIds parent case Ids
	 * @param childContactRequestsMapping child contact request mappings (key - contact request id, value - parent case id)
	 *
	 * @return Case Ids where the Case or one of it's child contact requests have AgentWork.
	 */
	private Set<Id> getCasesHavingActiveAgentWork(Set<Id> caseIds, Map<Id, Id> childContactRequestsMapping) {
		Set<Id> workItemIds = new Set<Id>(caseIds);
		workItemIds.addAll(childContactRequestsMapping.keySet());

		Set<Id> results = new Set<Id>();

		List<AgentWork> agentWorkList = AgentWorkSelector.newInstance().search(new Map<String, Object>{
				'workItemIds' => workItemIds,
				'status' => new Set<String>{SSSWConstants.OMNI_AGENTWORK_STATUS_ASSIGNED, SSSWConstants.OMNI_AGENTWORK_STATUS_OPENED}
		}, true);

		for (AgentWork aw: agentWorkList) {
			results.add(getCaseIdFromWorkItemId(aw.WorkItemId, caseIds, childContactRequestsMapping));
		}
		return results;
	}

	private Id getCaseIdFromWorkItemId(Id workItemId, Set<Id> caseIds, Map<Id, Id> childContactRequestsMapping){
		return (caseIds.contains(workItemId) ? workItemId : childContactRequestsMapping.get(workItemId));
	}

	private Datetime calculatePreferredAgentExpiry(RecordWrapper caseWrapper) {
		// get the default preferred agent expiry applicable for this case
		if(caseWrapper.caseRecord.businessHoursId != null && QUEUE_SETTINGS?.UnifiedPreferredAgentExpiry__c != null) {
			return BusinessHours.add(caseWrapper.caseRecord.businessHoursId, Datetime.now(), QUEUE_SETTINGS.UnifiedPreferredAgentExpiry__c.longValue() * 3600000);
		}
		// if business hours are not set on case or custom setting not configured (unlikely), use the current value on case.
		return caseWrapper.caseRecord.PreferredAgentExpiry__c;
	}

	/**
	 * @description Run logic to map case details for CaseReassignment scenario with below assignments:
	 *				1. Set Status = Updated
	 *				2. Set Owner = Unified Customer Service Case Queue
	 *				3. Set ClosedBySystem__c = false based on isClosedBySystem flag in recordWrapper
	 *				4. Set Reassignment Reason with following criteria:
	 *					4.1 'Cannot autoclose due to opt out automations', if Exclude_Subscription_Automation__c = True
	 *					4.2 'Cannot autoclose due to missing customer email', if Case.ContactEmail Is Blank
	 * @param record
	 * @return Case
	 */
	private Case updateCaseForCaseReassignment(RecordWrapper record) {
		Case updatedCase = record.caseRecord;
		updatedCase.Status = SSSWConstants.CASE_STATUS_UPDATED;
		updatedCase.OwnerId = QUEUE_SETTINGS.UnifiedDefaultOmniQueueId__c;
		updatedCase.ClosedBySystem__c = record.isClosedBySystem;
		updatedCase.ReassignmentReason__c = record.caseRecord.Exclude_Subscription_Automation__c == true
				? REASSIGNMENT_REASON_OPT_OUT_AUTOMATION
				: record.caseRecord.ContactEmail == null ? REASSIGNMENT_REASON_MISSING_CUSTOMER_EMAIL : null;
		updatedCase.PreferredAgentExpiry__c = calculatePreferredAgentExpiry(record);
		return updatedCase;
	}

	/**
	 * @description	Wrapper class for storing relevant data used by functionalities in Unified Case automation.
	 * 				Calling class may check basic Case eligibility and determine new root cause, reassignment reason and resolution code.
	 */
	public class RecordWrapper {
		public Schema.SObjectType srcObjectType { get; set; } // e.g. Case, Article__c, ScheduledAction__c based on the Entry point
		public String srcRecordId { get; set; } // Id of the source record
		public Case caseRecord { get; set; } // Case record
		public Boolean determineEligibility { get; set; } // False as default. Caller may set it to True if eligibility is too complex to calculate at source
		public String newResolutionCode { get; set; } // May be available if eligibility check is confirmed at source (entry point)
		public String newRootCause { get; set; } // May be available if eligibility check is confirmed at source (entry point)
		public String newReassignmentReason { get; set; } // May be available if eligibility check is confirmed at source (entry point)
		public Boolean isClosedBySystem { get; set; } // True as default. Caller may set it to False and is mapped to ClosedBySystem__c
		public RecordWrapper() {
			determineEligibility = false;
			isClosedBySystem = true;
		}
	}
}