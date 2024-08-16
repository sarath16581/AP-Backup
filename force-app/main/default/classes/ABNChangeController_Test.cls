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
		MockUtility.Mocks.when(contactsSelector.selectCloneableContactsByAccount((Id) fflib_Match.anyObject())).thenReturn(oldContacts);

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
		System.assert(true, 'Asserting true when completed. False if cloneContacts not completed with exceptions or errors');
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
		List<ABNChangeController.DataTableColumn> columns = ABNChangeController.retrieveColumns('Deal_Support_Request__c', 'ABNChangeDSRCreationDSRColumn');
		List<Schema.FieldSetMember> fields = SObjectType.Deal_Support_Request__c.fieldSets.ABNChangeDSRCreationDSRColumn.getFields();
		System.assertEquals(fields.size(), columns.size(), 'Number of columns retrieved should match the number of fields from the fieldSet. '
				+ 'Expected ' + fields.size() + '; Actual ' + columns.size());
	}

	/**
	 * Test:
	 *  Ensures that DSRs, at risk businesses and related opportunities are retrieved without issues
	 */
	@IsTest
	static void testGetDSRsBaRAndOpportunities() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accs = ApplicationTestDataFactory.getAccounts(1, true);
		List<At_Risk_Business__c> atRiskBusinesses = ApplicationTestDataFactory.getAtRiskBusiness(1, accs[0].Id, true);
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(1, accs[0].Id, true);
		List<Deal_Support_Request__c> dealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, opportunities[0].Id, accs[0].Id,  false);

		// =====================================
		// Stubbing
		// =====================================
		AtRiskBusinessSelector atRiskBusinessSelector = (AtRiskBusinessSelector) MockUtility.mockSelector(AtRiskBusinessSelector.class);
		DealSupportRequestsSelector dealSupportRequestsSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
		OpportunitiesSelector opportunitiesSelector = (OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(atRiskBusinessSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(atRiskBusinesses);
		MockUtility.Mocks.when(dealSupportRequestsSelector.selectByAtRiskBusinessId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(dealSupportRequests);
		MockUtility.Mocks.when(dealSupportRequestsSelector.selectByAccountId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(dealSupportRequests);
		MockUtility.Mocks.when(opportunitiesSelector.selectByAccountId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(opportunities);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Map<String, Object> result = ABNChangeController.getDSRsAndBaR(atRiskBusinesses[0].Id);
		System.assertEquals(atRiskBusinesses[0], result.get('businessAtRisk'), 'BaR record not matched');
		System.assertEquals(dealSupportRequests[0], result.get('dsrList'), 'dsr record not matched');

		List<Opportunity> opps = ABNChangeController.getOpportunities(accs[0].Id);
		System.assertEquals(opportunities[0], opps[0]);

		List<Deal_Support_Request__c> dsrs = ABNChangeController.getDSRsByAccountId(accs[0].Id);
		System.assertEquals(dealSupportRequests[0], dsrs[0], 'dsr record not matched');
	}

	/**
	 * Test:
	 *  Ensures that DSRs are created without issues
	 */
	@IsTest
	static void testCreateDSRs() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accs = ApplicationTestDataFactory.getAccounts(1, true);
		List<Billing_Account__c> bas = ApplicationTestDataFactory.getBillingAccounts(6, accs[0].Id, 'SAP ERP', false);
		Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
		List<ContentVersion> cvs = ApplicationTestDataFactory.getContentVersions(1, documentId, true);
		List<Opportunity> opps = ApplicationTestDataFactory.getOpportunities(1, accs[0].Id, true);
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accs[0].Id, true);
		List<At_Risk_Business__c> atRiskBusinesses = ApplicationTestDataFactory.getAtRiskBusiness(1, accs[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		BillingAccountsSelector billingAccountsSelector = (BillingAccountsSelector) MockUtility.mockSelector(BillingAccountsSelector.class);
		ContentVersionsSelector contentVersionsSelector = (ContentVersionsSelector) MockUtility.mockSelector(ContentVersionsSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(billingAccountsSelector.selectByOrganisationABN((Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<Billing_Account__c>(bas));
		MockUtility.Mocks.when(contentVersionsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, ContentVersion>(cvs));
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject()))
				.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject()))
				.thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		ABNChangeController.DSRRequestWrapper request = new ABNChangeController.DSRRequestWrapper();
		request.dsrTypes = new List<String>{'proposalGeneration', 'contractGeneration', 'terminateContracts', 'terminateSTBAs', 'closeAllBAs'};
		ABNChangeController.DSRRequestOpportunityWrapper opportunityWrapper = new ABNChangeController.DSRRequestOpportunityWrapper();
		opportunityWrapper.opportunityId = opps[0].Id;
		opportunityWrapper.productType = 'AP';
		opportunityWrapper.keyContactId = contacts[0].Id;
		request.opportunityWrappers = new List<ABNChangeController.DSRRequestOpportunityWrapper>{opportunityWrapper};
		request.atRiskBusinessId = atRiskBusinesses[0].Id;
		request.organisationId = accs[0].Id;
		request.organisationABN = '88888888';
		request.relatedOpportunity = opps[0].Id;
		request.allProductTypes = new List<String>{'StarTrack', 'AP'};
		request.isStandardPricing = 'Yes';
		request.estimatedClosureDate = System.today() + 1;
		request.customerRequestDocumentIds = new List<String>{documentId};

		List<String> failedDSRTypes = ABNChangeController.createDSRs(request);
		System.assert(failedDSRTypes.size() == 0, 'Not expecting failed DSRs');
	}
}