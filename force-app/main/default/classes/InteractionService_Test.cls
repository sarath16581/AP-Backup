/**
 * Test class for InteractionService
 * 
 * changelog:
 * 2024-09-24 	George Nguyen	created
 */
@IsTest
class InteractionService_Test {

	@IsTest
	static void mappedFields() {
		System.assertEquals(ContactRequest.WhatId, InteractionService.MAPPED_STANDARD_FIELDS.get(ContactRequest.SobjectType));
		System.assertEquals(VoiceCall.RelatedRecordId, InteractionService.MAPPED_STANDARD_FIELDS.get(VoiceCall.SobjectType));
		System.assertEquals(LiveChatTranscript.CaseId, InteractionService.MAPPED_CASE_FIELDS.get(LiveChatTranscript.SobjectType));
		System.assertEquals(ContactRequest.Case__c, InteractionService.MAPPED_CASE_FIELDS.get(ContactRequest.SobjectType));
		System.assertEquals(VoiceCall.Case__c, InteractionService.MAPPED_CASE_FIELDS.get(VoiceCall.SobjectType));
	}
    
	@IsTest
	static void retrieveInteractionRecords() {
		LiveChatTranscriptsSelector mockLiveChatTranscriptsSelector = (LiveChatTranscriptsSelector)MockUtility.mockSelector(LiveChatTranscriptsSelector.class);
		ContactRequestsSelector mockContactRequestsSelector = (ContactRequestsSelector)MockUtility.mockSelector(ContactRequestsSelector.class);
		VoiceCallsSelector mockVoiceCallsSelector = (VoiceCallsSelector)MockUtility.mockSelector(VoiceCallsSelector.class);

		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact ct = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		List<Case> caseList = ApplicationTestDataFactoryCase.getCases(3, true);

		ContactRequest cr = ApplicationTestDataFactoryCase.getContactRequests(1, caseList[0].Id, ct.Id, true)[0];
		cr.Case__c = caseList[0].Id; 

		VoiceCall vc = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{caseList[1].Id}, true)[0];
		vc.Case__c = caseList[1].Id; 

		LiveChatTranscript lc = ApplicationTestDataFactoryCase.getLiveChatTranscripts(1, new List<Id>{caseList[2].Id}, true)[0];
		
		Map<SObjectType, Set<Id>> mappedObjectTypeAndIds = new Map<SObjectType, Set<Id>>();
		mappedObjectTypeAndIds.put(LiveChatTranscript.SObjectType, new Set<Id>{lc.id});
		mappedObjectTypeAndIds.put(ContactRequest.SObjectType, new Set<Id>{cr.id});
		mappedObjectTypeAndIds.put(VoiceCall.SObjectType, new Set<Id>{vc.id});

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockLiveChatTranscriptsSelector.selectByIds(
															(Set<Object>)fflib_Match.eq(new Set<Object>{}),
															(Set<Id>)fflib_Match.eq(mappedObjectTypeAndIds.get(LiveChatTranscript.SObjectType))															
														)).thenReturn(
															new List<LiveChatTranscript>{lc}
														);

		MockUtility.Mocks.when(mockContactRequestsSelector.selectByIds(
															(Set<Object>)fflib_Match.eq(new Set<Object>{}),
															(Set<Id>)fflib_Match.eq(mappedObjectTypeAndIds.get(ContactRequest.SObjectType))															
														)).thenReturn(
															new List<ContactRequest>{cr}
														);

		MockUtility.Mocks.when(mockVoiceCallsSelector.selectByIds(
															(Set<Object>)fflib_Match.eq(new Set<Object>{}),
															(Set<Id>)fflib_Match.eq(mappedObjectTypeAndIds.get(VoiceCall.SObjectType))															
														)).thenReturn(
															new List<VoiceCall>{vc}
														);
		MockUtility.Mocks.stopStubbing();

		InteractionService service = new InteractionService();
		Map<Id, SObject> workItems = service.retrieveInteractionRecords(mappedObjectTypeAndIds);

		System.assert(workItems.containsKey(cr.Id), 'Should return a ContactRequest record');
		System.assert(workItems.containsKey(lc.Id), 'Should return a LiveChatTranscript record');
		System.assert(workItems.containsKey(vc.Id), 'Should return a VoiceCall record');
	}

	@IsTest
	static void populateCaseFieldOnAgentWorks() {
		ApplicationUnitOfWork mockApplicationUnitOfWork = MockUtility.mockUnitOfWork();
		String source = 'InteractionService.populateCaseFieldOnAgentWorks';

		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact ct = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		List<Case> caseList = ApplicationTestDataFactoryCase.getCases(3, true);

		ContactRequest cr = ApplicationTestDataFactoryCase.getContactRequests(1, caseList[0].Id, ct.Id, true)[0];
		cr.Case__c = caseList[0].Id; 

		VoiceCall vc = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{caseList[1].Id}, true)[0];
		vc.Case__c = caseList[1].Id; 

		LiveChatTranscript lc = ApplicationTestDataFactoryCase.getLiveChatTranscripts(1, new List<Id>{caseList[2].Id}, true)[0];

		List<AgentWork> agentWorkRecords = ApplicationTestDataFactoryCase.getAgentWorks(3, new List<Id>{UserInfo.getUserId(), UserInfo.getUserId(), UserInfo.getUserId()}, new List<Id>{cr.Id, vc.Id, lc.Id}, true);
		Map<Id, SObject> workItems = new Map<Id, SObject>{cr.Id => cr, vc.id => vc, lc.id => lc};

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		InteractionService service = new InteractionService();
		service.populateCaseFieldOnAgentWorks(workItems, agentWorkRecords, mockApplicationUnitOfWork, source);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockApplicationUnitOfWork, MockUtility.Mocks.times(1))).registerDirty(
															(List<AgentWork>)fflib_Match.eq(new List<AgentWork>{
																new AgentWork(Id = agentWorkRecords[0].Id, Case__c = caseList[0].Id),
																new AgentWork(Id = agentWorkRecords[1].Id, Case__c = caseList[1].Id),
																new AgentWork(Id = agentWorkRecords[2].Id, Case__c = caseList[2].Id)
															}), 
															(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{AgentWork.Case__c}),
															fflib_Match.eqBoolean(false), 
															(String)fflib_Match.eq(source)
														);
	}
}