/*
Test class for LiveChatTranscriptAutomationTrigHandler
Changelog:
2024-08-23	George Nguyen	Created
*/
@IsTest
class LiveChatTranscriptAutomationTrigHdr_Test {
    @IsTest
	private static void getUnitOfWorkSObjectTypes() {

		LiveChatTranscriptAutomationTrigHandler handler = new LiveChatTranscriptAutomationTrigHandler();

		System.assertNotEquals(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		System.assertEquals(LiveChatTranscript.SObjectType, handler.getsObjectType(), 'Should return LiveChatTranscript sobject type');

		List<SObjectType> types = LiveChatTranscriptAutomationTrigHandler.getUnitOfWorkSObjectTypes();

		System.assert(types.contains(AgentWork.SObjectType), 'Should have AgentWork sobject type');
	}

	/*
		Making sure that the right modules are registered with the right filters
	*/
	@IsTest
	private static void registerModules() {

		LiveChatTranscriptAutomationTrigHandler handler = new LiveChatTranscriptAutomationTrigHandler();
		handler.registerModules();

		Map<Type, String> recordFilterIndexes = ApplicationTriggerHandler.recordFilterIndexes.get(LiveChatTranscriptAutomationTrigHandler.class.getName());
		System.assert(recordFilterIndexes.containsKey(LiveChatTranscriptLegacyAutomationModule.class), 'It should have LiveChatTranscriptLegacyAutomationModule class registered');
		System.assert(recordFilterIndexes.containsKey(CaseRecordPopulationModule.class), 'It should have CaseRecordPopulationModule class registered');
	}

}