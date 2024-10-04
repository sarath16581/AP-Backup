/**
 * @description Unit Tests for the `UnifiedLiveChatCustomerLinkingModule` class.
 * @changelog
 * 2024-10-04 - Seth Heang - Created
 */
@IsTest
private class UnifiedLiveChatCustomerLinkingModuleTest {

	static Id mockContactId() {
		return fflib_IDGenerator.generate(Contact.getSObjectType());
	}

	/**
	 * Test: BeforeInsert Scenario, when a new Chat Transcript is created
	 * verify that a contact Id is linked successfully if exactly one contact is found
	 * verify that no contact Id is linked when there is no match or multiple matches
	 */
	@IsTest
	private static void testEnsureBeforeInsertPopulatesContactIdOnLiveChatCorrectly() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Contact> mockContactsList = new List<Contact> {
				new Contact(Id = mockContactId(), Email = 'test1@example.com'),
				new Contact(Id = mockContactId(), Email = 'test2@example.com'),
				new Contact(Id = mockContactId(), Email = 'test2@example.com')
		};

		List<LiveChatTranscript> chatTranscripts = new List<LiveChatTranscript> {
				new LiveChatTranscript(SuppliedEmail__c = 'test1@example.com'),
				new LiveChatTranscript(SuppliedEmail__c = 'test2@example.com'),
				new LiveChatTranscript(SuppliedEmail__c = 'test3@example.com'),
				new LiveChatTranscript(SuppliedEmail__c = ''),
				new LiveChatTranscript(SuppliedEmail__c = null),
				new LiveChatTranscript()
		};

		// =====================================
		// Stubbing
		// =====================================
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(
				ContactsSelector.class
		);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockContactsSelector.selectCustomerByEmail(
						(Set<String>) fflib_Match.anyObject(),
						(Set<Object>) fflib_Match.anyObject()
				)
		)
				.thenReturn(mockContactsList);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		new UnifiedLiveChatCustomerLinkingModule().onBeforeInsert(chatTranscripts, null);
		Test.stopTest();

		Assert.areEqual(mockContactsList[0].Id, chatTranscripts[0].ContactId, 'Correct Contact Id should be set (single match)');
		Assert.isNull(chatTranscripts[1].ContactId, 'Contact Id not should be set (multiple matches)');
		Assert.isNull(chatTranscripts[2].ContactId, 'Contact Id not should be set (no matches)');
		Assert.isNull(chatTranscripts[3].ContactId, 'Contact Id not should be set (no email)');
		Assert.isNull(chatTranscripts[4].ContactId, 'Contact Id not should be set (no email)');
		Assert.isNull(chatTranscripts[5].ContactId, 'Contact Id not should be set (no email)');
	}
}