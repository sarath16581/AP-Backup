/***
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tests
 * @domain Core
 * @description Test Class covering ArticlesSelector
 * @changelog
 * 2020-08-02 - Nathan Franklin - Updated for new return values in ApplicationDatabase
 * 2022-11-29 - Mahesh Parvathaneni - Updated for selectByCaseIds method
 * 2024-05-02 - Vasu Gorakati - updated for selectByArticleNames
 * 2024-05-02 - Vasu Gorakati - updated for selectByArticleNames
 * 2024-09-09 - Seth Heang - added test for selectByConsignmentIdAndChildArticles() and newInstance(fieldOverrides)
 * 2024-09-23 - Rejeesh Raghavan - Added test for `selectWithCasesByIdOrTrackingOrName` method
 */
@IsTest
private class ArticlesSelector_Test {

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

		ArticlesSelector selector = ArticlesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		Assert.areEqual(true, Pattern.compile('(?ism)\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select from Article__c: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{ ArticlesSelector.Options.WITH_RECORDTYPE });
		soql = qb.toSoqlString();

		Assert.areEqual(true, Pattern.compile('(?ism)\\bRecordType\\b').matcher(soql).find(), 'Resulting query does not select from RecordType: ' + soql);

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		ArticlesSelector selector = ArticlesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{ArticlesSelector.Options.WITH_CONSIGNMENT});
		soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)Consignment__r\\..*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Consignment__r fields: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{ArticlesSelector.Options.WITH_CHILDARTICLES});
		soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bFrom Articles__r\\b.*?\\).*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Articles__r child records: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{ArticlesSelector.Options.WITH_BILLINGACCOUNT});
		soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)Billing_Account__r\\..*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Billing_Account__r fields: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{ArticlesSelector.Options.FILTER_BY_NETWORK_NOT_NULL});
		soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?is)\\bNetwork__c\\b').matcher(soql).find(), 'Resulting query does not filter Network__c field: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE, ArticlesSelector.Options.WITH_CONSIGNMENT, ArticlesSelector.Options.WITH_CHILDARTICLES, ArticlesSelector.Options.WITH_BILLINGACCOUNT});
		soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)Consignment__r\\..*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Consignment__r fields: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)Billing_Account__r\\..*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Billing_Account__r fields: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)Select.*?\\(Select.*?\\bFrom Articles__r\\b.*?\\).*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Articles__r child records: ' + soql);

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

		ArticlesSelector selector = ArticlesSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Billing_Account__c.SObjectType => new Set<SObjectField>{Billing_Account__c.Name},
				Article__c.SObjectType => new Set<SObjectField>{Article__c.Source_System__c}
		});
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE, ArticlesSelector.Options.WITH_CONSIGNMENT, ArticlesSelector.Options.WITH_BILLINGACCOUNT});
		String soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)Consignment__r\\..*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Consignment__r fields: ' + soql);
		Assert.areEqual(false, Pattern.compile('(?ism)Billing_Account__r\\.Id.*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting selects Billing_Account__r.Id but it shouldn\'t: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)Billing_Account__r\\.Name.*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Billing_Account__r.Name field: ' + soql);
		Assert.areEqual(false, Pattern.compile('(?ism)\\bArticleID__c\\b.*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting selects ArticleID__c but it shouldn\'t: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)\\bSource_System__c\\b.*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Source_System__c field: ' + soql);

		selector = ArticlesSelector.newInstance(new Set<SObjectField>{Article__c.Source_System__c, Article__c.ArticleID__c});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();
		Assert.areEqual(true, Pattern.compile('(?ism)\\bArticleID__c\\b.*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select ArticleID__c field: ' + soql);
		Assert.areEqual(true, Pattern.compile('(?ism)\\bSource_System__c\\b.*?\\bfrom Article__c\\b').matcher(soql).find(), 'Resulting query does not select Source_System__c field: ' + soql);

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

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(2, consignment.Id, false);
		insert articles;

		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		insert cases;

		articles[0].Case__c = cases[0].Id;
		update articles[0];

		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWDeliveryRecordType;
		update cases[0];

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ArticlesSelector selector = ArticlesSelector.newInstance();
		Map<Id, Article__c> results = selector.selectById(new Set<Id>{articles[0].Id});
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		results = selector.selectByArticleIds(new Set<String>{articles[1].ArticleID__c});
		Assert.areEqual(1, results.size(), 'Expected result size of 1');

		results = selector.selectById(new Set<Id>{consignment.Id}, new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE, ArticlesSelector.Options.WITH_CONSIGNMENT, ArticlesSelector.Options.WITH_CHILDARTICLES});
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		Assert.areNotEqual(null, results.values()[0].RecordType, 'Expected RecordType to be populated');
		Assert.areEqual(null, results.values()[0].Consignment__r, 'Expected empty Consignment__r');
		Assert.areEqual(2, results.values()[0].Articles__r.size(), 'Expected Articles__r to be populated');

		results = selector.selectById(new Set<Id>{articles[0].Id}, new Set<Object>{ArticlesSelector.Options.WITH_CONSIGNMENT});
		Assert.areNotEqual(null, results.values()[0].Consignment__r, 'Expected Consignment__r to be populated');

		results = selector.selectByTracking(new Set<String>{articles[0].ArticleID__c}, new Set<Object>{ArticlesSelector.Options.WITH_CONSIGNMENT}, true);
		Assert.areNotEqual(null, results.values()[0].Consignment__r, 'Expected Consignment__r to be populated');
		Assert.areEqual(1, results.size(), 'Expected Articles__r to be populated');

		results = selector.selectByIdOrTracking(new Set<String>{articles[0].ArticleID__c}, new Set<Id>{articles[1].Id}, new Set<Object>{ArticlesSelector.Options.WITH_CONSIGNMENT}, true);
		Assert.areNotEqual(null, results.values()[0].Consignment__r, 'Expected Consignment__r to be populated');
		Assert.areEqual(2, results.size(), 'Expected Articles__r to be populated');

		results = selector.selectByCaseIds(new Set<Id>{cases[0].Id}, new Set<Object>{ArticlesSelector.Options.WITH_EVENTMESSAGES_DESC_ORDER});
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		
		List<Article__c> resultList = selector.selectByArticleNames(new Set<String>{articles[0].Name}, Constants.RECORDTYPE_NAME_ARTICLE_ARTICLE, new Set<Object>{ArticlesSelector.Options.WITH_RECORDTYPE});
		Assert.areEqual(1, resultList.size(), 'Expected result size of 1');

		results = selector.selectWithCasesByIdOrTrackingOrName(
			new Map<String, Object>{
				'trackingIds'=> new Set<String>{articles[0].Name}
				,'caseRecordTypes'=>ResourceCustomerInsightsV1.AP_CASE_RECORDTYPES
				,'closedCaseCutoffDate'=>Date.today().addDays(-30)
			}
			,new Set<Object>{ArticlesSelector.ComplexSubQueryOptions.WITH_RECENT_CASES}
		);
		Assert.areEqual(1, results.size(), 'Expected result size of 1');
		Assert.areEqual(1, results.values()[0].Cases__r.size(), 'Expected result size of 1');
		Test.stopTest();
	}
}