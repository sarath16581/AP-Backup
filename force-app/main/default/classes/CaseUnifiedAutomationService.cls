/**
 * @description Service class for storing Unified Case related automation including below functionalities:
 * 				- Processing Case Closure
 * 				- Processing Case Reassignment
 * NOTE: Caller classes may pass in RecordWrapper and specify InvocationPoint enum to determine the entry point and the automation will handle appropriately.
 *
 * @author Seth Heang
 * @date 2024-07-18
 * @test CaseUnifiedAutomationService_Test
 * @changelog
 * 2024-07-18 - Seth Heang - Created.
 */
public with sharing class CaseUnifiedAutomationService {
	private final String REASSIGNMENT_REASON_OPT_OUT_AUTOMATION = 'Cannot autoclose due to opt out automations';
	private final String REASSIGNMENT_REASON_MISSING_CUSTOMER_EMAIL = 'Cannot autoclose due to missing customer email';
	private final static QM__c QUEUE_SETTINGS = QM__c.getInstance();

	// Define an ENUM to identify the initial entry/invocation/caller.
	public enum InvocationPoint {
		MANUAL,
		ARTICLESAUTO,
		SCANAUTO,
		PROACTIVEAUTO,
		EMAILAUTO
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
			if (recType.DeveloperName.equals('UnifiedInvestigation')) {
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

	/**
	 * @description	Handles all logics for Case Closure based on source Entry Point
	 * @param records
	 * @param entryPoint
	 * @param uow
	 */
	public void processForCaseClosure(List<RecordWrapper> records, InvocationPoint entryPoint, ApplicationUnitOfWork uow) {
		List<Case> caseClosureForUpdate = new List<Case>();
		for (RecordWrapper record : records) {
			switch on entryPoint {
				when MANUAL, SCANAUTO, PROACTIVEAUTO, EMAILAUTO {
					caseClosureForUpdate.add(updateCaseForCaseClosure(record));
				}
				when ARTICLESAUTO {
					// Perform EDD updates specific logic. Define and create a separate method
				}
			}
		}
		if (!caseClosureForUpdate.isEmpty()) {
			ApplicationDatabase.getInstance().dmlUpdate(caseClosureForUpdate);

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
		Boolean currentOwnerIsNotAgent = !record.caseRecord.OwnerId.toString().startsWith(APT_Constants.LABEL_USER_ID_PREFIX);
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
		List<Case> caseReassignmentForUpdate = new List<Case>();
		for (RecordWrapper record : records) {
			switch on entryPoint {
				when MANUAL, SCANAUTO, PROACTIVEAUTO, EMAILAUTO {
					caseReassignmentForUpdate.add(updateCaseForCaseReassignment(record));
				}
				when ARTICLESAUTO {
					// Perform EDD updates specific logic. Define and create a separate method
				}
			}
		}
		if (!caseReassignmentForUpdate.isEmpty()) {
			ApplicationDatabase.getInstance().dmlUpdate(caseReassignmentForUpdate);
		}
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