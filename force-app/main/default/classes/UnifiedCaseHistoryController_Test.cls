/**
 * @description Unit tests for the `UnifiedCaseHistoryController` class.
 * 
 * @changelog
 * 2024-09-11 - Marcel HK - Created
 * 2024-09-12 - Seth Heang - added test method getDuplicateCasesRelatedToArticleTestPositive()
 */
@IsTest
public with sharing class UnifiedCaseHistoryController_Test {

	//
	// Test Setup and Utility Methods
	//

	// Case Record Types
	static final String CLASSIC_GENERAL_ENQUIRY_CASE_RT = UnifiedCaseHistoryController.CLASSIC_GENERAL_ENQUIRY_CASE_RT;
	static final String UNIFIED_GENERAL_ENQUIRY_CASE_RT = UnifiedCaseHistoryController.UNIFIED_GENERAL_ENQUIRY_CASE_RT;
	static final String UNIFIED_INVESTIGATION_CASE_RT = UnifiedCaseHistoryController.UNIFIED_INVESTIGATION_CASE_RT;
	static final String CLASSIC_SSSW_DELIVERY_CASE_RT = SSSWConstants.CASE_RT_SSSW_DELIVERY;

	// Case Types
	static final String GENERAL_ENQUIRY_TYPE = UnifiedCaseHistoryController.GENERAL_ENQUIRY_TYPE;
	static final String INVESTIGATION_TYPE = UnifiedCaseHistoryController.INVESTIGATION_TYPE;

	static Article__c createArticle(String trackingNumber, Boolean isConsignment) {
		Article__c article = new Article__c(
				Id = fflib_IDGenerator.generate(Article__c.getSObjectType()),
				ArticleID__c = isConsignment ? trackingNumber : null,
				ConsignmentTrackingNumber__c = isConsignment ? null : trackingNumber
		);
		return article;
	}

	static Case createCase(String recordTypeDeveloperName, String caseNumber, String status, Boolean isClosed) {
		Case c = ApplicationTestDataFactoryCase.getCases(1, true).get(0);
		c.ArticleTest__c = null;
		c.ContactId = fflib_IDGenerator.generate(Contact.getSObjectType());
		c.RecordType = new RecordType(DeveloperName = recordTypeDeveloperName);
		c.ReferenceID__c = null;
		c.Status = status;
		c.Subject = 'Testing Case';
		if(recordTypeDeveloperName == UNIFIED_GENERAL_ENQUIRY_CASE_RT){
			c.Type = GENERAL_ENQUIRY_TYPE;
		}else if(recordTypeDeveloperName == UNIFIED_INVESTIGATION_CASE_RT) {
			c.Type = INVESTIGATION_TYPE;
		}else if(recordTypeDeveloperName == CLASSIC_GENERAL_ENQUIRY_CASE_RT) {
			c.Type = GENERAL_ENQUIRY_TYPE;
		}else if(recordTypeDeveloperName == CLASSIC_SSSW_DELIVERY_CASE_RT){
			c.Type = INVESTIGATION_TYPE;
		}
		// Set the non-writable fields
		c = (Case) ApplicationTestDataFactory.setUnwritableFields(
				c,
				new Map<String, Object>{ 'CaseNumber' => caseNumber, 'IsClosed' => isClosed, 'LastModifiedDate' => DateTime.now() }
		);
		return c;
	}

	static Map<Id, Case> createCases() {
		List<Case> cases = new List<Case>();
		// Linkable (Unified General Enquiry - Closed)
		cases.add(createCase(UNIFIED_GENERAL_ENQUIRY_CASE_RT, '987654', 'Closed', true));
		cases.get(0).ReferenceID__c = 'ABC123XYZ';
		// Linkable (Unified Investigation Case - Open)
		cases.add(createCase(UNIFIED_INVESTIGATION_CASE_RT, '123456', 'New', false));

		// Not Linkable Case (Classic General Enquiry - Open)
		cases.add(createCase(CLASSIC_GENERAL_ENQUIRY_CASE_RT, '159753', 'New', false));

		// Not Linkable Case (Classic SSSW Delivery Case with Investigation Type - Open)
		cases.add(createCase(CLASSIC_SSSW_DELIVERY_CASE_RT, '159759', 'New', false));
		return new Map<Id, Case>(cases);
	}

	static void assertCaseHistoryResultMatches(UnifiedCaseHistoryController.CaseHistoryResult res, Case c) {
		Boolean isLinkable;
		switch on c.CaseNumber {
			when '987654' {
				isLinkable = true;
			}
			when '123456' {
				isLinkable = true;
			}
			when '159753' {
				isLinkable = false;
			}
			when '159759' {
				isLinkable = false;
			}
		}

		Boolean isUnifiedCase = CommonUtils.isUnifiedCase(c.RecordType.DeveloperName);
		Assert.areEqual(c.Id, res.caseId, 'caseId should match original Case');
		Assert.areEqual(c.CaseNumber, res.caseNumber, 'caseNumber should match original Case');
		Assert.areEqual(c.ContactId, res.contactId, 'contactId should match original Case');
		Assert.areEqual(c.IsClosed, res.isClosed, 'isClosed should match original Case');
		Assert.areEqual(isLinkable, res.isLinkable, 'isLinkable should be ' + isLinkable + ' for CaseNumber ' + c.CaseNumber + JSON.serialize(res));
		Assert.areEqual(isUnifiedCase, res.isUnifiedCase, 'isUnifiedCase should match');
		Assert.areEqual(c.LastModifiedDate, res.lastModifiedDate, 'LastModifiedDate should match original Case');
		Assert.areEqual(c.RecordType.DeveloperName, res.recordTypeDeveloperName, 'recordTypeDeveloperName should match original Case');
		Assert.areEqual(c.ReferenceID__c, res.referenceId, 'referenceId should match original Case');
		Assert.areEqual(c.Status, res.status, 'status should match original Case');
		Assert.areEqual(c.Subject, res.subject, 'subject should match original Case');
		Assert.areEqual(c.Type, res.type, 'type should match original Case');
	}

	static void stubArticlesSelectorSelectById(Map<Id, Article__c> articlesMap) {
		ArticlesSelector selector;
		selector = (ArticlesSelector) MockUtility.mockSelector(ArticlesSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(selector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(articlesMap);
		MockUtility.Mocks.stopStubbing();
	}

	static void stubCasesSelectorSelectByConsignmentTrackingNumberCaseHistory(Map<Id, Case> casesMap) {
		CasesSelector selector;
		selector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(selector.selectByConsignmentTrackingNumberCaseHistory((Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
				.thenReturn(casesMap);
		MockUtility.Mocks.stopStubbing();
	}

	static void stubCasesSelectorSelectByContactIdCaseHistory(Map<Id, Case> casesMap) {
		CasesSelector selector;
		selector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(selector.selectByContactIdCaseHistory((Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(casesMap);
		MockUtility.Mocks.stopStubbing();
	}

	//
	// Unit Tests
	//

	@IsTest
	static void getCasesRelatedToArticleTestPositive() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = createArticle('ABC123XYZ', true);
		Map<Id, Case> casesMap = createCases();
		Integer maxRecords = 10;

		// =====================================
		// Stubbing
		// =====================================
		stubArticlesSelectorSelectById(new Map<Id, Article__c> { article.Id => article });
		stubCasesSelectorSelectByConsignmentTrackingNumberCaseHistory(casesMap);

		UnifiedCaseHistoryController.CaseHistoryResponse res;
		res = UnifiedCaseHistoryController.getCasesRelatedToArticle(article.Id, maxRecords);

		Assert.areEqual(4, res.results.size(),'Should have 4 results');
	}

	@IsTest
	static void getDuplicateCasesRelatedToArticleTestPositive() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = createArticle('ABC123XYZ', true);
		Map<Id, Case> casesMap = createCases();

		// =====================================
		// Stubbing
		// =====================================
		stubCasesSelectorSelectByConsignmentTrackingNumberCaseHistory(casesMap);

		Integer dupCaseCount = UnifiedCaseHistoryController.getCountForDuplicatedCasesRelatedToArticle(article.ArticleID__c);

		Assert.areEqual(3, dupCaseCount,'Should have 3 results');
	}

	@IsTest
	static void getCasesRelatedToContactTestPositive() {
		// =====================================
		// Data Preparation
		// =====================================
		Id contactId = fflib_IDGenerator.generate(Contact.getSObjectType());
		Map<Id, Case> casesMap = createCases();
		for (Case c : casesMap.values()) {
			c.ContactId = contactId;
		}
		Integer maxRecords = 10;

		// =====================================
		// Stubbing
		// =====================================
		stubCasesSelectorSelectByContactIdCaseHistory(casesMap);

		UnifiedCaseHistoryController.CaseHistoryResponse res;
		res = UnifiedCaseHistoryController.getCasesRelatedToContact(contactId, maxRecords);

		Assert.areEqual(4, res.results.size(),'Should have 4 results');
	}

	@IsTest
	static void getConsignmentTrackingNumberTestFromConsignment() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = createArticle('ABC123XYZ', true);

		// =====================================
		// Stubbing
		// =====================================
		stubArticlesSelectorSelectById(new Map<Id, Article__c> { article.Id => article });

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		String consignmentTrackingNumber;
		consignmentTrackingNumber = UnifiedCaseHistoryController.getConsignmentTrackingNumber(article.Id);
		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		Assert.areEqual('ABC123XYZ', consignmentTrackingNumber, 'Consignment Tracking Number should be returned');
	}
	@IsTest
	static void getConsignmentTrackingNumberTestFromArticle() {
		// =====================================
		// Data Preparation
		// =====================================
		Article__c article = createArticle('ABC123XYZ', false);

		// =====================================
		// Stubbing
		// =====================================
		stubArticlesSelectorSelectById(new Map<Id, Article__c> { article.Id => article });

		// =====================================
		// Testing
		// =====================================

		Test.startTest();
		String consignmentTrackingNumber;
		consignmentTrackingNumber = UnifiedCaseHistoryController.getConsignmentTrackingNumber(article.Id);
		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		Assert.areEqual('ABC123XYZ', consignmentTrackingNumber, 'Consignment Tracking Number should be returned');
	}

	@IsTest
	static void processResultsTest() {
		// =====================================
		// Data Preparation
		// =====================================
		Map<Id, Case> casesMap = createCases();
		Integer maxRecords = 10;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		UnifiedCaseHistoryController.CaseHistoryResponse res;
		res = UnifiedCaseHistoryController.processResults(casesMap.values(), maxRecords, true);
		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		Assert.isFalse(res.hasMore, 'hasMore should be false');
		Assert.areEqual(4, res.results.size(),'Should have 4 results');
		for(UnifiedCaseHistoryController.CaseHistoryResult result : res.results) {
			assertCaseHistoryResultMatches(result, casesMap.get(result.caseId));
		}
	}

	@IsTest
	static void processResultsTestWithHasMore() {
		// =====================================
		// Data Preparation
		// =====================================
		Map<Id, Case> casesMap = createCases();
		Integer maxRecords = 2;

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		UnifiedCaseHistoryController.CaseHistoryResponse res;
		res = UnifiedCaseHistoryController.processResults(casesMap.values(), maxRecords, false);
		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		Assert.isTrue(res.hasMore, 'hasMore should be true');
		Assert.areEqual(2, res.results.size(), 'Should have 2 results');
	}
}