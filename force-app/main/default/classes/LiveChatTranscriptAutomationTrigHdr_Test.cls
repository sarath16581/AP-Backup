/**
 * @description Test class for LiveChatTranscriptAutomationTrigHandler
 * @changelog:
 * 2024-08-23 - George Nguyen - created
 * 2024-10-04 - Seth Heang - added test to verify UnifiedLiveChatCustomerLinkingModule registration
 */
@IsTest
class LiveChatTranscriptAutomationTrigHdr_Test {
	@IsTest
	private static void getUnitOfWorkSObjectTypes() {

		LiveChatTranscriptAutomationTrigHandler handler = new LiveChatTranscriptAutomationTrigHandler();

		Assert.areNotEqual(null, handler.newUnitOfWork(), 'Expected a valid instance of ApplicationUnitOfWork; but got null');
		Assert.areEqual(LiveChatTranscript.SObjectType, handler.getsObjectType(), 'Should return LiveChatTranscript sobject type');

		List<SObjectType> types = LiveChatTranscriptAutomationTrigHandler.getUnitOfWorkSObjectTypes();

		Assert.isTrue(types.contains(AgentWork.SObjectType), 'Should have AgentWork sobject type');
	}

	/*
		Making sure that the right modules are registered with the right filters
	*/
	@IsTest
	private static void registerModules() {

		LiveChatTranscriptAutomationTrigHandler handler = new LiveChatTranscriptAutomationTrigHandler();
		handler.registerModules();

		Map<Type, String> recordFilterIndexes = ApplicationTriggerHandler.recordFilterIndexes.get(LiveChatTranscriptAutomationTrigHandler.class.getName());
		Assert.isTrue(recordFilterIndexes.containsKey(LiveChatTranscriptLegacyAutomationModule.class), 'It should have LiveChatTranscriptLegacyAutomationModule class registered');
		Assert.isTrue(recordFilterIndexes.containsKey(CaseRecordPopulationModule.class), 'It should have CaseRecordPopulationModule class registered');
		Assert.isTrue(recordFilterIndexes.containsKey(UnifiedLiveChatCustomerLinkingModule.class), 'It should have UnifiedLiveChatCustomerLinkingModule class registered');
	}
}