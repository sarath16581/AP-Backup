/**
 * @description Application Module to handle the linking of contact Id to Live Chat Transcript on new creation if exactly one contact is identified.
 * @author Seth Heang
 * @date 2024-10-04
 * @test UnifiedLiveChatCustomerLinkingModuleTest
 * @changelog
 * 2024-10-04 - Seth Heang - Created.
 */
public inherited sharing class UnifiedLiveChatCustomerLinkingModule extends ApplicationModule {
	// Setup which triggers this module should respond to
	public UnifiedLiveChatCustomerLinkingModule() {
		getTriggerEvents().enableBeforeInsert();
	}

	/**
	 * @description Called a before Insert and Performs below operations:
	 * - link contact Id to LiveChat if exactly one contact is found
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			UnifiedLiveChatCustomerLinking.getInstance().linkChatsWithContact((List<LiveChatTranscript>) records);
		} catch (Exception ex) {
			ApplicationLogger.getInstance()
					.logException(ApplicationLogger.wrapException(ex), 'UnifiedLiveChatTranscript', UnifiedLiveChatCustomerLinkingModule.class.getName(), 'onBeforeInsert', 'LiveChatTranscript', ApplicationLogger.LoggingLevel.ERROR);
		}
	}
}