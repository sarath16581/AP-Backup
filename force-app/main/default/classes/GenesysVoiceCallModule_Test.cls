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
 */
@IsTest
public with sharing class GenesysVoiceCallModule_Test {
	// Mocking
	private static GenesysIntegrationService mockGenesysIntegration;
	private static ApplicationDatabase mockDatabase;
	private static VoiceCallsSelector voiceCallsSelector;
	private static ApplicationUnitOfWork uow;

	private Enum MockSetup {
		MOCKGENESYSINTEGRATION,
		MOCKDATABASE
	}

	@isTest
	public static void runGenesysVoiceCallModuleTest() {
		// Test Data
		VoiceCall testVoiceCall = generateTestVoiceCall();

		Map<Id,SObject> oldMap = new Map<Id,SObject>{
			testVoiceCall.Id => testVoiceCall.clone(true)
		};

		testVoiceCall.TrackingNumber__c = 'TRACK_PAUL_TEST';

		// Mock classes
		mockClasses(
			new Set<MockSetup>{ MockSetup.MOCKDATABASE, MockSetup.MOCKGENESYSINTEGRATION },
			new Map<SObjectType,Object>{
				VoiceCall.SObjectType => new List<VoiceCall>{ testVoiceCall }
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
		System.assert(asyncWorkerParams.containsKey('updatedFieldsByVoiceCallId'), 'Missing parameters');
		System.assert(
			((Map<Id,Object>)asyncWorkerParams.get('updatedFieldsByVoiceCallId')).containsKey(testVoiceCall.Id),
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
		Map<Id,Set<String>> updateFieldsSubSet = new Map<Id,Set<String>>{
			// Actual test records, tracking number + case updated
			testVoiceCalls[0].Id => new Set<String>{
				String.valueOf(VoiceCall.TrackingNumber__c),
				String.valueOf(VoiceCall.Contact__c)
			},
			testVoiceCalls[1].Id => new Set<String>{
				String.valueOf(VoiceCall.Case__c)
			},
			// Non existing record (usecase: deleted before processed), all mapped fields updated
			fflib_IDGenerator.generate(VoiceCall.SObjectType) => convertSObjToString(
				GenesysConstants.genesysFieldMappings.keySet()
			)
		};

		GenesysVoiceCallModule.AsyncGenesysAttributeSync instance = new GenesysVoiceCallModule.AsyncGenesysAttributeSync();
		instance.deserialiseParams(JSON.serialize(new Map<String,Object>{
			'updatedFieldsByVoiceCallId' => updateFieldsSubSet
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

	private static VoiceCall generateTestVoiceCall() {
		return generateTestVoiceCall(new Map<SObjectField,Object>());
	}

	private static VoiceCall generateTestVoiceCall(Map<SObjectField,Object> fieldOverrides) {
		// Populate all fixed fields
		Map<String,Object> voiceCallObjMap = new Map<String,Object>{
			String.valueOf(VoiceCall.CallCenterId) => fflib_IdGenerator.generate(CallCenter.SObjectType),
			String.valueOf(VoiceCall.ConversationId) => fflib_IdGenerator.generate(Conversation.SObjectType),
			String.valueOf(VoiceCall.Division__c) => 'AP',
			String.valueOf(VoiceCall.CallStartDateTime) => DateTime.now(),
			String.valueOf(VoiceCall.CallEndDateTime) =>  DateTime.now().addMinutes(1),
			String.valueOf(VoiceCall.FromPhoneNumber) => 'tel:04xxxxxxxx',
			String.valueOf(VoiceCall.ToPhoneNumber) => '(Internal) PERRY, Paul',
			String.valueOf(VoiceCall.CallType) => 'Inbound',
			String.valueOf(VoiceCall.VendorCallKey) => UUID.randomUUID() + ':' + UUID.randomUUID(),
			String.valueOf(VoiceCall.CustomerParticipantId__c) => UUID.randomUUID()
		};

		for (SObjectField field :fieldOverrides.keySet()) {
			voiceCallObjMap.put(String.valueOf(field), fieldOverrides.get(field));
		}

		// Add all missing fields that are used in the mappings (preventing field not in SOQL exception)
		for (SObjectField field :GenesysConstants.genesysFieldMappings.keySet()) {
			String fieldName = String.valueOf(field);

			if (!voiceCallObjMap.containsKey(fieldName)) {
				voiceCallObjMap.put(fieldName, null);
			}
		}

		// Populate all fields into VoiceCall SOobject
		VoiceCall result = (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(
			new VoiceCall(Id = fflib_IDGenerator.generate(VoiceCall.SObjectType)),
			voiceCallObjMap
		);

		return result;
	}

	private static void mockClasses(Set<MockSetup> setup, Map<SObjectType,Object> testRecordsBySObjectType) {
		// Mocking
		if (setup.contains(MockSetup.MOCKGENESYSINTEGRATION)) {
			mockGenesysIntegration = (GenesysIntegrationService)MockUtility.mockUtility(GenesysIntegrationService.class);
		}

		if (setup.contains(MockSetup.MOCKDATABASE)) {
			mockDatabase = MockUtility.mockDatabase();
			voiceCallsSelector = (VoiceCallsSelector)MockUtility.mockSelector(VoiceCallsSelector.class);
		}

		uow = (ApplicationUnitOfWork)MockUtility.mockUtility(ApplicationUnitOfWork.class);

		MockUtility.Mocks.startStubbing();

		if (setup.contains(MockSetup.MOCKGENESYSINTEGRATION)) {
			MockUtility.Mocks.when(
				mockGenesysIntegration.fetchConversationCallDetail(
					(String)fflib_Match.anyString()	// conversationId
				)
			).thenReturn(
				(Map<String,Object>)JSON.deserializeUntyped(GenesysIntegration_Test.MOCKRESPONSECALLLOG)
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
}