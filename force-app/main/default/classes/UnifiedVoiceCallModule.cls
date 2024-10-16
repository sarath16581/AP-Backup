/***
 * @description VoiceCall trigger module for VoiceCall sync and Genesys Interaction sync
 * NOTE: 	Invokes all the logic upon DML for the VoiceCall object
 * @author 	Paul Perry
 * @date 	2024-08-27
 * @changelog
 * 2024-08-27 Paul Perry - created
 * 2024-10-10 SteveL - updated with copyLookupDetailsFromTextValues to have the transferred calls lookup fields values populated from their text fields counterparts
 */
public with sharing class UnifiedVoiceCallModule extends ApplicationModule {
	public static UnifiedVoiceCallModule newInstance() {
		return (UnifiedVoiceCallModule)Application.Utilities.newInstance(UnifiedVoiceCallModule.class);
	}

	/**
	 * Constructor
	 */
	public UnifiedVoiceCallModule() {
		getTriggerEvents().enableBeforeInsert().enableAfterInsert();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			copyLookupDetailsFromTextValues(records);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'Unified Voice Call', UnifiedVoiceCallModule.class.getName(), 'onBeforeInsert', 'VoiceCall', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			autoLinkContact(records, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'Unified Voice Call', UnifiedVoiceCallModule.class.getName(), 'onAfterInsert', 'VoiceCall', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * when a Voice Call record is created, attempt to auto populate the Contact__c field base on the phone number when the Call Type is either inbound or outbound
	 * @param records List<SObject>
	 * @param uow ApplicationUnitOfWork
	 */
	@TestVisible
	private static void autoLinkContact(List<SObject> records, ApplicationUnitOfWork uow) {
		Set<Id> voiceCallToProcess = new Set<Id>();
		for (VoiceCall vc : (List<VoiceCall>) records) {
			if ((vc.CallType == GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE || vc.CallType == GenesysConstants.VOICE_CALL_OUTBOUND_CALL_TYPE) && (vc.CallerId != null || vc.RecipientId != null) ) {
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
			String reversedParticipantDisplayName = Util.reversePhoneString(vc.Caller?.ParticipantDisplayName);
			String reversedRecipientDisplayName = Util.reversePhoneString(vc.Recipient?.ParticipantDisplayName);
			if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE) && !String.isBlank(reversedParticipantDisplayName)) {
				voiceCallReversedPhoneNumber.add(reversedParticipantDisplayName);
			} else if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_OUTBOUND_CALL_TYPE) && !String.isBlank(reversedRecipientDisplayName)) {
				voiceCallReversedPhoneNumber.add(reversedRecipientDisplayName);
			}
		}

		if (voiceCallReversedPhoneNumber.isEmpty()) {
			return;
		}

		Map<Id, Contact> contactMap = ContactsSelector.newInstance(0, getContactFieldOverrides()).selectByReversedPhoneNumbers(new Set<Object>(), voiceCallReversedPhoneNumber);

		Map<String, Contact[]> contactsByReversedPhone = new Map<String,Contact[]>();
		for (Contact con : contactMap.values()) {
			Set<String> reversedNumbers = new Set<String>{con.ReverseVerifiedMobile__c, con.ReverseMobilePhone__c, con.ReversePhone__c};
			for (String rNumber : reversedNumbers) {
				if (contactsByReversedPhone.get(rNumber) == null) {
					contactsByReversedPhone.put(rNumber, new List<Contact>{con});
				} else {
					contactsByReversedPhone.get(rNumber).add(con);
				}
			}
		}

		for (VoiceCall vc : voiceCallRecordsMap.values()) {
			String reversedParticipantDisplayName = Util.reversePhoneString(vc.Caller?.ParticipantDisplayName);
			String reversedRecipientDisplayName = Util.reversePhoneString(vc.Recipient?.ParticipantDisplayName);

			if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE) && !String.isBlank(reversedParticipantDisplayName)) {
				List<Contact> potentialContact = contactsByReversedPhone.get(reversedParticipantDisplayName);
				vc.Contact__c = potentialContact?.size() == 1 ? potentialContact.get(0).Id : null;
			} else if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_OUTBOUND_CALL_TYPE) && !String.isBlank(reversedRecipientDisplayName)) {
				List<Contact> potentialContact = contactsByReversedPhone.get(reversedRecipientDisplayName);
				vc.Contact__c = potentialContact?.size() == 1 ? potentialContact.get(0).Id : null;
			}
		}

		uow.registerDirty(voiceCallRecordsMap.values());
	}

	/**
	 * when a new Voice Call is created with Call Type as Transfer, populate the Lookup up fields RelatedRecordId and Contact__c with the values from their respective text field value, then clear out the text field values
	 * @param records List<SObject>
	 */
	@TestVisible
	private static void copyLookupDetailsFromTextValues(List<SObject> records) {
		for (VoiceCall vc : (List<VoiceCall>) records) {
			if (vc.CallType == GenesysConstants.VOICE_CALL_TRANSFER_CALL_TYPE  && vc.PreviousCallId != null) {
				vc.Contact__c = vc.ContactId__c; // populate the Lookup field Contact__c from its text field equivalent as Genesys mapping does not support lookup fields
				vc.RelatedRecordId = vc.CaseId__c; // populate the Lookup field RelatedRecordId from its text field equivalent as Genesys mapping does not support lookup fields
				vc.ContactId__c = null;
				vc.CaseId__c = null;
			}
		}
	}

	@TestVisible
	private static Set<SObjectField> getContactFieldOverrides() {
		return new Set<SObjectField>{Contact.ReverseMobilePhone__c, Contact.ReverseVerifiedMobile__c, Contact.ReversePhone__c};
	}
}