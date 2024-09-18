/**
 * @author Seth Heang
 * @group Tests
 * @tag Case, ImpactedArticle__c
 * @domain Core
 * @description Test class for UnifiedCaseCreationController
 * @changelog
 * 2024-08-29 - Seth Heang - Created
 * 2024-09-06 - Seth Heang - added test methods for case, impactedArticle__c creation and exception handling
 */
@IsTest(IsParallel=true)
public class UnifiedCaseCreationControllerTest {

	/**
	 * Test getCaseRecordTypeInfos() with valid record type names
	 * And verify that the record types return successfully
	 */
	@IsTest
	static void testGetCaseRecordTypeInfosWithValidNames() {
		// =====================================
		// Data Preparation
		// =====================================
		// Test with valid developer names
		List<String> developerNames = new List<String>{
				'UnifiedInvestigation', 'UnifiedGeneralEnquiry'
		};

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<String, Object> result = UnifiedCaseCreationController.getCaseRecordTypeInfos(developerNames);
		Test.stopTest();

		// Verify the results
		Assert.areEqual(2, result.size(), 'Recordtype result count should be 2 but instead got ' + result.size());
		for (String recordTypeId : result.keySet()) {
			Map<String, Object> recordTypeInfo = (Map<String, Object>) result.get(recordTypeId);
			Assert.isTrue(developerNames.contains((String) recordTypeInfo.get('developerName')), 'Expected developerName to exists but was not found');
			Assert.isNotNull(recordTypeInfo.get('recordTypeId'), 'Expected recordTypeId to exists but was not found');
			Assert.isNotNull((recordTypeInfo.get('name')), 'Expected name to exists but was not found');
			Assert.isTrue(recordTypeInfo.containsKey('available'), 'Expected available key to exists but was not found');
			Assert.isTrue(recordTypeInfo.containsKey('defaultRecordTypeMapping'), 'Expected defaultRecordTypeMapping key to exists but was not found');
			Assert.isTrue(recordTypeInfo.containsKey('master'), 'Expected master key to exists but was not found');
		}
	}

	/**
	 * Test getCaseRecordTypeInfos() with invalid record type names
	 * And verify that the record types return blank result
	 */
	@IsTest
	static void testGetCaseRecordTypeInfosWithInvalidNames() {
		// =====================================
		// Data Preparation
		// =====================================
		// Test with invalid developer names
		List<String> developerNames = new List<String>{
				'Business_Account', 'Consumer', 'InvalidName'
		};

		// =====================================
		// Testing
		// =====================================
		Map<String, Object> resultWithInvalidNames = UnifiedCaseCreationController.getCaseRecordTypeInfos(developerNames);

		// Verify the results should be empty
		Assert.areEqual(0, resultWithInvalidNames.size());
	}

	/**
	 * Test getCaseRecordTypeInfos() with invalid input
	 * And verify that exception is thrown with pre-defined generic message
	 */
	@IsTest
	static void testGetCaseRecordTypeInfosExceptionHandling() {
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try {
			UnifiedCaseCreationController.getCaseRecordTypeInfos(null);
		} catch (AuraHandledException ex) {
			Assert.areEqual(UnifiedCaseCreationController.GENERIC_ERROR_MESSAGE, ex.getMessage(), 'Expected error message to match but instead got: ' + ex.getMessage());
		}

		try {
			UnifiedCaseCreationController.getCaseRecordTypeInfos(new List<String>());
		} catch (AuraHandledException ex) {
			Assert.areEqual(UnifiedCaseCreationController.GENERIC_ERROR_MESSAGE, ex.getMessage(), 'Expected error message to match but instead got: ' + ex.getMessage());
		}
		Test.stopTest();
	}

	/**
	 * Test buildGeneralEnquiryCaseAttributes() for populating UnifiedInvestigation Case attributes
	 * And verify all the attributes mapping is correct
	 */
	@IsTest
	static void testBuildUnifiedGeneralEnquiryCaseDataMapping() {
		// =====================================
		// Data Preparation
		// =====================================
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		UnifiedCaseCreationController.CaseCreationRequest caseRequest = new UnifiedCaseCreationController.CaseCreationRequest();
		caseRequest.consignmentId = ApplicationTestDataFactory.getArticles(1, true)[0].Id;
		caseRequest.recordTypeId = ApplicationTestDataFactoryCase.caseUnifiedGeneralEnquiryRecordType;
		caseRequest.contactId = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0].Id;
		caseRequest.enquiryType = UnifiedCaseCreationController.GENERAL_ENQUIRY_TYPE;
		caseRequest.enquirySubType = 'Tracking';
		caseRequest.productCategory = 'Domestic';
		caseRequest.productSubCategory = 'StarTrack Express';
		caseRequest.notes = 'This is a case note';
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Case result = UnifiedCaseCreationController.buildGeneralEnquiryCaseAttributes(caseRequest);
		Test.stopTest();

		Assert.areEqual(caseRequest.consignmentId, result.ArticleTest__c, 'ArticleTest__c should match but instead got: ' + result.ArticleTest__c);
		Assert.areEqual(caseRequest.recordTypeId, result.RecordTypeId, 'RecordTypeId should match but instead got: ' + result.RecordTypeId);
		Assert.areEqual(caseRequest.contactId, result.ContactId, 'ContactId should match but instead got: ' + result.ContactId);
		Assert.areEqual(caseRequest.enquiryType, result.Type, 'Type should match but instead got: ' + result.Type);
		Assert.areEqual(caseRequest.enquirySubType, result.EnquirySubType__c, 'EnquirySubType__c should match but instead got: ' + result.EnquirySubType__c);
		Assert.areEqual(caseRequest.productCategory, result.ProductCategory__c, 'ProductCategory__c should match but instead got: ' + result.ProductCategory__c);
		Assert.areEqual(caseRequest.productSubCategory, result.ProductSubCategory__c, 'ProductSubCategory__c should match but instead got: ' + result.ProductSubCategory__c);
		Assert.areEqual(caseRequest.notes, result.Description, 'Description should match but instead got: ' + result.Description);
		Assert.areEqual(UserInfo.getUserId(), result.OwnerId, 'OwnerId should match but instead got: ' + result.OwnerId);
		Assert.areEqual(UnifiedConstants.CASE_PRIORITY_NORMAL, result.Priority, 'Priority should match but instead got: ' + result.Priority);
		Assert.areEqual(UnifiedConstants.CASE_STATUS_CLOSED, result.Status, 'Status should match but instead got: ' + result.Status);
		Assert.areEqual(UnifiedCaseCreationController.UNCLEAR_EDD_ROOT_CAUSE, result.Root_cause__c, 'Root_cause__c should match but instead got: ' + result.Root_cause__c);
		Assert.areEqual(UnifiedCaseCreationController.CLOSED_TRACKING_ONLY_RESOLUTION_CODE, result.ResolutionCode__c, 'ResolutionCode__c should match but instead got: ' + result.ResolutionCode__c);
		Assert.areEqual(UnifiedConstants.CASE_CONTYPE_RECEIVER, result.Recent_Caller_Type__c, 'Recent_Caller_Type__c should match but instead got: ' + result.Recent_Caller_Type__c);
	}

	/**
	 * Test buildInvestigationCaseAttributes() for populating UnifiedInvestigation Case attributes
	 * And verify all the attributes mapping is correct
	 */
	@IsTest
	static void testBuildUnifiedInvestigationCaseDataMapping() {
		// =====================================
		// Data Preparation
		// =====================================
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		UnifiedCaseCreationController.CaseCreationRequest caseRequest = new UnifiedCaseCreationController.CaseCreationRequest();
		caseRequest.consignmentId = ApplicationTestDataFactory.getArticles(1, true)[0].Id;
		caseRequest.recordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		caseRequest.contactId = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0].Id;
		caseRequest.enquiryType = UnifiedCaseCreationController.INVESTIGATION_ENQUIRY_TYPE;
		caseRequest.enquirySubType = 'Late item';
		caseRequest.productCategory = 'Domestic';
		caseRequest.productSubCategory = 'StarTrack Express';
		caseRequest.notes = 'This is a case note';
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Case result = UnifiedCaseCreationController.buildInvestigationCaseAttributes(caseRequest);
		Test.stopTest();

		Assert.areEqual(caseRequest.consignmentId, result.ArticleTest__c, 'ArticleTest__c should match but instead got: ' + result.ArticleTest__c);
		Assert.areEqual(caseRequest.recordTypeId, result.RecordTypeId, 'RecordTypeId should match but instead got: ' + result.RecordTypeId);
		Assert.areEqual(caseRequest.contactId, result.ContactId, 'ContactId should match but instead got: ' + result.ContactId);
		Assert.areEqual(caseRequest.enquiryType, result.Type, 'Type should match but instead got: ' + result.Type);
		Assert.areEqual(caseRequest.enquirySubType, result.EnquirySubType__c, 'EnquirySubType__c should match but instead got: ' + result.EnquirySubType__c);
		Assert.areEqual(caseRequest.productCategory, result.ProductCategory__c, 'ProductCategory__c should match but instead got: ' + result.ProductCategory__c);
		Assert.areEqual(caseRequest.productSubCategory, result.ProductSubCategory__c, 'ProductSubCategory__c should match but instead got: ' + result.ProductSubCategory__c);
		Assert.areEqual(caseRequest.notes, result.Description, 'Description should match but instead got: ' + result.Description);
		Assert.areEqual(UserInfo.getUserId(), result.OwnerId, 'OwnerId should match but instead got: ' + result.OwnerId);
		Assert.areEqual(UnifiedConstants.CASE_PRIORITY_NORMAL, result.Priority, 'Priority should match but instead got: ' + result.Priority);
		Assert.areEqual(UnifiedConstants.CASE_STATUS_NEW, result.Status, 'Status should match but instead got: ' + result.Status);
		Assert.areEqual(UnifiedConstants.CASE_CONTYPE_RECEIVER, result.Recent_Caller_Type__c, 'Recent_Caller_Type__c should match but instead got: ' + result.Recent_Caller_Type__c);
	}

	/**
	 * Test create 'UnifiedGeneralEnquiry' case and subsequent ImpactedArticle__c successfully
	 * And verify all the attributes mapping for the case and ImpactedArticle__c are correct
	 */
	@IsTest
	static void testCreateNewUnifiedGeneralEnquiryCaseAndNewImpactedArticle() {
		// =====================================
		// Data Preparation
		// =====================================
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getArticles(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
		List<String> articleIds = new List<String>{
				articles[0].ArticleID__c, articles[1].ArticleID__c
		};

		UnifiedCaseCreationController.CaseCreationRequest caseRequest = new UnifiedCaseCreationController.CaseCreationRequest();
		caseRequest.consignmentId = ApplicationTestDataFactory.getArticles(1, true)[0].Id;
		caseRequest.recordTypeId = ApplicationTestDataFactoryCase.caseUnifiedGeneralEnquiryRecordType;
		caseRequest.contactId = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0].Id;
		caseRequest.enquiryType = UnifiedCaseCreationController.GENERAL_ENQUIRY_TYPE;
		caseRequest.enquirySubType = 'Tracking';
		caseRequest.productCategory = 'Domestic';
		caseRequest.productSubCategory = 'StarTrack Express';
		caseRequest.notes = 'This is a case note';
		caseRequest.impactedArticles = articleIds;
		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(
				ArticlesSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByConsignmentIdAndChildArticles(
						(Set<Id>) fflib_Match.anyObject(),
						(Set<String>) fflib_Match.anyObject()
				)
		).thenReturn(articles);
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Id caseId = UnifiedCaseCreationController.createNewCase(caseRequest);
		Test.stopTest();

		Assert.isNotNull(caseId, 'Case Id should not be null');
		fflib_ArgumentCaptor insertableSObjectCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) insertableSObjectCaptor.capture());
		List<SObject> insertableSObjects = new List<SObject>();
		for (Object objList : (List<Object>) insertableSObjectCaptor.getAllValues()) {
			insertableSObjects.addAll((List<SObject>) objList);
		}
		Case resultCase;
		List<ImpactedArticle__c> resultImpactedArticles = new List<ImpactedArticle__c>();
		for (SObject obj : insertableSObjects) {
			if (obj instanceof Case) {
				resultCase = (Case) obj;
			} else if (obj instanceof ImpactedArticle__c) {
				resultImpactedArticles.add((ImpactedArticle__c) obj);
			}
		}

		Assert.isNotNull(resultCase, 'Case should not be null');
		Assert.isFalse(resultImpactedArticles.isEmpty(), 'ImpactedArticles should not be empty');
		Assert.areEqual(caseId, resultCase.Id, 'Case Id should match but instead got: ' + resultCase.Id);
		Assert.areEqual(caseRequest.recordTypeId, resultCase.RecordTypeId, 'RecordTypeId should match but instead got: ' + resultCase.Id);
		Assert.areEqual(articleIds[0], resultImpactedArticles[0].Name, 'Name should match but instead got: ' + resultImpactedArticles[0].ArticleId__c);
		Assert.areEqual(resultCase.Id, resultImpactedArticles[0].Case__c, 'Case__c should match but instead got: ' + resultImpactedArticles[0].Case__c);
		Assert.areEqual(articles[0].Id, resultImpactedArticles[0].Article__c, 'Article__c should match but instead got: ' + resultImpactedArticles[0].Article__c);
		Assert.areEqual(articleIds[1], resultImpactedArticles[1].Name, 'Name should match but instead got: ' + resultImpactedArticles[1].ArticleId__c);
		Assert.areEqual(resultCase.Id, resultImpactedArticles[1].Case__c, 'Case__c should match but instead got: ' + resultImpactedArticles[1].Case__c);
		Assert.areEqual(articles[1].Id, resultImpactedArticles[1].Article__c, 'Article__c should match but instead got: ' + resultImpactedArticles[1].Article__c);
	}

	/**
	 * Test create 'UnifiedInvestigation' case and subsequent ImpactedArticle__c successfully
	 * And verify all the attributes mapping for the case and ImpactedArticle__c are correct
	 */
	@IsTest
	static void testCreateNewUnifiedInvestigationCaseAndNewImpactedArticle() {
		// =====================================
		// Data Preparation
		// =====================================
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getArticles(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
		List<String> articleIds = new List<String>{
				articles[0].ArticleID__c, articles[1].ArticleID__c
		};

		UnifiedCaseCreationController.CaseCreationRequest caseRequest = new UnifiedCaseCreationController.CaseCreationRequest();
		caseRequest.consignmentId = ApplicationTestDataFactory.getArticles(1, true)[0].Id;
		caseRequest.recordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		caseRequest.contactId = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0].Id;
		caseRequest.enquiryType = UnifiedCaseCreationController.INVESTIGATION_ENQUIRY_TYPE;
		caseRequest.enquirySubType = 'Late item';
		caseRequest.productCategory = 'Domestic';
		caseRequest.productSubCategory = 'StarTrack Express';
		caseRequest.notes = 'This is a case note';
		caseRequest.impactedArticles = articleIds;
		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(
				ArticlesSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByConsignmentIdAndChildArticles(
						(Set<Id>) fflib_Match.anyObject(),
						(Set<String>) fflib_Match.anyObject()
				)
		).thenReturn(articles);
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Id caseId = UnifiedCaseCreationController.createNewCase(caseRequest);
		Test.stopTest();

		Assert.isNotNull(caseId, 'Case Id should not be null');
		fflib_ArgumentCaptor insertableSObjectCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>) insertableSObjectCaptor.capture());
		List<SObject> insertableSObjects = new List<SObject>();
		for (Object objList : (List<Object>) insertableSObjectCaptor.getAllValues()) {
			insertableSObjects.addAll((List<SObject>) objList);
		}
		Case resultCase;
		List<ImpactedArticle__c> resultImpactedArticles = new List<ImpactedArticle__c>();
		for (SObject obj : insertableSObjects) {
			if (obj instanceof Case) {
				resultCase = (Case) obj;
			} else if (obj instanceof ImpactedArticle__c) {
				resultImpactedArticles.add((ImpactedArticle__c) obj);
			}
		}

		Assert.isNotNull(resultCase, 'Case should not be null');
		Assert.isFalse(resultImpactedArticles.isEmpty(), 'ImpactedArticles should not be empty');
		Assert.areEqual(caseId, resultCase.Id, 'Case Id should match but instead got: ' + resultCase.Id);
		Assert.areEqual(caseRequest.recordTypeId, resultCase.RecordTypeId, 'RecordTypeId should match but instead got: ' + resultCase.Id);
		Assert.areEqual(articleIds[0], resultImpactedArticles[0].Name, 'Name should match but instead got: ' + resultImpactedArticles[0].ArticleId__c);
		Assert.areEqual(resultCase.Id, resultImpactedArticles[0].Case__c, 'Case__c should match but instead got: ' + resultImpactedArticles[0].Case__c);
		Assert.areEqual(articles[0].Id, resultImpactedArticles[0].Article__c, 'Article__c should match but instead got: ' + resultImpactedArticles[0].Article__c);
		Assert.areEqual(articleIds[1], resultImpactedArticles[1].Name, 'Name should match but instead got: ' + resultImpactedArticles[1].ArticleId__c);
		Assert.areEqual(resultCase.Id, resultImpactedArticles[1].Case__c, 'Case__c should match but instead got: ' + resultImpactedArticles[1].Case__c);
		Assert.areEqual(articles[1].Id, resultImpactedArticles[1].Article__c, 'Article__c should match but instead got: ' + resultImpactedArticles[1].Article__c);
	}

	/**
	 * Test create a case with failure due to article count mismatch between the linked articles (which may contain duplicate)
	 * against child articles under a unique consignment in the system
	 * And verify that appropriate error message is returned
	 */
	@IsTest
	static void testCaseCreationWithFailureDueToMissingArticle() {
		// =====================================
		// Data Preparation
		// =====================================
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getArticles(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
		List<String> articleIds = new List<String>{
				articles[0].ArticleID__c, articles[1].ArticleID__c
		};

		UnifiedCaseCreationController.CaseCreationRequest caseRequest = new UnifiedCaseCreationController.CaseCreationRequest();
		caseRequest.consignmentId = ApplicationTestDataFactory.getArticles(1, true)[0].Id;
		caseRequest.recordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		caseRequest.contactId = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0].Id;
		caseRequest.enquiryType = UnifiedCaseCreationController.INVESTIGATION_ENQUIRY_TYPE;
		caseRequest.enquirySubType = 'Late item';
		caseRequest.productCategory = 'Domestic';
		caseRequest.productSubCategory = 'StarTrack Express';
		caseRequest.notes = 'This is a case note';
		caseRequest.impactedArticles = articleIds;
		// =====================================
		// Stubbing
		// =====================================
		ArticlesSelector mockArticlesSelector = (ArticlesSelector) MockUtility.mockSelector(
				ArticlesSelector.class
		);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockArticlesSelector.selectByConsignmentIdAndChildArticles(
						(Set<Id>) fflib_Match.anyObject(),
						(Set<String>) fflib_Match.anyObject()
				)
		).thenReturn(new List<Article__c>{
				articles[0]
		}); // mock selector to only return one of two articles
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		try {
			Test.startTest();
			UnifiedCaseCreationController.createNewCase(caseRequest);
			Test.stopTest();
			Assert.fail('Expecting an exception here but there was no exception');
		} catch (AuraHandledException ex) {
			Assert.areEqual(UnifiedCaseCreationController.GENERIC_ERROR_MESSAGE, ex.getMessage(), 'Expect error message to match but instead got: ' + ex.getMessage());
		}
	}

	/**
	 * Test create a case with failure due to unexpected error
	 * And verify that appropriate error message is returned
	 */
	@IsTest
	static void testCaseCreationWithFailureDueToUnexpectedError() {
		// =====================================
		// Data Preparation
		// =====================================
		Account testAccount = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Article__c consignment = ApplicationTestDataFactory.getArticles(1, true)[0];
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, true);
		List<String> articleIds = new List<String>{
				articles[0].ArticleID__c, articles[1].ArticleID__c
		};

		UnifiedCaseCreationController.CaseCreationRequest caseRequest = new UnifiedCaseCreationController.CaseCreationRequest();
		caseRequest.consignmentId = ApplicationTestDataFactory.getArticles(1, true)[0].Id;
		caseRequest.recordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		caseRequest.contactId = ApplicationTestDataFactory.getContacts(1, testAccount.Id, true)[0].Id;
		caseRequest.enquiryType = UnifiedCaseCreationController.INVESTIGATION_ENQUIRY_TYPE;
		caseRequest.enquirySubType = 'Late item';
		caseRequest.productCategory = 'Domestic';
		caseRequest.productSubCategory = 'StarTrack Express';
		caseRequest.notes = 'This is a case note';
		caseRequest.impactedArticles = articleIds;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		try {
			Test.startTest();
			UnifiedCaseCreationController.createNewCase(null);
			Test.stopTest();
			Assert.fail('Expecting an exception here but there was no exception');
		} catch (AuraHandledException ex) {
			Assert.areEqual(UnifiedCaseCreationController.GENERIC_ERROR_MESSAGE, ex.getMessage(), 'Expect error message to match but instead got: ' + ex.getMessage());
		}
	}
}