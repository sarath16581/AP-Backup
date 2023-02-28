/***
 * @author Dattaraj Deshmukh
 * @date 2022-12-08
 * @group Tests
 * @tag Selector
 * @tag Case
 * @domain Core
 * @description Test Class covering FeedItemsSelector
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created
 * 2023-02-28 - Dattaraj Deshmukh - Added 'TEXTPOST_ONLY' in testEnsureQueryBuilderProducesCorrectString method.
 */
@IsTest
private class FeedItemsSelector_Test {

   	/**
	 * Test:
	 * Ensures that the selectors QueryBuilder is generating the correct output
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

		FeedItemsSelector selector = FeedItemsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom FeedItem\\b').matcher(soql).find(), 'Resulting query does not select from FeedItem');

		qb = selector.newQueryBuilder(new Set<Object>{FeedItemsSelector.Options.WITH_CREATEDBY});
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)CreatedBy\\..*?\\bfrom FeedItem\\b').matcher(soql).find(), 'Resulting query does not select User fields');

		Test.stopTest();

	}

	/**
	 * Test:
	 * Executes a query to ensure it returns expected results
	 */
	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		insert articles;

		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		insert cases;

		List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, false);
		networks[0].Org_ID__c = '1234';

		insert networks;

		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, false);
		insert caseInvestigations;

		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, false);
		feedItems[0].Body = 'test feed'; feedItems[1].Body = 'test feed 2';
		insert feedItems;
		
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		FeedItemsSelector selector = FeedItemsSelector.newInstance();
		Map<Id, FeedItem> results = selector.selectById(new Set<Id> {feedItems[0].Id}, new Set<Object>{FeedItemsSelector.Options.TEXTPOST_ONLY});
		System.assert(results.size() >= 1, 'Expected result size greater than or equal to 1');

		FeedItemsSelector selectorLimit = FeedItemsSelector.newInstance(1);
		Map<Id, FeedItem> resultsLimit = selectorLimit.selectById(new Set<Id> {feedItems[0].Id});
		System.assertEquals(1, resultsLimit.size(), 'Expected result size of 1');

		FeedItemsSelector sObjectOverrideSelector = FeedItemsSelector.newInstance(1, new Set<SObjectField>{FeedItem.Id});
		Map<Id, FeedItem> sObjectOverrideSelectorResults = sObjectOverrideSelector.selectById(new Set<Id> {feedItems[0].Id});
		System.assert(sObjectOverrideSelectorResults.size() >= 1, 'Expected result size greater than or equal to 1');

		FeedItemsSelector sObjectTypeOverrideSelector = FeedItemsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{FeedItem.getSObjectType() => new Set<SObjectField>{FeedItem.Id}});
		Map<Id, FeedItem> sObjectTypeOverrideSelectorResults = sObjectTypeOverrideSelector.selectById(new Set<Id> {feedItems[0].Id});
		System.assert(sObjectTypeOverrideSelectorResults.size() >= 1, 'Expected result size greater than or equal to 1');

		Test.stopTest();

	}
}
