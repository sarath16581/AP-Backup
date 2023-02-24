/***
 * @author Dattaraj Deshmukh
 * @date 2022-12-08
 * @group Tests
 * @tag Selector
 * @tag Case
 * @domain Core
 * @description Test Class covering FeedItemCaseInvestigationDomain
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created
 */

@IsTest
private class FeedItemCaseInvestigationDomain_Test {
	
	
	/**
	 * @test: Ensure modules are registered with domain class.
	 */
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		List<FeedItem> feedItems = new List<FeedItem>();

		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();
		
		ApplicationDomain appDomain = FeedItemCaseInvestigationDomain.newInstance(feedItems);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(FeedItemCaseInvestigationModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}

	/**
	 * @test: Ensure records are filtered when passed to modules. 
	 * Expected to filter out FeedItems related to case investigations only. 
	 */
	@IsTest
	private static void testFeedItemsDomain() {
		
		// =====================================
		// Data Preparation
		// =====================================

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
	
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, null, null, true);
		
		//create case investigation feed items
		List<FeedItem> ciFeedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, true);
		
		//create case feed item
		FeedItem caseFeedItem = ApplicationTestDataFactory.getChatterFeeds(1, cases[0].Id, true)[0];

		List<FeedItem> feedItemsToPass = new List<FeedItem>{ciFeedItems[0], ciFeedItems[1], caseFeedItem};
		// =====================================
		// Stubbing
		// =====================================
		// Stubbing: Not required


		// =====================================
		// Testing
		// =====================================
		
		List<FeedItem> filteredList = (List<FeedItem>)FeedItemCaseInvestigationDomain.newInstance(feedItemsToPass).filter(feedItemsToPass);
		System.assertEquals(2, filteredList.size(), 'should be the same size as the RT list');
		System.assert(filteredList.contains(feedItemsToPass[2]) == false, 'should filter out this record');
	}

}