/**
* @description Test class covering CaseRecordPopulationModule
* @changelog
* 2024-08-23	George Nguyen	Created 
*/
@IsTest
class CaseRecordPopulationModule_Test {
    
	@IsTest
	static void mappedFields() {
		System.assertEquals(ContactRequest.WhatId, CaseRecordPopulationModule.MAPPED_LOOKUP_FIELDS.get(ContactRequest.SobjectType), 'It should return the correct field mapping');
		System.assertEquals(VoiceCall.RelatedRecordId, CaseRecordPopulationModule.MAPPED_LOOKUP_FIELDS.get(VoiceCall.SobjectType), 'It should return the correct field mapping');

		System.assertEquals(ContactRequest.Case__c, CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(ContactRequest.SobjectType), 'It should return the correct field mapping');
		System.assertEquals(VoiceCall.Case__c, CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(VoiceCall.SobjectType), 'It should return the correct field mapping');
		System.assertEquals(LiveChatTranscript.CaseId, CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(LiveChatTranscript.SobjectType), 'It should return the correct field mapping');
	}

	@IsTest
	static void assignCaseValues() {
		ApplicationRecursion mockApplicationRecursion = (ApplicationRecursion)MockUtility.mockUtility(ApplicationRecursion.class);
		ApplicationUnitOfWork mockApplicationUnitOfWork = MockUtility.mockUnitOfWork();
		String recursionContext = 'CaseRecordPopulationModule.assignCaseValues';

		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact ct = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		Case aCase = ApplicationTestDataFactoryCase.getCases(1, new Set<Id>{ct.Id}, true)[0];

		ContactRequest cr = ApplicationTestDataFactoryCase.getContactRequests(1, aCase.Id, ct.Id, true)[0];
		cr.Case__c = null; 

		VoiceCall vc = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{aCase.Id}, true)[0];
		vc.Case__c = null; 

		List<SObject> recordList = new List<SObject>{cr, vc};
		Map<Id, SObject> oldMap = new Map<Id, SObject>{
										cr.Id => cr.clone(true, true, true),
										vc.Id => (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(vc, new Map<String, Object>{'RelatedRecordId' => null}) // simulate changed field
									};

		((ContactRequest)oldMap.get(cr.Id)).WhatId = null; // simulate changed field

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockApplicationRecursion.getProcessableRecords(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{cr}), 
															(Map<Id, SObject>)fflib_Match.eq(oldMap), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_LOOKUP_FIELDS.get(ContactRequest.getsObjectType())})
														)).thenReturn(
															new List<ApplicationRecursion.RecordState>{
																new ApplicationRecursion.RecordState(cr, new Map<String, SObject>{cr.Id => oldMap.get(cr.Id)}, new Set<SObjectField>{ContactRequest.WhatId})
															}
														);

		MockUtility.Mocks.when(mockApplicationRecursion.getProcessableRecords(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{vc}), 
															(Map<Id, SObject>)fflib_Match.eq(oldMap), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_LOOKUP_FIELDS.get(Voicecall.getsObjectType())})
														)).thenReturn(
															new List<ApplicationRecursion.RecordState>{
																new ApplicationRecursion.RecordState(vc, new Map<String, SObject>{vc.Id => oldMap.get(vc.Id)}, new Set<SObjectField>{VoiceCall.RelatedRecordId})
															}
														);
		MockUtility.Mocks.stopStubbing();

		CaseRecordPopulationModule module = new CaseRecordPopulationModule();
		module.assignCaseValues(recordList, oldMap, mockApplicationUnitOfWork);

		System.assertEquals(aCase.Id, cr.Case__c, 'The case lookup field should be set');
		((ApplicationRecursion) MockUtility.Mocks.verify(mockApplicationRecursion, MockUtility.Mocks.times(1))).updateRecordState(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{cr}), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_LOOKUP_FIELDS.get(ContactRequest.getsObjectType())})
														);

		System.assertEquals(aCase.Id, vc.Case__c, 'The case lookup field should be set');
		((ApplicationRecursion) MockUtility.Mocks.verify(mockApplicationRecursion, MockUtility.Mocks.times(1))).updateRecordState(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{vc}), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_LOOKUP_FIELDS.get(VoiceCall.getsObjectType())})
														);
	}

	@IsTest
	static void backfillAgentWorkRecords() {
		ApplicationRecursion mockApplicationRecursion = (ApplicationRecursion)MockUtility.mockUtility(ApplicationRecursion.class);
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		ApplicationUnitOfWork mockApplicationUnitOfWork = MockUtility.mockUnitOfWork();
		String recursionContext = 'CaseRecordPopulationModule.backfillAgentWorkRecords';

		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact ct = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		List<Case> caseList = ApplicationTestDataFactoryCase.getCases(3, true);

		ContactRequest cr = ApplicationTestDataFactoryCase.getContactRequests(1, caseList[0].Id, ct.Id, true)[0];
		cr.Case__c = caseList[0].Id; 

		VoiceCall vc = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{caseList[1].Id}, true)[0];
		vc.Case__c = caseList[1].Id; 

		LiveChatTranscript lc = ApplicationTestDataFactoryCase.getLiveChatTranscripts(1, new List<Id>{caseList[2].Id}, true)[0];

		List<AgentWork> agentWorkList = ApplicationTestDataFactoryCase.getAgentWorks(3, new List<Id>{UserInfo.getUserId(), UserInfo.getUserId(), UserInfo.getUserId()}, new List<Id>{cr.Id, vc.Id, lc.Id}, true);
		List<SObject> recordList = new List<SObject>{cr, vc, lc};
		Map<Id, SObject> oldMap = new Map<Id, SObject>(recordList.deepClone(true, true, true));
		((ContactRequest)oldMap.get(cr.Id)).Case__c = null; // simulate change
		((VoiceCall)oldMap.get(vc.Id)).Case__c = null; // simulate change
		((LiveChatTranscript)oldMap.get(lc.Id)).CaseId = null; // simulate change

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockApplicationRecursion.getProcessableRecords(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{cr}), 
															(Map<Id, SObject>)fflib_Match.eq(oldMap), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(ContactRequest.getsObjectType())})
														)).thenReturn(
															new List<ApplicationRecursion.RecordState>{
																new ApplicationRecursion.RecordState(cr, new Map<String, SObject>{cr.Id => oldMap.get(cr.Id)}, new Set<SObjectField>{ContactRequest.Case__c})
															}
														);

		MockUtility.Mocks.when(mockApplicationRecursion.getProcessableRecords(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{vc}), 
															(Map<Id, SObject>)fflib_Match.eq(oldMap), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(Voicecall.getsObjectType())})
														)).thenReturn(
															new List<ApplicationRecursion.RecordState>{
																new ApplicationRecursion.RecordState(vc, new Map<String, SObject>{vc.Id => oldMap.get(vc.Id)}, new Set<SObjectField>{VoiceCall.Case__c})
															}
														);

		MockUtility.Mocks.when(mockApplicationRecursion.getProcessableRecords(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{lc}), 
															(Map<Id, SObject>)fflib_Match.eq(oldMap), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(LiveChatTranscript.getsObjectType())})
														)).thenReturn(
															new List<ApplicationRecursion.RecordState>{
																new ApplicationRecursion.RecordState(lc, new Map<String, SObject>{lc.Id => oldMap.get(lc.Id)}, new Set<SObjectField>{LiveChatTranscript.CaseId})
															}
														);	

		MockUtility.Mocks.when(mockAgentWorkSelector.selectByWorkItemIds(
															(Set<Id>)fflib_Match.eq(oldMap.keySet()),
															(Set<Object>)fflib_Match.eq(new Set<Object>{})															
														)).thenReturn(
															agentWorkList
														);
		MockUtility.Mocks.stopStubbing();

		CaseRecordPopulationModule module = new CaseRecordPopulationModule();
		module.backfillAgentWorkRecords(recordList, oldMap, mockApplicationUnitOfWork);

		((ApplicationRecursion) MockUtility.Mocks.verify(mockApplicationRecursion, MockUtility.Mocks.times(1))).updateRecordState(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{cr}), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(ContactRequest.getsObjectType())})
														);

		((ApplicationRecursion) MockUtility.Mocks.verify(mockApplicationRecursion, MockUtility.Mocks.times(1))).updateRecordState(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{vc}), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(VoiceCall.getsObjectType())})
														);

		((ApplicationRecursion) MockUtility.Mocks.verify(mockApplicationRecursion, MockUtility.Mocks.times(1))).updateRecordState(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{lc}), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{CaseRecordPopulationModule.MAPPED_CASE_FIELDS.get(LiveChatTranscript.getsObjectType())})
														);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockApplicationUnitOfWork, MockUtility.Mocks.times(1))).registerDirty(
															(List<AgentWork>)fflib_Match.eq(new List<AgentWork>{
																new AgentWork(Id = agentWorkList[0].Id, Case__c = caseList[0].Id),
																new AgentWork(Id = agentWorkList[1].Id, Case__c = caseList[1].Id),
																new AgentWork(Id = agentWorkList[2].Id, Case__c = caseList[2].Id)
															}), 
															(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{AgentWork.Case__c}),
															fflib_Match.eqBoolean(false), 
															(String)fflib_Match.eq(recursionContext)
														);
	}

}