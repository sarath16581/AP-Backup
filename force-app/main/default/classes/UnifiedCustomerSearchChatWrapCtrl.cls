/**
 * @description Controller for the Unified Customer Search Live Chat Wrapper.
 * Used to return pre-chat details in a structured format to pre-fill the search form.
 * @changelog
 * 2024-09-02 - Marcel HK - Created
 */
public with sharing class UnifiedCustomerSearchChatWrapCtrl {
	// Map the Pre-Chat Context Key (UPPER CASE) to `PreChatDetails` Property Name
	static final Map<String, String> PRE_CHAT_FEILD_MAP = new Map<String, String>{
		'FIRST NAME' => 'firstName',
		'LAST NAME' => 'lastName',
		'EMAIL' => 'emailAddress',
		'PHONE' => 'phoneNumber'
	};

	/**
	 * @description Queries the `ConversationContextEntry` SObject and maps the results.
	 *
	 * @param liveChatTranscriptId - The Id of the Live Chat Transcript to get pre-chat details for.
	 * @return a `PreChatDetails` object with the mapped values.
	 */
	@AuraEnabled(cacheable=true)
	public static PreChatDetails getPreChatContext(Id liveChatTranscriptId) {
		try {
			if (String.isBlank(liveChatTranscriptId)) {
				return new PreChatDetails();
			}

			ConversationContextEntrySelector selector = ConversationContextEntrySelector.newInstance();
			Map<Id, ConversationContextEntry> preChatContextMap = selector.selectByParentId(liveChatTranscriptId);

			Map<String, String> preChatDetails = new Map<String, String>();
			for (ConversationContextEntry item : preChatContextMap.values()) {
				String key = item.CustomDetailContextKey?.toUpperCase();
				String value = item.CustomDetailContextValue?.trim();

				String propName = PRE_CHAT_FEILD_MAP.get(key);
				if (propName != null) {
					preChatDetails.put(propName, value);
				}
			}

			// Convert map to object (required to dynamically set properties based on map)
			return (PreChatDetails) JSON.deserialize(JSON.serialize(preChatDetails), PreChatDetails.class);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Wrapper object to return pre-chat details in a structured format.
	 */
	public class PreChatDetails {
		@AuraEnabled
		public String firstName;

		@AuraEnabled
		public String lastName;

		@AuraEnabled
		public String emailAddress;

		@AuraEnabled
		public String phoneNumber;
	}
}