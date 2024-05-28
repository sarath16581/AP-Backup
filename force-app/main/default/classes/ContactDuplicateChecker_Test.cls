/**
 * @author Harry Wang
 * @date 2024-05-22
 * @tag CSP
 * @description Test class for ContactDuplicateChecker
 * @changelog
 * 2024-05-22 - Harry Wang - Created
 */
@IsTest
public with sharing class ContactDuplicateChecker_Test {
	/**
	 * Test:
	 *  Ensures that unqiue contacts are returned based on the hashed field values
	 */
	@IsTest
	private static void testFindUniqueContacts() {
		// Data Preparation
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Contact> contactsAccount1 = ApplicationTestDataFactory.getContacts(3, accounts[0].Id, false);
		contactsAccount1[2].FirstName = 'Unique';
		contactsAccount1[2].LastName = 'Contact';
		contactsAccount1[2].Email = 'unique_contact@test.com';
		List<Contact> contactsAccount2 = ApplicationTestDataFactory.getContacts(2, accounts[1].Id, false);

		Test.startTest();
		List<Contact> deduplicatedContacts = ContactDuplicateChecker.findUniqueContacts(contactsAccount1, contactsAccount2);

		System.assert(deduplicatedContacts.size() > 0, 'Expected 1 unique contact');
		System.assertEquals('unique_contact@test.com', deduplicatedContacts[0].Email, 'Expected unique contact email');
		Test.stopTest();
	}
}