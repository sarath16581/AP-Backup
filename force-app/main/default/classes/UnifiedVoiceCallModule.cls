/***
 * @description VoiceCall trigger module for VoiceCall sync and Genesys Interaction sync
 * NOTE: 	Invokes all the logic upon DML for the VoiceCall object
 * @author 	Paul Perry
 * @date 	2024-08-27
 * @group 	Domain
 * @test 	TBD
 * @changelog
 */
public with sharing class UnifiedVoiceCallModule extends ApplicationModule {
	public static UnifiedVoiceCallModule newInstance() {
		return (UnifiedVoiceCallModule)Application.Utilities.newInstance(UnifiedVoiceCallModule.class);
	}

	/**
	 * Constructor
	 */
    public UnifiedVoiceCallModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
    }

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			populateOriginalVoiceCall(records, uow);
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
			syncVoiceCallToGenesysCallInteraction(records, existingRecords);
			syncCaseWhenRelatedRecordIdChanged(changedRecords, existingRecords, uow);
			syncVoiceCallParticipants(changedRecords, existingRecords, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'Unified Voice Call', UnifiedVoiceCallModule.class.getName(), 'onAfterUpdate', 'VoiceCall', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @param records List<SObject> records
	 * @param uow ApplicationUnitOfWork
	 * @description when a VoiceCall record is created, check if it has PreviousCallId, and if it does, populate the OriginalVoiceCall__c field with its Previous Call's OriginalVoiceCall__c value
	 */
	@TestVisible
	private static void populateOriginalVoiceCall(List<SObject> records, ApplicationUnitOfWork uow) {
		Map<Id,Id> previousCallIds = new Map<Id,Id>();
		Set<Id> voiceToProcessIds = new Set<Id>();
		for (VoiceCall vc : (List<VoiceCall>) records) {
			if (vc.PreviousCallId != null && vc.CallType.equalsIgnoreCase(GenesysConstants.TRANSFER_CALL_TYPE)) {
				previousCallIds.put(vc.Id, vc.PreviousCallId);
				voiceToProcessIds.add(vc.Id);
			}
		}

		if (previousCallIds.isEmpty()) {
			return;
		}

		Set<SObjectField> fieldOverrides = new Set<SObjectField>(GenesysConstants.voiceCallFieldMappings.keySet());
		fieldOverrides.add(VoiceCall.OriginalVoiceCall__c);
		fieldOverrides.add(VoiceCall.PreviousCallId);
		Map<Id,VoiceCall> previousCallsMap = new Map<Id, VoiceCall>(VoiceCallsSelector.newInstance(0,fieldOverrides).selectByIds(new Set<Object>(), new Set<Id>(previousCallIds.values())));
		List<VoiceCall> voiceCallsUpdatable = VoiceCallsSelector.newInstance(0,fieldOverrides).selectByIds(new Set<Object>(), voiceToProcessIds);
		for (VoiceCall vc : voiceCallsUpdatable) {
			vc.OriginalVoiceCall__c = previousCallsMap.get(vc.PreviousCallId).OriginalVoiceCall__c ?? previousCallsMap.get(vc.PreviousCallId).Id;
			for (SObjectField field : GenesysConstants.voiceCallFieldMappings.keySet()) {
				vc.put(field, previousCallsMap.get(vc.PreviousCallId).get(field));
			}
		}

		uow.registerDirty(voiceCallsUpdatable);
	}

	/**
	 * @param records List<SObject> records
	 * @param existingRecords Map<Id, SObject>
	 * @param uow ApplicationUnitOfWork
	 * @description sync the Case__c and fields defined in the GenesysConstants when related record changes to a new case
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

		Set<SObjectField> voiceCaseFieldOverride = new Set<SObjectField>(GenesysConstants.voiceCallCaseFieldMappings.values());
		voiceCaseFieldOverride.add(VoiceCall.Case__c);
		voiceCaseFieldOverride.add(VoiceCall.RelatedRecordId);
		voiceCaseFieldOverride.add(VoiceCall.RootCause__c);
		voiceCaseFieldOverride.add(VoiceCall.Outcome__c);
		Map<Id,VoiceCall> voiceCallUpdatable = new Map<Id,VoiceCall>(VoiceCallsSelector.newInstance(0, voiceCaseFieldOverride).selectByIds(new Set<Object>(), voiceCallIdToProcess.keySet()));
		Map<Id,Case> relatedCases = CasesSelector.newInstance(GenesysConstants.voiceCallCaseFieldMappings.keySet()).selectById(relatedCaseIds);
		for (Id vcId : voiceCallUpdatable.keySet()) {
			VoiceCall vc = voiceCallUpdatable.get(vcId);
			vc.Case__c = voiceCallIdToProcess.get(vcId).RelatedRecordId;
			for (SObjectField field : GenesysConstants.voiceCallCaseFieldMappings.keySet()) {
				vc.put(GenesysConstants.voiceCallCaseFieldMappings.get(field), relatedCases.get(vc.RelatedRecordId).get(field));
			}
			vc.RootCause__c = vc.RootCause__c ?? GenesysConstants.DEFAULT_VOICE_CALL_ROOT_CAUSE;
			vc.Outcome__c = determineVoiceCallOutcome(vc);
		}

		uow.registerDirty(voiceCallUpdatable.values());
	}

	/**
	 * @param voiceCall VoiceCall
	 * @return String
	 * @description logic to determine the value of the Outcome__c field
	 */
	private static String determineVoiceCallOutcome(VoiceCall voiceCall) {
		if (voiceCall.Case__c == null) { //todo can the below constant be made into a map to reduce code
			return GenesysConstants.VOICE_CALL_OUTCOME_UNLINKED_CONTACT;
		} else if (GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_GENERAL_ENQUIRY.equalsIgnoreCase(voiceCall.EnquiryType__c)) {
			return GenesysConstants.VOICE_CALL_OUTCOME_FCR;
		} else if (GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_INVESTIGATION.equalsIgnoreCase(voiceCall.EnquiryType__c)) {
			return GenesysConstants.VOICE_CALL_OUTCOME_ENQUIRY_LODGED;
		} else if (GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_INVESTIGATION.equalsIgnoreCase(voiceCall.EnquiryType__c)) { //todo figure out the distinction with the above
			return GenesysConstants.VOICE_CALL_OUTCOME_ENQUIRY_UPDATED;
		}
		return null;
	}

	/**
	 * @param records List<SObject>
	 * @param existingRecords Map<Id, SObject>
	 * @description Syncs the VoiceCall status to the Call Interaction record so that the view call page can show the call status.
	 */
	@TestVisible
	private static void syncVoiceCallToGenesysCallInteraction(List<SObject> records, Map<Id, SObject> existingRecords) {
		// Consolidate voice call records and invoke platform event for synchronisation to Genesys
		List<GenesysVoiceInteraction__e> eventList = GenesysInteractionSyncQueueable.obtainVoiceCallChangeEvents(
			records,
			existingRecords
		);

		if (eventList != null && !eventList.isEmpty()) {
			ApplicationDatabase.getInstance().eventPublish(eventList);
		}
	}

	/**
	 * @param records List<SObject>
	 * @param existingRecords Map<Id, SObject>
	 * @param uow ApplicationUnitOfWork
	 * @description when a Voice Call is being transferred, if the subsequent Voice Call changes, it should sync back to the original call
	 */
	@TestVisible
	private static void syncVoiceCallParticipants(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		Map<Id,Map<SObjectField,Object>> updatesByOriginalCallId = new Map<Id,Map<SObjectField,Object>>();
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{VoiceCall.Id, VoiceCall.OriginalVoiceCall__c};
		for (VoiceCall record :(List<VoiceCall>)records) {
			if (record.OriginalVoiceCall__c == null && record.NextCallId == null) {
				continue;
			}
			for (SObjectField field :GenesysConstants.voiceCallFieldMappings.keySet()) {
				if (hasChanged(record, existingRecords?.get(record.Id), field)) {
					Id keyVoiceCallId = record.OriginalVoiceCall__c ?? record.Id;
					if (!updatesByOriginalCallId.containsKey(keyVoiceCallId)) {
						updatesByOriginalCallId.put(keyVoiceCallId, new Map<SObjectField,Object>());
					}

					updatesByOriginalCallId.get(keyVoiceCallId).put(
						field, record.get(field)
					);

					fieldOverrides.add(field);
				}
			}
		}

		if (updatesByOriginalCallId.isEmpty()) {
			return;
		}

		List<VoiceCall> relatedVoiceCalls = VoiceCallsSelector.newInstance(0,fieldOverrides).selectByOriginalVoiceCalls(new Set<Object>(), updatesByOriginalCallId.keySet());
		List<VoiceCall> originalVoiceCalls = VoiceCallsSelector.newInstance(0,fieldOverrides).selectByIds(new Set<Object>(), updatesByOriginalCallId.keySet());
		List<VoiceCall> voiceCallUpdatable = new List<VoiceCall>();
		voiceCallUpdatable.addAll(relatedVoiceCalls);
		voiceCallUpdatable.addAll(originalVoiceCalls);
		for (VoiceCall vc : voiceCallUpdatable) {
			Map<SObjectField,Object> fieldValues = updatesByOriginalCallId.get(vc.OriginalVoiceCall__c) ?? updatesByOriginalCallId.get(vc.Id); // use OriginalVoiceCall__c for the related calls, and id for the original call itself
			for (SObjectField field : fieldValues.keySet()) {
				vc.put(field, fieldValues.get(field));
			}
		}
		uow.registerDirty(voiceCallUpdatable);
	}

	/**
	 * Filter the list of records by comparing the old record's field values with the new record's field values
	 * @param newList - new list of records
	 * @param oldMap - map of old record values
	 * @param comparisonFields - list of fields to compare
	 * @return list of records that have >= 1 comparisonFields changed
	 */
	private static List<SObject> hasChanged(List<SObject> newList, Map<Id,SObject> oldMap, Set<SObjectField> comparisonFields) {
		List<SObject> result = new List<SObject>();

		for (SObject record :newList) {
			if (hasChanged(record, oldMap.get(record.Id), comparisonFields)) {
				result.add(record);
			}
		}

		return result;
	}

	/**
	 * Compare the two SObject instances passed in by doing a field by field comparison for the set of fields
	 * Returns true if at least one field is different.
	 *
	 * @param newRecord SObject for comparison
	 * @param existingRecord SObject for comparison
	 * @param comparisonFields fields to compare
	 *
	 * @return true if at least one field from the interested field set is different. false otherwise.
	 */
	private static Boolean hasChanged(SObject newRecord, SObject existingRecord, Set<SObjectField> comparisonFields) {
		Boolean result = false;

		if (newRecord != null && existingRecord != null) {
			for (SObjectField field : comparisonFields) {
				if (hasChanged(newRecord, existingRecord, field)) {
					result = true;
					break;
				}
			}
		}

		return result;
	}

	private static Boolean hasChanged(SObject newRecord, SObject existingRecord, SObjectField field) {
		return existingRecord == null || newRecord.get(field) != existingRecord.get(field);
	}
}