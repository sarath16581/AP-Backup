/**
 * @description Test class for LiveChatTranscriptAutomationTrigHandler
 * @changelog:
 * 2024-08-23 - George Nguyen - created
 * 2024-10-04 - Seth Heang - added test to verify UnifiedLiveChatCustomerLinkingModule registration
 * 2024-10-11 - Seth Heang - added test for 'filterUnified' filter
 */
@IsTest
class LiveChatTranscriptAutomationTrigHdr_Test {

	@TestSetup
	static void testSetup(){
		QM__c queueSettings = QM__c.getOrgDefaults();
		// live chat ID is used here for testing purpose only, custom setting should be configured with actual live chat button Id
		queueSettings.UnifiedLiveChatButtonId__c = ApplicationTestDataFactoryCase.getLiveChatTranscripts(1, null, true)[0].Id;
		insert queueSettings;
	}

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

		List<LiveChatTranscript> liveChatTranscripts = ApplicationTestDataFactoryCase.getLiveChatTranscripts(3, null, true);
		liveChatTranscripts[0].LiveChatButtonId = QM__c.getInstance().UnifiedLiveChatButtonId__c;
		liveChatTranscripts[1].LiveChatButtonId = ApplicationTestDataFactoryCase.getCases(1,true)[0].Id; // Invalid Id
		liveChatTranscripts[2].LiveChatButtonId = null; // Blank Id

		Map<String, List<SObject>> filteredGroupRecords = handler.primeRecordFilters(liveChatTranscripts);
		Assert.areEqual(1, filteredGroupRecords.size(), 'Expected exactly one filter group but instead got: ' + filteredGroupRecords.size());

		Assert.areEqual(1, filteredGroupRecords.get('filterUnified').size(),'Expected exactly one filter for Unified but instead got: ' + filteredGroupRecords.get('filterUnified').size());
		Assert.areEqual(liveChatTranscripts[0].LiveChatButtonId, filteredGroupRecords.get('filterUnified')[0].Id);
	}
}