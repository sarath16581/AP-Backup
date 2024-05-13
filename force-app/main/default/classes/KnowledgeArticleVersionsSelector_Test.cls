@isTest
public with sharing class KnowledgeArticleVersionsSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {
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

		KnowledgeArticleVersionsSelector selector = KnowledgeArticleVersionsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Knowledge__Kav\\b').matcher(soql).find(), 'Resulting query does select from Knowledge__kav: ' + soql);

		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {
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
		//Fields to Query
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ Knowledge__kav.Answer__c, Knowledge__kav.Summary, Knowledge__kav.UrlName, Knowledge__kav.id, Knowledge__kav.Title };

		KnowledgeArticleVersionsSelector selector = KnowledgeArticleVersionsSelector.newInstance(fieldOverrides);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ KnowledgeArticleVersionsSelector.Options.WITH_RECORDTYPE });
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Answer__c.*?\\bfrom Knowledge__kav\\b').matcher(soql).find(), 'Query returning Knowledge__kav fields' + soql);

		//testing LIMIT
		selector = KnowledgeArticleVersionsSelector.newInstance(1, fieldOverrides);
		qb = selector.newQueryBuilder(new Set<Object>{ KnowledgeArticleVersionsSelector.Options.WITH_RECORDTYPE });
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Knowledge__kav.*?\\bLIMIT 1').matcher(soql).find(), 'Query returning Knowledge__kav With Limit' + soql);

		Test.stopTest();
	}

	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveWithParams() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(1, false);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';
		insert criticalIncidents;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Set<SObjectField> fields = new Set<SObjectField>{
			Knowledge__kav.Id,
			Knowledge__kav.Message__c,
			Knowledge__kav.NetworkOrgId__c,
			Knowledge__kav.KnowledgeArticleId,
			Knowledge__kav.UrlName,
			Knowledge__kav.Title
		};
		
		Test.startTest();

		KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(fields);
		Map<String, Object> params = new Map<String, Object>{ 'statuses' => new Set<String>{ 'Draft' }, 'languages' => new Set<String>{ 'en_US' }, 'recordTypeNames' => new Set<String>{ 'Critical_Incident' } };
		List<Knowledge__kav> kavLst = (List<Knowledge__kav>) kavSelector.search(params, true);

		System.assertEquals(1, kavLst.size(), 'Expected critical incidents knowledge articles to return');

		Test.stopTest();
	}

	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveWithLimit() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(2, false);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';
		insert criticalIncidents;
		
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Set<SObjectField> fields = new Set<SObjectField>{
			Knowledge__kav.Id,
			Knowledge__kav.Message__c,
			Knowledge__kav.NetworkOrgId__c,
			Knowledge__kav.KnowledgeArticleId,
			Knowledge__kav.UrlName,
			Knowledge__kav.Title
		};
		Test.startTest();

		Schema.SobjectField lastModifiedDate = Knowledge__kav.lastModifiedDate;

		KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(1, fields);

		Map<String, Object> params = new Map<String, Object>{ 'statuses' => new Set<String>{ 'Draft' }, 'languages' => new Set<String>{ 'en_US' }, 'recordTypeNames' => new Set<String>{ 'Critical_Incident' } };
		List<Knowledge__kav> kavLst = (List<Knowledge__kav>) kavSelector.search(params, true, lastModifiedDate, 'Desc');

		System.assertEquals(1, kavLst.size(), 'Expected critical incidents knowledge articles to return');

		Test.stopTest();
	}

	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveWithTypes() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(2, false);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';
		criticalIncidents[0].Type__c = 'Welcome';
		insert criticalIncidents;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Set<SObjectField> fields = new Set<SObjectField>();
		Test.startTest();

		Schema.SobjectField lastModifiedDate = Knowledge__kav.lastModifiedDate;

		KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(1, fields);

		Map<String, Object> params = new Map<String, Object>{ 'statuses' => new Set<String>{ 'Draft' }, 'languages' => new Set<String>{ 'en_US' }, 'recordTypeNames' => new Set<String>{ 'Critical_Incident' } };
		List<Knowledge__kav> kavLst = (List<Knowledge__kav>) kavSelector.search(params, true, lastModifiedDate, 'Desc');

		System.assertEquals(1, kavLst.size(), 'Expected critical incidents knowledge articles to return');

		Test.stopTest();
	}

	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 * Query should return the records based on the provided Ids
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveWithGivenIds() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactoryKnowledge.getCriticalIncidents(2, false);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';
		criticalIncidents[0].Type__c = 'Welcome';
		insert criticalIncidents;
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Set<SObjectField> fields = new Set<SObjectField>();
		Test.startTest();

		KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(1, fields);

		Map<String, Object> params = new Map<String, Object>{ 'knowledgeIds' => new Set<Id>{ criticalIncidents[0].Id } };
		List<Knowledge__kav> kavLst = (List<Knowledge__kav>) kavSelector.search(params, new Set<Object>());

		System.assertEquals(1, kavLst.size(), 'Expected critical incidents knowledge articles to return');

		Test.stopTest();
	}

	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 * Query should return the records based on the provided Search Term
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveForGivenSearchTerm() {
		List<Knowledge__kav> pushEDMs = ApplicationTestDataFactoryKnowledge.getPushEDMs(2, true);
		// =====================================
		// Stubbing
		// =====================================
		KnowledgeArticleVersionsSelector mockSelector = (KnowledgeArticleVersionsSelector) MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.searchArticles((String) fflib_Match.anyObject(), (List<String>) fflib_Match.anyObject())).thenReturn(pushEDMs);
		MockUtility.Mocks.stopStubbing();
		Test.startTest();

		ShareInformationController.ShareInformationControllerWrapper wrapper = new ShareInformationController.ShareInformationControllerWrapper();
		List<Knowledge__kav> searchResults = wrapper.searchArticles('test', new List<String>{ 'Push_EDM' });
		System.assertEquals(2, searchResults.size(), 'Expected push EM knowledge articles to return');

		Test.stopTest();
	}
}