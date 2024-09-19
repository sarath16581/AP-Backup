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
		getTriggerEvents().enableAfterInsert();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			autoLinkContact(records, uow);
		} catch (Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'Unified Voice Call', UnifiedVoiceCallModule.class.getName(), 'onAfterInsert', 'VoiceCall', ApplicationLogger.LoggingLevel.ERROR);
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
			String reversedPhoneNumber = con.ReverseMobilePhone__c ?? con.ReverseVerifiedMobile__c;
			reversedPhoneNumber = reversedPhoneNumber ?? con.ReversePhone__c;
			if (contactsByReversedPhone.get(reversedPhoneNumber) == null) {
				contactsByReversedPhone.put(reversedPhoneNumber, new List<Contact>{con});
			} else {
				contactsByReversedPhone.get(reversedPhoneNumber).add(con);
			}
		}

		for (VoiceCall vc : voiceCallRecordsMap.values()) {
			String reversedParticipantDisplayName = Util.reversePhoneString(vc.Caller?.ParticipantDisplayName);
			String reversedRecipientDisplayName = Util.reversePhoneString(vc.Recipient?.ParticipantDisplayName);
			if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE) && !String.isBlank(reversedParticipantDisplayName)) {
				List<Contact> potentialContact = contactsByReversedPhone.get(Util.reversePhoneString(vc.Caller.ParticipantDisplayName));
				vc.Contact__c = potentialContact?.size() == 1 ? potentialContact.get(0).Id : null;
			} else if (vc.CallType.equalsIgnoreCase(GenesysConstants.VOICE_CALL_OUTBOUND_CALL_TYPE) && !String.isBlank(reversedRecipientDisplayName)) {
				List<Contact> potentialContact = contactsByReversedPhone.get(reversedRecipientDisplayName);
				vc.Contact__c = potentialContact?.size() == 1 ? potentialContact.get(0).Id : null;
			}
		}

		uow.registerDirty(voiceCallRecordsMap.values());
	}

	@TestVisible
	private static Set<SObjectField> getContactFieldOverrides() {
		return new Set<SObjectField>{Contact.ReverseMobilePhone__c, Contact.ReverseVerifiedMobile__c, Contact.ReversePhone__c};
	}
}