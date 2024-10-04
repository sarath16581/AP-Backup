/**
 * @description 
 * @changelog
 * 2024-10-04 - Marcel HK - Created
 */
public with sharing class ChatLinking {
	/**
	 * @description Populates the `LiveChatTranscript.ContactId` based on the 
	 * Email Address entered by the customer in the pre-chat form.
	 * 
	 * This method will only update the `ContactId` field if there is only 1
	 * Customer Contact record that matches the Email Address exactly.
	 * 
	 * Note: This method does not perform any DML updates.
	 * 
	 * @param chatTranscripts - The List of `LiveChatTranscripts` to update
	 */
	public static void linkChatsWithContact(List<LiveChatTranscript> chatTranscripts) {
		// Get a list of unique email addresses to query with
		Set<String> emailAddresses = getUniqueEmailAddresses(chatTranscripts);

		// Find all potential Contacts
		List<Contact> contacts = ContactsSelector.newInstance()
			.selectCustomerByEmail(emailAddresses, new Set<Object>());

		// Map each Email address with unique list of Contact Ids
		Map<String, List<Id>> emailContactsMap = mapContactsWithEmails(emailAddresses, contacts);

		// Populate the Contact Id on each record (only where there is exactly 1 match)
		populateContactIds(chatTranscripts, emailContactsMap);
	}

	/**
	 * @description Populate the Contact Id on each record (only where there is exactly 1 match)
	 * 
	 * @param chatTranscripts - The List of `LiveChatTranscripts` to update
	 * @param emailContactsMap - The Map of email addresses to a list of Contact Ids
	 */
	@TestVisible
	private static void populateContactIds(List<LiveChatTranscript> chatTranscripts, Map<String, List<Id>> emailContactsMap) {
		for(LiveChatTranscript chatTranscript : chatTranscripts) {
			if(String.isBlank(chatTranscript.SuppliedEmail__c)) {
				continue;
			}

			List<Id> contactIds = emailContactsMap.get(chatTranscript.SuppliedEmail__c);
			if(contactIds.size() == 1) {
				chatTranscript.ContactId = contactIds.get(0);
			}
		}
	}

	/**
	 * @description Compile a list of email addresses from the list of chat transcripts.
	 * This method also removes any blank or null values.
	 * 
	 * @param chatTranscripts - The List of SObjects to update
	 * @return Set<String> - The unique list of email addresses
	 */
	@TestVisible
	private static Set<String> getUniqueEmailAddresses(List<LiveChatTranscript> chatTranscripts) {
		Set<String> emailAddresses = new Set<String>();
		for (LiveChatTranscript ct : chatTranscripts) {
			if(String.isNotBlank(ct.SuppliedEmail__c)) {
				emailAddresses.add(ct.SuppliedEmail__c);
			}
		}
		return emailAddresses;
	}

	/**
	 * @description Maps each email address with a unique list of Contact Ids
	 * that have the email address in either `Email` or `VerifiedEmail__c`.
	 * 
	 * @param emailAddresses - The unique list of email addresses
	 * @param contacts - The Contact records to map the emails with
	 * @return Map<String, List<Id>> - Map of email addresses to a list of Contact Ids
	 */
	@TestVisible
	private static Map<String, List<Id>> mapContactsWithEmails(Set<String> emailAddresses, List<Contact> contacts) {
		Map<String, List<Id>> emailContactsMap = new Map<String, List<Id>>();
		for(String emailAddress : emailAddresses) {
			Set<Id> contactIds = new Set<Id>();
			for (Contact c : contacts) {
				if (String.isNotBlank(emailAddress) && (c.Email == emailAddress || c.VerifiedEmail__c == emailAddress)) {
					contactIds.add(c.Id);
				}
			}
			emailContactsMap.put(emailAddress, new List<Id>(contactIds));
		}
		return emailContactsMap;
	}
}