/**
 * @description			: Test class for FeedCommentCaseInvestigationDomain
 * @author 				: Mahesh Parvathaneni
 * @domain				: Case Investigation
 * @changelog
 * 2023-04-04 - Mahesh Parvathaneni - created
 **/

@IsTest
private class FeedCommentCaseInvestigationDomain_Test {
	
	/**
	 * @test: Ensure modules are registered with domain class.
	 */
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		List<FeedComment> feedComments = new List<FeedComment>();

		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();
		
		ApplicationDomain appDomain = FeedCommentCaseInvestigationDomain.newInstance(feedComments);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(FeedCommentCaseInvestigationModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}

	/**
	 * @test: Ensure records are filtered when passed to modules. 
	 * Expected to filter out FeedComments related to case investigations only. 
	 */
	@IsTest
	private static void testFeedCommentsDomain() {
		
		// =====================================
		// Data Preparation
		// =====================================

		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, null, null, true);
		
		//create case investigation feed items and comments
		List<FeedItem> ciFeedItems = ApplicationTestDataFactory.getChatterFeeds(1, caseInvestigations[0].Id, true);
		List<FeedComment> ciFeedComments = ApplicationTestDataFactory.getFeedComments(1, caseInvestigations[0].Id, ciFeedItems[0].Id, true);
		//create case feed items and comments
		FeedItem caseFeedItem = ApplicationTestDataFactory.getChatterFeeds(1, cases[0].Id, true)[0];
		List<FeedComment> caseFeedComments = ApplicationTestDataFactory.getFeedComments(1, cases[0].Id, caseFeedItem.Id, true);

		List<FeedComment> feedCommentsToPass = new List<FeedComment>{ciFeedComments[0], caseFeedComments[0]};
		// =====================================
		// Stubbing
		// =====================================
		// None


		// =====================================
		// Testing
		// =====================================
		
		List<FeedComment> filteredList = (List<FeedComment>)FeedCommentCaseInvestigationDomain.newInstance(feedCommentsToPass).filter(feedCommentsToPass);
		System.assertEquals(1, filteredList.size(), 'should be the same size as the ciFeedComments list');
		System.assert(filteredList.contains(feedCommentsToPass[1]) == false, 'should filter out this record');
	}
}