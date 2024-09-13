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

	@IsTest
	private static void testAfterUpdate_SyncCaseWhenRelatedRecordIdChanged() {
		List<Case> cases = ApplicationTestDataFactory.getCases(1, 'REF0001', true);
		cases[0].Type = GenesysConstants.VOICE_CALL_ENQUIRY_TYPE_GENERAL_ENQUIRY;
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{
	'CreatedDate' => System.now()
		});

		List<VoiceCall> voiceCalls = ApplicationTestDataFactory.getVoiceCalls(2, true);
		VoiceCall vcOld = voiceCalls[0];

		ConversationParticipant caller = new ConversationParticipant();
		caller = (ConversationParticipant)ApplicationTestDataFactory.setUnwritableFields(caller, new Map<String, Object>{
	'ParticipantDisplayName' => '+61440123456'
		});

		vcOld = (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(vcOld, new Map<String, Object>{
	'CallType' => GenesysConstants.VOICE_CALL_INBOUND_CALL_TYPE,
	'CallerId' => '123456',
	'Caller' => caller,
	'CallStartDateTime' => System.now().addMinutes(-5)
		});

		VoiceCall vcNew = vcOld.clone(true,true,true);
		vcNew.RelatedRecordId = cases[0].Id;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(VoiceCallTriggerHandler.getUnitOfWorkSObjectTypes());
		VoiceCallsSelector voiceCallsSelector = (VoiceCallsSelector)MockUtility.mockSelector(VoiceCallsSelector.class);
		CasesSelector casesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		CaseHistoriesSelector caseHistoriesSelector = (CaseHistoriesSelector)MockUtility.mockSelector(CaseHistoriesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(voiceCallsSelector.selectByIds((Set<Object>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject())).thenReturn(new List<VoiceCall>{vcNew});
		MockUtility.Mocks.when(casesSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id,Case>(cases));
		MockUtility.Mocks.when(caseHistoriesSelector.selectCaseHistoriesByTypeAndCaseIds((Set<Object>)fflib_Match.anyObject(), (Set<Id>)fflib_Match.anyObject(), (String)fflib_Match.anyObject())).thenReturn(new Map<Id, CaseHistory>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		UnifiedVoiceCallModule module = UnifiedVoiceCallModule.newInstance();
		module.onAfterUpdate(new List<VoiceCall>{vcNew}, new Map<Id,VoiceCall>{vcOld.Id => vcOld}, uow);
		System.assertEquals(cases[0].Id, vcNew.Case__c, 'Expect the Case__c to be populated based on the RelatedRecordId');
		System.assertEquals(GenesysConstants.DEFAULT_VOICE_CALL_ROOT_CAUSE, vcNew.RootCause__c, 'Expect RootCause__c to be populated by the default value');
		System.assertEquals(GenesysConstants.VOICE_CALL_OUTCOME_FCR, vcNew.Outcome__c, 'Expect Outcome to be FCR as Case is created after the Voice Call record, and it is of Type General Enquiry');

		Test.stopTest();
	}
}