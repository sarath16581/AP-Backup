/**
 * @description
 * Test class for UnifiedVoiceCallModule
 * @author SteveL
 * @date 2024-09-10
 * @group Tests
 * @changelog
 * 2024-09-10 - SteveL - Created
 * 2024-09-24 - SteveL - added assignRelatedRecordIdWhenCaseLinked_Test
 */

@IsTest
private class UnifiedVoiceCallModule_Test {
	@IsTest
	private static void testBeforeInsert_AutoLinkContact() {
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		acc.LEGACY_ID__c = '60000000';

		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'TEAM', true)[0];

		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc.Id, true);
		contacts[0].FirstName = 'Sim';
		contacts[0].Phone = '+61440123456';
		contacts[0].BillingAccount__c = billingAcc.Id;
		contacts[0] = (Contact)ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{
			'ReverseMobilePhone__c' => '654321044'
		});

		Case aCase = ApplicationTestDataFactoryCase.getCases(1, new Set<Id>{contacts[0].Id}, true)[0];
		VoiceCall vc = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{aCase.Id}, true)[0];

		ConversationParticipant caller = new ConversationParticipant();
		caller = (ConversationParticipant)ApplicationTestDataFactory.setUnwritableFields(caller, new Map<String, Object>{
			'ParticipantDisplayName' => '+61440123456'
		});

		vc = (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(vc, new Map<String, Object>{
			'CallType' => GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE,
			'CallerId' => '123456',
			'Caller' => caller
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(VoiceCallTriggerHandler.getUnitOfWorkSObjectTypes());
		VoiceCallsSelector voiceCallsSelector = (VoiceCallsSelector)MockUtility.mockSelector(VoiceCallsSelector.class);
		ContactsSelector contactsSelector = (ContactsSelector)MockUtility.mockSelector(ContactsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(voiceCallsSelector.selectByIds((Set<Object>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject())).thenReturn(new List<VoiceCall>{vc});
		MockUtility.Mocks.when(contactsSelector.selectByReversedPhoneNumbers((Set<Object>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id,Contact>(contacts));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		UnifiedVoiceCallModule module = UnifiedVoiceCallModule.newInstance();
		module.onAfterInsert(new List<VoiceCall>{vc}, uow);
		System.assertEquals(contacts[0].Id, vc.Contact__c, 'Expect the new Voice Record to link to the existing Contact record');
		Test.stopTest();
	}

	@IsTest
	private static void testBeforeTrigger_assignRelatedRecordIdWhenCaseLinked() {
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		acc.LEGACY_ID__c = '60000000';

		Billing_Account__c billingAcc = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'TEAM', true)[0];

		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc.Id, true);
		contacts[0].FirstName = 'Sim';
		contacts[0].Phone = '+61440123456';
		contacts[0].BillingAccount__c = billingAcc.Id;
		contacts[0] = (Contact)ApplicationTestDataFactory.setUnwritableFields(contacts[0], new Map<String, Object>{
				'ReverseMobilePhone__c' => '654321044'
		});

		Case aCase = ApplicationTestDataFactoryCase.getCases(1, new Set<Id>{contacts[0].Id}, true)[0];
		VoiceCall vc = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{aCase.Id}, true)[0];
		vc.Case__c = aCase.Id;

		ConversationParticipant caller = new ConversationParticipant();
		caller = (ConversationParticipant)ApplicationTestDataFactory.setUnwritableFields(caller, new Map<String, Object>{
				'ParticipantDisplayName' => '+61440123456'
		});

		vc = (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(vc, new Map<String, Object>{
				'CallType' => GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE,
				'CallerId' => '123456',
				'Caller' => caller,
				'RelatedRecordId' => null // the getVoiceCalls method will populate the RelatedRecordId, and the method being tested is attempting to populate this, so getting rid of it here in data setup
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(VoiceCallTriggerHandler.getUnitOfWorkSObjectTypes());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		UnifiedVoiceCallModule module = UnifiedVoiceCallModule.newInstance();
		module.onBeforeInsert(new List<VoiceCall>{vc}, uow);
		System.assert(vc.RelatedRecordId != null, 'Expecting the Voice Call record RelatedRecordId not to be null');
		System.assert(vc.Case__c != null, 'Expecting the Voice Call record Case__c not to be null');
		System.assertEquals(vc.RelatedRecordId, vc.Case__c, 'Expecting the Voice Call record to have the RelatedRecordId populated with Case__c value');

		UnifiedVoiceCallModule module2 = UnifiedVoiceCallModule.newInstance();
		Map<Id, VoiceCall> oldVoiceCalls = new Map<Id, VoiceCall>{vc.Id => vc};
		vc.Case__c = null;
		module2.onBeforeUpdate(new List<VoiceCall>{vc}, oldVoiceCalls, uow);
		System.assertEquals(null, vc.Case__c, 'Expecting the Voice Call Case__c to be null during this update trigger');
		System.assertEquals(null, vc.RelatedRecordId, 'Expecting the Voice Call RelatedRecordId to be null during this update trigger');
		Test.stopTest();
	}
}