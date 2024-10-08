/**
 * @description Unit tests for the `UnifiedCustomerSearchChatWrapCtrl` class.
 * @changelog
 * 2024-09-02 - Marcel HK - Created
 */
@IsTest
public with sharing class UnifiedCustomerSearchChatWrapCtrl_Test {
	static ConversationContextEntry mockContextEntry(String key, String value) {
		return new ConversationContextEntry(
			Id = fflib_IDGenerator.generate(ConversationContextEntry.getSObjectType()),
			CustomDetailContextKey = key,
			CustomDetailContextValue = value
		);
	}

	@IsTest
	static void testGetPreChatContextWithResult() {
		// =====================================
		// Data Preparation
		// =====================================
		Id liveChatTranscriptId = fflib_IDGenerator.generate(LiveChatTranscript.getSObjectType());

		Map<Id, ConversationContextEntry> mockSelectorResult = new Map<Id, ConversationContextEntry>();
		ConversationContextEntry r1 = mockContextEntry('First Name', 'Tony');
		ConversationContextEntry r2 = mockContextEntry('Last Name', 'Stark');
		ConversationContextEntry r3 = mockContextEntry('Email', 'tony@starkindustries.com');
		ConversationContextEntry r4 = mockContextEntry('Phone', '0400000000');
		mockSelectorResult.put(r1.Id, r1);
		mockSelectorResult.put(r2.Id, r2);
		mockSelectorResult.put(r3.Id, r3);
		mockSelectorResult.put(r4.Id, r4);

		// =====================================
		// Stubbing
		// =====================================
		ConversationContextEntrySelector mockSelector = (ConversationContextEntrySelector) MockUtility.mockSelector(ConversationContextEntrySelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByParentId(liveChatTranscriptId)).thenReturn(mockSelectorResult);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		UnifiedCustomerSearchChatWrapCtrl.PreChatDetails result;
		result = UnifiedCustomerSearchChatWrapCtrl.getPreChatContext(liveChatTranscriptId);
		Test.stopTest();

		Assert.areEqual(result.firstName, 'Tony', 'Expect firstName to match mocked data');
		Assert.areEqual(result.lastName, 'Stark', 'Expect lastName to match mocked data');
		Assert.areEqual(result.emailAddress, 'tony@starkindustries.com', 'Expect emailAddress to match mocked data');
		Assert.areEqual(result.phoneNumber, '0400000000', 'Expect phoneNumber to match mocked data');
	}

	@IsTest
	static void testGetPreChatContextWithNoResults() {
		// =====================================
		// Data Preparation
		// =====================================
		Id liveChatTranscriptId = fflib_IDGenerator.generate(LiveChatTranscript.getSObjectType());

		Map<Id, ConversationContextEntry> mockSelectorResult = new Map<Id, ConversationContextEntry>();

		// =====================================
		// Stubbing
		// =====================================
		ConversationContextEntrySelector mockSelector = (ConversationContextEntrySelector) MockUtility.mockSelector(ConversationContextEntrySelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectByParentId(liveChatTranscriptId)).thenReturn(mockSelectorResult);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		UnifiedCustomerSearchChatWrapCtrl.PreChatDetails result;
		result = UnifiedCustomerSearchChatWrapCtrl.getPreChatContext(liveChatTranscriptId);
		Test.stopTest();

		Assert.isNull(result.firstName, 'Expect firstName to be null');
		Assert.isNull(result.lastName, 'Expect lastName to be null');
		Assert.isNull(result.emailAddress, 'Expect emailAddress to be null');
		Assert.isNull(result.phoneNumber, 'Expect phoneNumber to be null');
	}
}