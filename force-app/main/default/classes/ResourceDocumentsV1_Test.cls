/**
 * @description Test class for ResourceDocumentsV1
 * @author Nathan Franklin
 * @date 2020-10-06
 * @group API
 * @changelog
 */
@IsTest
private class ResourceDocumentsV1_Test {

	/**
	 * Scenario: Ensure the correct account number can be extracted from the uri
	 */
	@IsTest
	private static void ensureEntityNumberIsExtractedFromUrlCorrectly() {

		// =====================================
		// Data Preparation
		// =====================================
		Account parentAccountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		parentAccountRecord.LEGACY_ID__c = '60000002';

		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		accountRecord.LEGACY_ID__c = '60000001';

		Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
		caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{'CaseNumber' => '1002938'});

		Billing_Account__c billingAccountRecord = ApplicationTestDataFactory.getBillingAccounts(1, parentAccountRecord.Id, 'SAP ERP', true)[0];
		billingAccountRecord.LEGACY_ID__c = '7000001';

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);
		BillingAccountsSelector mockBillingAccountsSelector = (BillingAccountsSelector)MockUtility.mockSelector(BillingAccountsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAccountNumber(new Set<String>{accountRecord.LEGACY_ID__c})).thenReturn(new Map<Id, Account>{accountRecord.Id => accountRecord});
		MockUtility.Mocks.when(mockCasesSelector.selectByCaseNumber(new Set<String>{caseRecord.CaseNumber})).thenReturn(new Map<Id, Case>{caseRecord.Id => caseRecord});
		MockUtility.Mocks.when(mockBillingAccountsSelector.selectByAccountNumber(new Set<String>{billingAccountRecord.LEGACY_ID__c})).thenReturn(new Map<Id, Billing_Account__c>{billingAccountRecord.Id => billingAccountRecord});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		String uri = '/1.0/documents/' + accountRecord.LEGACY_ID__c;
		Id entityId = ResourceDocumentsV1.getEntityId(uri, 'Account', false);
		System.assertEquals(accountRecord.Id, entityId);
		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectByAccountNumber(new Set<String>{accountRecord.LEGACY_ID__c});

		uri = '/1.0/documents/' + caseRecord.CaseNumber;
		entityId = ResourceDocumentsV1.getEntityId(uri, 'Case', false);
		System.assertEquals(caseRecord.Id, entityId);
		((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, 1)).selectByCaseNumber(new Set<String>{caseRecord.CaseNumber});

		uri = '/1.0/documents/' + billingAccountRecord.LEGACY_ID__c;
		entityId = ResourceDocumentsV1.getEntityId(uri, 'Billing_Account__c', false);
		System.assertEquals(billingAccountRecord.Id, entityId);
		((BillingAccountsSelector)MockUtility.Mocks.verify(mockBillingAccountsSelector, 1)).selectByAccountNumber(new Set<String>{billingAccountRecord.LEGACY_ID__c});

		uri = '/1.0/documents/' + billingAccountRecord.LEGACY_ID__c;
		entityId = ResourceDocumentsV1.getEntityId(uri, 'Billing_Account__c', true);
		System.assertEquals(parentAccountRecord.Id, entityId);
		((BillingAccountsSelector)MockUtility.Mocks.verify(mockBillingAccountsSelector, 2)).selectByAccountNumber(new Set<String>{billingAccountRecord.LEGACY_ID__c});

		// make sure an exception is thrown when an invalid number is passed in
		try {
			uri = '/1.0/documents/6T1111T';
			ResourceDocumentsV1.getEntityId(uri, 'Account', false);

			System.assert(false, 'Expected an exception to be thrown due to invalid organisation number');
		} catch (Exception ex) {
			System.assert(true);
		}
		try {
			uri = '/1.0/documents/6T1111T';
			ResourceDocumentsV1.getEntityId(uri, 'Billing_Account__c', false);

			System.assert(false, 'Expected an exception to be thrown due to invalid organisation number');
		} catch (Exception ex) {
			System.assert(true);
		}
		try {
			uri = '/1.0/documents/6T1111T';
			ResourceDocumentsV1.getEntityId(uri, 'Case', false);

			System.assert(false, 'Expected an exception to be thrown due to invalid organisation number');
		} catch (Exception ex) {
			System.assert(true);
		}

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that a document can be created successfully and that it is assigned the appropriate perm for exposure to community
	 */
	@IsTest
	private static void ensureDocumentCreationFlowWithCommunityAccess() {

		// =====================================
		// Data Preparation
		// =====================================
		String organisationNumber = '60000001';
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		accountRecord.LEGACY_ID__c = organisationNumber;

		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, fflib_IDGenerator.generate(ContentDocument.SObjectType), true)[0];

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		ContentVersionsSelector mockContentVersionsSelector = (ContentVersionsSelector) MockUtility.mockSelector(ContentVersionsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Selectors
		MockUtility.Mocks.when(mockAccountsSelector.selectByAccountNumber(new Set<String>{organisationNumber})).thenReturn(new Map<Id, Account>{accountRecord.Id => accountRecord});
		MockUtility.Mocks.when(mockContentDocumentLinksSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, ContentDocumentLink>());
		MockUtility.Mocks.when(mockContentVersionsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, ContentVersion>{contentVersionRecord.Id => contentVersionRecord});

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		request.httpMethod = 'PUT';
		request.requestURI = '/1.0/documents/' + organisationNumber;
		request.params.putAll(getReportRequestAttributesWithCommunityAssignment());
		request.requestBody = Blob.valueOf('pdfcontent');

		RestContext.request = request;
		RestContext.response = response;

		// execute the api
		ResourceDocumentsV1.put();

		Test.stopTest();

		// make sure the method behaved
		// 2 inserts - 1 ContentVersion, 1 ContentDocumentLink
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 2)).dmlInsert((List<SObject>)fflib_Match.anyObject());

		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectByAccountNumber(new Set<String>{organisationNumber});
		((ContentDocumentLinksSelector)MockUtility.Mocks.verify(mockContentDocumentLinksSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ContentVersionsSelector)MockUtility.Mocks.verify(mockContentVersionsSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());

		// these records are logged from AnswerGenericDMLInserted
		System.assertEquals(2, MockUtility.mockDMLInsertedRecords.size());
		System.assertEquals(ContentVersion.SObjectType, MockUtility.mockDMLInsertedRecords[0].getSObjectType());
		System.assertEquals(ContentDocumentLink.SObjectType, MockUtility.mockDMLInsertedRecords[1].getSObjectType());

		// Make sure the content document link was created for the organisation
		System.assertEquals(accountRecord.Id, MockUtility.mockDMLInsertedRecords[1].get('LinkedEntityId'));
		System.assertEquals('AllUsers', MockUtility.mockDMLInsertedRecords[1].get('Visibility'));

		Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(contentVersionRecord.ContentDocumentId, responseObject.get('id'));
		System.assertEquals('1', responseObject.get('versionNumber'));
		System.assertEquals(200, response.statusCode);
	}

	/**
	 * Test:
	 *  Ensures that Report documents are correctly validated
	 *  Certain parameters are enforced when the record type is Report
	 */
	@IsTest
	private static void ensureValidationRuleErrorsForReports() {

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
		Test.startTest();

		// Baseline test - Report
		Map<String, String> attributes = getReportRequestAttributesWithCommunityAssignment();
		List<String> errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assert(errors.isEmpty());

		// Test 1
		attributes.remove('document_date');
		errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assertNotEquals(0, errors.size());

		// Test 2
		attributes.put('document_date', 'invalid');
		errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assertNotEquals(0, errors.size());

		// Test 3
		attributes = getReportRequestAttributesWithCommunityAssignment();
		attributes.remove('document_type');
		errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assertNotEquals(0, errors.size());

		// Test 4
		attributes = getReportRequestAttributesWithCommunityAssignment();
		attributes.remove('document_interval');
		errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assertNotEquals(0, errors.size());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that validation rules are correctly triggered when invalid attributes are passed in
	 */
	@IsTest
	private static void ensureGenericValidationRuleErrors() {

		// =====================================
		// Data Preparation
		// =====================================
		String organisationNumber = '60000001';
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		accountRecord.LEGACY_ID__c = organisationNumber;

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAccountsSelector.selectByAccountNumber(new Set<String>{organisationNumber})).thenReturn(new Map<Id, Account>{accountRecord.Id => accountRecord});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Baseline test - Report
		Map<String, String> attributes = getContractRequestAttributesWithNoCommunityAssignment(); // Contract record type contains no specific validation rules
		List<String> errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assert(errors.isEmpty(), errors);

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		request.httpMethod = 'PUT';
		request.requestURI = '/1.0/documents/' + organisationNumber;
		request.requestBody = Blob.valueOf('pdfcontent');

		RestContext.request = request;
		RestContext.response = response;

		// Test 1
		attributes = getContractRequestAttributesWithNoCommunityAssignment();
		attributes.put('document_date', 'invalid');
		request.params.clear();
		request.params.putAll(attributes);
		ResourceDocumentsV1.put();
		Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(500, response.statusCode);
		System.assertNotEquals(0, ((List<Object>)responseObject.get('errors')).size());

		// Test 2
		attributes = getContractRequestAttributesWithNoCommunityAssignment();
		attributes.put('community_access', 'invalid');
		request.params.clear();
		request.params.putAll(attributes);
		ResourceDocumentsV1.put();
		responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(500, response.statusCode);
		System.assertNotEquals(0, ((List<Object>)responseObject.get('errors')).size());

		// Test 3
		attributes = getContractRequestAttributesWithNoCommunityAssignment();
		attributes.remove('filename');
		request.params.clear();
		request.params.putAll(attributes);
		ResourceDocumentsV1.put();
		responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(500, response.statusCode);
		System.assertNotEquals(0, ((List<Object>)responseObject.get('errors')).size());

		// Test 4
		attributes = getContractRequestAttributesWithNoCommunityAssignment();
		attributes.remove('record_type');
		request.params.clear();
		request.params.putAll(attributes);
		ResourceDocumentsV1.put();
		responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(500, response.statusCode);
		System.assertNotEquals(0, ((List<Object>)responseObject.get('errors')).size());

		// Test 5 - invalid account number in url
		request.requestURI = '/1.0/documents/T1129384';
		request.params.clear();
		request.params.putAll(getContractRequestAttributesWithNoCommunityAssignment());
		ResourceDocumentsV1.put();
		responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(500, response.statusCode);
		System.assertNotEquals(0, ((List<Object>)responseObject.get('errors')).size());

		// Test 6 - entity type invalid
		attributes = getContractRequestAttributesWithNoCommunityAssignment();
		attributes.put('entity_type', 'invalid');
		request.params.clear();
		request.params.putAll(attributes);
		ResourceDocumentsV1.put();
		responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(500, response.statusCode);
		System.assertNotEquals(0, ((List<Object>)responseObject.get('errors')).size());

		// Test 7 - entity type invalid
		attributes = getContractRequestAttributesWithNoCommunityAssignment();
		attributes.put('entity_type', 'EventMessage__c');
		request.params.clear();
		request.params.putAll(attributes);
		ResourceDocumentsV1.put();
		responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(500, response.statusCode);
		System.assertNotEquals(0, ((List<Object>)responseObject.get('errors')).size());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that record type is enforced
	 */
	@IsTest
	private static void ensureValidationRuleErrorsForRecordType() {

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
		Test.startTest();

		// Baseline test
		Map<String, String> attributes = getReportRequestAttributesWithCommunityAssignment();
		List<String> errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assert(errors.isEmpty());

		// Test 1
		attributes.remove('record_type');
		errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assertNotEquals(0, errors.size());

		// Test 1
		attributes.put('record_type', 'invalid');
		errors = ResourceDocumentsV1.validateRequest('PUT', attributes);
		System.assertNotEquals(0, errors.size());

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that a document can be created successfully and that it is assigned the appropriate perm for NO exposure to community
	 */
	@IsTest
	private static void ensureDocumentCreationFlowWithNoCommunityAccess() {

		// =====================================
		// Data Preparation
		// =====================================
		String organisationNumber = '60000001';
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		accountRecord.LEGACY_ID__c = organisationNumber;

		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, fflib_IDGenerator.generate(ContentDocument.SObjectType), true)[0];

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		ContentVersionsSelector mockContentVersionsSelector = (ContentVersionsSelector) MockUtility.mockSelector(ContentVersionsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Selectors
		MockUtility.Mocks.when(mockAccountsSelector.selectByAccountNumber(new Set<String>{organisationNumber})).thenReturn(new Map<Id, Account>{accountRecord.Id => accountRecord});
		MockUtility.Mocks.when(mockContentDocumentLinksSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, ContentDocumentLink>());
		MockUtility.Mocks.when(mockContentVersionsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, ContentVersion>{contentVersionRecord.Id => contentVersionRecord});

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		request.httpMethod = 'PUT';
		request.requestURI = '/1.0/documents/' + organisationNumber;
		request.params.putAll(getReportRequestAttributesWithNoCommunityAssignment());
		request.requestBody = Blob.valueOf('pdfcontent');

		RestContext.request = request;
		RestContext.response = response;

		// execute the api
		ResourceDocumentsV1.put();

		Test.stopTest();

		// make sure the method behaved
		// 2 inserts - 1 ContentVersion, 1 ContentDocumentLink
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 2)).dmlInsert((List<SObject>)fflib_Match.anyObject());

		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectByAccountNumber(new Set<String>{organisationNumber});
		((ContentDocumentLinksSelector)MockUtility.Mocks.verify(mockContentDocumentLinksSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ContentVersionsSelector)MockUtility.Mocks.verify(mockContentVersionsSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());

		// these records are logged from AnswerGenericDMLInserted
		System.assertEquals(2, MockUtility.mockDMLInsertedRecords.size());
		System.assertEquals(ContentVersion.SObjectType, MockUtility.mockDMLInsertedRecords[0].getSObjectType());
		System.assertEquals(ContentDocumentLink.SObjectType, MockUtility.mockDMLInsertedRecords[1].getSObjectType());

		// Make sure the content document link was created for the organisation
		System.assertEquals(accountRecord.Id, MockUtility.mockDMLInsertedRecords[1].get('LinkedEntityId'));
		System.assertEquals('InternalUsers', MockUtility.mockDMLInsertedRecords[1].get('Visibility'));

		Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(contentVersionRecord.ContentDocumentId, responseObject.get('id'));
		System.assertEquals('1', responseObject.get('versionNumber'));
		System.assertEquals(200, response.statusCode);
	}

	/**
	 * Test:
	 *  Ensures that a document version can be created where another version already exists and that it is assigned the appropriate perm for NO exposure to community
	 *  NOTE: a dmlUpdate operation is required since the existing record is mocked to equal 'InternalUsers'
	 */
	@IsTest
	private static void ensureExistingDocumentIsVersionedFlowWithNoCommunityAccess() {

		// =====================================
		// Data Preparation
		// =====================================
		String organisationNumber = '60000001';
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		accountRecord.LEGACY_ID__c = organisationNumber;

		Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, documentId, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, accountRecord.Id, documentId, true)[0];
		documentLinkRecord.Visibility = 'AllUsers'; // <-- this will cause a dmlUpdate operation since the 'existing' record is set for all users rather than just internal users

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		ContentVersionsSelector mockContentVersionsSelector = (ContentVersionsSelector) MockUtility.mockSelector(ContentVersionsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Selectors
		MockUtility.Mocks.when(mockAccountsSelector.selectByAccountNumber(new Set<String>{organisationNumber})).thenReturn(new Map<Id, Account>{accountRecord.Id => accountRecord});
		MockUtility.Mocks.when(mockContentDocumentLinksSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, ContentDocumentLink>{documentLinkRecord.Id => documentLinkRecord});
		MockUtility.Mocks.when(mockContentVersionsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, ContentVersion>{contentVersionRecord.Id => contentVersionRecord});

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		request.httpMethod = 'PUT';
		request.requestURI = '/1.0/documents/' + organisationNumber;
		request.params.putAll(getReportRequestAttributesWithNoCommunityAssignment());
		request.requestBody = Blob.valueOf('pdfcontent');

		RestContext.request = request;
		RestContext.response = response;

		// execute the api
		ResourceDocumentsV1.put();

		Test.stopTest();

		// make sure the method behaved
		// 1 insert - 1 ContentVersion
		// 1 update - 1 ContentDocumentLink
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectByAccountNumber(new Set<String>{organisationNumber});
		((ContentDocumentLinksSelector)MockUtility.Mocks.verify(mockContentDocumentLinksSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ContentVersionsSelector)MockUtility.Mocks.verify(mockContentVersionsSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());

		// these records are logged from AnswerGenericDMLInserted and AnswerGenericDMLUpdated
		System.assertEquals(1, MockUtility.mockDMLInsertedRecords.size());
		System.assertEquals(1, MockUtility.mockDMLUpdatedRecords.size());

		System.assertEquals(ContentVersion.SObjectType, MockUtility.mockDMLInsertedRecords[0].getSObjectType());
		System.assertEquals(ContentDocumentLink.SObjectType, MockUtility.mockDMLUpdatedRecords[0].getSObjectType());

		// Make sure the content document link was created for the organisation
		System.assertEquals(documentId, MockUtility.mockDMLInsertedRecords[0].get('ContentDocumentId'));
		System.assertEquals('InternalUsers', MockUtility.mockDMLUpdatedRecords[0].get('Visibility'));

		Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(documentId, responseObject.get('id'));
		System.assertEquals(200, response.statusCode);
	}

	/**
	 * Test:
	 *  Ensures that a document version can be created where another version already exists and that it is assigned the appropriate perm for exposure to community
	 */
	@IsTest
	private static void ensureExistingDocumentIsVersionedFlowWithCommunityAccess() {

		// =====================================
		// Data Preparation
		// =====================================
		String organisationNumber = '60000001';
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		accountRecord.LEGACY_ID__c = organisationNumber;

		Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, documentId, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, accountRecord.Id, documentId, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		ContentVersionsSelector mockContentVersionsSelector = (ContentVersionsSelector) MockUtility.mockSelector(ContentVersionsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Selectors
		MockUtility.Mocks.when(mockAccountsSelector.selectByAccountNumber(new Set<String>{organisationNumber})).thenReturn(new Map<Id, Account>{accountRecord.Id => accountRecord});
		MockUtility.Mocks.when(mockContentDocumentLinksSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, ContentDocumentLink>{documentLinkRecord.Id => documentLinkRecord});
		MockUtility.Mocks.when(mockContentVersionsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, ContentVersion>{contentVersionRecord.Id => contentVersionRecord});

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		request.httpMethod = 'PUT';
		request.requestURI = '/1.0/documents/' + organisationNumber;
		request.params.putAll(getReportRequestAttributesWithCommunityAssignment());
		request.requestBody = Blob.valueOf('pdfcontent');

		RestContext.request = request;
		RestContext.response = response;

		// execute the api
		ResourceDocumentsV1.put();

		Test.stopTest();

		// make sure the method behaved
		// 1 insert - 1 ContentVersion
		// 1 update - 1 ContentDocumentLink
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectByAccountNumber(new Set<String>{organisationNumber});
		((ContentDocumentLinksSelector)MockUtility.Mocks.verify(mockContentDocumentLinksSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ContentVersionsSelector)MockUtility.Mocks.verify(mockContentVersionsSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());

		// these records are logged from AnswerGenericDMLInserted and AnswerGenericDMLUpdated
		System.assertEquals(1, MockUtility.mockDMLInsertedRecords.size());
		System.assertEquals(1, MockUtility.mockDMLUpdatedRecords.size());

		System.assertEquals(ContentVersion.SObjectType, MockUtility.mockDMLInsertedRecords[0].getSObjectType());
		System.assertEquals(ContentDocumentLink.SObjectType, MockUtility.mockDMLUpdatedRecords[0].getSObjectType());

		// Make sure the content document link was created for the organisation
		System.assertEquals(documentId, MockUtility.mockDMLInsertedRecords[0].get('ContentDocumentId'));
		System.assertEquals('AllUsers', MockUtility.mockDMLUpdatedRecords[0].get('Visibility'));

		Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(documentId, responseObject.get('id'));
		System.assertEquals(200, response.statusCode);
	}

	/**
	 * Test:
	 *  Ensures that a document version can be created where another version already exists. This existing link record is mocked to for community access already (AllUsers), so no dmlUpdate operation is fired to update the 'existing' link
	 */
	@IsTest
	private static void ensureExistingDocumentIsVersionedFlowWithNoChangeToAccessPermissions() {

		// =====================================
		// Data Preparation
		// =====================================
		String organisationNumber = '60000001';
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, true)[0];
		accountRecord.LEGACY_ID__c = organisationNumber;

		Id documentId = fflib_IDGenerator.generate(ContentDocument.SObjectType);
		ContentVersion contentVersionRecord = ApplicationTestDataFactory.getContentVersions(1, documentId, true)[0];
		ContentDocumentLink documentLinkRecord = ApplicationTestDataFactory.getContentDocumentLinks(1, accountRecord.Id, documentId, true)[0];
		documentLinkRecord.Visibility = 'AllUsers'; // <-- since this is the same value as what we are requesting, there will be no need to update the 'existing' link record to change access permissions

		// =====================================
		// Stubbing
		// =====================================
		AccountsSelector mockAccountsSelector = (AccountsSelector) MockUtility.mockSelector(AccountsSelector.class);
		ContentDocumentLinksSelector mockContentDocumentLinksSelector = (ContentDocumentLinksSelector) MockUtility.mockSelector(ContentDocumentLinksSelector.class);
		ContentVersionsSelector mockContentVersionsSelector = (ContentVersionsSelector) MockUtility.mockSelector(ContentVersionsSelector.class);

		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();

		// Selectors
		MockUtility.Mocks.when(mockAccountsSelector.selectByAccountNumber(new Set<String>{organisationNumber})).thenReturn(new Map<Id, Account>{accountRecord.Id => accountRecord});
		MockUtility.Mocks.when(mockContentDocumentLinksSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new Map<Id, ContentDocumentLink>{documentLinkRecord.Id => documentLinkRecord});
		MockUtility.Mocks.when(mockContentVersionsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, ContentVersion>{contentVersionRecord.Id => contentVersionRecord});

		// Database
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		request.httpMethod = 'PUT';
		request.requestURI = '/1.0/documents/' + organisationNumber;
		request.params.putAll(getReportRequestAttributesWithCommunityAssignment());
		request.requestBody = Blob.valueOf('pdfcontent');

		RestContext.request = request;
		RestContext.response = response;

		// execute the api
		ResourceDocumentsV1.put();

		Test.stopTest();

		// make sure the method behaved
		// 1 insert - 1 ContentVersion
		// 1 update - 1 ContentDocumentLink
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlInsert((List<SObject>)fflib_Match.anyObject());
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 0)).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		((AccountsSelector)MockUtility.Mocks.verify(mockAccountsSelector, 1)).selectByAccountNumber(new Set<String>{organisationNumber});
		((ContentDocumentLinksSelector)MockUtility.Mocks.verify(mockContentDocumentLinksSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
		((ContentVersionsSelector)MockUtility.Mocks.verify(mockContentVersionsSelector, 1)).selectById((Set<Id>)fflib_Match.anyObject());

		// these records are logged from AnswerGenericDMLInserted and AnswerGenericDMLUpdated
		System.assertEquals(1, MockUtility.mockDMLInsertedRecords.size());
		System.assertEquals(ContentVersion.SObjectType, MockUtility.mockDMLInsertedRecords[0].getSObjectType());
		System.assertEquals(documentId, MockUtility.mockDMLInsertedRecords[0].get('ContentDocumentId'));

		Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		System.assertEquals(documentId, responseObject.get('id'));
		System.assertEquals(200, response.statusCode);
	}

	/**
	 * Test:
	 *  Ensures that a document can be created end to end
	 */
	@IsTest
	private static void ensureDocumentCreationFlowEndToEnd() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert accountRecord;
		accountRecord = [SELECT Id, LEGACY_ID__c FROM Account LIMIT 1];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		request.httpMethod = 'PUT';
		request.requestURI = '/1.0/documents/' + accountRecord.LEGACY_ID__c;
		request.params.putAll(getReportRequestAttributesWithCommunityAssignment());
		request.requestBody = Blob.valueOf('pdfcontent');

		RestContext.request = request;
		RestContext.response = response;

		// execute the api
		ResourceDocumentsV1.put();

		Test.stopTest();

		Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Id documentId = Id.valueOf(String.valueOf(responseObject.get('id')));
		String versionNumber = String.valueOf(responseObject.get('versionNumber'));

		ContentVersion versionRecord = [SELECT ContentDocumentId, VersionNumber FROM ContentVersion];
		List<ContentDocumentLink> linkRecords = [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :documentId AND LinkedEntityId = :accountRecord.Id];

		System.assertEquals('1', versionNumber);
		System.assertEquals(200, response.statusCode);
		System.assertEquals(documentId, versionRecord.ContentDocumentId);
		System.assertEquals(1, linkRecords.size());
	}

	/**
	 * Test:
	 *  Ensures that a document can be created where an existing version already exists end to end
	 */
	@IsTest
	private static void ensureExistingDocumentIsVersionedFlowEndToEnd() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert accountRecord;
		accountRecord = [SELECT Id, LEGACY_ID__c FROM Account LIMIT 1];

		// insert the file and set the access settings
		Map<String, String> parameters = getReportRequestAttributesWithCommunityAssignment();

		ContentVersion documentVersionRecord = new ContentVersion();
		documentVersionRecord.RecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('ContentVersion', new Set<String>{'Report'}).values()[0].Id;
		documentVersionRecord.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
		documentVersionRecord.PathOnClient = '/' + parameters.get('filename'); // The files name, extension is very important here which will help the file in preview.
		documentVersionRecord.Title = parameters.get('filename').substringBeforeLast('.'); // Display name of the files
		documentVersionRecord.VersionData = Blob.valueOf('pdfcontent');
		documentVersionRecord.Document_Type__c = parameters.get('document_type');
		documentVersionRecord.Document_Interval__c = parameters.get('document_interval');
		documentVersionRecord.Document_Date__c = Date.valueOf(parameters.get('document_date'));
		insert documentVersionRecord;

		// grab the document id from the version record that was just created
		Id newDocumentId = [SELECT ContentDocumentId FROM ContentVersion].ContentDocumentId;

		ContentDocumentLink newDocumentLinkRecord = new ContentDocumentLink();
		newDocumentLinkRecord.LinkedEntityId = accountRecord.Id;
		newDocumentLinkRecord.ContentDocumentId = newDocumentId;
		newDocumentLinkRecord.ShareType = 'I';
		newDocumentLinkRecord.Visibility = 'AllUsers';
		insert newDocumentLinkRecord;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();

		request.httpMethod = 'PUT';
		request.requestURI = '/1.0/documents/' + accountRecord.LEGACY_ID__c;
		request.params.putAll(getReportRequestAttributesWithCommunityAssignment());
		request.requestBody = Blob.valueOf('pdfcontent');

		RestContext.request = request;
		RestContext.response = response;

		// execute the api
		ResourceDocumentsV1.put();

		Test.stopTest();

		Map<String, Object> responseObject = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Id documentId = Id.valueOf(String.valueOf(responseObject.get('id')));
		String versionNumber = String.valueOf(responseObject.get('versionNumber'));

		ContentDocument documentRecord = [SELECT LatestPublishedVersion.VersionNumber FROM ContentDocument WHERE Id = :documentId];
		List<ContentDocumentLink> linkRecords = [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :documentId AND LinkedEntityId = :accountRecord.Id];

		System.assertEquals('2', versionNumber);
		System.assertEquals('2', documentRecord.LatestPublishedVersion.VersionNumber);
		System.assertEquals(200, response.statusCode);
		System.assertEquals(1, linkRecords.size());

		// make sure no additional link record was created
		System.assertEquals(newDocumentLinkRecord.Id, linkRecords[0].Id);
	}

	/**
	 * Test:
	 *  Ensures that when searching for an existing document, only valid matches are returned.
	 */
	@IsTest
	private static void ensureDocumentSearchMatchesCorrectlyEndToEnd() {

		// =====================================
		// Data Preparation
		// =====================================
		Account accountRecord = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert accountRecord;
		accountRecord = [SELECT Id, LEGACY_ID__c FROM Account LIMIT 1];

		Map<String, String> parameters = getReportRequestAttributesWithCommunityAssignment();

		Id reportRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('ContentVersion', new Set<String>{'Report'}).values()[0].Id;
		Id contractRecordType = RecordTypesSelector.newInstance().selectByDeveloperName('ContentVersion', new Set<String>{'Contract'}).values()[0].Id;

		// insert the file and set the access settings
		ContentVersion documentVersionRecord = new ContentVersion();
		documentVersionRecord.RecordTypeId = reportRecordType;
		documentVersionRecord.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
		documentVersionRecord.PathOnClient = '/' + parameters.get('filename'); // The files name, extension is very important here which will help the file in preview.
		documentVersionRecord.Title = parameters.get('filename').substringBeforeLast('.'); // Display name of the files
		documentVersionRecord.VersionData = Blob.valueOf('pdfcontent');
		documentVersionRecord.Document_Type__c = parameters.get('document_type');
		documentVersionRecord.Document_Interval__c = parameters.get('document_interval');
		documentVersionRecord.Document_Date__c = Date.valueOf(parameters.get('document_date'));
		insert documentVersionRecord;

		// grab the document id from the version record that was just created
		Id newDocumentId = [SELECT ContentDocumentId FROM ContentVersion].ContentDocumentId;

		ContentDocumentLink newDocumentLinkRecord = new ContentDocumentLink();
		newDocumentLinkRecord.LinkedEntityId = accountRecord.Id;
		newDocumentLinkRecord.ContentDocumentId = newDocumentId;
		newDocumentLinkRecord.ShareType = 'I';
		newDocumentLinkRecord.Visibility = 'AllUsers';
		insert newDocumentLinkRecord;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		String title = parameters.get('filename').substringBeforeLast('.');
		String documentType = parameters.get('document_type');
		String documentInterval = parameters.get('document_interval');
		Date documentDate = Date.valueOf(parameters.get('document_date'));
		Id recordTypeId = reportRecordType;

		// a match should be found
		ContentDocumentLink linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, title, recordTypeId, documentDate, documentType, documentInterval);
		System.assertNotEquals(null, linkRecord);

		// no match
		linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, title, recordTypeId, documentDate, documentType, '');
		System.assertEquals(null, linkRecord);

		// no match
		linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, title, recordTypeId, documentDate, '', documentInterval);
		System.assertEquals(null, linkRecord);

		// no match
		linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, title, recordTypeId, null, documentType, documentInterval);
		System.assertEquals(null, linkRecord);

		// no match
		linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, title, contractRecordType, documentDate, documentType, documentInterval);
		System.assertEquals(null, linkRecord);

		// no match
		linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, 'another-title', recordTypeId, documentDate, documentType, documentInterval);
		System.assertEquals(null, linkRecord);

		// no match
		linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, title, recordTypeId, documentDate, documentType, 'arbitrary');
		System.assertEquals(null, linkRecord);

		// no match
		linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, title, recordTypeId, documentDate, 'arbitrary', documentInterval);
		System.assertEquals(null, linkRecord);

		// no match
		linkRecord = ResourceDocumentsV1.searchExistingFiles(accountRecord.Id, title, recordTypeId, Date.valueOf('2000-01-01'), documentType, documentInterval);
		System.assertEquals(null, linkRecord);

		Test.stopTest();
	}

	private static Map<String, String> getReportRequestAttributesWithCommunityAssignment() {
		return new Map<String, String>{
				'entity_type' => 'Account',
				'record_type' => 'report',
				'filename' => 'filename.pdf',
				'document_type' => 'DIFOT',
				'document_interval' => 'weekly',
				'document_date' => '2020-08-21',
				'community_access' => 'true'
		};
	}
	private static Map<String, String> getReportRequestAttributesWithNoCommunityAssignment() {
		return new Map<String, String>{
				'entity_type' => 'Account',
				'record_type' => 'report',
				'filename' => 'filename.pdf',
				'document_type' => 'DIFOT',
				'document_interval' => 'weekly',
				'document_date' => '2020-08-21',
				'community_access' => 'false'
		};
	}
	private static Map<String, String> getContractRequestAttributesWithNoCommunityAssignment() {
		return new Map<String, String>{
				'entity_type' => 'Account',
				'record_type' => 'contract',
				'filename' => 'filename.pdf',
				'document_type' => 'Contract',
				'community_access' => 'false'
		};
	}
}