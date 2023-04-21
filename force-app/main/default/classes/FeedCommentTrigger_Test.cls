/* 
* @author		: Mahesh Parvathaneni
* @date			: 06/04/2023
* @description	: test class to cover FeedComment Trigger
* @changelog	:
*/

@IsTest
private class FeedCommentTrigger_Test {

	@IsTest
	static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Article__c> articles = ApplicationTestDataFactory.getArticles(1, false);
		insert articles;
		List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
		cases[0].ArticleTest__c = articles[0].Id;
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseStarTrackGeneralEnquiryRecordType;
		insert cases;

		List<FeedItem> feedItems = ApplicationTestDataFactory.getChatterFeeds(1, cases[0].Id, false);
		feedItems[0].Body = 'test feed for case';
		insert feedItems;

		

		// =====================================
		// Stubbing
		// =====================================
		FeedCommentTriggerHandler2 mock = (FeedCommentTriggerHandler2)MockUtility.mockUtility(FeedCommentTriggerHandler2.class);

		// =====================================
		// Testing
		// =====================================
		List<FeedComment> feedComments = ApplicationTestDataFactory.getFeedComments(1, cases[0].Id, feedItems[0].Id, false);
		feedComments[0].CommentBody = 'test comment';

		Test.startTest();
		insert feedComments;
		Test.stopTest();

		((FeedCommentTriggerHandler2) MockUtility.Mocks.verify(mock, MockUtility.Mocks.atLeastOnce())).dispatch();

		System.assertNotEquals(null, feedComments[0].id,'FeedComment should be inserted');

	}
}