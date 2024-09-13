/***
 * @description VoiceCall trigger module for VoiceCall sync and Genesys Interaction sync
 * NOTE: 	Invokes all the logic upon DML for the VoiceCall object
 * @author 	Paul Perry
 * @date 	2024-08-27
 * @changelog
 * 2024-08-27 Paul Perry - created
 */
public with sharing class UnifiedVoiceCallModule extends ApplicationModule {
	public static UnifiedVoiceCallModule newInstance() {
		return (UnifiedVoiceCallModule)Application.Utilities.newInstance(UnifiedVoiceCallModule.class);
	}

	/**
	 * Constructor
	 */
	public UnifiedVoiceCallModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate().enableBeforeUpdate();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			autoLinkContact(records, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'Unified Voice Call', UnifiedVoiceCallModule.class.getName(), 'onBeforeUpdate', 'VoiceCall', ApplicationLogger.LoggingLevel.ERROR);
		}

	}

	/**
	 * @param records List<SObject>
	 * @param existingRecords Map<Id, SObject>
	 * @param uow ApplicationUnitOfWork
	 * @description Called after a VoiceCall is updated.
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			Set<SObjectField> monitoredFields = GenesysConstants.voiceCallFieldMappings.keySet();
			List<ApplicationRecursion.RecordState> changedRecordStates = ApplicationRecursion.getInstance().getProcessableRecords('UnifiedVoiceCallModule', records, existingRecords, monitoredFields);
			List<SObject> changedRecords = new List<SObject>();
			for (ApplicationRecursion.RecordState recordState : changedRecordStates) {
	changedRecords.add(recordState.record);
			}
			syncCaseWhenRelatedRecordIdChanged(changedRecords, existingRecords, uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'Unified Voice Call', UnifiedVoiceCallModule.class.getName(), 'onAfterUpdate', 'VoiceCall', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * when a Voice Call record is created, attempt to auto populate the Contact__c field base on the phone number
	 * @param records List<SObject>
	 * @param uow ApplicationUnitOfWork
	 */
	@TestVisible
	private static void autoLinkContact(List<SObject> records, ApplicationUnitOfWork uow) {
		Set<Id> voiceCallToProcess = new Set<Id>();
		for (VoiceCall vc : (List<VoiceCall>) records) {
			if ((vc.CallType == GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE || vc.CallType == GenesysConstants.VOICE_CALL_OUTBOUND_CALL_TYPE) &&
		(vc.CallerId != null || vc.RecipientId != null) ) {
	voiceCallToProcess.add(vc.Id);
			}
		}

		if (voiceCallToProcess.isEmpty()) {
			return;
		}

		Set<SObjectField> fieldOverrides = new Set<SObjectField>();
		fieldOverrides.add(VoiceCall.Contact__c);
		fieldOverrides.add(VoiceCall.CallType);

		Set<Object> selectorOptions = new Set<Object>();
		selectorOptions.add(VoiceCallsSelector.Options.WITH_CALLER);
		selectorOptions.add(VoiceCallsSelector.Options.WITH_RECIPIENT);
		Map<Id,VoiceCall> voiceCallRecordsMap = new Map<Id, VoiceCall>(VoiceCallsSelector.newInstance(0,fieldOverrides).selectByIds(selectorOptions, voiceCallToProcess));

		Set<String> voiceCallReversedPhoneNumber = new Set<String>();
		for (VoiceCall vc : voiceCallRecordsMap.values()) {
			if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE) && !String.isBlank(Util.reversePhoneString(vc.Caller.ParticipantDisplayName))) {
	voiceCallReversedPhoneNumber.add(Util.reversePhoneString(vc.Caller.ParticipantDisplayName));
			} else if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_OUTBOUND_CALL_TYPE) && !String.isBlank(Util.reversePhoneString(vc.Recipient.ParticipantDisplayName))) {
	voiceCallReversedPhoneNumber.add(Util.reversePhoneString(vc.Recipient.ParticipantDisplayName));
			}
		}

		if (voiceCallReversedPhoneNumber.isEmpty()) {
			return;
		}

		Map<Id, Contact> contactMap = ContactsSelector.newInstance(0, getContactFieldOverrides()).selectByReversedPhoneNumbers(new Set<Object>(), voiceCallReversedPhoneNumber);

		Map<String, Contact[]> contactsByReversedPhone = new Map<String,Contact[]>();
		for (Contact con : contactMap.values()) {
			String reversedPhoneNumber = con.ReverseMobilePhone__c ?? con.ReverseVerifiedMobile__c;
			reversedPhoneNumber = reversedPhoneNumber ?? con.ReversePhone__c;
			if (contactsByReversedPhone.get(reversedPhoneNumber) == null) {
	contactsByReversedPhone.put(reversedPhoneNumber, new List<Contact>{con});
			} else {
	contactsByReversedPhone.get(reversedPhoneNumber).add(con);
			}
		}

		for (VoiceCall vc : voiceCallRecordsMap.values()) {
			if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE) && !String.isBlank(Util.reversePhoneString(vc.Caller.ParticipantDisplayName))) {
	List<Contact> potentialContact = contactsByReversedPhone.get(Util.reversePhoneString(vc.Caller.ParticipantDisplayName));
	vc.Contact__c = potentialContact?.size() == 1 ? potentialContact.get(0).Id : null;
			} else if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_OUTBOUND_CALL_TYPE) && !String.isBlank(Util.reversePhoneString(vc.Recipient.ParticipantDisplayName))) {
	List<Contact> potentialContact = contactsByReversedPhone.get(Util.reversePhoneString(vc.Recipient.ParticipantDisplayName));
	vc.Contact__c = potentialContact?.size() == 1 ? potentialContact.get(0).Id : null;
			}
		}

		uow.registerDirty(voiceCallRecordsMap.values());
	}

	/**
	 * sync the Case__c and fields defined in the GenesysConstants when related record changes to a new case
	 * @param records List<SObject> records
	 * @param existingRecords Map<Id, SObject>
	 * @param uow ApplicationUnitOfWork
	 */
	@TestVisible
	private static void syncCaseWhenRelatedRecordIdChanged(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		VoiceCall oldVc;
		Map<Id,VoiceCall> voiceCallIdToProcess = new Map<Id,VoiceCall>();
		Set<Id> relatedCaseIds = new Set<Id>();
		for (VoiceCall vc : (List<VoiceCall>) records) {
			oldVc = (VoiceCall) existingRecords.get(vc.Id);
			if ((vc.RelatedRecordId == null && oldVc.RelatedRecordId != null) ||
		(vc.RelatedRecordId != oldVc.RelatedRecordId && String.valueOf(vc.RelatedRecordId).startsWith('500'))) {
	relatedCaseIds.add(vc.RelatedRecordId);
	voiceCallIdToProcess.put(vc.Id, vc);
			}
		}

		if (voiceCallIdToProcess.isEmpty()) {
			return;
		}

		Set<SObjectField> voiceCallFieldOverride = new Set<SObjectField>(GenesysConstants.voiceCallCaseFieldMappings.values());
		voiceCallFieldOverride.addAll(getVoiceCallAdditionalFieldOverrides());

		Set<SObjectField> voiceCaseFieldOverride = new Set<SObjectField>(GenesysConstants.voiceCallCaseFieldMappings.keySet());
		voiceCaseFieldOverride.addAll(getCaseAdditionalFieldOverrides());

		Map<Id,VoiceCall> voiceCallUpdatable = new Map<Id,VoiceCall>(VoiceCallsSelector.newInstance(0, voiceCallFieldOverride).selectByIds(new Set<Object>(), voiceCallIdToProcess.keySet()));
		Map<Id,Case> relatedCases = CasesSelector.newInstance(voiceCaseFieldOverride).selectById(relatedCaseIds, new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE});
		Map<Id,CaseHistory> caseGEHistories = CaseHistoriesSelector.newInstance().selectCaseHistoriesByTypeAndCaseIds(new Set<Object>{CaseHistoriesSelector.Options.WITH_CASE}, relatedCaseIds, GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_GENERAL_ENQUIRY);
		Map<Id,CaseHistory[]> relatedCaseGEHistory = new Map<Id,CaseHistory[]>();
		for (CaseHistory cHistory : caseGEHistories.values()) {
			if (relatedCaseGEHistory.get(cHistory.CaseId) == null) {
	relatedCaseGEHistory.put(cHistory.CaseId, new List<CaseHistory>{cHistory});
			} else {
	relatedCaseGEHistory.get(cHistory.CaseId).add(cHistory);
			}
		}

		for (Id vcId : voiceCallUpdatable.keySet()) {
			VoiceCall vc = voiceCallUpdatable.get(vcId);
			vc.Case__c = voiceCallIdToProcess.get(vcId).RelatedRecordId;
			if (vc.Case__c == null) {
	vc.Outcome__c = GenesysConstants.VOICE_CALL_OUTCOME_UNLINKED_CONTACT;
			} else {
	for (SObjectField field : GenesysConstants.voiceCallCaseFieldMappings.keySet()) {
		vc.put(GenesysConstants.voiceCallCaseFieldMappings.get(field), relatedCases.get(vc.RelatedRecordId).get(field));
	}
	vc.RootCause__c = vc.RootCause__c ?? GenesysConstants.DEFAULT_VOICE_CALL_ROOT_CAUSE;
	vc.Outcome__c = determineVoiceCallOutcome(relatedCases.get(vc.RelatedRecordId), vc, relatedCaseGEHistory.get(vc.Case__c));
			}
		}

		uow.registerDirty(voiceCallUpdatable.values());
	}

	/**
	 * logic to determine the value of the Outcome__c field
	 * @param relatedCase Case
	 * @param voiceCall VoiceCall
	 * @param relatedGECaseHistory List<CaseHistory>
	 * @return String
	 */
	private static String determineVoiceCallOutcome(Case relatedCase, VoiceCall voiceCall, List<CaseHistory> relatedGECaseHistory) {
		Boolean caseOlderThanVoice = relatedCase.CreatedDate < voiceCall.CallStartDateTime;
		if (GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_GENERAL_ENQUIRY.equalsIgnoreCase(relatedCase.Type) && !caseOlderThanVoice) { // the case is created with Type = General Enquiry during the interaction
			return GenesysConstants.VOICE_CALL_OUTCOME_FCR;
		} else if ((GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_INVESTIGATION.equalsIgnoreCase(relatedCase.Type) && !caseOlderThanVoice) ||
	(GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_INVESTIGATION.equalsIgnoreCase(relatedCase.Type) && caseOlderThanVoice && relatedGECaseHistory != null && !relatedGECaseHistory.isEmpty())) { // the case is created with Type = Investigation is before the call OR the case was of Type GE, but has been updated to Investigate during the call
			return GenesysConstants.VOICE_CALL_OUTCOME_ENQUIRY_LODGED;
		} else if (GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_INVESTIGATION.equalsIgnoreCase(relatedCase.Type) && caseOlderThanVoice && relatedGECaseHistory == null) { // the case has always been of Type Investigation before and during the call
			return GenesysConstants.VOICE_CALL_OUTCOME_ENQUIRY_UPDATED;
		}
		return null;
	}

	@TestVisible
	private static Set<SObjectField> getVoiceCallAdditionalFieldOverrides() {
		return new Set<SObjectField>{VoiceCall.Case__c, VoiceCall.RelatedRecordId, VoiceCall.RootCause__c, VoiceCall.Outcome__c, VoiceCall.CallStartDateTime};
	}

	@TestVisible
	private static Set<SObjectField> getCaseAdditionalFieldOverrides() {
		return new Set<SObjectField>{Case.CreatedDate, Case.LastModifiedDate};
	}

	@TestVisible
	private static Set<SObjectField> getContactFieldOverrides() {
		return new Set<SObjectField>{Contact.ReverseMobilePhone__c, Contact.ReverseVerifiedMobile__c, Contact.ReversePhone__c};
	}
}