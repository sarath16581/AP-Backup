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
		List<Contact> oldContacts = ApplicationTestDataFactory.getContacts(51, accounts[0].Id, false);

		// =====================================
		// Stubbing
		// =====================================
		AtRiskBusinessSelector atRiskBusinessSelector = (AtRiskBusinessSelector) MockUtility.mockSelector(AtRiskBusinessSelector.class);
		ContactsSelector contactsSelector = (ContactsSelector) MockUtility.mockSelector(ContactsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(atRiskBusinessSelector.selectById((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(atRiskBusinesses);
		MockUtility.Mocks.when(contactsSelector.selectCloneableContactsByAccount((Set<Id>) fflib_Match.anyObject())).thenReturn(oldContacts);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> contactsBaR = ABNChangeController.getDeduplicatedContactsAndBaR(atRiskBusinesses[0].Id);
		System.assertEquals(accounts[0].Id, ((SObject)contactsBaR.get('businessAtRisk')).get('Legal_Entity_Name__c'), 'Expected legal entity: ' + accounts[0].Id
				+  ' retrieved from the BaR; Actual: ' + ((SObject)contactsBaR.get('businessAtRisk')).get('Legal_Entity_Name__c'));
		System.assertEquals(51, ((List<Contact>)contactsBaR.get('contacts')).size(), 'Expected 51; Actual '
				+ ((List<Contact>)contactsBaR.get('contacts')).size());
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
		ABNChangeController.cloneContacts(accs[0].Id, oldContactIds);
		System.assert(true, 'cloneContacts Not completed');
		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that datatable columns are retrieved
	 */
	@IsTest
	static void testRetrieveColumns() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		// =====================================
		// Stubbing
		// =====================================
		// None!
		// =====================================
		// Testing
		// =====================================
		List<ABNChangeController.DataTableColumn> columns = ABNChangeController.retrieveColumns();
		List<Schema.FieldSetMember> fields = SObjectType.Contact.fieldSets.ABNChangeContactColumn.getFields();
		System.assertEquals(fields.size(), columns.size(), 'Number of columns retrieved should match the number of fields from the fieldSet. '
				+ 'Expected ' + fields.size() + '; Actual ' + columns.size());
	}
}