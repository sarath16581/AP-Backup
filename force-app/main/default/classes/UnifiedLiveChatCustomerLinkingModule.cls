/**
 * @description Application Module to handle the automatic populating of `LiveChatTranscript.ContactId`.
 *
 * @author Seth Heang
 * @date 2024-10-04
 * @test UnifiedLiveChatCustomerLinkingModuleTest
 * @changelog
 * 2024-10-04 - Seth Heang - Created.
 * 2024-10-07 - Marcel HK - Moved utility methods into module class
 */
public inherited sharing class UnifiedLiveChatCustomerLinkingModule extends ApplicationModule {
	// Setup which triggers this module should respond to
	public UnifiedLiveChatCustomerLinkingModule() {
		getTriggerEvents().enableBeforeInsert();
	}

	/**
	 * @description Called on the BeforeInsert operation and performs the following actions:
	 * - Link contact Id to LiveChat if exactly one contact is found.
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			linkChatsWithContact((List<LiveChatTranscript>) records);
		} catch (Exception ex) {
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(ex),
					'UnifiedLiveChatTranscript',
					UnifiedLiveChatCustomerLinkingModule.class.getName(),
					'onBeforeInsert',
					'LiveChatTranscript',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}

	/**
	 * @description Populates the `LiveChatTranscript.ContactId` based on the
	 * Email Address entered by the customer in the pre-chat form.
	 *
	 * This method will only update the `ContactId` field if there is only 1
	 * Customer Contact record that matches the Email Address exactly.
	 *
	 * Note: This method does not perform any DML operations.
	 *
	 * @param chatTranscripts - The List of `LiveChatTranscripts` to update
	 */
	@TestVisible
	private static void linkChatsWithContact(List<LiveChatTranscript> chatTranscripts) {
		// Get a list of unique email addresses to query with
		Set<String> emailAddresses = getUniqueEmailAddresses(chatTranscripts);

		// Find all potential Contacts
		Set<SObjectField> fieldOverrides = new Set<SObjectField> {
			Contact.Id, Contact.Email, Contact.VerifiedEmail__c
		};
		List<Contact> contacts = ContactsSelector.newInstance(fieldOverrides).selectCustomerByEmail(emailAddresses, new Set<Object>());

		// Map each Email address with unique set of Contact Ids
		Map<String, Set<Id>> emailContactsMap = mapContactsWithEmails(emailAddresses, contacts);

		// Populate the Contact Id on each record (only where there is exactly 1 match)
		populateContactIds(chatTranscripts, emailContactsMap);
	}

	/**
	 * @description Populate the Contact Id on each record (only where there is exactly 1 match)
	 * 
	 * Note: All email addresses are converted to lower-case to improve matching results
	 *
	 * @param chatTranscripts - The List of `LiveChatTranscripts` to update
	 * @param emailContactsMap - The Map of email addresses to a list of Contact Ids
	 */
	@TestVisible
	private static void populateContactIds(List<LiveChatTranscript> chatTranscripts, Map<String, Set<Id>> emailContactsMap) {
		for (LiveChatTranscript chatTranscript : chatTranscripts) {
			if(chatTranscript.ContactId != null) {
				// Avoid overwriting existing values
				continue;
			}

			String emailAddress = (chatTranscript.Email__c ?? '').toLowerCase();
			if (String.isBlank(emailAddress) || !emailContactsMap.containsKey(emailAddress)) {
				continue;
			}

			List<Id> contactIds = new List<Id>(emailContactsMap.get(emailAddress));
			if (contactIds != null && contactIds.size() == 1) {
				chatTranscript.ContactId = contactIds.get(0);
			}
		}
	}

	/**
	 * @description Compile a list of email addresses from the list of chat transcripts.
	 * This method also removes any blank or null values.
	 * 
	 * Note: All email addresses are converted to lower-case to improve matching results
	 *
	 * @param chatTranscripts - The List of SObjects to update
	 * @return Set<String> - The unique list of email addresses
	 */
	@TestVisible
	private static Set<String> getUniqueEmailAddresses(List<LiveChatTranscript> chatTranscripts) {
		Set<String> emailAddresses = new Set<String>();
		for (LiveChatTranscript ct : chatTranscripts) {
			if (String.isNotBlank(ct.Email__c)) {
				emailAddresses.add(ct.Email__c.toLowerCase());
			}
		}
		return emailAddresses;
	}

	/**
	 * @description Maps each email address with a unique list of Contact Ids
	 * that have the email address in either `Email` or `VerifiedEmail__c`.
	 * 
	 * Note: All email addresses are converted to lower-case to improve matching results
	 *
	 * @param emailAddresses - The unique list of email addresses
	 * @param contacts - The Contact records to map the emails with
	 * @return Map<String, List<Id>> - Map of email addresses to a list of Contact Ids
	 */
	@TestVisible
	private static Map<String, Set<Id>> mapContactsWithEmails(Set<String> emailAddresses, List<Contact> contacts) {
		Map<String, Set<Id>> emailContactsMap = new Map<String, Set<Id>>();
		for(String emailAddress : emailAddresses) {
			emailContactsMap.put(emailAddress.toLowerCase(), new Set<Id>());
		}

		for (Contact c : contacts) {
			if(String.isNotBlank(c.Email)) {
				emailContactsMap.get(c.Email.toLowerCase()).add(c.Id);
			}

			if(String.isNotBlank(c.VerifiedEmail__c)) {
				emailContactsMap.get(c.VerifiedEmail__c.toLowerCase()).add(c.Id);
			}
		}

		return emailContactsMap;
	}
}