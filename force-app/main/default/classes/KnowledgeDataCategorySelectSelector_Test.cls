@isTest
public with sharing class KnowledgeDataCategorySelectSelector_Test {
	
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

		KnowledgeDataCategorySelectionsSelector selector = KnowledgeDataCategorySelectionsSelector.newInstance(new Set<SObjectField>{});
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Knowledge__DataCategorySelection\\b').matcher(soql).find(), 'Resulting query does select from Knowledge__DataCategorySelection: ' + soql);

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
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Knowledge__DataCategorySelection.DataCategoryGroupName,
			Knowledge__DataCategorySelection.DataCategoryName,
			Knowledge__DataCategorySelection.ParentId
		};

		Set<Id> parentIds = new Set<Id>();

		KnowledgeDataCategorySelectionsSelector selector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{});
		QueryBuilder.ConditionsManager conditions = qb.conditionsManager;
		//Where clause
		conditions.add(new QueryBuilder.SimpleCondition(Knowledge__DataCategorySelection.parentId + ' IN :parentIds'));
		conditions.endConditions();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)ParentId.*?\\bfrom Knowledge__DataCategorySelection\\b').matcher(soql).find(), 'Query returning provided fields' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Knowledge__DataCategorySelection.*?\\bwhere parentId in\\b').matcher(soql).find(), 'Query returning with In condition ' + soql);
		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureRecordsRetrieveWithInsertedData() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Knowledge__kav> pushEDMs = ApplicationTestDataFactoryKnowledge.getPushEDMs(1, false);
		insert pushEDMs;
		Id pushEdmId = [SELECT Id from Knowledge__kav LIMIT 1].Id;
		List<Knowledge__DataCategorySelection> dataCategories = ApplicationTestDataFactoryKnowledge.getDataCatogories(1, false,pushEdmId);
		insert dataCategories;		
		// =====================================
		// Testing
		// =====================================
		
		//Fields to Query
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{
			Knowledge__DataCategorySelection.DataCategoryGroupName,
			Knowledge__DataCategorySelection.DataCategoryName,
			Knowledge__DataCategorySelection.ParentId
		};

		//Passing Knowledge Article Ids
		Map<String, Object> params = new Map<String, Object>{'parentIds' => new Set<Id>{ pushEdmId }};
		KnowledgeDataCategorySelectionsSelector dataCategorySelector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);
		Set<Object> selectorOptions = new Set<Object>();
		//Selector should return the data categories related to the given Articles
		List<Knowledge__DataCategorySelection> dataCategoryLst = dataCategorySelector.search(params);
		System.assertEquals(dataCategoryLst.size(), dataCategories.size(), 'Data categories retrieved based on the given parent Id');	
	}
}