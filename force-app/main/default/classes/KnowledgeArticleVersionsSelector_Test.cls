@isTest
public with sharing class KnowledgeArticleVersionsSelector_Test {
	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveWithParams() {
		
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactory.getCriticalIncidents(1, false);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';
		insert criticalIncidents;
		
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
		Map<String, Object> params = new Map<String, Object>{'statuses' => new Set<String>{'Draft'}, 'languages' => new Set<String>{'en_US'}, 'recordTypeNames' => new Set<String>{'Critical_Incident'}};

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
		
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactory.getCriticalIncidents(2, false);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';
		insert criticalIncidents;
		
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
		
		Map<String, Object> params = new Map<String, Object>{'statuses' => new Set<String>{'Draft'}, 'languages' => new Set<String>{'en_US'}, 'recordTypeNames' => new Set<String>{'Critical_Incident'}};						
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
		
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactory.getCriticalIncidents(2, false);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';
		criticalIncidents[0].Type__c = 	'Welcome';
		insert criticalIncidents;
		
		Set<SObjectField> fields = new Set<SObjectField>();
		Test.startTest();
		
		Schema.SobjectField lastModifiedDate = Knowledge__kav.lastModifiedDate;
		
		KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(1, fields);
				
		Map<String, Object> params = new Map<String, Object>{'statuses' => new Set<String>{'Draft'}, 'languages' => new Set<String>{'en_US'}, 'recordTypeNames' => new Set<String>{'Critical_Incident'}};										
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
		
		List<Knowledge__kav> criticalIncidents = ApplicationTestDataFactory.getCriticalIncidents(2, false);
		criticalIncidents[0].NetworkOrgId__c = '1234;4321';
		criticalIncidents[0].Type__c = 	'Welcome';
		insert criticalIncidents;
		
		Set<SObjectField> fields = new Set<SObjectField>();
		Test.startTest();
		
		KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(1, fields);
				
		Map<String, Object> params = new Map<String, Object>{'knowledgeIds' => new Set<Id>{criticalIncidents[0].Id}};										
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
		
		List<Knowledge__kav> pushEDMs = ApplicationTestDataFactory.getPushEDMs(2, true);
		// =====================================
		// Stubbing
		// =====================================

		KnowledgeArticleVersionsSelector mockSelector = (KnowledgeArticleVersionsSelector)MockUtility.mockSelector(KnowledgeArticleVersionsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.searchArticles((String)fflib_Match.anyObject(), (List<String>)fflib_Match.anyObject())).thenReturn(pushEDMs);
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
		
		ShareInformationController.ShareInformationControllerWrapper wrapper = new ShareInformationController.ShareInformationControllerWrapper();

		List<Knowledge__kav> searchResults = wrapper.searchArticles('test', new List<String>{'Push_EDM'});
		System.assertEquals(2, searchResults.size(), 'Expected push EM knowledge articles to return');
		
		Test.stopTest();
	}

}