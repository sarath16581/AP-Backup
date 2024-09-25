/**
 * @description Testclass for Genesys VoiceCall Module (Interaction Sync)
 * NOTE: 	Synchronises VoiceCall changes to Genesys
 *	- Filters changes in VoiceCall record data (newList => oldMap)
 *	- Generates plaftorm events based on Genesys field Mappings
 *	- Contains the AsyncWorker logic to perform callouts outside of the trigger context
 * @author 	Paul Perry
 * @date 	2024-08-27
 * @group 	Unified
 * @changelog
 * 	2024-08-27 - Paul Perry - created
 */
@IsTest
public with sharing class GenesysVoiceCallModule_Test {
	// Mocking
	private static GenesysIntegrationService mockGenesysIntegration;
	private static ApplicationDatabase mockDatabase;
	private static VoiceCallsSelector voiceCallsSelector;
	private static AgentWorkSelector agentWorkSelector;
	private static ApplicationUnitOfWork uow;

	private Enum MockSetup {
		MOCKGENESYSINTEGRATION,
		MOCKDATABASE
	}

	@isTest
	public static void runGenesysVoiceCallModuleTest() {
		// Test Data
		VoiceCall testVoiceCall = generateTestVoiceCall(fflib_IdGenerator.generate(Conversation.SObjectType));
		VoiceCall testVoiceCall2 = generateTestVoiceCall(testVoiceCall.Id);

		Map<Id,SObject> oldMap = new Map<Id,SObject>{
			testVoiceCall.Id => testVoiceCall.clone(true)
		};

		testVoiceCall.TrackingNumber__c = 'TRACK_PAUL_TEST';

		// Mock classes
		mockClasses(
			new Set<MockSetup>{ MockSetup.MOCKDATABASE, MockSetup.MOCKGENESYSINTEGRATION },
			new Map<SObjectType,Object>{
				VoiceCall.SObjectType => new List<VoiceCall>{ testVoiceCall, testVoiceCall2 },
				AgentWork.SObjectType => new List<AgentWork>{
					generateTestAgentWork(new Map<SObjectField,Object>{
						AgentWork.WorkItemId => testVoiceCall.Id,
						AgentWork.AcceptDateTime => Datetime.now(),
						AgentWork.Status => 'Opened'
					}),
					generateTestAgentWork(new Map<SObjectField,Object>{
						AgentWork.WorkItemId => testVoiceCall2.Id,
						AgentWork.AcceptDateTime => Datetime.now().addMinutes(5),
						AgentWork.Status => 'Opened'
					})
				}
			}
		);

		// Test
		Test.startTest();

		GenesysVoiceCallModule instance = GenesysVoiceCallModule.newInstance();
 		instance.onAfterUpdate(new List<SObject>{ testVoiceCall }, oldMap, uow);

		fflib_ArgumentCaptor registerWorkCaptor = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		// Ensure registerAsyncWork has been invoked once
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(uow, 1)).registerAsyncWork(
			(ApplicationUnitOfWork.AsyncStagingWorker)registerWorkCaptor.capture()
		);

		ApplicationUnitOfWork.AsyncStagingWorker asyncWorker = (ApplicationUnitOfWork.AsyncStagingWorker)registerWorkCaptor.getValue();

		Test.stopTest();

		// Assertions
		System.assertEquals(
			GenesysVoiceCallModule.AsyncGenesysAttributeSync.class,
			asyncWorker.classType,
			'Unexpected AsyncWorker'
		);

		Map<String,Object> asyncWorkerParams = (Map<String,Object>)asyncWorker.params;
		System.debug(JSON.serialize(asyncWorkerParams));
		System.assert(asyncWorkerParams.containsKey('voiceCallIds'), 'Missing parameters');
		System.assert(
			((List<Id>)asyncWorkerParams.get('voiceCallIds')).contains(testVoiceCall.Id),
			'VoiceCallId expected within parameters'
		);
	}

	@IsTest
	public static void runAsyncGenesysAttributeSyncTest() {
		// Test Data
		List<VoiceCall> testVoiceCalls = new List<VoiceCall>{
			generateTestVoiceCall(new Map<SObjectField,Object>{
				VoiceCall.TrackingNumber__c => 'TRACK_PAUL_TEST',
				// Include logic for missing Customer Participant Id:
				VoiceCall.CustomerParticipantId__c => null
			}),
			generateTestVoiceCall(new Map<SObjectField,Object>{
				VoiceCall.Case__c => fflib_IDGenerator.generate(Case.SObjectType)
			})
		};

		// Mock classes
		mockClasses(
			new Set<MockSetup>{ MockSetup.MOCKDATABASE, MockSetup.MOCKGENESYSINTEGRATION },
			new Map<SObjectType,Object>{
				VoiceCall.SObjectType => testVoiceCalls
			}
		);

		// Test
		Test.startTest();

		// Test input for the async worker
		Set<Id> testVoiceCallIds = new Set<Id>{
			// Actual test records, tracking number + case updated
			testVoiceCalls[0].Id,
			testVoiceCalls[1].Id
		};

		GenesysVoiceCallModule.AsyncGenesysAttributeSync instance = new GenesysVoiceCallModule.AsyncGenesysAttributeSync();
		instance.deserialiseParams(JSON.serialize(new Map<String,Object>{
			'voiceCallIds' => testVoiceCallIds
		}));

		instance.execute(uow);

		System.assertEquals(GenesysVoiceCallModule.AsyncGenesysAttributeSync.class, instance.getClassType(), 'Invalid class type');
		System.assertEquals(VoiceCall.SObjectType, instance.getSObjectTypeGroup(), 'Invalid SObjectType');

		fflib_ArgumentCaptor conversationIdCaptor = fflib_ArgumentCaptor.forClass(GenesysIntegrationService.class);
		fflib_ArgumentCaptor participantIdCaptor = fflib_ArgumentCaptor.forClass(GenesysIntegrationService.class);
		fflib_ArgumentCaptor attributesCaptor = fflib_ArgumentCaptor.forClass(GenesysIntegrationService.class);

		// Ensure fetchConversationCallDetail has been invoked once
		((GenesysIntegrationService)MockUtility.Mocks.verify(mockGenesysIntegration, 1)).fetchConversationCallDetail(
			(String)conversationIdCaptor.capture()
		);

		String conversationId = testVoiceCalls[0].VendorCallKey.split(':')[1];

		System.assertEquals(conversationId, conversationIdCaptor.getValue(), 'ConversationId incorrect');

		conversationIdCaptor = fflib_ArgumentCaptor.forClass(GenesysIntegrationService.class);
		// Ensure fetchConversationCallDetail has been invoked 2 times
		((GenesysIntegrationService)MockUtility.Mocks.verify(mockGenesysIntegration, 2)).patchConversationParticipantAttributes(
			(String)conversationIdCaptor.capture(),
			(String)participantIdCaptor.capture(),
			(Map<String,Object>)attributesCaptor.capture()
		);

		// Use the values from all ArgumentCaptor assignments for the first invocation: .getAllValues()[0]
		System.assertEquals(conversationId, conversationIdCaptor.getAllValues()[0], 'Invalid conversationId');
		System.assert(String.isNotBlank((String)(participantIdCaptor.getAllValues()[0])), 'Missing participantId');

		Map<String,Object> responseMap = (Map<String,Object>)(attributesCaptor.getAllValues()[0]);

		// Ensure attribute presence, validating update logic and additional business logic
		for (String attributeName :new Set<String>{ 'Tracking_Number', 'Tracking_ID', 'ContactId' }) {
			System.assert(responseMap.containsKey(attributeName), 'Missing attribute ' + attributeName);
		}

		Test.stopTest();
	}

	@isTest
	public static void authoritativeVoiceCallTest() {
		// All VC's share the same ConversationId
		Id conversationId = fflib_IDGenerator.generate(Conversation.SObjectType);

		Map<String,VoiceCall> voiceCallTestPool = new Map<String,VoiceCall>{
			'answer-agent-1' => generateTestVoiceCall(new Map<SObjectField,Object>{
				VoiceCall.ConversationId => conversationId
				/*
					"Name" : "VC-00001206",
					"Id" : "0LQAD000001FBNa4AO",
					"CreatedById" : "0053000000553YiAAI",
					"LastModifiedDate" : "2024-09-23T06:30:13.000+0000",
					"LastModifiedById" : "0053000000553YiAAI",
					"CreatedDate" : "2024-09-23T06:28:49.000+0000",
					"OwnerId" : "0052v00000k80QjAAI",
					"CallStartDateTime" : "2024-09-23T06:28:48.000+0000",
					"CallEndDateTime" : "2024-09-23T06:30:12.000+0000",
					"FromPhoneNumber" : "+61 431 598 408",
					"ToPhoneNumber" : "(Internal) Nayak, Suchismita",
					"CallDisposition" : "completed",
					"CallType" : "Inbound",
					"ConversationId" : "0dwAD000002Pl7RYAS",
					"Consignment__c" : "a1hAD000001K3vdYAC",
					"ProductCategory__c" : "Parcel",
					"ProductSubCategory__c" : "eParcel",
					"EnquirySubType__c" : "Missing Parcel",
					"TrackingNumber__c" : "123456789",
					"CustomerParticipantId__c" : "cfa58594-7cf8-42b3-8e38-19b9f528756b",
					"Division__c" : "AP",
					"Contact__c" : "003AD00000MAqTpYAL",
					"EnquiryType__c" : "Local Track",
					"VendorCallKey" : "1887d9a2-7d3d-4a52-9f9c-0fe84eb16683:3ddcd2bf-25b0-4c0d-958f-22c38508cc67" */
			}),
			'consult-agent-2' => generateTestVoiceCall(new Map<SObjectField,Object>{
				VoiceCall.ConversationId => conversationId
			}),
			'transfer-agent-3' => generateTestVoiceCall(new Map<SObjectField,Object>{
				VoiceCall.ConversationId => conversationId
			})
		};

		// Single voiceCall in Conversation
		//	Reason: Single VC in a converation will always be the authoritative VC
		System.assertEquals(
			true,
			GenesysVoiceCallModule.isAuthoritativeVoiceCall(
				voiceCallTestPool.get('answer-agent-1'),
				new List<VoiceCall>{ voiceCallTestPool.get('answer-agent-1') },
				null
			),
			'Authoritative VC should be selected if there is a single VC in the conversation'
		);

		// Consult call cannot be assessed without AgentWork
		//	Reason: System will evaluate all other VC's first whereafter it'll
		//			fetch related AgentWork records for further assessment
		System.assertEquals(
			null,
			GenesysVoiceCallModule.isAuthoritativeVoiceCall(
				voiceCallTestPool.get('consult-agent-2'),
				new List<VoiceCall>{
					voiceCallTestPool.get('answer-agent-1'),
					voiceCallTestPool.get('consult-agent-2')
				},
				null
			),
			'Should return null as multiple VC\'s in a Conversation cannot be assessed without AgentWork'
		);

		// 2 related VC's for this Conversation
		List<VoiceCall> voiceCallParticipants = new List<VoiceCall>{
			voiceCallTestPool.get('answer-agent-1'),
			voiceCallTestPool.get('consult-agent-2')
		};

		// Represents scenario: VC2 got created during the conversation 5 mins after VC1
		Map<Id,AgentWork> relatedAgentWorkMap = new Map<Id,AgentWork>{
			voiceCallTestPool.get('answer-agent-1').Id => generateTestAgentWork(new Map<SObjectField,Object>{
				AgentWork.WorkItemId => voiceCallTestPool.get('answer-agent-1').Id,
				AgentWork.AcceptDateTime => Datetime.now(),
				AgentWork.Status => 'Opened'
			}),
			voiceCallTestPool.get('consult-agent-2').Id => generateTestAgentWork(new Map<SObjectField,Object>{
				AgentWork.WorkItemId => voiceCallTestPool.get('consult-agent-2').Id,
				AgentWork.AcceptDateTime => Datetime.now().addMinutes(5),
				AgentWork.Status => 'Opened'
			})
		};

		// Consult call to 2nd agent where agent #2 should not be assessed as the the authoratitive VC
		//  Reason: Agent work records with status Opened + Related VC's AgentWork got accepted after answer-agent-1 VC
		System.Assert.areEqual(
			false,
			GenesysVoiceCallModule.isAuthoritativeVoiceCall(
				voiceCallTestPool.get('consult-agent-2'),	// assess this voice call
				voiceCallParticipants,
				relatedAgentWorkMap
			),
			'consulted agent VC party isn\'t considered authoritative VC'
		);

		relatedAgentWorkMap = new Map<Id,AgentWork>{
			voiceCallTestPool.get('answer-agent-1').Id => generateTestAgentWork(new Map<SObjectField,Object>{
				AgentWork.WorkItemId => voiceCallTestPool.get('answer-agent-1').Id,
				AgentWork.AcceptDateTime => Datetime.now().addMinutes(-20),
				AgentWork.Status => 'Closed',
				AgentWork.CloseDateTime => Datetime.now().addMinutes(-5)
			}),
			voiceCallTestPool.get('consult-agent-2').Id => generateTestAgentWork(new Map<SObjectField,Object>{
				AgentWork.WorkItemId => voiceCallTestPool.get('consult-agent-2').Id,
				AgentWork.AcceptDateTime => Datetime.now().addMinutes(-15),
				AgentWork.Status => 'Closed',
				AgentWork.CloseDateTime => Datetime.now().addMinutes(-10)
			}),
			voiceCallTestPool.get('transfer-agent-3').Id => generateTestAgentWork(new Map<SObjectField,Object>{
				AgentWork.WorkItemId => voiceCallTestPool.get('transfer-agent-3').Id,
				AgentWork.AcceptDateTime => Datetime.now().addMinutes(-5),
				AgentWork.Status => 'Closed',
				AgentWork.CloseDateTime => Datetime.now().addMinutes(0)
			})
		};

		// Add VC for agent 3 representing a blind transfer from agent 1 (after consult with agent 2)
		voiceCallParticipants.add(voiceCallTestPool.get('transfer-agent-3'));

		// Consult call to 2nd agent where agent #2 should not be assessed as the the authoratitive VC
		//  Reason: No Agent work found with status Opened + Related VC's AgentWork was closed most recently
		System.Assert.areEqual(
			true,
			GenesysVoiceCallModule.isAuthoritativeVoiceCall(
				voiceCallTestPool.get('transfer-agent-3'),	// assess this voice call
				voiceCallParticipants,
				relatedAgentWorkMap
			),
			'Last agent is considered authoritative VC'
		);
	}

	private static VoiceCall generateTestVoiceCall(Id conversationId) {
		return generateTestVoiceCall(new Map<SObjectField,Object>{
			VoiceCall.ConversationId => conversationId
		});
	}

	private static VoiceCall generateTestVoiceCall(Map<SObjectField,Object> fieldOverrides) {
		// Populate all fixed fields
		Map<SObjectField,Object> voiceCallObjMap = new Map<SObjectField,Object>{
			VoiceCall.CallCenterId => fflib_IdGenerator.generate(CallCenter.SObjectType),
			VoiceCall.Division__c => 'AP',
			VoiceCall.CallStartDateTime => DateTime.now(),
			VoiceCall.CallEndDateTime =>  DateTime.now().addMinutes(1),
			VoiceCall.FromPhoneNumber => 'tel:04xxxxxxxx',
			VoiceCall.ToPhoneNumber => '(Internal) PERRY, Paul',
			VoiceCall.CallType => 'Inbound',
			VoiceCall.VendorCallKey => UUID.randomUUID() + ':' + UUID.randomUUID(),
			VoiceCall.CustomerParticipantId__c => UUID.randomUUID()
		};

		for (SObjectField field :fieldOverrides.keySet()) {
			voiceCallObjMap.put(field, fieldOverrides.get(field));
		}

		// Add all missing fields that are used in the mappings (preventing field not in SOQL exception)
		for (SObjectField field :GenesysConstants.genesysFieldMappings.keySet()) {
			if (!voiceCallObjMap.containsKey(field)) {
				voiceCallObjMap.put(field, null);
			}
		}

		if (!voiceCallObjMap.containsKey(VoiceCall.ConversationId)) {
			voiceCallObjMap.put(VoiceCall.ConversationId, fflib_IdGenerator.generate(Conversation.SObjectType));
		}

		// Populate all fields into VoiceCall SOobject
		VoiceCall result = (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(
			new VoiceCall(Id = fflib_IDGenerator.generate(VoiceCall.SObjectType)),
			convertFieldMap(voiceCallObjMap)
		);

		return result;
	}

	private static AgentWork generateTestAgentWork(Map<SObjectField,Object> fieldOverrides) {
		return (AgentWork)ApplicationTestDataFactory.setUnwritableFields(
			new AgentWork(Id = fflib_IDGenerator.generate(AgentWork.SObjectType)),
			convertFieldMap(fieldOverrides)
		);
	}

	private static void mockClasses(Set<MockSetup> setup, Map<SObjectType,Object> testRecordsBySObjectType) {
		// Mocking
		if (setup.contains(MockSetup.MOCKGENESYSINTEGRATION)) {
			mockGenesysIntegration = (GenesysIntegrationService)MockUtility.mockUtility(GenesysIntegrationService.class);
		}

		if (setup.contains(MockSetup.MOCKDATABASE)) {
			mockDatabase = MockUtility.mockDatabase();
			voiceCallsSelector = (VoiceCallsSelector)MockUtility.mockSelector(VoiceCallsSelector.class);
			agentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		}

		uow = (ApplicationUnitOfWork)MockUtility.mockUtility(ApplicationUnitOfWork.class);

		MockUtility.Mocks.startStubbing();

		if (setup.contains(MockSetup.MOCKGENESYSINTEGRATION)) {
			MockUtility.Mocks.when(
				mockGenesysIntegration.fetchConversationCallDetail(
					(String)fflib_Match.anyString()	// conversationId
				)
			).thenReturn(
				(Map<String,Object>)JSON.deserializeUntyped(GenesysIntegrationService_Test.MOCKRESPONSECALLLOG)
			);

			MockUtility.Mocks.when(
				mockGenesysIntegration.patchConversationParticipantAttributes(
					(String)fflib_Match.anyString(),			// conversationId
					(String)fflib_Match.anyString(),			// participantId
					(Map<String,Object>)fflib_Match.anyObject()	// custom attributes to set
				)
			).thenReturn(
				(String)JSON.serialize(new Map<String,Object>{ 'Tracking_Number' => '123456' })
			);
		}

		if (setup.contains(MockSetup.MOCKDATABASE)) {
			MockUtility.Mocks.when(
				mockDatabase.enqueueJob((Object)fflib_Match.anyObject())
			).thenReturn(
				fflib_IDGenerator.generate(AsyncApexJob.SObjectType)
			);

			MockUtility.Mocks.when(
				voiceCallsSelector.selectByIds(
					(Set<Object>)fflib_Match.anyObject(),
					(Set<Id>)fflib_Match.anyObject()
				)
			).thenReturn(
				(List<VoiceCall>)testRecordsBySObjectType.get(VoiceCall.SObjectType)
			);

			MockUtility.Mocks.when(
				voiceCallsSelector.selectByConversationIds(
					(Set<Object>)fflib_Match.anyObject(),
					(Set<Id>)fflib_Match.anyObject()
				)
			).thenReturn(
				(List<VoiceCall>)testRecordsBySObjectType.get(VoiceCall.SObjectType)
			);

			MockUtility.Mocks.when(
				agentWorkSelector.selectByAcceptedWorkItemIds(
					(Set<Id>)fflib_Match.anyObject(),
					(Set<Object>)fflib_Match.anyObject()
				)
			).thenReturn(
				(List<AgentWork>)testRecordsBySObjectType.get(AgentWork.SObjectType)
			);
		}

		MockUtility.Mocks.stopStubbing();
	}

	private static Set<String> convertSObjToString(Set<SObjectField> fieldSet) {
		Set<String> result = new Set<String>();

		for (SObjectField field :fieldSet) {
			result.add(String.valueOf(field));
		}

		return result;
	}

	private static Map<String,Object> convertFieldMap(Map<SObjectField,Object> objectMap) {
		Map<String,Object> result = new Map<String,Object>();

		for (SObjectField field :objectMap.keySet()) {
			result.put(String.valueOf(field), objectMap.get(field));
		}

		return result;
	}
}