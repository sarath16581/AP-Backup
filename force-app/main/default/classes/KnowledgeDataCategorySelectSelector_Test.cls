@isTest
public with sharing class KnowledgeDataCategorySelectSelector_Test {

		
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveWithParents() {
	// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> pushEDMs = ApplicationTestDataFactory.getPushEDMs(1, false);
		insert pushEDMs;
		Id pushEdmId = [SELECT Id from Knowledge__kav LIMIT 1].Id;
		List<Knowledge__DataCategorySelection> dataCates = ApplicationTestDataFactory.getDataCatogories(1, false,pushEdmId);
		insert dataCates;
		
		// =====================================
		// Testing
		// =====================================
		
		//Fields to Query
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Knowledge__DataCategorySelection.DataCategoryName,
			Knowledge__DataCategorySelection.ParentId
		};

		Map<String, Object> params = new Map<String, Object>{'parentIds' => new Set<Id>{pushEdmId}};
		KnowledgeDataCategorySelectionSelector datCatSelector = KnowledgeDataCategorySelectionSelector.newInstance(fieldOverrides);
		Set<Object> selectorOptions = new Set<Object>();
		selectorOptions.add(KnowledgeDataCategorySelectionSelector.Options.WITH_PARENT);
		List<Knowledge__DataCategorySelection> dataCatesLst = datCatSelector.search(params, selectorOptions, true);
		System.assertEquals(dataCatesLst.size(), dataCates.size() , 'Data categories retrieved based on parent Id');
	}
	
	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveWithParentFields() {
	// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> pushEDMs = ApplicationTestDataFactory.getPushEDMs(1, false);
		insert pushEDMs;
		Id pushEdmId = [SELECT Id from Knowledge__kav LIMIT 1].Id;
		List<Knowledge__DataCategorySelection> dataCates = ApplicationTestDataFactory.getDataCatogories(1, false,pushEdmId);
		insert dataCates;
		// =====================================
		// Testing
		// =====================================
		//Fields to Query
		Map<SobjectType, Set<SObjectField>> fieldOverrides = new Map<SobjectType, Set<SObjectField>>();
		fieldOverrides.put(Knowledge__DataCategorySelection.SObjectType, new Set<SObjectField>{
			Knowledge__DataCategorySelection.DataCategoryGroupName,
			Knowledge__DataCategorySelection.DataCategoryName,
			Knowledge__DataCategorySelection.ParentId
		} );
		fieldOverrides.put(Knowledge__kav.SobjectType, new Set<SObjectField>{
			Knowledge__kav.Answer__c,
			Knowledge__kav.Summary,
			Knowledge__kav.UrlName,
			Knowledge__kav.id,
			Knowledge__kav.Title
		});

		Set<String> allowedArticles = new Set<String>{'PUSH_EDM','FAQ'};
		Map<String, Object> params = new Map<String, Object>{'recordTypeNames' => allowedArticles};
		KnowledgeDataCategorySelectionSelector datCatSelector = KnowledgeDataCategorySelectionSelector.newInstance(fieldOverrides);
		//Set<Object> selectorOptions = new Set<Object>();
		//selectorOptions.add(KnowledgeDataCategorySelectionSelector.Options.WITH_PARENT);
		List<Knowledge__DataCategorySelection> dataCatesLst = datCatSelector.search(params, true);
		System.assertEquals(dataCatesLst.size(), dataCates.size() , 'Data categories retrieved based on the recordtype names');
	}
}