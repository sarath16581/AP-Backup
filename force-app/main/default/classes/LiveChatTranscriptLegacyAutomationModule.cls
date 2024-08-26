/**
 * @description Module that wraps all of the Case legacy code which hasn't been uplifted yet for the LiveChatTranscript Object
 * NOTE: Because this is wrapping legacy code, filters should NOT be used here as they won't work 
 * 
 * @test LiveChatTranscriptTriggerTest
 * @author Nathan Franklin
 * @date 2024-08-01
 * @changelog
 * 2024-08-23	George Nguyen	Changed the call to LiveChatTranscriptTriggerHandler.execute(...) to LiveChatTranscriptTriggerHandler.getInstance().executeLegacy(...) to enable mocking in unit test
 */
public inherited sharing class LiveChatTranscriptLegacyAutomationModule extends ApplicationModule {
	
	// Setup which triggers this module should respond to
	public LiveChatTranscriptLegacyAutomationModule() {
		getTriggerEvents().enableAll();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		LiveChatTranscriptTriggerHandler.getInstance().executeLegacy();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		LiveChatTranscriptTriggerHandler.getInstance().executeLegacy();
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		LiveChatTranscriptTriggerHandler.getInstance().executeLegacy();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		LiveChatTranscriptTriggerHandler.getInstance().executeLegacy();
	}

	public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		LiveChatTranscriptTriggerHandler.getInstance().executeLegacy();
	}

	public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
		LiveChatTranscriptTriggerHandler.getInstance().executeLegacy();
	}

	public override void onAfterUndelete(List<SObject> records, ApplicationUnitOfWork uow) {
		LiveChatTranscriptTriggerHandler.getInstance().executeLegacy();
	}
}