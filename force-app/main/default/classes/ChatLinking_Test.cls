/**
 * @description Unit Tests for the `ChatLinking` class.
 * @changelog
 * 2024-10-04 - Marcel HK - Created
 */
@IsTest
public with sharing class ChatLinking_Test {

	static Id mockContactId() {
		return fflib_IDGenerator.generate(Contact.getSObjectType());
	}

	@IsTest
	static void testPopulateContactIds() {
		List<LiveChatTranscript> chatTranscripts = new List<LiveChatTranscript> {
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
		emailContactsMap.put('test1@example.com', new List<Id> { contactId1 });
		emailContactsMap.put('test2@example.com', new List<Id> { contactId2, contactId3 });
		emailContactsMap.put('test3@example.com', new List<Id>());

		Test.startTest();
		ChatLinking.populateContactIds(chatTranscripts, emailContactsMap);
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
		List<LiveChatTranscript> chatTranscripts = new List<LiveChatTranscript> {
			new LiveChatTranscript(SuppliedEmail__c = 'test1@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = 'test1@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = 'test2@example.com'),
			new LiveChatTranscript(SuppliedEmail__c = ''),
			new LiveChatTranscript(SuppliedEmail__c = null),
			new LiveChatTranscript()
		};

		Test.startTest();
		Set<String> emailAddresses = ChatLinking.getUniqueEmailAddresses(chatTranscripts);
		Test.stopTest();

		Assert.areEqual(2, emailAddresses.size(), 'Expected 2 unique email addresses');
	}

	@IsTest
	static void testMapContactsWithEmails() {
		Set<String> emailAddresses = new Set<String> {
			'test1@example.com',
			'test2@example.com',
			'test3@example.com'
		};

		List<Contact> contacts = new List<Contact> {
			new Contact(Id = mockContactId(), Email = 'test1@example.com'),
			new Contact(Id = mockContactId(), Email = 'test2@example.com'),
			new Contact(Id = mockContactId(), Email = 'test2@example.com')
		};

		Test.startTest();
		Map<String, List<Id>> result = ChatLinking.mapContactsWithEmails(emailAddresses, contacts);
		Test.stopTest();

		Assert.areEqual(3, result.size(), 'Results should have 3 keys');
		Assert.areEqual(1, result.get('test1@example.com').size(), 'test1 should map to 1 Contact Id');
		Assert.areEqual(2, result.get('test2@example.com').size(), 'test2 should map to 2 Contact Ids');
		Assert.areEqual(0, result.get('test3@example.com').size(), 'test3 should map to 0 Contact Ids');
	}
}