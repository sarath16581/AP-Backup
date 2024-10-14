/**
 * @description
 * Test class for UnifiedVoiceCallModule
 * @author SteveL
 * @date 2024-09-10
 * @group Tests
 * @changelog
 * 2024-09-10 - SteveL - Created
 * 2024-10-10 - SteveL - updated with a test method for copyLookupDetailsFromTextValues
 */

@IsTest
private class UnifiedVoiceCallModule_Test {
	@IsTest
	private static void testAfterInsert_AutoLinkContact() {
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
	private static void testAfterBefore_CopyLookupDetailsFromPreviousCall() {
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

		ConversationParticipant caller = new ConversationParticipant();
		caller = (ConversationParticipant)ApplicationTestDataFactory.setUnwritableFields(caller, new Map<String, Object>{
				'ParticipantDisplayName' => '+61440123456'
		});

		String testContactTextId = '003AD00000VQW8rYAH';
		String testCaseTextId = '500AD00000I3BscYAF';

		VoiceCall currentVoiceCall = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{aCase.Id}, true)[0];
		currentVoiceCall = (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(currentVoiceCall, new Map<String, Object>{
				'CallType' => GenesysConstants.VOICE_CALL_TRANSFER_CALL_TYPE,
				'CallerId' => '123456',
				'Caller' => caller,
				'ContactId__c' => testContactTextId,
				'CaseId__c' => testCaseTextId,
				'PreviousCallId' => '32993292'
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(VoiceCallTriggerHandler.getUnitOfWorkSObjectTypes());

		Test.startTest();
		UnifiedVoiceCallModule module = UnifiedVoiceCallModule.newInstance();
		module.onBeforeInsert(new List<VoiceCall>{currentVoiceCall}, uow);

		System.assertEquals(testContactTextId, currentVoiceCall.Contact__c, 'Expect the new Voice Record to copy the text value from ContactId__c');
		System.assertEquals(null, currentVoiceCall.ContactId__c, 'Expect the new Voice Record to blank out the text ContactId__c value');
		System.assertEquals(testCaseTextId, currentVoiceCall.RelatedRecordId, 'Expect the new Voice Record to copy the text value from CaseId__c');
		System.assertEquals(currentVoiceCall.Case__c, currentVoiceCall.RelatedRecordId, 'Expect the newly insert Voice Call to have the Case__c field populated by the RelatedRecordId');
		System.assertEquals(null, currentVoiceCall.CaseId__c, 'Expect the new Voice Record to blank out the text CaseId__c value');
		Test.stopTest();
	}
}