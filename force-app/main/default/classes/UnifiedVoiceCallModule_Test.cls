/**
 * @description
 * Test class for UnifiedVoiceCallModule
 * @author SteveL
 * @date 2024-09-10
 * @group Tests
 * @changelog
 * 2024-09-10 - SteveL - Created
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

		VoiceCall vc = ApplicationTestDataFactory.getVoiceCalls(1, true)[0];

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
}