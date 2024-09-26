/**
* @description Test class covering CaseRecordPopulationModule
* @changelog
* 2024-08-23	George Nguyen	Created 
*/
@IsTest
class CaseRecordPopulationModule_Test {

	@IsTest
	static void triggerMethods() {
		Contact con = TestDataProvider.createTestContact();
        insert con;
        
	    Case case1 = new Case(
        	RecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id,
        	Type = 'Feedback',
        	Subject = 'Newsdd',
        	Status = 'New',
        	ProductCategory__c = 'Travel & ID',
        	EnquirySubType__c = 'Product Support',
        	ProductSubCategory__c = 'KeyPass',
        	ContactId = con.Id,
        	ReferenceID__c = '123',
        	ChatKey__c = '8f441452-eb7d-4142-8ae6-5b3ccfffggg'
		);
        insert case1;
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        
        LiveChatTranscript lc = new LiveChatTranscript(
        	ChatKey = '8f441452-eb7d-4142-8ae6-5b3ccfffggg', // must match the case.ChatKey__c
        	Body = 'test',
        	LiveChatVisitorid = lcv.id
		);
        insert lc;

	    lc = [select CaseId from LiveChatTranscript where Id = :lc.Id];
        System.assert(case1.Id == lc.CaseId);

		ContactRequest cr = new ContactRequest(
			WhoId = con.Id,
			WhatId = case1.id,
			RequestDescription = 'test call'
		);

		insert cr;

		cr = [SELECT Case__c FROM ContactRequest WHERE Id =: cr.Id LIMIT 1];
		System.assertEquals(case1.Id, cr.Case__c, 'Case look up Id should match');

		List <CallCenter> listCallCenters = [SELECT Id FROM CallCenter];
		
		VoiceCall vc = new VoiceCall(
			CallCenterId = null, 
			VendorType = 'ContactCenter', 
			CallType = 'Inbound',
			FromPhoneNumber = '+19999999999', 
			ToPhoneNumber = '+19999999999',
			CallStartDateTime = System.now().addMinutes( - 3 ),
			CallEndDateTime = System.now(),
			CallDisposition = 'completed',
			relatedrecordid = case1.Id
		);
		
		insert vc;
		
		vc = [SELECT Case__c FROM VoiceCall WHERE Id =: vc.id LIMIT 1];
		System.assertEquals(case1.Id, vc.Case__c, 'Case look up Id should match');
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
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_STANDARD_FIELDS.get(ContactRequest.getsObjectType())})
														)).thenReturn(
															new List<ApplicationRecursion.RecordState>{
																new ApplicationRecursion.RecordState(cr, new Map<String, SObject>{cr.Id => oldMap.get(cr.Id)}, new Set<SObjectField>{ContactRequest.WhatId})
															}
														);

		MockUtility.Mocks.when(mockApplicationRecursion.getProcessableRecords(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{vc}), 
															(Map<Id, SObject>)fflib_Match.eq(oldMap), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_STANDARD_FIELDS.get(Voicecall.getsObjectType())})
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
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_STANDARD_FIELDS.get(ContactRequest.getsObjectType())})
														);

		System.assertEquals(aCase.Id, vc.Case__c, 'The case lookup field should be set');
		((ApplicationRecursion) MockUtility.Mocks.verify(mockApplicationRecursion, MockUtility.Mocks.times(1))).updateRecordState(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{vc}), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_STANDARD_FIELDS.get(VoiceCall.getsObjectType())})
														);
	}

	@IsTest
	static void backfillAgentWorkRecords() {
		ApplicationRecursion mockApplicationRecursion = (ApplicationRecursion)MockUtility.mockUtility(ApplicationRecursion.class);
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		ApplicationUnitOfWork mockApplicationUnitOfWork = MockUtility.mockUnitOfWork();
		InteractionService mockInteractionService = (InteractionService)MockUtility.mockUtility(InteractionService.class);

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
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_CASE_FIELDS.get(ContactRequest.getsObjectType())})
														)).thenReturn(
															new List<ApplicationRecursion.RecordState>{
																new ApplicationRecursion.RecordState(cr, new Map<String, SObject>{cr.Id => oldMap.get(cr.Id)}, new Set<SObjectField>{ContactRequest.Case__c})
															}
														);

		MockUtility.Mocks.when(mockApplicationRecursion.getProcessableRecords(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{vc}), 
															(Map<Id, SObject>)fflib_Match.eq(oldMap), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_CASE_FIELDS.get(Voicecall.getsObjectType())})
														)).thenReturn(
															new List<ApplicationRecursion.RecordState>{
																new ApplicationRecursion.RecordState(vc, new Map<String, SObject>{vc.Id => oldMap.get(vc.Id)}, new Set<SObjectField>{VoiceCall.Case__c})
															}
														);

		MockUtility.Mocks.when(mockApplicationRecursion.getProcessableRecords(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{lc}), 
															(Map<Id, SObject>)fflib_Match.eq(oldMap), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_CASE_FIELDS.get(LiveChatTranscript.getsObjectType())})
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
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_CASE_FIELDS.get(ContactRequest.getsObjectType())})
														);

		((ApplicationRecursion) MockUtility.Mocks.verify(mockApplicationRecursion, MockUtility.Mocks.times(1))).updateRecordState(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{vc}), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_CASE_FIELDS.get(VoiceCall.getsObjectType())})
														);

		((ApplicationRecursion) MockUtility.Mocks.verify(mockApplicationRecursion, MockUtility.Mocks.times(1))).updateRecordState(
															(String)fflib_Match.eq(recursionContext), 
															(List<SObject>)fflib_Match.eq(new List<SObject>{lc}), 
															(Set<SObjectField>)fflib_Match.eq(new Set<SObjectField>{InteractionService.MAPPED_CASE_FIELDS.get(LiveChatTranscript.getsObjectType())})
														);

		((InteractionService) MockUtility.Mocks.verify(mockInteractionService, MockUtility.Mocks.times(1))).populateCaseFieldOnAgentWorks(
															(Map<Id, SObject>)fflib_Match.eq(new Map<Id, SObject>(recordList)), 
															(List<AgentWork>)fflib_Match.eq(agentWorkList), 
															(ApplicationUnitOfWork)fflib_Match.eq(mockApplicationUnitOfWork),
															(String)fflib_Match.eq(recursionContext)
														);
	}

}