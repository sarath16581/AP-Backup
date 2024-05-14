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

		KnowledgeDataCategorySelectionsSelector selector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{KnowledgeDataCategorySelectionsSelector.Options.WITH_PARENT});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Parent\\.Answer__c.*?\\bfrom Knowledge__DataCategorySelection\\b').matcher(soql).find(), 'Query returning parent fields' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Parent\\.RecordType..*?\\bfrom Knowledge__DataCategorySelection\\b').matcher(soql).find(), 'Query returning parent recordtype' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Parent\\.RecordType\\.DeveloperName.*?\\bfrom Knowledge__DataCategorySelection\\b').matcher(soql).find(), 'Query returning parent recordtype developer name' + soql);
		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the qurey returned the expected data categories
	 */
	@IsTest
	private static void testEnsureQueryReturnDataCategoriesRecords() {

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

		KnowledgeDataCategorySelectionsSelector selector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{KnowledgeDataCategorySelectionsSelector.Options.WITH_PARENT});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Parent\\.Answer__c.*?\\bfrom Knowledge__DataCategorySelection\\b').matcher(soql).find(), 'Query returning parent fields' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Parent\\.RecordType..*?\\bfrom Knowledge__DataCategorySelection\\b').matcher(soql).find(), 'Query returning parent recordtype' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)Parent\\.RecordType\\.DeveloperName.*?\\bfrom Knowledge__DataCategorySelection\\b').matcher(soql).find(), 'Query returning parent recordtype developer name' + soql);
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
		List<Knowledge__DataCategorySelection> dataCates = ApplicationTestDataFactoryKnowledge.getDataCatogories(1, false,pushEdmId);
		insert dataCates;		
		// =====================================
		// Testing
		// =====================================
		
        //Fields to Query
        Map<SobjectType, Set<SObjectField>> fieldOverrides = new Map<SobjectType, Set<SObjectField>>();
        fieldOverrides.put(
            Knowledge__DataCategorySelection.SObjectType,
            new Set<SObjectField>{
                Knowledge__DataCategorySelection.DataCategoryGroupName,
                Knowledge__DataCategorySelection.DataCategoryName,
                Knowledge__DataCategorySelection.ParentId
            }
        );
        fieldOverrides.put(
            Knowledge__kav.SobjectType,
            new Set<SObjectField>{
                Knowledge__kav.Answer__c,
                Knowledge__kav.Summary,
                Knowledge__kav.UrlName,
                Knowledge__kav.id,
                Knowledge__kav.Title
            }
        );

        //Passing Knowledge Article Ids
        Map<String, Object> params = new Map<String, Object>{'parentIds' => new Set<Id>{ pushEdmId }};
        KnowledgeDataCategorySelectionsSelector datCatSelector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);
        Set<Object> selectorOptions = new Set<Object>();
        selectorOptions.add(KnowledgeDataCategorySelectionsSelector.Options.WITH_PARENT);
        //Selector should return the data categories related to the given Articles
        List<Knowledge__DataCategorySelection> dataCatesLst = datCatSelector.search(params, selectorOptions, false);
        System.assertEquals(dataCatesLst.size(), dataCates.size(), 'Data categories retrieved based on the given parent Id');

		
		Set<String> allowedArticles = new Set<String>{'PUSH_EDM', 'FAQ'};
		//Passing recordType Names
		params = new Map<String, Object>{'recordTypeNames' => allowedArticles};
		datCatSelector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);
		//Selector should return the data categories related to the given recordType
		dataCatesLst = datCatSelector.search(params, false);
		System.assertEquals(dataCatesLst.size(), dataCates.size(), 'Data categories retrieved based on the given recordTypes');
		
		//Passing recordType and parent Ids to test AND condition
		params = new Map<String, Object>{'recordTypeNames' => allowedArticles, 'parentIds' => new Set<Id>{ pushEdmId }};
		datCatSelector = KnowledgeDataCategorySelectionsSelector.newInstance(fieldOverrides);
		//Selector should return the data categories related to the given recordType and parent Ids
		dataCatesLst = datCatSelector.search(params, true);
		System.assertEquals(dataCatesLst.size(), dataCates.size(), 'Data categories retrieved based on the given recordTypes');		
	}
}