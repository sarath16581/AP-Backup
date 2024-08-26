/**
* @description Test class covering LiveChatTranscriptLegacyAutomationModule
* @test LiveChatTranscriptLegacyAutomationModule
* @changelog
* 2024-08-20	George Nguyen	Created
*/
@IsTest
class LiveChatTranscriptLegacyAutomatioModTest {
    
	@IsTest
	static void onBeforeInsert() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		LiveChatTranscriptTriggerHandler mockHandler = (LiveChatTranscriptTriggerHandler)MockUtility.mockUtility(LiveChatTranscriptTriggerHandler.class);
		List<SObject> records = new List<SObject>();
		LiveChatTranscriptLegacyAutomationModule module = new LiveChatTranscriptLegacyAutomationModule();
		module.onBeforeInsert(records, uow);
		((LiveChatTranscriptTriggerHandler)MockUtility.Mocks.verify(mockHandler, 1)).executeLegacy();
	}

	@IsTest
	static void onAfterInsert() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		LiveChatTranscriptTriggerHandler mockHandler = (LiveChatTranscriptTriggerHandler)MockUtility.mockUtility(LiveChatTranscriptTriggerHandler.class);
		List<SObject> records = new List<SObject>();
		LiveChatTranscriptLegacyAutomationModule module = new LiveChatTranscriptLegacyAutomationModule();
		module.onAfterInsert(records, uow);
		((LiveChatTranscriptTriggerHandler)MockUtility.Mocks.verify(mockHandler, 1)).executeLegacy();
	}

	@IsTest
	static void onBeforeUpdate() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		LiveChatTranscriptTriggerHandler mockHandler = (LiveChatTranscriptTriggerHandler)MockUtility.mockUtility(LiveChatTranscriptTriggerHandler.class);
		List<SObject> records = new List<SObject>();
		Map<Id, SObject> existingRecords = new Map<Id, SObject>();
		LiveChatTranscriptLegacyAutomationModule module = new LiveChatTranscriptLegacyAutomationModule();
		module.onBeforeUpdate(records, existingRecords, uow);
		((LiveChatTranscriptTriggerHandler)MockUtility.Mocks.verify(mockHandler, 1)).executeLegacy();
	}

	@IsTest
	static void onAfterUpdate() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		LiveChatTranscriptTriggerHandler mockHandler = (LiveChatTranscriptTriggerHandler)MockUtility.mockUtility(LiveChatTranscriptTriggerHandler.class);
		List<SObject> records = new List<SObject>();
		Map<Id, SObject> existingRecords = new Map<Id, SObject>();
		LiveChatTranscriptLegacyAutomationModule module = new LiveChatTranscriptLegacyAutomationModule();
		module.onAfterUpdate(records, existingRecords, uow);
		((LiveChatTranscriptTriggerHandler)MockUtility.Mocks.verify(mockHandler, 1)).executeLegacy();
	}

	@IsTest
	static void onBeforeDelete() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		LiveChatTranscriptTriggerHandler mockHandler = (LiveChatTranscriptTriggerHandler)MockUtility.mockUtility(LiveChatTranscriptTriggerHandler.class);
		List<SObject> records = new List<SObject>();
		LiveChatTranscriptLegacyAutomationModule module = new LiveChatTranscriptLegacyAutomationModule();
		module.onBeforeDelete(records, uow);
		((LiveChatTranscriptTriggerHandler)MockUtility.Mocks.verify(mockHandler, 1)).executeLegacy();
	}

	@IsTest
	static void onAfterDelete() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		LiveChatTranscriptTriggerHandler mockHandler = (LiveChatTranscriptTriggerHandler)MockUtility.mockUtility(LiveChatTranscriptTriggerHandler.class);
		List<SObject> records = new List<SObject>();
		LiveChatTranscriptLegacyAutomationModule module = new LiveChatTranscriptLegacyAutomationModule();
		module.onAfterDelete(records, uow);
		((LiveChatTranscriptTriggerHandler)MockUtility.Mocks.verify(mockHandler, 1)).executeLegacy();
	}

	@IsTest
	static void onAfterUndelete() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		LiveChatTranscriptTriggerHandler mockHandler = (LiveChatTranscriptTriggerHandler)MockUtility.mockUtility(LiveChatTranscriptTriggerHandler.class);
		List<SObject> records = new List<SObject>();
		LiveChatTranscriptLegacyAutomationModule module = new LiveChatTranscriptLegacyAutomationModule();
		module.onAfterUndelete(records, uow);
		((LiveChatTranscriptTriggerHandler)MockUtility.Mocks.verify(mockHandler, 1)).executeLegacy();
	}
}