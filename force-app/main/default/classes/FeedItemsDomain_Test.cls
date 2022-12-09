/***
 * @author Dattaraj Deshmukh
 * @date 2022-12-08
 * @group Tests
 * @tag Selector
 * @tag Case
 * @domain Core
 * @description Test Class covering FeedItemsDomain
 * @changelog
 * 2022-12-08 - Dattaraj Deshmukh - Created
 */

@isTest
private class FeedItemsDomain_Test {
    /**
	 * Bulk of the tests are handled in the Core class
	 */
	@IsTest
	private static void testFeedItemsDomain() {
        
		// =====================================
        // Data Preparation
        // =====================================
        List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, true);

        List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
        cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;

        List<Network__c> networks = ApplicationTestDataFactory.getNetworks(1, true);
		networks[0].Org_ID__c = '1234';

        List<CaseInvestigation__c> caseInvestigations = ApplicationTestDataFactory.getCaseInvestigations(1, cases[0].Id, articles[0], networks[0].Id, true);
		
		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(2, caseInvestigations[0].Id, true);

		// =====================================
		// Stubbing
		// =====================================
        // Stubbing: Not required


        // =====================================
		// Testing
		// =====================================
		ApplicationDomain.IConstructable constructableDomain = new FeedItemsDomain.Constructor();
		FeedItemsDomain domain = (FeedItemsDomain) constructableDomain.construct(feedItems);

        //asserting feeditems are filtered
		System.assertEquals(2, domain.records.size(), 'Records should have been filtered in call to newInstance');
		system.debug(domain.records[0]);
		System.assertEquals(feedItems[0].Id, domain.records[0].Id, 'Expected record');
    }
}
