/**
 * @description Trigger handler to execute all the registered ApplicationModule's
 * @Test LiveChatTranscriptAutomationTrigHdr_Test
 * @author Nathan Franklin
 * @date 2024-07-31
 * @changelog
 * 2024-10-04 - Seth Heang - registered UnifiedLiveChatCustomerLinkingModule
 * 2024-10-11 - Seth Heang - added filter check by livechat button and added `filterUnified` filter
 */
public inherited sharing class LiveChatTranscriptAutomationTrigHandler extends ApplicationTriggerHandler {

	/**
	 * These live chat button are using a part of pre-filtering records prior to module execution.
	 */
	private static final Map<String, Id> LIVECHAT_BUTTONS_BY_KEY {
		get {
			if (LIVECHAT_BUTTONS_BY_KEY == null) {
				QM__c queueSettings = QM__c.getInstance();
				LIVECHAT_BUTTONS_BY_KEY = new Map<String, Id>{
						'Unified' => queueSettings.UnifiedLiveChatButtonId__c
				};
			}
			return LIVECHAT_BUTTONS_BY_KEY;
		}
		private set;
	}

	public override SObjectType getSObjectType() {
		return LiveChatTranscript.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	/**
	 * Pre filter records to minimise repetitive looping inside the modules
	 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered
	 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
				'filterUnified' => new List<SObject>()
		};
		for(SObject record : records){
			Id liveChatButtonId = ((LiveChatTranscript)record)?.LiveChatButtonId;
			if( LIVECHAT_BUTTONS_BY_KEY.get('Unified') != null &&
				LIVECHAT_BUTTONS_BY_KEY.get('Unified').equals(liveChatButtonId)
			){
				filteredRecords.get('filterUnified').add(record);
			}
		}
		return filteredRecords;
	}

	public override void registerModules() {

		// Handles all the legacy code execution that hasn't been uplifted yet
		registerModule(LiveChatTranscriptLegacyAutomationModule.class);

		// populate the case id on both the relevant agent work records and the contactrequest records themselves
		// This provides an easy to reference lookup to the case the record is associated with
		registerModule(CaseRecordPopulationModule.class);
		registerModule(ProductCategoryPopulationModule.class);

		// link customer Id to Live Chat for Unified
		registerModule(UnifiedLiveChatCustomerLinkingModule.class, 'filterUnified');
	}

	/**
	 * This defines a list of objects that may be 'touched' during module execution.
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
				LiveChatTranscript.SObjectType,
				AgentWork.SObjectType,
				Contact.SObjectType
		};
	}
}