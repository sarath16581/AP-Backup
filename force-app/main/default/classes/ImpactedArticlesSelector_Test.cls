/**
 * @description Impacted Articles Selector Test class
 * @author Vasu Gorakati
 * @date 2024-06-18
 * @changelog
 * 2024-06-18 - Vasu Gorakati - Case Hand-off
 * 2024-09-06 - Seth Heang - added tests for selectById() and newInstance(fieldOverrides)
 **/
@IsTest(IsParallel=true)
private class ImpactedArticlesSelector_Test {
	/**
	 * Test: Ensures that the selectors QueryBuilder is generating the correct output
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

		ImpactedArticlesSelector selector = ImpactedArticlesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		Assert.areEqual(true, Pattern.compile('(?ism)\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select from ImpactedArticle__c: ' + soql);

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorIntegration() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, false)[0];
		insert consignment;

		Article__c article = ApplicationTestDataFactory.getArticles(2, consignment.Id, false)[0];
		insert article;

		Case caserec = ApplicationTestDataFactory.getCases(1, false)[0];
		insert caserec;

		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactory.getImpactedArticles(1, caserec.Id, article.Id, false);
		insert impactedArticles;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ImpactedArticlesSelector selector = ImpactedArticlesSelector.newInstance();
		List<ImpactedArticle__c> results = selector.selectByCaseId(new Set<Id>{ caserec.Id }, new Set<Object>());
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		ImpactedArticlesSelector.newInstance();
		results = selector.selectById(new Set<Id>{ impactedArticles[0].Id }, new Set<Object>());
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		Test.stopTest();
	}

	/**
	 * Test: Ensures that the selectors QueryBuilder is generating the correct output
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

		Map<SObjectType, Set<SObjectField>> SELECTOR_FIELDS = new Map<SObjectType, Set<SObjectField>>{
			ImpactedArticle__c.SObjectType => new Set<SObjectField>{ ImpactedArticle__c.Case__c, ImpactedArticle__c.Article__c },
			Case.SObjectType => new Set<SObjectField>{ Case.Id, Case.CaseNumber },
			Article__c.SObjectType => new Set<SObjectField>{ Article__c.ArticleID__c }
		};

		ImpactedArticlesSelector selector = ImpactedArticlesSelector.newInstance(SELECTOR_FIELDS);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ ImpactedArticlesSelector.Options.WITH_CASE, ImpactedArticlesSelector.Options.WITH_ARTICLE });
		String soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)\\bArticle__c\\b.*?\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select Article__c field: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)\\bCase__c\\b.*?\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select Case__c field: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)\\bCase__r.Id\\b.*?\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select Case__r.Id field: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)\\bCase__r.CaseNumber\\b.*?\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select Case__r.CaseNumber field: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)\\bArticle__r.ArticleID__c\\b.*?\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select Article__r.ArticleID__c field: ' + soql);
		Test.stopTest();
	}
}