/**
 * @description Unit Tests for the `UnifiedLiveChatCustomerLinkingModule` class.
 * @changelog
 * 2024-10-04 - Seth Heang - Created
 * 2024-10-07 - Marcel HK - Moved utility methods into module class, update tests
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
		List<Contact> mockContactsList = new List<Contact>{
			new Contact(Id = mockContactId(), Email = 'test1@example.com'),
			new Contact(Id = mockContactId(), Email = 'test2@example.com'),
			new Contact(Id = mockContactId(), Email = 'test2@example.com')
		};
		List<LiveChatTranscript> chatTranscripts = new List<LiveChatTranscript>{
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
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectCustomerByEmail((Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
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

	@IsTest
	static void testLinkChatsWithContact() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Contact> mockContactsList = new List<Contact>{
			new Contact(Id = mockContactId(), Email = 'test1@example.com'),
			new Contact(Id = mockContactId(), Email = 'test2@example.com'),
			new Contact(Id = mockContactId(), Email = 'test2@example.com')
		};
		List<LiveChatTranscript> chatTranscripts = new List<LiveChatTranscript>{
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
		ContactsSelector mockContactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactsSelector.selectCustomerByEmail((Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
			.thenReturn(mockContactsList);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		UnifiedLiveChatCustomerLinkingModule.linkChatsWithContact(chatTranscripts);
		Test.stopTest();

		Assert.areEqual(mockContactsList[0].Id, chatTranscripts[0].ContactId, 'Correct Contact Id should be set (single match)');
		Assert.isNull(chatTranscripts[1].ContactId, 'Contact Id not should be set (multiple matches)');
		Assert.isNull(chatTranscripts[2].ContactId, 'Contact Id not should be set (no matches)');
		Assert.isNull(chatTranscripts[3].ContactId, 'Contact Id not should be set (no email)');
		Assert.isNull(chatTranscripts[4].ContactId, 'Contact Id not should be set (no email)');
		Assert.isNull(chatTranscripts[5].ContactId, 'Contact Id not should be set (no email)');
	}

	@IsTest
	static void testPopulateContactIds() {
		// =====================================
		// Data Preparation
		// =====================================
		List<LiveChatTranscript> chatTranscripts = new List<LiveChatTranscript>{
			new LiveChatTranscript(SuppliedEmail__c = 'test1@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = 'test2@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = 'test3@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = ''),
			new LiveChatTranscript(SuppliedEmail__c = null),
			new LiveChatTranscript()
		};

		Id contactId1 = mockContactId();
		Id contactId2 = mockContactId();
		Id contactId3 = mockContactId();

		Map<String, List<Id>> emailContactsMap = new Map<String, List<Id>>();
		emailContactsMap.put('test1@example.com', new List<Id>{ contactId1 });
		emailContactsMap.put('test2@example.com', new List<Id>{ contactId2, contactId3 });
		emailContactsMap.put('test3@example.com', new List<Id>());

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		UnifiedLiveChatCustomerLinkingModule.populateContactIds(chatTranscripts, emailContactsMap);
		Test.stopTest();

		Assert.areEqual(contactId1, chatTranscripts[0].ContactId, 'Correct Contact Id should be set (single match)');
		Assert.isNull(chatTranscripts[1].ContactId, 'Contact Id not should be set (multiple matches)');
		Assert.isNull(chatTranscripts[2].ContactId, 'Contact Id not should be set (no matches)');
		Assert.isNull(chatTranscripts[3].ContactId, 'Contact Id not should be set (no email)');
		Assert.isNull(chatTranscripts[4].ContactId, 'Contact Id not should be set (no email)');
		Assert.isNull(chatTranscripts[5].ContactId, 'Contact Id not should be set (no email)');
	}

	@IsTest
	static void testGetUniqueEmailAddresses() {
		// =====================================
		// Data Preparation
		// =====================================
		List<LiveChatTranscript> chatTranscripts = new List<LiveChatTranscript>{
			new LiveChatTranscript(SuppliedEmail__c = 'test1@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = 'test1@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = 'test2@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = ''),
			new LiveChatTranscript(SuppliedEmail__c = null),
			new LiveChatTranscript()
		};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Set<String> emailAddresses = UnifiedLiveChatCustomerLinkingModule.getUniqueEmailAddresses(chatTranscripts);
		Test.stopTest();

		Assert.areEqual(2, emailAddresses.size(), 'Expected 2 unique email addresses');
	}

	@IsTest
	static void testMapContactsWithEmails() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Contact> contacts = new List<Contact>{
			new Contact(Id = mockContactId(), Email = 'test1@example.com'),
			new Contact(Id = mockContactId(), Email = 'test2@example.com'),
			new Contact(Id = mockContactId(), Email = 'test2@example.com')
		};
		Set<String> emailAddresses = new Set<String>{ 'test1@example.com', 'test2@example.com', 'test3@example.com' };

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, List<Id>> result = UnifiedLiveChatCustomerLinkingModule.mapContactsWithEmails(emailAddresses, contacts);
		Test.stopTest();

		Assert.areEqual(3, result.size(), 'Results should have 3 keys');
		Assert.areEqual(1, result.get('test1@example.com').size(), 'test1 should map to 1 Contact Id');
		Assert.areEqual(2, result.get('test2@example.com').size(), 'test2 should map to 2 Contact Ids');
		Assert.areEqual(0, result.get('test3@example.com').size(), 'test3 should map to 0 Contact Ids');
	}
}
