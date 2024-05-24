/**
 * @author Harry Wang
 * @date 2024-05-22
 * @tag CSP
 * @description Test class for ABNChangeController
 * @changelog
 * 2024-05-22 - Harry Wang - Created
 */
@IsTest
public with sharing class ABNChangeController_Test {
	/**
	 * Test:
	 *  Ensures that the depuplicated contacts and BaR are selected and retrieved
	 */
	@IsTest
	private static void testGetDeduplicatedContactsAndBaR() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<At_Risk_Business__c> atRiskBusinesses = ApplicationTestDataFactory.getAtRiskBusiness(1, accounts[0].Id, false);
		List<Contact> oldContacts = ApplicationTestDataFactory.getContacts(3, accounts[0].Id, false);
		List<Contact> newContacts = ApplicationTestDataFactory.getContacts(2, accounts[1].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		AtRiskBusinessSelector atRiskBusinessSelector = (AtRiskBusinessSelector) MockUtility.mockSelector(AtRiskBusinessSelector.class);
		ContactsSelector contactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(atRiskBusinessSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(atRiskBusinesses);
		MockUtility.Mocks.when(ContactsSelector.selectCloneableContactsByAccount((Set<Id>) fflib_Match.anyObject())).thenReturn(oldContacts);
		MockUtility.Mocks.when(ContactsSelector.selectByAccount((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, Contact>(newContacts));

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> contactsBaR = ABNChangeController.getDeduplicatedContactsAndBaR(atRiskBusinesses[0].Id);
		System.assertEquals(accounts[0].Id, ((SObject)contactsBaR.get('businessAtRisk')).get('Legal_Entity_Name__c'), 'Expected legal entity name from the BaR');
		System.assertEquals(1, ((List<Contact>)contactsBaR.get('contacts')).size(), 'Expected 1 found');

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that contacts are cloned without issues
	 */
	@IsTest
	private static void testCloneContacts() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accs = ApplicationTestDataFactory.getAccounts(1, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accs[0].Id, true);
		List<Id> oldContactIds = new List<Id>{contacts[0].Id};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ContactsSelector contactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(contactsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Contact>(contacts));
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), (Database.DMLOptions)fflib_Match.anyObject()))
				.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<String> ids = ABNChangeController.cloneContacts(accs[0].Id, oldContactIds);
		System.assertEquals(1, ids.size(), 'Expected 1 contact cloned');
		Test.stopTest();
	}
}